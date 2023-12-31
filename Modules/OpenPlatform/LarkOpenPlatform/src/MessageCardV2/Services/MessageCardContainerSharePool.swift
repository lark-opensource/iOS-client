//
//  MessageCardContainerSharePool.swift
//  LarkOpenPlatform
//
//  Created by zhangjie.alonso on 2023/7/10.
//

import Foundation
import LarkMessageCard
import LKCommonsLogging
import LarkContainer
import LarkSetting


protocol MessageCardContainerSharePoolService {
    func retainInuse(_ key: AnyHashable)
    func addReuse(_ key: AnyHashable)
    func remove(_ key: AnyHashable)
    func get(_ cardContainerData: MessageCardContainer.ContainerData, reuseKey: UUID) -> MessageCardContainer
}

public class MessageCardContainerSharePool: MessageCardContainerSharePoolService {
    typealias TimeIntervalContainer = (timeInterval: TimeInterval, container: MessageCardContainer)
    let logger = Logger.log(MessageCardContainerSharePool.self, category: "MessageCardContainerSharePool")
    let lock = NSLock()

    //正在用的缓存池
    //key: cardID
    private var containerInUse : [AnyHashable: MessageCardContainer] = [:]

    //可以被复用的缓存vm didEnddisplay的缓存池,用时间戳标记，有相同messageid时直接复用，没找到时使用时间戳最小的。
    //key: cardID
    private var containerReuse : [AnyHashable: TimeIntervalContainer] = [:]

    //复用的lynxview必须放入缓存10ms以上，避免前后卡片突然上屏
    private let reuseMinTimeInterval = 0.01 //10ms

    //复用池lynxView超过缓冲数量5的，且放入缓冲时间超过1秒的，可以被清除节省内存
    private let minClearTimeInterval = 1.0
    private let reuseMaxCount = 5

    //保证复用时可复用的卡片数大于5，避免endDisplay后直接willDisplay上屏的lynxView被别的cell拿走复用了，导致原卡片空白
    private let reuseMinCount = 3

    //原来使用messageID作为key，后发现话题套话题时，同一个会话存在同一个messageID的两张卡片，这里换用uuid
    @FeatureGatingValue(key: "universalcard.resuepooluseuuid.enable")
    var enableReusePoolUseUUID

    //由于存在didenddisplay后放入缓存池后，原有cell不经更新渲染直接上屏，这里重新放回正在使用的池 containerInUse
    //key: cardID
    public func retainInuse(_ key: AnyHashable) {
        lock.lock()
        defer {
            lock.unlock()
        }

        if containerInUse.keys.contains(key) {
            return
        }
        if let container = containerReuse[key]?.container {
            containerInUse[key] = container
            containerReuse.removeValue(forKey: key)
            return
        }
        logger.error("pool error retainCache failed \(key) containerInUse:\(containerInUse.count) containerReuse:\(containerReuse.count)")
    }

    //key: cardID
    public func addReuse(_ key: AnyHashable) {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let container = containerInUse[key] else {
            logger.error("pool error addReuse failed \(key) containerInUse don't have it")
            return
        }
        containerInUse.removeValue(forKey: key)
        if containerReuse[key] != nil {
            logger.error(" error addResue \(key) reuse pool had it ")
        }
        containerReuse[key] = (Date().timeIntervalSince1970, container)
        clearReuse()
    }

    //key: cardID
    public func remove(_ key: AnyHashable) {
        lock.lock()
        defer {
            lock.unlock()
        }
        containerReuse.removeValue(forKey: key)
        containerInUse.removeValue(forKey: key)

    }

    public func get(_ cardContainerData: MessageCardContainer.ContainerData, reuseKey: UUID) -> MessageCardContainer {
        lock.lock()
        defer {
            lock.unlock()
        }

        //根据FG切换复用池key
        let key: AnyHashable = enableReusePoolUseUUID ? reuseKey : cardContainerData.cardID
        if let container = containerInUse[key] {
            return container
        }
        if let container = containerReuse[key]?.container {
            containerInUse[key] = container
            containerReuse.removeValue(forKey: key)
            return container
        }

        //需要找到最旧的container进行复用
        if containerReuse.count > reuseMinCount,
           var oldestElement = containerReuse.first {
            for element in containerReuse {
                if element.value.timeInterval < oldestElement.value.timeInterval {
                    oldestElement = element
                }
            }
            if Date().timeIntervalSince1970 - oldestElement.value.timeInterval > reuseMinTimeInterval {
                containerInUse[key] = oldestElement.value.container
                containerReuse.removeValue(forKey: oldestElement.key)
                let time = Date().timeIntervalSince1970
                logger.info("pool containerReuse \(key) use other \(oldestElement.key) nowTime\(time)  oldTime:\(oldestElement.value.timeInterval) \(containerInUse.count)")
                clearReuse()
                return oldestElement.value.container
            }
        }

        let container = MessageCardContainer.create(cardContainerData)
        containerInUse[key] = container
        clearReuse()
        return container
    }

    //超过缓冲数量5的，且放入缓冲时间超过1秒的清掉
    func clearReuse() {

        let needClearCount = containerReuse.count - reuseMaxCount
        guard needClearCount > 0 else {
            return
        }
        let now = Date().timeIntervalSince1970
        let containers = containerReuse.sorted(by: {$0.value.timeInterval<$1.value.timeInterval})
        for index in 0..<needClearCount {
            let timeContainer = containers[index]
            guard now - timeContainer.value.timeInterval > minClearTimeInterval else {
                return
            }
            containerReuse.removeValue(forKey: timeContainer.key)
        }
    }
}
