//
//  OpenRedPacketHandler.swift
//  LarkCore
//
//  Created by CharlieSu on 2018/11/7.
//

import Foundation
import LarkContainer
import Swinject
import LarkFoundation
import LarkUIKit
import LarkModel
import RxSwift
import EENavigator
import LarkNavigator
import LKCommonsLogging
import UniverseDesignToast
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkSetting
import LarkPrivacySetting

final class OpenRedPacketHandler: UserTypedRouterHandler {

    private let disposeBag = DisposeBag()

    private var chatIds: [String] = []
    private var toast: UDToast?
    private lazy var disableUserInteractionFG: Bool = {
        guard let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self) else { return false }
        return featureGatingService.staticFeatureGatingValue(with: "messenger.redpacket.loading_disable_user_interaction")
    }()
    private static let logger = Logger.log(OpenRedPacketHandler.self, category: "open.red.packet.handle")

    override init(resolver: UserResolver) {
        super.init(resolver: resolver)
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(chatMessagesVcDisAppear(_:)),
              name: NSNotification.Name("ChatMessagesViewControllerDisAppear"),
              object: nil
            )
    }

    func handle(_ body: OpenRedPacketBody, req: EENavigator.Request, res: Response) throws {

        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }
        let chatId = body.chatId
        let messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        let redPacketAPI = try userResolver.resolve(assert: RedPacketAPI.self)
        switch body.model {
        case .message(let message):
            guard let content = message.content as? HongbaoContent else { return }
            redPacketCellDidClick(message: message,
                                  chatId: chatId,
                                  redpacketId: content.id,
                                  redPacketAPI: redPacketAPI,
                                  from: from)
        case .ids(let mesageId, let hongbaoId):
            let hud = from.fromViewController?.viewIfLoaded?.window.map {
                UDToast.showLoading(on: $0, disableUserInteraction: true)
            }
            messageAPI.fetchMessage(id: mesageId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (message) in
                    hud?.remove()
                    guard let `self` = self else { return }
                    self.redPacketCellDidClick(message: message,
                                               chatId: chatId,
                                               redpacketId: hongbaoId,
                                               redPacketAPI: redPacketAPI,
                                               from: from)
                }, onError: { (_) in
                    hud?.remove()
                }).disposed(by: disposeBag)

        case .messageId(let messageId):
            let hud = from.fromViewController?.viewIfLoaded?.window.map {
                UDToast.showLoading(on: $0, disableUserInteraction: true)
            }
            messageAPI.fetchMessage(id: messageId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (message) in
                    hud?.remove()
                    guard let `self` = self else { return }
                    guard let content = message.content as? HongbaoContent else { return }
                    self.redPacketCellDidClick(message: message,
                                               chatId: chatId,
                                               redpacketId: content.id,
                                               redPacketAPI: redPacketAPI,
                                               from: from)
                }, onError: { (_) in
                    hud?.remove()
                }).disposed(by: disposeBag)

        }
        res.end(resource: EmptyResource())
    }

    @objc
    private func chatMessagesVcDisAppear(_ notification: NSNotification) {
        if disableUserInteractionFG {
            return
        }
        Self.logger.info("chatMessagesVc disAppear")
        guard let notificationInfo = notification.object as? [String: Any] else { return }
        guard let chatId = notificationInfo["chatId"] as? String else { return }
        removeRedFlag(chatId)
        if let hud = toast {
            hud.remove()
        }
    }

    private func removeRedFlag(_ chatId: String) {
        if !chatId.isEmpty,
           chatIds.contains(chatId),
           let index = chatIds.firstIndex(of: chatId) {
            Self.logger.info("removeRedFlag chatId Success")
            chatIds.remove(at: index)
        }
    }
    /// 红包被点击
    ///
    /// - Parameters:
    ///   - message: 红包message
    ///   - redPacketAPI: 红包API
    private func redPacketCellDidClick(message: Message,
                                       chatId: String?,
                                       redpacketId: String,
                                       redPacketAPI: RedPacketAPI,
                                       from: NavigatorFrom) {
        // 获取权限SDK支付开关，默认打开，无权限则不处理红包点击
        let isPay = LarkPayAuthority.checkPayAuthority()
        guard isPay else {
            if let fromeView = from.fromViewController?.viewIfLoaded {
                UDToast.showTips(with: BundleI18n.LarkFinance.Lark_Core_OpenRedPacketDisabledByAdmin_Toast,
                                 on: fromeView)
            }
            Self.logger.info("redPacketCellDidClick isPay:\(isPay)")
            return
        }
        Self.logger.info("redPacketCellDidClick disableUserInteractionFG \(disableUserInteractionFG)")
        if let chatId = chatId,
           !disableUserInteractionFG,
           !chatIds.contains(chatId) {
            Self.logger.info("redPacketCellDidClick addChatId \(disableUserInteractionFG)")
            chatIds.append(chatId)
        }
        //先getInfo
        let fromeView = disableUserInteractionFG ? from.fromViewController?.viewIfLoaded?.window : from.fromViewController?.viewIfLoaded
        let hud = fromeView.map {
            UDToast.showLoading(on: $0, disableUserInteraction: disableUserInteractionFG)
        }
        toast = hud
        redPacketAPI.getRedPaketInfo(redPacketID: redpacketId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                guard let `self` = self,
                      let redPacketAPI = try? self.userResolver.resolve(assert: RedPacketAPI.self),
                      let payManagerService = try? self.userResolver.resolve(assert: PayManagerService.self) else { return }
                Self.logger.info("getRedPaketInfo Success")
                if let charId = chatId,
                   !self.disableUserInteractionFG,
                   !self.chatIds.contains(charId) {
                    Self.logger.info("getRedPaketInfo chatIds notContain chatId \(self.chatIds.count) \(self.disableUserInteractionFG)")
                    return
                }
                if !self.disableUserInteractionFG {
                    self.removeRedFlag(chatId ?? "")
                }
                let isMeSendP2PRedPacket = info.type == .p2P && message.isMeSend(userId: self.userResolver.userID)
                if !info.hasPermissionToGrab /// 专属红包，自己不可以领取
                    || (!isMeSendP2PRedPacket && !info.canGrab)
                    || isMeSendP2PRedPacket {
                    self.gotoRedPacketResult(redPakcetID: redpacketId,
                                             type: .unknown,
                                             redPacketInfo: info,
                                             redPacketAPI: redPacketAPI,
                                             from: from,
                                             hud: hud)
                } else {
                    let vc = OpenRedPacketViewController(
                        currentChatterID: self.userResolver.userID,
                        messageID: message.id,
                        chatID: chatId,
                        redPacketInfo: info,
                        redPacketAPI: redPacketAPI,
                        payManager: payManagerService,
                        userResolver: self.userResolver
                    )
                    self.userResolver.navigator.present(vc, wrap: nil, from: from, animated: Display.phone) // iPad 上关闭动画
                    hud?.remove()
                }

                redPacketAPI
                    .updateRedPacket(messageID: message.id,
                                     type: .unknown,
                                     isClicked: true,
                                     isGrabbed: (info.grabAmount != nil),
                                     isGrabbedFinish: info.isGrabbedFinish,
                                     isExpired: info.isExpired)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            }, onError: { [weak fromeView, weak self] (error) in
                print(error)
                Self.logger.error("getRedPaketInfo error \(error)")
                guard let self = self else { return }
                if !self.disableUserInteractionFG {
                    self.removeRedFlag(chatId ?? "")
                }
                hud?.remove()
                if let view = fromeView {
                    UDToast.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_NetworkError, on: view, error: error)
                }
            })
            .disposed(by: disposeBag)
    }

    private func gotoRedPacketResult(redPakcetID: String,
                                     type: RedPacketType,
                                     redPacketInfo: RedPacketInfo? = nil,
                                     receiveInfo: RedPacketReceiveInfo? = nil,
                                     redPacketAPI: RedPacketAPI,
                                     from: NavigatorFrom,
                                     hud: UDToast? = nil) {
        let hud = hud ?? from.fromViewController?.viewIfLoaded?.window.map {
            UDToast.showLoading(on: $0, disableUserInteraction: true)
        }

        let infoOb: Observable<RedPacketInfo>
        if let redPacketInfo = redPacketInfo {
            infoOb = Observable.just(redPacketInfo)
        } else {
            infoOb = redPacketAPI.getRedPaketInfo(redPacketID: redPakcetID)
        }

        let receiveOb: Observable<RedPacketReceiveInfo>
        if let receiveInfo = receiveInfo {
            receiveOb = Observable.just(receiveInfo)
        } else {
            receiveOb = redPacketAPI.getRedPacketReceiveDetail(redPacketID: redPakcetID, type: type, cursor: "", count: 20)
        }

        Observable.zip(infoOb, receiveOb)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (infoResponse, detailResponse) in
                let body = RedPacketResultBody(redPacketInfo: infoResponse, receiveInfo: detailResponse)
                self.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: {
                    $0.modalPresentationStyle = .formSheet
                })
                hud?.remove()
            }, onError: { (error) in
                hud?.remove()
                Self.logger.error("gotoRedPacketResult error \(error)")
                if let fromView = from.fromViewController?.viewIfLoaded?.window {
                    UDToast.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_NetworkError, on: fromView, error: error)
                }
            })
            .disposed(by: disposeBag)
    }
}
