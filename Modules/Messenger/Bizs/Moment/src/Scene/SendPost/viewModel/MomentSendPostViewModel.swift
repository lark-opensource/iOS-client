//
//  MomentSendPostViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Photos
import LarkContainer
import LarkAttachmentUploader
import LKCommonsLogging
import LarkCore
import LarkUIKit
import LarkMessengerInterface
import LarkSendMessage
import LarkSDKInterface
import LarkMessageCore
import Kingfisher
import RustPB
import LarkFoundation
import ByteWebImage
import LarkFeatureGating
import LarkGuide
import LarkGuideUI
import LarkSetting

private typealias Path = LarkSDKInterface.PathWrapper

struct MomentsPostStorageData {
    let categoryID: String
    let anonymous: Bool
    let attr: NSAttributedString?
    let items: [PhotoInfoItem]
}

final class MomentsPostImageSelectModel: UserResolverWrapper {
    let userResolver: UserResolver
    var selectedItems: [SelectImageInfoItem] = []
    let maxImageCount: Int = 9

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func isVideo() -> Bool? {
        return self.selectedItems.first?.isVideo
    }

    func leftCount() -> Int? {
        guard let isVideo = self.isVideo() else {
            return nil
        }
        if isVideo {
            return self.selectedItems.isEmpty ? 1 : 0
        }
        return maxImageCount - self.selectedItems.count
    }

    func photoPickerAssetType() -> PhotoPickerAssetType {
        guard let isVideo = self.isVideo() else {
            return .default
        }
        if isVideo {
            return .videoOnly(maxCount: self.leftCount() ?? 0)
        } else {
            return .imageOnly(maxCount: self.leftCount() ?? 0)
        }
    }

    func convertPhotoTypeToImageType(_ type: PhotoPickerAssetType) -> ImagePickerAssetType {
        var imageType: ImagePickerAssetType = .imageOrVideo(imageMaxCount: maxImageCount, videoMaxCount: 1)
        switch type {
        case .imageOnly(let maxCount):
            imageType = .imageOnly(maxCount: maxCount)
        case .videoOnly(let maxCount):
            imageType = .videoOnly(maxCount: maxCount)
        case .imageOrVideo(let imageMaxCount, let videoMaxCount):
            imageType = .imageOrVideo(imageMaxCount: imageMaxCount, videoMaxCount: videoMaxCount)
        case .imageAndVideo(let imageMaxCount, let videoMaxCount):
            imageType = .imageAndVideo(imageMaxCount: imageMaxCount, videoMaxCount: videoMaxCount)
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            imageType = .imageAndVideoWithTotalCount(totalCount: totalCount)
        @unknown default:
            imageType = .imageOrVideo(imageMaxCount: maxImageCount, videoMaxCount: 1)
        }
        return imageType
    }
}

final class MomentSendPostViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let nameSpace = "sendPost"
    static let logger = Logger.log(MomentSendPostViewModel.self, category: "Module.Moments.SendPostViewModel")

    @ScopedInjectedLazy var sendImageProcessor: SendImageProcessor?

    @ScopedInjectedLazy var postService: PostApiService?

    @ScopedInjectedLazy var resourceAPI: ResourceAPI?

    @ScopedInjectedLazy var transcodeService: VideoTranscodeService?

    @ScopedInjectedLazy var videoSendService: VideoMessageSendService?

    @ScopedInjectedLazy var chatterAPI: ChatterAPI?

    /// 权限管控服务
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    @ScopedInjectedLazy var dirveSDKDependency: LarkMomentDependency?

    @ScopedInjectedLazy var draftService: MomentsDraftService?

    @ScopedInjectedLazy var categoriesApi: PostCategoriesApiService?
    @ScopedInjectedLazy var anonymousApi: NickNameAndAnonymousService?
    @ScopedInjectedLazy var anonymousConfigService: UserAnonymousConfigService?
    @ScopedInjectedLazy var circleConfigService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy var hashTagService: HashTagApiService?
    @ScopedInjectedLazy var guideManager: NewGuideService?
    @ScopedInjectedLazy var settingService: SettingService?

    var isLoadingHistoryHashTag = false

    private let disposeBag = DisposeBag()
    lazy var IsCompressCameraPhotoFG: Bool = {
        (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "feature_key_camera_photo_compress") ?? false
    }()

    lazy var selectedImagesModel: MomentsPostImageSelectModel = {
        return MomentsPostImageSelectModel(userResolver: userResolver)
    }()

    /// 图片压缩设置
    lazy var imageCompressConfig: MomentsImageCompressConfig = {
        return MomentsImageCompressConfig(settingService: settingService, defaultLength: 2000, defaultQuality: 0.8)
    }()
    /// FG打开的时候 才需要展示引导
    var shouldShowNickNameGuide: Bool {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false
        return fgValue && (guideManager?.checkShouldShowGuide(key: nickNameGuideKey) ?? false)
    }

    /// 花名页引导key
    let nickNameGuideKey = "moments_nicknameprofile_onboarding"

    var getCategoriesListCallBack: (succeed: (([RawData.PostCategory]) -> Void), fail: (() -> Void))?
    /// 是否是匿名
    var isAnonymous: Bool = false {
        didSet {
            onAnonymousStatusChangeBlock?(isAnonymous)
        }
    }
    var onAnonymousStatusChangeBlock: ((Bool) -> Void)?
    /// 是否还有匿名的余额
    var hasQuota: Bool?
    var uploadingItems: [SelectImageInfoItem] = []
    /// 缓存获取到的数据
    var categoryItems: [RawData.PostCategory] = []

    let source: String?
    var circleId: String?
    let selectedHashTagContent: String?
    var selectedCategoryID: String?
    public let attachmentUploader: AttachmentUploader
    static func momentsSendPostDraftKey() -> String {
        return "moments_send_post"
    }
    var anonymityEnabled: Bool {
        return anonymousConfigService?.anonymityPolicyEnable ?? false
    }
    init(userResolver: UserResolver,
         source: String?,
         selectedCategoryID: String?,
         selectedHashTagContent: String?,
         attachmentUploader: AttachmentUploader) {
        self.userResolver = userResolver
        self.source = source
        self.selectedCategoryID = selectedCategoryID
        self.selectedHashTagContent = selectedHashTagContent
        self.attachmentUploader = attachmentUploader
    }

    @discardableResult
    func uploadImageItems(_ items: [SelectImageInfoItem]) -> [SelectImageInfoItem] {
        for item in items {
            if let image = item.imageSource?.image {
                let extraInfo: [String: AnyHashable] = [
                    "image_type": item.imageSource?.sourceType.description ?? "unknown",
                    "color_space": item.imageSource?.colorSpaceName ?? "unknown",
                    "is_image_origin": item.useOriginal,
                    "resource_height": item.originSize.height,
                    "resource_width": item.originSize.width,
                    "compress_cost": item.imageSource?.compressCost ?? 0,
                    "resource_content_length": item.imageSource?.data?.count ?? 0,
                    "from_type": UploadImageInfo.FromType.post.rawValue, // 富文本消息
                    "scene": UploadImageInfo.UploadScene.chat.rawValue // scene
                ]
                let attachmentKey = self.upload(image: image, imageData: item.imageSource?.data, useOriginal: item.useOriginal, extraInfo: extraInfo)
                item.attachmentKey = attachmentKey ?? ""
            }
        }
        return items
    }

    func getAllPostImageMediaInfoItems() -> [PostImageMediaInfo] {
        var infoItems: [PostImageMediaInfo] = []
        for item in self.selectedImagesModel.selectedItems {
            var imageItem: PostCommonItemInfo?
            var videoItem: PostItemVideoInfo?
            if item.isVideo {
                let corveImage = PostCommonItemInfo(width: item.originSize.width,
                                                    height: item.originSize.height,
                                                    token: item.token,
                                                    localPath: item.localImageKey)
                let videoInfo = PostCommonItemInfo(width: item.videoInfo?.naturalSize.width ?? 0,
                                                   height: item.videoInfo?.naturalSize.height ?? 0,
                                                   token: item.dirveToken,
                                                   localPath: item.videoInfo?.compressPath ?? "")
                videoItem = PostItemVideoInfo(corveImage: corveImage,
                                              videoInfo: videoInfo,
                                              videoDurationSec: item.videoInfo?.duration ?? 0)
            } else {
                imageItem = PostCommonItemInfo(width: item.originSize.width,
                                               height: item.originSize.height,
                                               token: item.token,
                                               localPath: item.localImageKey)
            }
            let info = PostImageMediaInfo(imageInfo: imageItem, videoInfo: videoItem)
            infoItems.append(info)
        }
        return infoItems
    }

    /// 组织图片浏览器数据
    func getCustomSelectedAssets() -> [Asset] {
        var assets: [Asset] = []
        self.selectedImagesModel.selectedItems.forEach { (item) in
            let asset = LKDisplayAsset()
            var imageSet = RawData.ImageSet()
            imageSet.origin.key = item.localImageKey
            asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.image(imageSet)]
            asset.key = item.localImageKey
            asset.originalImageKey = item.localImageKey
            asset.forceLoadOrigin = true
            asset.isAutoLoadOriginalImage = true
            assets.append(asset.transform())
        }
        return assets
    }

    func upload(image: UIImage, imageData: Data?, useOriginal: Bool, extraInfo: [String: AnyHashable]? = nil) -> String? {
        var imageInfo: [String: String] = [
            "width": "\(Int32(image.size.width))",
            "height": "\(Int32(image.size.height))",
            "type": "post",
            "useOriginal": useOriginal ? "1" : "0"
        ]
        // 额外信息，为了不破坏原有结构，所以转jsonString放进去
        if let extra = extraInfo,
           let jsonData = try? JSONSerialization.data(withJSONObject: extra, options: .fragmentsAllowed) {
            let string = String(data: jsonData, encoding: .utf8)
            imageInfo["extraInfo"] = string
        }
        guard let data = imageData else {
            MomentSendPostViewModel.logger.info("image 无法转化为对应 data")
            return nil
        }

        let imageAttachment = self.attachmentUploader.attachemnt(data: data, type: .secureImage, info: imageInfo)
        MomentSendPostViewModel.logger.info("use custom uploader attachmentKey: \(imageAttachment.key)")
        self.attachmentUploader.customUpload(attachment: imageAttachment)
        return imageAttachment.key
    }

    /// 上传视频
    func upload(videoInfo: VideoParseInfo) -> String? {
        let preview = videoInfo.preview
        let imageInfo: [String: String] = [
            "width": "\(Int32(preview.size.width))",
            "height": "\(Int32(preview.size.height))",
            "type": "post",
            "useOriginal": "1"
        ]
        var imageData = preview.kf.gifRepresentation()
        if imageData == nil {
            if let firstFrameData = videoInfo.firstFrameData {
                imageData = firstFrameData
            } else {
                imageData = preview.jpegData(compressionQuality: 0.75)
            }
        }
        guard let data = imageData else {
            MomentSendPostViewModel.logger.info("video image 无法转化为对应 data")
            return nil
        }
        let imageAttachment = self.attachmentUploader.attachemnt(data: data, type: .secureImage, info: imageInfo)
        guard self.attachmentUploader.upload(attachment: imageAttachment) else {
            MomentSendPostViewModel.logger.error("没有注册 image 类型的 attachment uptrueload handler")
            return nil
        }
        return imageAttachment.key
    }

    /// 上传视频文件
    /// - Parameters:
    ///   - videoInfo: 视频信息
    ///   - item: 选中的videoItem
    func uploadVideoToSDK(videoInfo: VideoParseInfo, item: SelectImageInfoItem, finish: @escaping ((Bool) -> Void)) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.dirveSDKDependency?.upload(localPath: videoInfo.compressPath, fileName: videoInfo.name, mountNodePoint: "", mountPoint: "moments")
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (info) in
                    if info.uploadStatus == .success {
                        item.dirveToken = info.fileToken
                        item.dirveKey = info.uploadKey
                        self?.selectedImagesModel.selectedItems.append(item)
                        finish(true)
                        MomentSendPostViewModel.logger.info("视频key: \(info.uploadKey) 上传成功")
                    } else if info.uploadStatus == .failed || info.uploadStatus == .cancel {
                        finish(false)
                        MomentSendPostViewModel.logger.error("视频key: \(info.uploadKey) 上传失败 -- uploadStatus：\(info.uploadStatus)")
                    }
                }).disposed(by: self.disposeBag)
        }
    }

    /// 视频转码服务
    /// - Parameters:
    ///   - info: 视频信息
    func videoTranscodeServiceWith(info: VideoParseInfo, finish: (@escaping (Bool) -> Void)) {
        let key = "\(Int64(Date().timeIntervalSince1970 * 1000))"
        DispatchQueue.global(qos: .userInteractive).async {
            let respone = self.videoSendService?.transcode(
                key: key,
                form: info.exportPath,
                to: info.compressPath,
                isOriginal: true,
                videoSize: info.naturalSize,
                extraInfo: [:],
                progressBlock: nil,
                dataBlock: nil,
                retryBlock: nil
            ).do(onNext: { (arg) in
                if arg.key == key, case .finish = arg.status {
                    let compressPath = info.compressPath
                    let fileName = String(URL(string: compressPath)?.path.split(separator: "/").last ?? "")
                    let fileSize = try? FileUtils.fileSize(compressPath)
                    sendVideoCache(userID: self.userResolver.userID).saveFileName(
                        fileName,
                        size: Int(fileSize ?? 0)
                    )
                }
            })

            respone?.observeOn(MainScheduler.instance)
                .subscribe(onNext: { (arg) in
                    if arg.key == key, case .finish = arg.status {
                        finish(true)
                    }
                }, onError: { (_) in
                    finish(false)
                }).disposed(by: self.disposeBag)
        }
    }

    func getAllEffectiveAttachmentIds() -> [String] {
        let attachmentIds = self.uploadingItems.map { $0.attachmentKey }
        return attachmentIds.filter { !$0.isEmpty }
    }

    func saveDraftWithRichText(_ richText: RustPB.Basic_V1_RichText?, categoryID: String?) {
        var images: [String] = []
        var videos: [String] = []
        if !self.selectedImagesModel.selectedItems.isEmpty, let isVideo = self.selectedImagesModel.isVideo() {
            let infos = self.selectedImagesModel.selectedItems.map({ $0.stringify() })
            if isVideo {
                videos = infos
            } else {
                images = infos
            }
        }
        if images.isEmpty, videos.isEmpty, richText == nil {
            self.clearDraft()
            return
        }
        let draftItem = MomentsDraftItem(categoryID: categoryID ?? "", anonymous: isAnonymous, content: richText, images: images, videos: videos)
        self.draftService?.setValue(draftItem.stringify(), forKey: Self.momentsSendPostDraftKey(), nameSpace: Self.nameSpace)
    }

    /// 获取可以重新组织UI的数据
    func getDraftWithAttributes(_ attributes: [NSAttributedString.Key: Any],
                                complete: ((MomentsPostStorageData?) -> Void)?) {
        self.draftService?.valueForKey(Self.momentsSendPostDraftKey(), nameSpace: Self.nameSpace) { [weak self] (success, value) in
            if success, !value.isEmpty {
                let draftItem = MomentsDraftItem.parse(value)
                DispatchQueue.main.async { [weak self] in
                    self?.recoverDataWith(attributes: attributes, item: draftItem, complete: complete)
                }
            } else {
                complete?(nil)
            }
        }
    }

    func getDisplayItemsWithData(_ data: [RawData.PostCategory]) -> [PostCategoryItem] {
        var items = Array(data.prefix(6)).map({ (category) -> PostCategoryItem in
            let selected = category.category.categoryID == selectedCategoryID ?? ""
            return PostCategoryItem(id: category.category.categoryID,
                                    title: category.category.name,
                                    selected: selected,
                                    iconKey: category.category.iconKey)
        })
        let index = data.firstIndex { $0.category.categoryID == self.selectedCategoryID ?? "" }
        guard let idx = index else {
            return items
        }
        if idx < items.count {
            let item = items[idx]
            items.remove(at: idx)
            items.insert(item, at: 0)
        } else {
            items.removeLast()
            let category = data[idx]
            let item = PostCategoryItem(id: category.category.categoryID, title: category.category.name, selected: true, iconKey: category.category.iconKey)
            items.insert(item, at: 0)
        }
        return items
    }

    func clearDraft() {
        self.draftService?.removeValueForKey(Self.momentsSendPostDraftKey(), nameSpace: Self.nameSpace)
    }

    /// 获取列表
    func getCategoriesListLocalFirst() {
        Self.logger.info("getCategoriesList")
        getCategoriesList(forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (data) in
                self?.getCategoriesListCallBack?.succeed(data)
                self?.getCategoriesListRemote()
        }, onError: { [weak self] (error) in
            Self.logger.error("getCategoriesList error \(error)")
            self?.getCategoriesListRemote()
        }).disposed(by: disposeBag)
    }
    private func getCategoriesListRemote() {
        getCategoriesList(forceRemote: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (data) in
                self?.getCategoriesListCallBack?.succeed(data)
        }, onError: { [weak self] (error) in
            Self.logger.error("getCategoriesListRemote error \(error)")
            self?.getCategoriesListCallBack?.fail()
        }).disposed(by: disposeBag)
    }
    func getCategoriesList(forceRemote: Bool = false) -> CategoryApi.RxGetCategories {
        return self.categoriesApi?.getListCategories(forceRemote: forceRemote) ?? .empty()
    }

    func recoverDataWith(attributes: [NSAttributedString.Key: Any],
                         item: MomentsDraftItem,
                         complete: ((MomentsPostStorageData?) -> Void)?) {
        /// 这里图片和视频能有一个 如果有图片了 不再处理视频
        var attr: NSAttributedString?
        if item.content != nil {
            //必须在主线程调用
            attr = item.contentToAttrbuteStringWith(attributes: attributes)
        }
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            var isVideo = false
            if !item.images.isEmpty {
                item.images.forEach { (info) in
                    self.selectedImagesModel.selectedItems.append(SelectImageInfoItem.parse(info))
                }
            } else if !item.videos.isEmpty {
                item.videos.forEach { (info) in
                    let selectItem = SelectImageInfoItem.parse(info)
                    /// 视频的本地文件存在，如果缓存被清楚 不再展示
                    if let exportPath = selectItem.videoInfo?.compressPath, Path(exportPath).exists {
                        self.selectedImagesModel.selectedItems.append(selectItem)
                    }
                }
                isVideo = true
            }
            let group = DispatchGroup()
            /// 从草稿中映射图片
            self.selectedImagesModel.selectedItems.forEach { (item) in
                group.enter()
                self.attachmentUploader.getDraftAttachment(attachmentName: item.attachmentKey) { (data) in
                    defer {
                        group.leave()
                    }
                    if let data = data,
                       let image = DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                        item.photoItem = PhotoInfoItem(image: image, isVideo: isVideo)
                    } else {
                        Self.logger.error("no image found in draft")
                    }
                }
            }
            group.notify(queue: DispatchQueue.main) { [weak self] in
                guard let self = self else { return }
                self.selectedImagesModel.selectedItems.removeAll { (item) -> Bool in
                    return item.photoItem == nil
                }
                let data = MomentsPostStorageData(categoryID: item.categoryID,
                                                  anonymous: item.anonymous,
                                                  attr: attr,
                                                  items: self.selectedImagesModel.selectedItems.compactMap({ $0.photoItem }))
                complete?(data)
            }
        }
    }
    func queryAnonymousQuotaFinish(_ finish: ((Bool) -> Void)?) {
        anonymousConfigService?.getAnonymousQuotaWithPostID(postID: nil) { [weak self] (hasQuota) in
            self?.hasQuota = hasQuota
            finish?(hasQuota)
        }
    }

    func getHistroyHashtag(_ finish: (((RawData.HashTagResponse, String)) -> Void)?) {
        if isLoadingHistoryHashTag {
            return
        }
        hashTagService?
            .hashTagListForHistory()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                self?.isLoadingHistoryHashTag = false
                if !data.0.hashtagInfos.isEmpty {
                    finish?(data)
                }
            }).disposed(by: disposeBag)
    }

    ///这个方法只在FG "moments.publish.bind_category" 为false时会用到
    func selectCategoryAndMoveToFirst(_ category: RawData.PostCategory) {
        selectedCategoryID = category.category.categoryID
        categoryItems.removeAll(where: { $0.category.categoryID == category.category.categoryID })
        categoryItems.insert(category, at: 0)
    }
}
