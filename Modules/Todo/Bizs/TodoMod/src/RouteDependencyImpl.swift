//
//  RouteDependencyImpl.swift
//  LarkTodo
//
//  Created by 张威 on 2021/1/25.
//

import EENavigator
import LarkNavigator
import Swinject
import RxSwift
import LarkUIKit
import RustPB
import LarkAccountInterface
import LarkFeatureGating
import LarkModel
import TodoInterface
import LarkContainer

#if MessengerMod
import LarkMessengerInterface
import LarkForward
import LarkSDKInterface
import LarkChat
import LarkMessageBase
import TodoInterface
import LarkMessageCore
import LarkCore
import LKCommonsTracker
#endif

final class RouteDependencyImpl: RouteDependency, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var passportUserService: PassportUserService?
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    /// 选择分享目标
    func selectSharingItem(with body: SelectSharingItemBody, params: RouteParams) {
        #if MessengerMod
        let factory = ForwardAlertFactory(userResolver: userResolver)
        guard let provider = factory.createWithContent(content: body) else {
            return
        }
        if let router = try? userResolver.resolve(assert: ForwardViewControllerRouterProtocol.self) {
            let vc = NewForwardViewController(provider: provider, router: router)
            doJump(with: vc, params: params)
        }
        #endif
    }

    /// 显示 profile 页
    func showProfile(with chatterId: String, params: RouteParams) {
        #if MessengerMod
        let body = PersonCardBody(
            chatterId: chatterId,
            sourceName: "",
            source: .unknownSource
        )
        doJump(with: body, params: params)
        #endif
    }

    /// 显示 at picker
    func showAtPicker(
        title: String,
        chatId: String,
        onSelect: @escaping ((_ viewConroller: UIViewController?, _ seletedId: String) -> Void),
        onCancel: @escaping (() -> Void),
        params: RouteParams
    ) {
        #if MessengerMod
        let info = ChatterPickerSource.TodoInfo(
            chatId: chatId,
            isAssignee: true
        )
        var body = getBasePickerBody(title: title, info: info)
        body.selectStyle = .single(style: .callbackWithReset)
        body.selectedCallback = { (viewController, results) in
            if let item = results.chatterInfos.first {
                onSelect(viewController, item.ID)
            }
        }
        body.cancelCallback = onCancel
        doJump(with: body, params: params)
        #endif
    }

    func showOwnerPicker(
        title: String,
        chatId: String?,
        selectedChatterIds: [String],
        supportbatchAdd: Bool,
        disableBatchAdd: Bool,
        batchHandler: ((UIViewController) -> Void)?,
        selectedCallback: ((UIViewController?, [String]) -> Void)?,
        params: RouteParams
    ) {
        #if MessengerMod
        let info = ChatterPickerSource.TodoInfo(
            chatId: chatId,
            isAssignee: true,
            isBatchAdd: supportbatchAdd,
            isDisableBatch: disableBatchAdd,
            onTapBatch: supportbatchAdd ? batchHandler : nil
        )
        var body = getBasePickerBody(title: title, info: info)
        body.selectStyle = .single(style: .callbackWithReset)
        body.forceSelectedChatterIds = selectedChatterIds
        body.selectedCallback = { (viewController, res) in
            let ids = res.chatterInfos.map { $0.ID }
            selectedCallback?(viewController, ids)
        }
        doJump(with: body, params: params)
        #endif
    }

    func showSharePicker(
        title: String,
        selectedChatterIds: [String],
        selectedCallback: ((UIViewController?, [TodoContactPickerResult], [TodoContactPickerResult]) -> Void)?,
        params: RouteParams
    ) {
        #if MessengerMod
        let info = ChatterPickerSource.TodoInfo(
            chatId: nil,
            isAssignee: true,
            isShare: true
        )
        var body = getSharePickerBody(title: title, info: info)
        body.forceSelectedChatterIds = selectedChatterIds
        body.supportSelectGroup = true
        body.selectedCallback = { (viewController, res) in
            let users = res.chatterInfos.map { info in
                return TodoContactPickerResult(
                    identifier: info.ID,
                    name: info.name,
                    avatarKey: info.avatarKey
                )
            }
            let groups = res.chatInfos.map { info in
                return TodoContactPickerResult(
                    identifier: info.id,
                    name: info.name,
                    avatarKey: info.avatarKey
                )
            }
            selectedCallback?(viewController, users, groups)
        }
        doJump(with: body, params: params)
        #endif
    }

    /// 显示选人组件
    func showChatterPicker(
        title: String,
        chatId: String?,
        isAssignee: Bool,
        selectedChatterIds: [String],
        selectedCallback: ((UIViewController?, [String]) -> Void)?,
        params: RouteParams
    ) {
        #if MessengerMod
        let info = ChatterPickerSource.TodoInfo(
            chatId: chatId,
            isAssignee: isAssignee
        )
        var body = getBasePickerBody(title: title, info: info)
        body.forceSelectedChatterIds = selectedChatterIds
        body.selectedCallback = { [weak self] (viewController, res) in
            let ids = res.chatterInfos.map { $0.ID }
            Tracker.post(TeaEvent("todo_select_click", params: [
                "click": "confirm",
                "select_type": isAssignee ? "is_exector" : "is_follower",
                "selected_member_count": ids.count,
                "is_select_all": info.isSelectAll ? 1 : 0
            ]))
            selectedCallback?(viewController, ids)
        }
        doJump(with: body, params: params)
        #endif
    }

    #if MessengerMod
    private func getBasePickerBody(title: String, info: ChatterPickerSource.TodoInfo) -> ChatterPickerBody {
        var body = ChatterPickerBody()
        body.source = .todo(info)
        body.supportCustomTitleView = true
        body.allowDisplaySureNumber = false
        body.needSearchOuterTenant = true
        body.title = title
        return body
    }
    #endif

    #if MessengerMod
    private func getSharePickerBody(title: String, info: ChatterPickerSource.TodoInfo) -> ChatterPickerBody {
        var body = ChatterPickerBody()
        body.source = .todo(info)
        body.supportCustomTitleView = true
        body.allowDisplaySureNumber = false
        body.needSearchOuterTenant = true
        body.title = title
        return body
    }
    #endif

    private func fixChannel(in message: inout Basic_V1_Message) {
        if !message.hasChannel || (message.channel.type == .chat && message.channel.id != message.chatID) {
            var channel = Basic_V1_Channel()
            channel.id = message.chatID
            channel.type = .chat
            message.channel = channel
        }
        if message.type == .mergeForward {
            for i in 0..<message.content.mergeForwardContent.messages.count {
                fixChannel(in: &message.content.mergeForwardContent.messages[i])
            }
        }
    }

    /// 显示合并消息详情
    func showMergedMessageDetail(withEntity entity: Basic_V1_Entity, messageId: String, params: RouteParams) {
        #if MessengerMod
        do {
            var entity = entity
            for k in entity.messages.keys {
                fixChannel(in: &entity.messages[k]!)
            }
            let fakeChatPB = Basic_V1_Chat()
            let chat = LarkModel.Chat.transform(pb: fakeChatPB)
            let message = try LarkModel.Message.transform(entity: entity, id: messageId, currentChatterID: "")
            let body = MergeForwardDetailBody(message: message, chat: chat, downloadFileScene: .todo)
            doJump(with: body, params: params)
        } catch {
            //
        }
        #endif
    }

    func showChat(with chatId: String, position: Int32?, params: RouteParams) {
        #if MessengerMod
        let body = ChatControllerByIdBody(chatId: chatId, position: position)
        doJump(with: body, params: params)
        #endif
    }

    func showThread(with threadId: String, position: Int32?, params: RouteParams) {
        #if MessengerMod
        let body = ThreadDetailByIDBody(threadId: threadId, loadType: .position, position: position)
        doJump(with: body, params: params)
        #endif
    }

    /// 跳转到大搜
    /// - Parameter from: home
    func showMainSearchVC(from: UIViewController) {
        #if MessengerMod
        let searchMainBody = SearchMainBody(
            searchTabName: "todo"
        )
        userResolver.navigator.push(body: searchMainBody, from: from)
        #endif
    }

    func previewImages(
        _ image: PreviewImages,
        sourceIndex: Int,
        sourceView: UIImageView?,
        from: UIViewController
    ) {
        #if MessengerMod
        let assets: [LarkMessengerInterface.Asset]
        switch image {
        case .property(let images):
            assets = images.map { property -> Asset in
                var asset = LarkMessengerInterface.Asset(sourceType: .post(property))
                asset.isAutoLoadOrigin = true
                asset.forceLoadOrigin = true
                asset.visibleThumbnail = sourceView
                asset.key = property.originKey
                return asset
            }
        case .imageSet(let images):
            assets = images.map { imageSet -> Asset in
                var asset = LarkMessengerInterface.Asset(sourceType: .image(imageSet))
                asset.isAutoLoadOrigin = true
                asset.forceLoadOrigin = true
                asset.visibleThumbnail = sourceView
                asset.key = imageSet.origin.key
                return asset
            }
        @unknown default: return
        }
        var body = PreviewImagesBody(
            assets: assets,
            pageIndex: sourceIndex,
            scene: .normal(assetPositionMap: [:], chatId: nil),
            shouldDetectFile: true,
            canShareImage: false,
            hideSavePhotoBut: true,
            canTranslate: false,
            translateEntityContext: (nil, .other)
        )
        body.customTransition = BaseImageViewWrapperTransition()
        userResolver.navigator.present(body: body, from: from)
        #endif
    }

    func showLocalFile(
        from: UIViewController,
        enableCount: Int,
        chooseLocalFiles: (([TaskFileInfo]) -> Void)?,
        chooseFilesChange: (([String]) -> Void)?,
        cancelCallback: (() -> Void)?
    ) {
        #if MessengerMod
        var body = LocalFileBody()
        let gigaByte = 1024 * 1024 * 1024
        body.maxSelectCount = enableCount
        body.maxSingleFileSize = 10 * gigaByte
        body.maxTotalFileSize = 10 * gigaByte
        body.requestFrom = .other
        body.chooseLocalFiles = { files in
            let baseTime = Int64(Date().timeIntervalSince1970 * 1000)
            let taskFiles = files.enumerated().map { (index, file) in
                TaskFileInfo(
                    name: file.name,
                    fileURL: file.fileURL.path,
                    size: file.size,
                    uploadTime: baseTime + Int64(index)
                )
            }
            chooseLocalFiles?(taskFiles)
        }
        body.chooseFilesChange = chooseFilesChange
        body.cancelCallback = cancelCallback
        userResolver.navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
        #endif
    }
}

extension RouteDependencyImpl {

    private func doJump<T: EENavigator.Body>(with body: T, params: RouteParams) {
        if params.openType == .present {
            userResolver.navigator.present(
                body: body,
                context: params.context,
                wrap: params.wrap,
                from: params.from,
                prepare: params.prepare,
                animated: params.animated,
                completion: { (_, _)  in params.completion?() }
            )
        } else {
            userResolver.navigator.push(
                body: body,
                context: params.context,
                from: params.from,
                animated: params.animated,
                completion: { (_, _) in params.completion?() }
            )
        }
    }

    private func doJump(with viewController: UIViewController, params: RouteParams) {
        if params.openType == .present {
            var controller = viewController
            if let wrap = params.wrap, !(controller is UINavigationController) {
                controller = wrap.init(rootViewController: controller)
            }
            params.prepare?(controller)
            params.from.present(controller, animated: params.animated, completion: params.completion)
        } else {
            userResolver.navigator.push(
                viewController,
                from: params.from,
                animated: params.animated,
                completion: params.completion
            )
        }
    }

}
