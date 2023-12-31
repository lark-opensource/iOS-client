//
//  SearchImageInChatViewModel.swift
//  LarkSearch
//
//  Created by zc09v on 2018/9/10.
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
import LKCommonsTracker
import Homeric
import RustPB
import ByteWebImage
import LarkSearchCore

final class SearchImageInChatViewModel {
    //初始化状态
    enum InitialStatus {
        case initialLoading  //初始化中
        case initialFinish //初始化完成
        case initialFailed //初始化失败
    }

    // ViewModel 状态
    enum Status {
        case initialLoading  //初始化中
        case initialFinish(hasMore: Bool) //初始化完成
        case initialFailed //初始化失败
        case searchFinished(hasMore: Bool)
        case searchFailed(hasMore: Bool)
        case loadMoreFinished(hasMore: Bool)
        case loadMoreFailed(hasMore: Bool)
        case requestFinished(contextID: String)
    }

    //数据刷新类型
    enum TableViewFreshType {
        case refresh(hasMore: Bool)
        case loadFailed(hasMore: Bool)
    }

    let repo: SearchInChatResourcePresntable
    let chatId: String

    private let disposeBag = DisposeBag()
    #if DEBUG || INHOUSE || ALPHA
    let debugDataManager: ASLContextIDProtocol
    #endif

    private lazy var chat: Chat? = self.chatAPI.getLocalChat(by: chatId)
    private var isThread: Bool {
        return (self.chat?.chatMode ?? .default) == .threadV2
    }

    //以时间维度划分 本周/本月/按月划分
    private var resourceMap: [String: [SearchResource]] = [:]
    //resourceMap key有序排列后的数组，供ui顺序显示
    private var sections: [String] = []
    var resources: [SearchResource] = []

    //供ui使用,数据源的copy
    private (set) var sectionsDataSource: [String] = []
    private var resourceMapDataSource: [String: [SearchResource]] = [:]
    private var resourcesDataSource: [SearchResource] = []

    // FG
    var enableSearchAbility: Bool {
        return SearchFeatureGatingKey.inChatImageV2.isEnabled && SearchFeatureGatingKey.inChatImageSearchV2.isEnabled
    }

    var chatAPI: ChatAPI {
        return repo.chatAPI
    }

    var messageAPI: MessageAPI {
        return repo.messageAPI
    }

    var coldAndHotTipType: HotAndColdTipType?
    var currentQuery: (() -> String)?

    private let tableRefreshPublish = PublishSubject<(TableViewFreshType)>()
    var tableRefreshDriver: Driver<(TableViewFreshType)> {
        return tableRefreshPublish
            .asDriver(onErrorRecover: { _ in .empty() })
            .do(onNext: { [weak self] (_) in
                self?.sectionsDataSource = self?.sections ?? []
                self?.resourceMapDataSource = self?.resourceMap ?? [:]
                self?.resourcesDataSource = self?.resources ?? []
            })
    }

    func resources(section: Int) -> [SearchResource] {
        guard let key = sectionsDataSource[safe: section] else { return [] }
        if let resources = self.resourceMapDataSource[key] {
            return resources
        } else {
            assertionFailure()
            return []
        }
    }

    func resource(section: Int, row: Int) -> SearchResource? {
        return self.resources(section: section)[safe: row]
    }

    func asset(resource: SearchResource, thumbnail: UIImageView?) -> SearchAssetInfo {
        switch resource.data {
        case .image(let imageSet):
            var asset = Asset(sourceType: .image(imageSet))
            asset.key = imageSet.middle.key
            asset.originKey = imageSet.origin.key
            if let originSize = resource.originSize,
               let isOriginSource = resource.isOriginSource {
                asset.originImageFileSize = originSize
                if asset.originImageFileSize <= 500 * 1024 {
                    asset.forceLoadOrigin = true
                    asset.isAutoLoadOrigin = true
                } else {
                    asset.forceLoadOrigin = !isOriginSource
                    asset.isAutoLoadOrigin = false
                }
                asset.intactKey = imageSet.intact.key
            }
            asset.visibleThumbnail = thumbnail
            asset.placeHolder = LarkImageService.shared.image(
                with: .default(key: ImageItemSet.transform(imageSet: imageSet).getThumbInfoForSearchHistory().0),
                cacheOptions: .memory
            )
            asset.permissionState = (resource.hasPreviewPremission ?? false) ? .allow : .previewDeny
            let messageMap = try? self.messageAPI.getMessagesMap(ids: [resource.messageId])
            asset.riskObjectKeys = messageMap?[resource.messageId]?.riskObjectKeys ?? []
            asset.addSecurityExtraInfo(for: .saveImage, securityExtraInfo: SecurityExtraInfo(fileKey: imageSet.origin.key, message: messageMap?[resource.messageId], chat: self.chat))
            var messageType: SearchAssetInfo.MessageType = isThread ?
                .thread(postion: resource.threadPosition, id: resource.threadID) :
                .message(postion: resource.messagePosition, id: resource.messageId)
            if !isThread, resource.messagePosition == replyInThreadMessagePosition {
                messageType = .thread(postion: resource.threadPosition, id: resource.threadID)
            }
            let assetInfo = SearchAssetInfo(asset: asset, messageType: messageType)
            return assetInfo
        case .video(let mediaContent):
            // 保存到网盘函数实现条件--需要判断url是否为空
            let mediaInfoItem = MediaInfoItem(key: mediaContent.key,
                                              videoKey: "",
                                              coverImage: mediaContent.image,
                                              url: mediaContent.url,
                                              videoCoverUrl: "",
                                              localPath: "",
                                              size: Float(mediaContent.size),
                                              messageId: resource.messageId,
                                              channelId: resource.threadID,
                                              sourceId: "",
                                              sourceType: .typeFromUnkonwn,
                                              downloadFileScene: nil,
                                              duration: Int32(mediaContent.duration),
                                              isPCOriginVideo: mediaContent.isOriginal)
            var asset = Asset(sourceType: .video(mediaInfoItem))
            asset.key = mediaContent.key
            asset.isVideo = true
            asset.visibleThumbnail = thumbnail
            asset.duration = mediaInfoItem.duration
            asset.videoUrl = mediaContent.url
            asset.permissionState = (resource.hasPreviewPremission ?? false) ? .allow : .previewDeny
            let messageMap = try? self.messageAPI.getMessagesMap(ids: [resource.messageId])
            asset.riskObjectKeys = messageMap?[resource.messageId]?.riskObjectKeys ?? []
            var messageType: SearchAssetInfo.MessageType = isThread ?
                .thread(postion: resource.threadPosition, id: resource.threadID) :
                .message(postion: resource.messagePosition, id: resource.messageId)
            if !isThread, resource.messagePosition == replyInThreadMessagePosition {
                messageType = .thread(postion: resource.threadPosition, id: resource.threadID)
            }
            let assetInfo = SearchAssetInfo(asset: asset, messageType: messageType)
            return assetInfo
        @unknown default:
            assert(false, "new value")
            let asset = Asset(sourceType: .other)
            let messageType: SearchAssetInfo.MessageType = isThread ?
                .thread(postion: resource.threadPosition, id: resource.threadID) :
                .message(postion: resource.messagePosition, id: resource.messageId)
            return SearchAssetInfo(asset: asset, messageType: messageType)
        }
    }

    func allAssets() -> [SearchAssetInfo] {
        return resources.map { asset(resource: $0, thumbnail: nil) }
    }

    var initialStatusDirver: Driver<InitialStatus> {
        return initialStatus
            .asDriver(onErrorRecover: { _ in .empty() })
    }
    let initialStatus = PublishSubject<InitialStatus>()

    init(repo: SearchInChatResourcePresntable,
         chatId: String) {
        self.repo = repo
        self.chatId = chatId
        #if DEBUG || INHOUSE || ALPHA
        self.debugDataManager = ASLDebugDataManager()
        #endif
        setupRepo()
    }

    func fetchInitData() {
        repo.fetchInitData()
    }

    func loadMore() {
        repo.loadMore()
    }

    func search(param: SearchParam) {
        resourceMap = [:]
        sections = []
        resources = []
        repo.search(param: param)
    }

    private func setupRepo() {
        repo.status
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .initialLoading:
                    self.initialStatus.onNext(.initialLoading)
                case .initialFailed:
                    self.initialStatus.onNext(.initialFailed)
                case .initialFinish(let hasMore):
                    self.tableRefreshPublish.onNext(.refresh(hasMore: hasMore))
                    self.initialStatus.onNext(.initialFinish)
                case .searchFinished(let hasMore):
                    self.tableRefreshPublish.onNext(.refresh(hasMore: hasMore))
                case .searchFailed(let hasMore):
                    self.tableRefreshPublish.onNext(.loadFailed(hasMore: hasMore))
                case .loadMoreFinished(let hasMore):
                    self.tableRefreshPublish.onNext(.refresh(hasMore: hasMore))
                case .loadMoreFailed(let hasMore):
                    self.tableRefreshPublish.onNext(.loadFailed(hasMore: hasMore))
                case .requestFinished(let contextID):
                    #if DEBUG || INHOUSE || ALPHA
                    self.debugDataManager.contextIDOnNext(contextID: contextID)
                    #else
                    break
                    #endif
                }
            })
            .disposed(by: disposeBag)

        repo.resoures
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (resoures, query, responseTipType) in
                guard let self = self else { return }
                guard query == self.currentQuery?() else { return }
                let currentDate = Date()
                self.resources += resoures
                for resoure in resoures {
                    if resoure.createTime.year == currentDate.year,
                       resoure.createTime.month == currentDate.month,
                       resoure.createTime.weekOfMonth == currentDate.weekOfMonth {
                        //本周
                        self.add(resource: resoure, key: BundleI18n.LarkSearch.Lark_Legacy_ThisWeek)
                    } else if resoure.createTime.year == currentDate.year,
                              resoure.createTime.month == currentDate.month {
                        //本月
                        self.add(resource: resoure, key: BundleI18n.LarkSearch.Lark_Legacy_ThisMonth)
                    } else {
                        //按年-月划分
                        let year = resoure.createTime.year
                        let month = resoure.createTime.month
                        let key = "\(year)-\(month)"
                        self.add(resource: resoure, key: key)
                    }
                }
                self.coldAndHotTipType = responseTipType
            })
            .disposed(by: disposeBag)

        repo.loadMoreDuration
            .subscribe(onNext: { duration in
                let params: [AnyHashable: Any] = ["return_data_time": duration]
                Tracker.post(TeaEvent(Homeric.CHAT_HISTORY_VIEW_PICTURE,
                                      params: params))
            })
            .disposed(by: disposeBag)
    }

    private func add(resource: SearchResource, key: String) {
        if var resourcesInMap = self.resourceMap[key] {
            resourcesInMap.append(resource)
            self.resourceMap[key] = resourcesInMap
        } else {
            var resourcesInMap: [SearchResource] = []
            resourcesInMap.append(resource)
            self.resourceMap[key] = resourcesInMap
            self.sections.append(key)
        }
    }

}
