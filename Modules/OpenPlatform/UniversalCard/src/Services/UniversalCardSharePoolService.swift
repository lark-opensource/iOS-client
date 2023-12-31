//
//  UniversalCardSharePoolService.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/8/17.
//

import Foundation
import UniversalCardInterface
import LKCommonsLogging
import LarkSetting
import EEAtomic
import LarkContainer

public protocol UniversalCardSharePoolProtocol {
    typealias ReuseKey = AnyHashable
    func retainInUse(_ key: ReuseKey)
    func addReuse(_ key: ReuseKey)
    func remove(_ key: ReuseKey)
    func get(_ key: ReuseKey) -> UniversalCard
    func createNew(count: Int)
    func clearAll()
}
private let maxNewCardCount: Int = 15
public class UniversalCardSharePool: UniversalCardSharePoolProtocol {
    public typealias ReuseKey = AnyHashable
    private typealias TimeIntervalCard = (timeInterval: TimeInterval, card: UniversalCard)

    private let logger = Logger.log(UniversalCardSharePool.self, category: "UniversalCardSharePool")
    // 预创建的全新卡片
    @AtomicObject
    private var cardNew : [UniversalCard] = []
    //正在用的缓存池
    @AtomicObject
    private var cardInUse : [ReuseKey: UniversalCard] = [:]

    //可以被复用的缓存vm didEnddisplay的缓存池,用时间戳标记，有相同messageid时直接复用，没找到时使用时间戳最小的。
    @AtomicObject
    private var cardReuse : [ReuseKey: TimeIntervalCard] = [:]

    //复用的lynxview必须放入缓存10ms以上，避免前后卡片突然上屏
    private let reuseMinTimeInterval = 0.01 //10ms

    //复用池lynxView超过缓冲数量5的，且放入缓冲时间超过1秒的，可以被清除节省内存
    private let minClearTimeInterval = 1.0
    private let reuseMaxCount = 5
    //保证复用时可复用的卡片数大于3，避免endDisplay后直接willDisplay上屏的lynxView被别的cell拿走复用了，导致原卡片空白
    private let reuseMinCount = 3

    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func createNew(count: Int) {
        // 取创建数量, 创建数量不能比剩余可创建数量大
        let count = min(maxNewCardCount - cardNew.count, count)
        guard count > 0 else { return }
        for _ in 1...count { cardNew.append(UniversalCard.create(resolver: resolver)) }
    }

    private func getNew() -> UniversalCard {
        var card = cardNew.popLast()
        if card == nil {
            if Thread.isMainThread { card = UniversalCard.create(resolver: resolver) }
            // 极端情况下切主线程创建, 若子线程在等主线程, 可能引起死锁, 只允许内部使用
            else { DispatchQueue.main.sync { card = UniversalCard.create(resolver: self.resolver, renderMode: .async) } }
        }
        // 新的被使用, 继续创建保持缓存池健康
        let isHealth = cardNew.count > 5
        DispatchQueue.main.async {
            if isHealth  { self.createNew(count: 1) }
            else { self.createNew(count: 5) }
        }
        return card ?? UniversalCard.create(resolver: resolver)
    }

    //由于存在didenddisplay后放入缓存池后，原有cell不经更新渲染直接上屏，这里重新放回正在使用的池 cardInUse
    public func retainInUse(_ key: ReuseKey) {
        guard let card = cardReuse[key]?.card else { return }
        cardInUse[key] = card
        cardReuse.removeValue(forKey: key)
    }

    public func addReuse(_ key: ReuseKey) {
        guard let card = cardInUse[key] else {
            logger.error("AddReuse failed \(key) cardInUse don't have it")
            return
        }
        cardInUse.removeValue(forKey: key)
        if cardReuse[key] != nil {
            logger.error("AddReuse failed \(key) reuse pool had it ")
        }
        cardReuse[key] = (Date().timeIntervalSince1970, card)
        clearReuse()
    }
    
    public func remove(_ key: ReuseKey) {
        cardReuse.removeValue(forKey: key)
        cardInUse.removeValue(forKey: key)
    }

    // 获取 UniversalCard, 内部会优先拿使用中的 Card, 其次是已创建的新 Card, 其次是切主线程创建
    public func get(_ key: ReuseKey) -> UniversalCard {
        if let card = cardInUse[key] {
            return card
        }
        if let card = cardReuse[key]?.card {
            cardInUse[key] = card
            cardReuse.removeValue(forKey: key)
            return card
        }

        //需要找到最旧的card进行复用
        if cardReuse.count > reuseMinCount,
           var oldestElement = cardReuse.first {
            for element in cardReuse {
                if element.value.timeInterval < oldestElement.value.timeInterval {
                    oldestElement = element
                }
            }
            if Date().timeIntervalSince1970 - oldestElement.value.timeInterval > reuseMinTimeInterval {
                cardInUse[key] = oldestElement.value.card
                cardReuse.removeValue(forKey: oldestElement.key)
                let time = Date().timeIntervalSince1970
                logger.info("pool cardReuse \(key) use other \(oldestElement.key) nowTime:\(time)  oldTime:\(oldestElement.value.timeInterval) \(cardInUse.count)")
                clearReuse()
                return oldestElement.value.card
            }
        }
        let card = FeatureGatingManager.shared.featureGatingValue(with: "universalcard.async_render.enable") ? getNew() : UniversalCard.create(resolver: resolver)
        cardInUse[key] = card
        clearReuse()
        return card
    }

    //超过缓冲数量5的，且放入缓冲时间超过1秒的清掉
    func clearReuse() {
        let needClearCount = cardReuse.count - reuseMaxCount
        guard needClearCount > 0 else { return }
        let now = Date().timeIntervalSince1970
        let cards = cardReuse.sorted(by: {$0.value.timeInterval<$1.value.timeInterval})
        for index in 0..<needClearCount {
            let timeCard = cards[index]
            guard now - timeCard.value.timeInterval > minClearTimeInterval else {
                return
            }
            cardReuse.removeValue(forKey: timeCard.key)
        }
    }

    public func clearAll() {
        cardNew.removeAll()
        cardInUse.removeAll()
        cardReuse.removeAll()
    }
}
