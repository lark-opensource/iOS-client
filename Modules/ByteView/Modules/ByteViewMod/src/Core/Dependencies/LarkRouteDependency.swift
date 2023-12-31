//
//  LarkRouteDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import LarkContainer
import LarkNavigator
import ByteView
import ByteViewCommon
import ByteViewLiveCert
import ByteViewNetwork
import ByteViewInterface
import LarkSceneManager
import LarkUIKit
import LarkTab
#if canImport(LarkCustomerService)
import LarkCustomerService
#endif
#if canImport(LarkAssetsBrowser)
import LarkAssetsBrowser
#endif
#if canImport(LarkRVC)
import LarkRVC
#endif
#if canImport(WebBrowser)
import WebBrowser
#endif
#if MessengerMod
import LarkMessengerInterface
#endif
#if CCMMod
import SpaceInterface
#endif

final class LarkRouteDependency: RouteDependency {
    private static let logger = Logger.getLogger("Dependency")

    private let userResolver: UserResolver
    private var navigator: UserNavigator { userResolver.navigator }
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func gotoUserProfile(userId: String, meetingTopic: String, sponsorName: String, sponsorId: String, meetingId: String, from: UIViewController) {
        #if MessengerMod
        Self.logger.info("gotoUserProfile: \(userId), topic = \(meetingTopic), meetingId = \(meetingId), sponsor = \(sponsorId), \(sponsorName)")
        let sender = meetingTopic.isEmpty ? sponsorName : ""
        let body = PersonCardBody(chatterId: userId, chatId: "", fromWhere: .none, senderID: sponsorId, sender: sender,
                                  sourceID: meetingId, sourceName: meetingTopic, source: .vc)
        navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: from, prepareForPresent: { vc in
            vc.modalPresentationStyle = .formSheet
        })
        #endif
    }

    func gotoUpgrade(from: UIViewController) {
        #if MessengerMod
        navigator.push(body: MineAboutLarkBody(), from: from)
        #endif
    }

    func launchCustomerService() {
        #if canImport(LarkCustomerService)
        _ = try? userResolver.resolve(assert: LarkCustomerServiceAPI.self).launchCustomerService()
        #endif
    }

    func gotoCustomer(from: UIViewController) {
        #if canImport(LarkCustomerService)
        let routerParams = RouterParams(sourceModuleType: .videoChat, needDissmiss: false, prepare: { $0.modalPresentationStyle = .fullScreen })
        try? userResolver.resolve(assert: LarkCustomerServiceAPI.self).showCustomerServicePage(routerParams: routerParams, onSuccess: nil, onFailed: nil)
        #endif
    }

    func gotoDocs(urlString: String, context: [String: Any], from: UIViewController) {
        Self.logger.info("gotoDocs: \(urlString)")
        #if CCMMod
        if let url = URL(string: urlString) {
            navigator.push(url, context: context, from: from, animated: true)
        }
        #else
        let docVC = UIViewController()
        docVC.title = "Docs:\(urlString)"
        navigator.push(docVC, from: from)
        #endif
    }

    func gotoChat(body: ChatBody, fromGetter: @escaping () -> UIViewController, completion: ((UIViewController, Int) -> Void)?) {
        Self.logger.info("gotoChat: \(body.chatId), isGroup = \(body.isGroup), switchFeedTab = \(body.switchFeedTab)")
        #if MessengerMod
        if body.switchFeedTab {
            navigator.switchTab(Tab.feed.url, from: fromGetter(), animated: true) { _ in
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: body.chatId, selectionType: .skipSame)
                ]
                if body.isGroup {
                    self.navigator.showDetail(body: body.toChatBody(), context: context, wrap: LkNavigationController.self, from: fromGetter())
                } else {
                    self.navigator.showDetail(body: body.toChattterBody(), context: context, wrap: LkNavigationController.self, from: fromGetter())
                }
            }
        } else {
            if body.isGroup {
                let from = fromGetter()
                let count = from.navigationController?.viewControllers.count ?? 0
                let controllerService = ChatViewControllerServiceImpl(messageCloseBlock: body.messageCloseBlock, messageRenderBlock: body.messageRenderBlock, messageDeinitBlock: body.messageDeinitBlock)
                var chatBody = body.toChatBody()
                chatBody.controllerService = controllerService
                if body.isPresent {
                    navigator.present(body: chatBody, wrap: LkNavigationController.self, from: from, prepare: { $0.modalPresentationStyle = .fullScreen }, animated: body.animated, completion: { _, resp in
                        if let chatVC = resp.resource as? UIViewController {
                            controllerService.associateToObject(chatVC)
                        }
                        completion?(from, count)
                    })
                } else {
                    navigator.push(body: chatBody, from: from, completion: { _, _ in
                        completion?(from, count)
                    })
                }
            } else {
                navigator.push(body: body.toChattterBody(), from: fromGetter())
            }
        }
        #else
        let chatVC = UIViewController()
        chatVC.title = "消息聊天页面"
        navigator.push(chatVC, from: fromGetter())
        #endif
    }

    func openURL(_ url: URL, from: UIViewController) {
        Self.logger.info("openURL: \(url)")
        #if canImport(WebBrowser)
        navigator.present(body: SimpleWebBody(url: url), wrap: LkNavigationController.self, from: from, prepare: { $0.modalPresentationStyle = .fullScreen })
        #else
        UIApplication.shared.open(url)
        #endif
    }

    func hasValidNavigableContent(for url: URL, context: [String: Any]) -> Bool {
        navigator.response(for: url).resource != nil
    }

    func push(_ url: URL, context: [String: Any], from: UIViewController, forcePush: Bool, animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        navigator.push(url, context: context, from: from, forcePush: forcePush, animated: animated) { (_, response) in
            completion?(response.resource != nil, response.error?.current)
        }
    }

    func present(_ url: URL, context: [String: Any], from: UIViewController, animated: Bool, completion: ((Bool, Error?) -> Void)?) {
        navigator.present(url, context: context, from: from, animated: animated) { (_, response) in
            completion?(response.resource != nil, response.error?.current)
        }
    }
    func showDetailOrPush(_ url: URL,
                          context: [String: Any],
                          from: UIViewController,
                          animated: Bool,
                          completion: ((Bool, Error?) -> Void)?) {
        navigator.showDetailOrPush(url, context: context, wrap: LkNavigationController.self, from: from, animated: animated) { (_, response) in
            completion?(response.resource != nil, response.error?.current)
        }
    }

    func gotoGeneralSettings(source: String, from: UIViewController) {
        #if MessengerMod
        navigator.presentOrPush(body: MineSettingBody(), wrap: LkNavigationController.self, from: from, prepareForPresent: { vc in
            vc.modalPresentationStyle = .formSheet
        }) { _, res in
            guard let vc = res.resource as? UIViewController else { return }
            self.navigator.push(body: ByteViewSettingsBody(source: source), from: vc)
        }
        #endif
    }

    var mainSceneWindow: UIWindow? {
        navigator.mainSceneWindow
    }

    /// needs LarkAssetsBrowser
    func showImagePicker(from: UIViewController, sendButtonTitle: String?, takePhotoEnable: Bool,
                         completion: @escaping (UIViewController, PickedImage?) -> Void) {
        #if canImport(LarkAssetsBrowser)
        let imagePicker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1), isOriginal: true, isOriginButtonHidden: false, sendButtonTitle: sendButtonTitle, takePhotoEnable: false)
        imagePicker.showMultiSelectAssetGridViewController()
        imagePicker.imagePickerFinishSelect = { (picker, result) in
            guard let asset = result.selectedAssets.first, asset.mediaType == .image else {
                completion(picker, nil)
                return
            }
            let image = PickedImage(fileSize: asset.size, fileName: asset.assetResource?.originalFilename,
                                    pixelSize: asset.originSize, isGIF: asset.isGIF) { () -> UIImage? in
                asset.originalImage()
            }
            completion(picker, image)
        }
        imagePicker.imagePikcerCancelSelect = { (picker, _) in
            completion(picker, nil)
        }
        imagePicker.modalPresentationStyle = .fullScreen
        from.present(imagePicker, animated: true, completion: nil)
        #else
        let vc = UIViewController()
        vc.title = "ImagePicker"
        vc.modalPresentationStyle = .fullScreen
        from.present(vc, animated: true, completion: nil)
        #endif
    }

    func gotoChatterPicker(_ msg: String, displayStatus: Int, disableUserKey: String?, disableGroupKey: String?, customView: UIView?, pickedConfirmCallBack: (([LivePermissionMember]) -> Void)?, defaultSelectedMembers: [LivePermissionMember]?, from: UIViewController) {
        #if MessengerMod
        let picker = VCLiveSettingPicker(msg, displayStatus: displayStatus, disableUserKey: disableUserKey, disableGroupKey: disableGroupKey, customView: customView, pickedConfirmCallBack: pickedConfirmCallBack, defaultSelectedMembers: defaultSelectedMembers, from: from)
        let body = picker.buildBody()
        navigator.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .fullScreen })
        #endif
    }

    func gotoLiveCert(from: UIViewController, wrap: UINavigationController.Type?, callback: ((Result<Void, Error>) -> Void)?) {
        if let service = try? userResolver.resolve(assert: CertService.self) {
            service.showLiveCert(from: from, wrap: wrap, callback: callback)
        }
    }

    func presentOrPushViewController(_ vc: UIViewController, from: UIViewController, style: UIModalPresentationStyle, withWrap: Bool) {
        navigator.presentOrPush(vc, wrap: withWrap ? LkNavigationController.self : nil, from: from, prepareForPresent: { vc in
            vc.modalPresentationStyle = style
        })
    }

    func gotoRVCPage(roomId: String, meetingId: String, from: UIViewController) {
        #if canImport(LarkRVC)
        Self.logger.info("present LRVC page if needed , roomId: \(roomId), meetingId: \(meetingId), from: \(from)")
        let body = LRVCWebContainerBody(roomId: roomId, meetingId: meetingId)
        navigator.present(body: body, from: from)
        #endif
    }
}

#if MessengerMod
class ChatViewControllerServiceImpl: ChatViewControllerService {
    static var associcateKey: UInt8 = 0

    private var messageCloseBlock: (() -> Void)?
    private var messageRenderBlock: (() -> Void)?
    private var messageDeinitBlock: (() -> Void)?

    init(messageCloseBlock: (() -> Void)?, messageRenderBlock: (() -> Void)?, messageDeinitBlock: (() -> Void)?) {
        self.messageCloseBlock = messageCloseBlock
        self.messageRenderBlock = messageRenderBlock
        self.messageDeinitBlock = messageDeinitBlock
    }

    deinit {
        messageDeinitBlock?()
    }

    func associateToObject(_ object: Any) {
        objc_setAssociatedObject(object, &ChatViewControllerServiceImpl.associcateKey, self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func backDismissAndCloseSceneItemTapped() {
        messageCloseBlock?()
    }

    func messagesBeenRendered() {
        messageRenderBlock?()
    }
}

extension ChatBody {
    func toChatBody() -> ChatControllerByIdBody {
        let fromWhere: ChatFromWhere = setFromWhere ? .vcMeeting : .ignored
        return ChatControllerByIdBody(chatId: chatId, position: position, fromWhere: fromWhere, showNormalBack: showNormalBack)
    }

    func toChattterBody() -> ChatControllerByChatterIdBody {
        return ChatControllerByChatterIdBody(chatterId: chatId, position: position, isCrypto: false)
    }
}
#endif
