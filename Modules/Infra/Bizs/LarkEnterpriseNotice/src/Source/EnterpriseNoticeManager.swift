//
//  EnterpriseNoticeManager.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import RustPB
import ServerPB
import LarkContainer
import RxSwift
import LarkSDKInterface
import ThreadSafeDataStructure
import LarkPushCard
import LKCommonsLogging
import LarkNavigator
import LarkStorage
import Homeric
import LKCommonsTracker
import LarkSetting

public protocol EnterpriseNoticeService {
    /// 全量拉取Card数据
    func loadAllEnterpriseNoticeCards()

    /// 更新卡片数据
    func addEnterpriseNoticeCards(_ cards: [EnterpriseNoticeCard])
    
    /// 移除卡片数据
    func removeEnterpriseNoticeCards(_ cards: [EnterpriseNoticeCard])

    /// 上报已读通知卡片
    func uploadEnterpriseNoticeAckState(id: Int64, confirmType: CardConfirmType)
}

final class EnterpriseNoticeManager: EnterpriseNoticeService, EnterpriseNoticeViewDelegate {

    static let logger = Logger.log(EnterpriseNoticeManager.self, category: "EnterpriseNoticeManager")

    // 正在展示的卡片
    private var showingCards: [EnterpriseNoticeCard] = []

    private var userResolver: UserResolver

    private var noticeAPI: EnterpriseNoticeAPI

    private var pushEnterpriseNoticeCards: Observable<PushEnterpriseNoticeMessage>

    private var pushWebSocketStatus: Observable<PushWebSocketStatus>

    private let pushCardService = PushCardCenter.shared

    private let disposeBag = DisposeBag()

    // KVStore
    private static let domain = Domain.biz.messenger.child("EnterpriseNotice")
    private let kvStore: KVStore

    init(userResolver: UserResolver,
         noticeAPI: EnterpriseNoticeAPI,
         pushEnterpriseNoticeCards: Observable<PushEnterpriseNoticeMessage>,
         pushWebSocketStatus: Observable<PushWebSocketStatus>) {
        self.userResolver = userResolver
        self.noticeAPI = noticeAPI
        self.pushWebSocketStatus = pushWebSocketStatus
        self.pushEnterpriseNoticeCards = pushEnterpriseNoticeCards
        self.kvStore = KVStores.udkv(space: .user(id: self.userResolver.userID), domain: Self.domain)
        if FeatureGatingManager.shared.featureGatingValue(with: "lark.subscriptions.dialog") {
            self.pushWebSocketStatus
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] webSocketStatus in
                    switch webSocketStatus.status {
                    case .success:
                        self?.loadAllEnterpriseNoticeCards()
                    @unknown default:
                        break
                    }
            }).disposed(by: self.disposeBag)

            self.pushEnterpriseNoticeCards
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] message in
                    switch message.status {
                    case .new:
                        self?.addEnterpriseNoticeCards([message.card])
                    case .confirm, .delete:
                        self?.removeEnterpriseNoticeCards([message.card])
                    }
            }).disposed(by: self.disposeBag)
        }
    }

    /// 全量拉取Card数据
    func loadAllEnterpriseNoticeCards() {
        noticeAPI.pullEnterpriseNoticeCardInfo()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] cards in
                Self.logger.info("load enterprise notice card success!, card ids: \(cards.map({ $0.id }))")
                guard let self = self else {
                    return
                }
                let removeCards = self.showingCards.filter({ showingCard in
                    !cards.contains(where: { showingCard.id == $0.id })
                })
                self.removeEnterpriseNoticeCards(removeCards)
                self.addEnterpriseNoticeCards(cards)
        }, onError: { error in
            Self.logger.error("load enterprise notice card faild! error: \(error)")
        }).disposed(by: self.disposeBag)
    }

    func addEnterpriseNoticeCards(_ cards: [EnterpriseNoticeCard]) {
        // 按时间排序
        cards.sorted(by: { $0.receiveTime < $1.receiveTime }).forEach({ card in
            // 如果本地记录了上报的key，则不再展示
            let key = Self.transCardIdToStoreKey(card.id)
            if self.kvStore.contains(key: key) {
                self.uploadEnterpriseNoticeAckState(id: card.id, confirmType: .close)
                return
            }
            // 未确认且未展示
            if !card.isConfirmed,
               !self.showingCards.contains(where: { $0.id == card.id }){
                self.showingCards.append(card)
                let cardable = self.createCardWith(card)
                self.pushCardService.post(cardable)
                Tracker.post(TeaEvent(Homeric.IM_SUBSCRIPTION_POPUP_CARD_VIEW, params: ["pop_up_id": "\(card.id)"]))
                self.uploadEnterpriseNoticeCardExposeEvent(ids: [card.id])
            }
        })
    }

    func removeEnterpriseNoticeCards(_ cards: [EnterpriseNoticeCard]) {
        cards.forEach({ card in
            // 需要关闭
            if let index = showingCards.firstIndex(where: { $0.id == card.id }) {
                let id = "\(card.id)"
                showingCards.remove(at: index)
                self.pushCardService.remove(with: id)
            }
        })
    }

    /// 上报已读通知卡片
    func uploadEnterpriseNoticeAckState(id: Int64, confirmType: CardConfirmType) {
        self.noticeAPI.uploadEnterpriseNoticeCardAckStatus(id: id, confirmType: confirmType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                let key = Self.transCardIdToStoreKey(id)
                if self.kvStore.contains(key: key) {
                    self.kvStore.removeValue(forKey: key)
                }
                Self.logger.info("upload enterprise notice ack success, id: \(id)")
            }, onError: { error in
                // 根据卡片id保存上报失败状态
                self.kvStore.set(true, forKey: Self.transCardIdToStoreKey(id))
                Self.logger.error("upload enterprise notice ack failed, id: \(id), error: \(error)")
        }).disposed(by: self.disposeBag)
    }

    private func createCardWith(_ card: EnterpriseNoticeCard) -> Cardable {
        let view = EnterpriseNoticeView(card: card)
        view.delegate = self
        let model = EnterpriseNoticeModel(id: "\(card.id)",
                                          priority: card.closable ? .normal : .medium,
                                          customView: view,
                                          removeHandler: { [weak self] _ in
            self?.uploadEnterpriseNoticeAckState(id: card.id, confirmType: .close)
        })
        return model
    }

    // 上报曝光事件,支持订阅号后台曝光统计
    func uploadEnterpriseNoticeCardExposeEvent(ids: [Int64]) {
        self.noticeAPI.uploadEnterpriseNoticeCardExposeEvent(ids: ids).subscribe().disposed(by: self.disposeBag)
    }

    func didClickMainBtn(cardInfo: EnterpriseNoticeCard) {
        let params = ["pop_up_id": "\(cardInfo.id)",
                      "click": "confirm"]
        Tracker.post(TeaEvent(Homeric.IM_SUBSCRIPTION_POPUP_CARD_CLICK, params: params))
        self.pushCardService.remove(with: "\(cardInfo.id)")
        self.uploadEnterpriseNoticeAckState(id: cardInfo.id, confirmType: .open)
        showingCards.removeAll(where: { $0.id == cardInfo.id })
        guard let window = userResolver.navigator.mainSceneWindow,
              let url = URL(string: cardInfo.buttonLink) else {
            return
        }
        userResolver.navigator.push(url, from: window)
    }

    func didClickCloseBtn(cardInfo: EnterpriseNoticeCard) {
        let params = ["pop_up_id": "\(cardInfo.id)",
                      "click": "cancel"]
        Tracker.post(TeaEvent(Homeric.IM_SUBSCRIPTION_POPUP_CARD_CLICK, params: params))
        self.pushCardService.remove(with: "\(cardInfo.id)")
        self.uploadEnterpriseNoticeAckState(id: cardInfo.id, confirmType: .close)
        showingCards.removeAll(where: { $0.id == cardInfo.id })
    }

    static func transCardIdToStoreKey(_ cardId: Int64) -> String {
        return "enterprise_notice_\(cardId)"
    }
}
