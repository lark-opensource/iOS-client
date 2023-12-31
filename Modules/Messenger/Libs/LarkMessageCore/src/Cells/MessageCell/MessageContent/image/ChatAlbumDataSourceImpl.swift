//
//  ChatAlbumDataSourceImpl.swift
//  LarkMessageCore
//
//  Created by 王元洵 on 2021/5/26.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkModel
import RxSwift
import RxCocoa
import DateToolsSwift
import LarkSDKInterface
import LarkUIKit
import RustPB
import LarkAssetsBrowser
import ByteWebImage
import LarkCore
import LarkContainer
import LarkSetting
import EENavigator
import LKCommonsLogging
import LKCommonsTracker
import LarkAlertController
import UniverseDesignToast

typealias MessageMeta = Media_V1_GetChatResourcesResponse.MessageMeta
typealias MediaResource = RustPB.Media_V1_GetChatResourcesResponse.Resource

final class ChatAlbumDataSourceImpl: UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver

    private var countInitRequest: Int32 {
        if Display.phone { return  countPerRequest }
        return countPerRequest * 2
    }
    private let countPerRequest: Int32 = 20
    private let requestResourceTypes: [RustPB.Media_V1_ChatResourceType] = [.image, .video]
    private let disposeBag = DisposeBag()
    private let chat: Chat
    private let isMeSend: (String) -> Bool

    private var initialStatus = BehaviorRelay<InitialStatus>(value: .initialLoading)
    private var hasMore = false
    private var lastResourceMessageId: String?
    private var loadingMore = false
    private var hasFetchInitData = false

    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy private var fileDependency: DriveSDKFileDependency?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    private lazy var canTranslate: Bool = {
        return fgService?.staticFeatureGatingValue(with: .init(key: .imageViewerInOtherScenesTranslateEnable)) ?? false
    }()

    private static let logger = Logger.log(ChatAlbumDataSourceImpl.self,
                                           category: "LarkMessageCore.MediaDataSourceImpl")

    //以时间维度划分 本周/本月/按月划分
    private var resourceMap: [String: [Resource]] = [:]
    //以key划分
    private var resourceKeyMap: [String: Resource] = [:]
    //resourceMap key有序排列后的数组，供ui顺序显示
    private var sections: [String] = []

    //供ui使用,数据源的copy
    private (set) var sectionsDataSource: [String] = []
    private var resourceMapDataSource: [String: [Resource]] = [:]

    private lazy var dataQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "SearchImageInChatViewModelDataQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    fileprivate lazy var dataScheduler: OperationQueueScheduler = {
        let scheduler = OperationQueueScheduler(operationQueue: dataQueue)
        return scheduler
    }()

    private let tableRefreshPublish = PublishSubject<(TableViewFreshType)>()
    var tableRefreshDriver: Driver<(TableViewFreshType)> {
        return tableRefreshPublish
            .asDriver(onErrorRecover: { _ in .empty() })
            .do(onNext: { [weak self] (_) in
                self?.sectionsDataSource = self?.sections ?? []
                self?.resourceMapDataSource = self?.resourceMap ?? [:]
            })
    }

    lazy var initialStatusDirver: Driver<InitialStatus> = {
        return initialStatus.asDriver()
    }()

    init(chat: Chat, isMeSend: @escaping (String) -> Bool, userResolver: UserResolver) {
        self.chat = chat
        self.isMeSend = isMeSend
        self.userResolver = userResolver
    }

    private func handleError(isInitial: Bool) {
        if isInitial {
            self.initialStatus.accept(.initialError)
        } else {
            self.tableRefreshPublish.onNext(.loadMoreFail(hasMore: self.hasMore))
            self.loadingMore = false
        }
    }

    private func handle(result: FetchChatResourcesResult,
                        isInitial: Bool) {
        self.messageAPI?.fetchMessages(ids: result.messageMetas.map { $0.id })
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }

                self.setUpResource(lastResourceMessageId: result.messageMetas.last?.id,
                                   metas: zip(result.messageMetas, messages).map { $0 },
                                   hasMoreBefore: result.hasMoreBefore)
                self.tableRefreshPublish.onNext(.refresh(hasMore: self.hasMore))

                if isInitial {
                    self.initialStatus.accept(.initialFinish)
                } else {
                    self.loadingMore = false
                }
            },
            onError: { [weak self] error in
                Self.logger.error("fetch messages failed!", error: error)
                self?.handleError(isInitial: isInitial)
            }).disposed(by: self.disposeBag)
    }

    private func setUpResource(lastResourceMessageId: String?,
                               metas: [(MessageMeta, Message)],
                               hasMoreBefore: Bool) {
        self.hasMore = hasMoreBefore
        let currentDate = Date()
        for (meta, message) in metas {
            let metaCreateDate = Date(timeIntervalSince1970: TimeInterval(meta.createTime))
            let metaResources = meta.resources.map { (responseResource) -> Resource in
                let resource = Resource(messageId: meta.id,
                                        messagePosition: meta.position,
                                        threadId: meta.threadID,
                                        threadPosition: meta.threadPosition,
                                        data: responseResource,
                                        fromPost: message.type == .post,
                                        asset: self.transform(resource: responseResource, message: message),
                                        isBurnMessage: message.isOnTimeDel)

                self.resourceKeyMap[resource.key] = resource
                return resource
            }
            if metaCreateDate.year == currentDate.year,
               metaCreateDate.month == currentDate.month,
               metaCreateDate.weekOfMonth == currentDate.weekOfMonth {
                //本周
                self.addToResourceMap(resources: metaResources,
                                      key: BundleI18n.LarkMessageCore.Lark_Legacy_ThisWeek)
            } else if metaCreateDate.year == currentDate.year,
                      metaCreateDate.month == currentDate.month {
                //本月
                self.addToResourceMap(resources: metaResources,
                                      key: BundleI18n.LarkMessageCore.Lark_Legacy_ThisMonth)
            } else {
                //按年-月划分
                let year = metaCreateDate.year
                let month = metaCreateDate.month
                let key = "\(year)-\(month)"
                self.addToResourceMap(resources: metaResources, key: key)
            }
        }
        self.lastResourceMessageId = lastResourceMessageId
    }

    private func addToResourceMap(resources: [Resource], key: String) {
        if var resourcesInMap = self.resourceMap[key] {
            resourcesInMap.append(contentsOf: resources)
            self.resourceMap[key] = resourcesInMap
        } else {
            self.resourceMap[key] = resources
            self.sections.append(key)
        }
    }

    private func transform(resource: MediaResource,
                           message: Message) -> LKDisplayAsset {
        switch resource.type {
        case .image:
            return LKDisplayAsset.asset(with: resource.image,
                                        isTranslated: false,
                                        isOriginSource: resource.isOriginSource,
                                        originSize: resource.originSize,
                                        isAutoLoadOrigin: isMeSend(message.fromId),
                                        permissionState: self.chatSecurityControlService?.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow,
                                        message: message,
                                        chat: self.chat)
        case .video:
            let mediaContent = MediaContent.transform(
                content: resource.video.mediaContent,
                filePath: resource.video.filePath)

            return LKDisplayAsset.asset(with: .init(
                                            content: mediaContent,
                                            messageId: message.id,
                                            messageRiskObjectKeys: message.riskObjectKeys,
                                            fatherMFId: message.fatherMFMessage?.id,
                                            replyThreadRootId: message.threadMessageType == .threadReplyMessage ? message.rootId : nil,
                                            channelId: self.chat.id,
                                            sourceId: "",
                                            sourceType: .typeFromUnkonwn,
                                            isSuccess: true,
                                            downloadFileScene: nil),
                                        message: message,
                                        permissionState: self.chatSecurityControlService?.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            )

        @unknown default:
            assert(false, "new value")
        }
        return .init()
    }

    private func gernateForwardMessageTitle() -> String {
        switch self.chat.type {
        case .p2P:
            if chat.chatter?.id == chatterManager?.currentChatter.id ?? "" {
                return BundleI18n.LarkMessageCore.Lark_Legacy_ChatMergeforwardtitlebyoneside(chat.chatter?.displayName ?? "")
            } else {
                let myName = chatterManager?.currentChatter.displayName ?? ""
                let otherName = chat.chatter?.displayName ?? ""
                return BundleI18n.LarkMessageCore.Lark_Legacy_ChatMergeforwardtitlebytwoside(myName, otherName)
            }
        case .group, .topicGroup:
            return BundleI18n.LarkMessageCore.Lark_Legacy_ForwardGroupChatHistory
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkMessageCore.Lark_Legacy_ForwardGroupChatHistory
        }
    }
}

private extension ChatAlbumDataSourceImpl {
    private enum ResourceType {
        case image
        case video(duration: Int32)
    }

    private struct Resource {
        let messageId: String
        let threadId: String
        let messagePosition: Int32
        let threadPosition: Int32
        let fromPost: Bool
        let key: String
        let imageItemSet: ImageItemSet
        let type: ResourceType
        let asset: LKDisplayAsset
        let isBurnMessage: Bool

        init(messageId: String,
             messagePosition: Int32,
             threadId: String,
             threadPosition: Int32,
             data: MediaResource,
             fromPost: Bool,
             asset: LKDisplayAsset,
             isBurnMessage: Bool) {
            self.messageId = messageId
            self.messagePosition = messagePosition
            self.threadId = threadId
            self.threadPosition = threadPosition
            self.fromPost = fromPost
            self.asset = asset
            self.isBurnMessage = isBurnMessage

            switch data.type {
            case .image:
                self.key = data.image.origin.key
                self.imageItemSet = ImageItemSet.transform(imageSet: data.image)
                self.type = .image
            case .video:
                self.key = data.video.mediaContent.image.origin.key
                self.imageItemSet = ImageItemSet.transform(imageSet: data.video.mediaContent.image)
                self.type = .video(duration: data.video.mediaContent.duration)
            @unknown default:
                assertionFailure("new value")
                self.key = ""
                self.imageItemSet = .init()
                self.type = .image
            }
        }

        func transform() -> LKMediaResource {
            switch self.type {
            case .image:
                return LKMediaResource(data: self.imageItemSet,
                                       type: .image,
                                       key: self.key,
                                       canSelect: !self.fromPost && !asset.permissionState.canNotReceive,
                                       permissionState: asset.permissionState)
            case .video(let duration):
                return LKMediaResource(data: self.imageItemSet,
                                       type: .video(duration: duration),
                                       key: self.key,
                                       canSelect: !self.fromPost && !asset.permissionState.canNotReceive,
                                       permissionState: asset.permissionState)
            }
        }
    }
}

/// LKMediaAssetsDataSource protocol
extension ChatAlbumDataSourceImpl: LKMediaAssetsDataSource {
    var currentResourceCount: Int { self.resourceKeyMap.count }

    func fetchInitData() {
        self.chatAPI?
            .fetchChatResources(chatId: chat.id, count: countInitRequest, resourceTypes: requestResourceTypes)
            .observeOn(dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }

                self.handle(result: result, isInitial: true)
            }, onError: { [weak self] (error) in
                Self.logger.error("fetch initial data failed!", error: error)
                self?.handleError(isInitial: true)
            }).disposed(by: self.disposeBag)
    }

    func loadMore() {
        guard !loadingMore, let lastResourceMessageId = lastResourceMessageId else {
            return
        }

        self.loadingMore = true
        self.chatAPI?
            .fetchChatResources(chatId: chat.id,
                                fromMessageId: lastResourceMessageId,
                                count: countPerRequest,
                                direction: .before,
                                resourceTypes: requestResourceTypes)
            .observeOn(dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }

                self.handle(result: result, isInitial: false)
            }, onError: { [weak self] (error) in
                Self.logger.error("load more data failed!", error: error)
                self?.handleError(isInitial: false)
            }).disposed(by: self.disposeBag)
    }

    func resources(section: Int) -> [LKMediaResource] {
        let key = sectionsDataSource[section]
        if let resources = self.resourceMapDataSource[key] {
            return resources.map { $0.transform() }
        } else {
            assertionFailure()
            return []
        }
    }

    func resource(section: Int, row: Int) -> LKMediaResource {
        return self.resources(section: section)[row]
    }

    func didTapSelect() { PublicTracker.AssetsBrowser.Click.chatAlbumClick(action: .select) }

    func didTapAsset(with key: String,
                     in sourceVC: UIViewController,
                     thumbnail: UIImageView?) {
        guard let resource = self.resourceKeyMap[key] else {
            assertionFailure("shoud not happen")
            return
        }
        let scene: PreviewImagesScene
        if resource.messagePosition != replyInThreadMessagePosition {
            scene = PreviewImagesScene.chatAlbum(chatId: chat.id,
                                                 messageId: resource.messageId,
                                                 position: resource.messagePosition,
                                                 isMsgThread: false)

        } else {
            scene = PreviewImagesScene.chatAlbum(chatId: chat.id,
                                                 messageId: resource.threadId,
                                                 position: resource.threadPosition,
                                                 isMsgThread: true)
        }

        if !resource.asset.permissionState.isAllow {
            switch resource.asset.permissionState {
            case .allow:
                assertionFailure()
            case .previewDeny:
                let type: SecurityControlEvent
                switch resource.type {
                case .image:
                    type = .localImagePreview
                case .video:
                    type = .localVideoPreview
                }
                //这里authResult实在不好传过来，只好重新请求一次。这里的authResult只用于弹窗，anonymousId和message不传 不会有影响。 @jiaxiao
                if let authResult = self.chatSecurityControlService?.checkPermissionPreview(anonymousId: "", message: nil).1 {
                    self.chatSecurityControlService?.authorityErrorHandler(event: type, authResult: authResult, from: sourceVC, errorMessage: nil, forceToAlert: true)
                }
            case .receiveDeny:
                self.chatSecurityControlService?.alertForDynamicAuthority(event: .receive, result: .deny, from: sourceVC)
            case .receiveLoading:
                self.chatSecurityControlService?.alertForDynamicAuthority(event: .receive, result: .loading, from: sourceVC)
            }
            return
        }
        // 优先判断跳转文件 之后再判断跳转图片预览的场景
        if !goToFilePreviewIfNeeded(resource: resource, sourceVC: sourceVC) {
            self.goToImagePreview(resource: resource, scene: scene, sourceVC: sourceVC)
        }
    }

    private func goToFilePreviewIfNeeded(
        resource: Resource,
        sourceVC: UIViewController
    ) -> Bool {
        switch resource.asset.extraInfo[ImageAssetExtraInfo] as? LKImageAssetSourceType ?? .other {
        case .video(let info):
            if info.isPCOriginVideo,
               !info.messageId.isEmpty {
                var startTime = CACurrentMediaTime()
                messageAPI?.fetchMessage(id: info.messageId).observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self, weak sourceVC] (message) in
                        guard let `self` = self, let fromVC = sourceVC else { return }
                        var extra: [String: Any] = [:]
                        if let downloadFileScene = info.downloadFileScene {
                            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
                        }
                        let fileMessage = message.transformToFileMessageIfNeeded()
                        self.fileDependency?.openSDKPreview(
                            message: fileMessage,
                            chat: nil,
                            fileInfo: nil,
                            from: fromVC,
                            supportForward: true,
                            canSaveToDrive: true,
                            browseFromWhere: .file(extra: extra)
                        )
                        Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                            "result": 1,
                            "cost_time": (CACurrentMediaTime() - startTime) * 1000
                        ]))
                    }, onError: { error in
                        Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                            "result": 0,
                            "cost_time": (CACurrentMediaTime() - startTime) * 1000,
                            "errorMsg": "\(error)"
                        ]))
                    }).disposed(by: disposeBag)
                return true
            }
        default:
            break
        }
        return false
    }

    private func goToImagePreview(
        resource: Resource,
        scene: PreviewImagesScene,
        sourceVC: UIViewController
    ) {
        let body = PreviewImagesBody(
            assets: [resource.asset.transform()],
            pageIndex: 0,
            scene: scene,
            trackInfo: PreviewImageTrackInfo(messageID: resource.messageId),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: !chat.enableRestricted(.download),
            showImageOnly: false,
            canTranslate: self.canTranslate,
            translateEntityContext: (resource.messageId, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )

        self.navigator.present(body: body, from: sourceVC)
    }

    func getDisplayAsset(with key: String) -> LKDisplayAsset {
        guard let resource = self.resourceKeyMap[key] else {
            assertionFailure("resource do not match")
            return .init()
        }

        return resource.asset
    }

    func forwardButtonDidTapped(with keys: [String],
                                from sourceVC: UIViewController,
                                isMerge: Bool,
                                completion: (() -> Void)?) {
        PublicTracker.AssetsBrowser.Click.chatAlbumClick(action: .forward)

        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: sourceVC.view)
            return
        }

        let pickedMessageIds = keys
            .map { self.resourceKeyMap[$0]?.messageId }
            .compactMap { $0 }
        let containBurnMessage = keys.contains(where: { self.resourceKeyMap[$0]?.isBurnMessage == true })

        if isMerge {
            self.navigator.present(
                body: MergeForwardMessageBody(
                    originMergeForwardId: nil,
                    fromChannelId: self.chat.id,
                    messageIds: pickedMessageIds,
                    title: self.gernateForwardMessageTitle(),
                    traceChatType: .unknown,
                    finishCallback: nil,
                    containBurnMessage: containBurnMessage,
                    afterForwardBlock: completion),
                from: sourceVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        } else {
            self.navigator.present(
                body: BatchTransmitMessageBody(
                    fromChannelId: self.chat.id,
                    originMergeForwardId: nil,
                    messageIds: pickedMessageIds,
                    title: self.gernateForwardMessageTitle(),
                    traceChatType: .unknown,
                    containBurnMessage: containBurnMessage,
                    finishCallback: nil),
                from: sourceVC,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        }
    }

    func deleteButtonDidTapped(with keys: [String],
                               completion: (() -> Void)? = nil) {
        PublicTracker.AssetsBrowser.Click.chatAlbumClick(action: .delete)

        let pickedMessageIds = keys
            .map { self.resourceKeyMap[$0]?.messageId }
            .compactMap { $0 }

        self.messageAPI?.delete(messageIds: pickedMessageIds)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                // 更新resourceMap
                var newResourceMap: [String: [Resource]] = [:]
                self.resourceMap.forEach {
                    let deletedList = $0.value.filter { resource in
                        !pickedMessageIds.contains(resource.messageId)
                    }
                    if !deletedList.isEmpty {
                        newResourceMap[$0.key] = deletedList
                    }
                }
                self.resourceMap = newResourceMap

                // 更新sections
                self.sections = self.sections.filter { self.resourceMap[$0] != nil }

                // 更新keyMap
                self.resourceKeyMap = self.resourceKeyMap.filter { !keys.contains($0.key) }

                // 更新ui
                self.tableRefreshPublish.onNext(.delete(hasMore: self.hasMore))

                completion?()

            }, onError: { error in
                Self.logger.error("delete message failed!", error: error)
            }).disposed(by: self.disposeBag)
    }
}

class DefaultAlbumDataSourceImpl: LKMediaAssetsDataSource {
    var sectionsDataSource: [String] = []

    var initialStatusDirver: RxCocoa.Driver<LarkAssetsBrowser.InitialStatus> = .empty()

    var tableRefreshDriver: RxCocoa.Driver<(LarkAssetsBrowser.TableViewFreshType)> = .empty()

    var currentResourceCount: Int = 0

    func resources(section: Int) -> [LarkAssetsBrowser.LKMediaResource] {
        return []
    }

    func resource(section: Int, row: Int) -> LarkAssetsBrowser.LKMediaResource {
        return LKMediaResource(data: ImageItemSet(),
                               type: .image,
                               key: "",
                               canSelect: false,
                               permissionState: .allow)
    }

    func fetchInitData() {
    }

    func loadMore() {
    }

    func didTapSelect() {
    }

    func didTapAsset(with key: String, in vc: UIViewController, thumbnail: UIImageView?) {
    }

    func getDisplayAsset(with key: String) -> LarkUIKit.LKDisplayAsset {
        return LKDisplayAsset()
    }

    func forwardButtonDidTapped(with keys: [String], from sourceVC: UIViewController, isMerge: Bool, completion: (() -> Void)?) {
    }

    func deleteButtonDidTapped(with keys: [String], completion: (() -> Void)?) {
    }
}
