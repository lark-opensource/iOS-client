//
//  ShareExtensionHandler.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/6.
//

import Foundation
import LarkContainer
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkExtensionCommon
import LarkCore
import Swinject
import EENavigator
import UniverseDesignToast
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import LarkOpenFeed
import LarkSendMessage
import LarkModel
import LarkNavigator

public protocol LarkMailShareInterface {
    func onShareEml(action: LarkMailShareEmlAction) -> RxSwift.Observable<()>
}

/// shareExtesion 进入飞书事件.
public enum LarkMailShareEmlAction {
    case open(LarkMailShareEmlEntry)
}

public struct LarkMailShareEmlEntry {
    public let data: Data
    public let from: NavigatorFrom

    public init(data: Data, from: NavigatorFrom) {
        self.data = data
        self.from = from
    }
}

public final class ShareExtensionHandler: UserTypedRouterHandler, ForwardAndShareHandler {
    static private let logger = Logger.log(ShareExtensionHandler.self, category: "Module.IM.Share")

    private let disposeBag: DisposeBag = DisposeBag()
    fileprivate var config: ShareExtensionConfig
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    @ScopedInjectedLazy var forwardService: ForwardService?
    @ScopedInjectedLazy var videoMessageSendService: VideoMessageSendService?

    init(userResolver: UserResolver, config: ShareExtensionConfig) {
        self.config = config
        super.init(resolver: userResolver)
    }

    public func handle(_ body: ShareExtensionBody, req: EENavigator.Request, res: Response) throws {
        guard let shareContent = config.shareData(),
            let shareData = shareContent.data() else {
            res.end(resource: EmptyResource())
            ShareExtensionHandler.logger.error("ShareExtension: can not read data.")
            return
        }

        guard let from = req.context.from() else {
            return
        }

        switch shareContent.targetType {
        case .myself:
            sentToMyself(with: shareData, from: from)
        case .friend:
            try sentToFriend(with: shareData, from: from)
        case .eml:
            shareEml(with: shareData, from: from)
        default:
            assert(false, "New share type.")
            ShareExtensionHandler.logger.error(
                "ShareExtension: unknown type.",
                additionalData: ["ShareType": "\(shareContent.targetType)"]
            )
        }

        res.end(resource: EmptyResource())
        return
    }

    private func shareEml(with shareContentData: Data, from: NavigatorFrom) {
        (try? userResolver
            .resolve(assert: LarkMailShareInterface.self))?
            .onShareEml(action: .open(LarkMailShareEmlEntry(data: shareContentData, from: from)))
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] (error) in
                guard let self = self else { return }
                if let fromVC = from.fromViewController {
                    shareExtensionErrorHandler(userResolver: self.userResolver, hud: UDToast(), on: fromVC, error: error)
                }
                self.cancelSend()
                ShareExtensionHandler.logger.error("ShareExtension: share eml failed.", error: error)

            }).disposed(by: self.disposeBag)
    }

    private func sentToMyself(with shareContentData: Data, from: NavigatorFrom) {
        guard let user = chatterManager?.currentChatter else { return }
        let userService = try? resolver.resolve(assert: PassportUserService.self)
        let forwardItem = ForwardItem(avatarKey: user.avatarKey,
                                      name: user.displayWithAnotherName,
                                      subtitle: user.department,
                                      description: user.description_p.text,
                                      descriptionType: user.description_p.type,
                                      localizeName: user.localizedName,
                                      id: user.id,
                                      type: .user,
                                      isCrossTenant: false,
                                      isCrossWithKa: false,
                                      isCrypto: false,
                                      isThread: false,
                                      doNotDisturbEndTime: user.doNotDisturbEndTime,
                                      hasInvitePermission: true,
                                      userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                                      enableThreadMiniIcon: false,
                                      isOfficialOncall: false)
        sendShareData(shareContentData, with: [forwardItem], extraText: "", from: from)
    }

    private func sentToFriend(with shareContentData: Data, from: NavigatorFrom) throws {
        try createForward(with: shareContentData, from: from)
    }

    private func createForward(with shareContentData: Data, from: NavigatorFrom) throws {

        let content = ShareExtensionAlertContent(shareContentData: shareContentData)

        let factory = ForwardAlertFactory(userResolver: self.userResolver)
        guard let provider = factory.createWithContent(content: content) else { return }

        // 分享菜单打开时,进行一些视频预处理
        let movieItem: ShareMovieItem? = {
            if let content = ShareContent(shareContentData) {
                return ShareMovieItem(content.contentData)
            }
            return nil
        }()
        let sendOriginVideo = false // 分享视频目前策略为非原图
        if let movieItem {
            videoMessageSendService?.preprocessVideo(with: .fileURL(movieItem.url),
                                                    isOriginal: sendOriginVideo, scene: .shareFromSystem, preProcessManager: nil)
        }
        let router = ForwardViewControllerRouterImpl(userResolver: userResolver)
        let nvc: LkNavigationController
        let vc = NewForwardViewController(provider: provider, router: router, canForwardToTopic: false)
        nvc = LkNavigationController(rootViewController: vc)
        vc.cancelCallBack = { [weak nvc, weak self] in
            nvc?.dismiss(animated: true, completion: nil)
            self?.cancelSend()
        }

        vc.successCallBack = { [weak self] in
            /// 当选人组件dismiss完成后，会调用此callBack。
            /// 如果分享的内容是视频形式，则在这里进行调用发视频流程。
            ///     因为发视频流程中会弹框提示“是否转文件发送”，如果在点击确认选人后调用发视频流程，弹框会被选人组件马上dismiss掉，从而导致发送失败
            /// 如果是分享其他的内容（图片、文字），则在选人组件点击确认选人后已经调用接口发送
            guard let self,
                  let movieItem,
                  let chats = self.forwardService?.getAndDeleteChatInfoInShareVideo()
            else { return }
            chats.flatMap { chat in
                let sendVideoParams = SendVideoParams(content: .fileURL(movieItem.url),
                                                      isCrypto: chat.isCrypto,
                                                      isOriginal: sendOriginVideo,
                                                      forceFile: chat.isPrivateMode,
                                                      chatId: chat.id,
                                                      threadId: nil,
                                                      parentMessage: nil,
                                                      from: from)
                self.videoMessageSendService?.sendVideo(with: sendVideoParams, extraParam: nil, context: nil, createScene: .commonShare, sendMessageTracker: nil, stateHandler: nil)
            }
        }

        if Display.pad {
            nvc.modalPresentationStyle = .formSheet
        } else {
            nvc.modalPresentationStyle = .fullScreen
        }

        // 当从Lark分享内容到Lark时，Present 会命中正在 dismiss 的 Controller 用来做 present， 造成没有响应的假象。
        // 这里先判断 topMost 是不是在动画中，是则先等动画结束；否则直接执行 present
        // nolint: magic_number
        if let transition = from.fromViewController?.transitionCoordinator,
           transition.isAnimated == true {
            transition.animateAlongsideTransition(in: nil, animation: nil) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.userResolver.navigator.present(nvc, from: from)
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.userResolver.navigator.present(nvc, from: from)
            }
        }
        // enable-lint: magic_number
    }

    func sendShareData(_ data: Data, with items: [ForwardItem], extraText: String, from: NavigatorFrom) {
        let ids = self.itemsToIds(items)
        forwardService?
            .extensionShare(content: data, to: ids.chatIds, userIds: ids.userIds, extraText: extraText)
            .observeOn(MainScheduler.instance).subscribe { [weak self] _ in
                guard let self = self,
                      let content = ShareContent(data),
                      let chats = self.forwardService?.getAndDeleteChatInfoInShareVideo(),
                      let movieItem = ShareMovieItem(content.contentData) else { return }
                chats.flatMap { chat in
                    let sendVideoParams = SendVideoParams(content: .fileURL(movieItem.url),
                                                          isCrypto: chat.isCrypto,
                                                          isOriginal: false,
                                                          forceFile: chat.isPrivateMode,
                                                          chatId: chat.id,
                                                          threadId: nil,
                                                          parentMessage: nil,
                                                          from: from)
                    self.videoMessageSendService?.sendVideo(with: sendVideoParams, extraParam: nil, context: nil, createScene: .commonShare, sendMessageTracker: nil, stateHandler: nil)
                }
            } onError: { [weak self] error in
                guard let self = self else { return }
                if let fromVC = from.fromViewController {
                    shareExtensionErrorHandler(userResolver: self.userResolver, hud: UDToast(), on: fromVC, error: error)
                }
                self.cancelSend()
                ShareExtensionHandler.logger.error("ShareExtension: share failed.", error: error)
            }.disposed(by: self.disposeBag)
    }

    func cancelSend() {
        ShareExtensionHandler.logger.error("ShareExtension: cancel send.")
        config.cleanShareCache()
    }
}
