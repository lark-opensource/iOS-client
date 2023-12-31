//
//  PostContentCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkFoundation
import LarkCore
import LarkMessageCore
import LarkAccountInterface
import LarkContainer
import RichLabel
import LarkMessengerInterface
import LarkModel
import LarkUIKit
import EENavigator
import LarkStorage
import ByteWebImage
import LarkFeatureGating
import RustPB
import LarkSDKInterface
import LarkSetting

private typealias Path = LarkSDKInterface.PathWrapper

final class PostTextAndMediaContentCellViewModel: BaseMomentSubCellViewModel<RawData.PostEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver
    public override var identifier: String {
        return "text_media_content"
    }

    private lazy var scene: MomentContextScene = {
        return self.context.pageAPI?.scene ?? .unknown
    }()

    var isDisplay: Bool = true {
        didSet {
            if isDisplay != oldValue {
                binder.update(with: self)
                update(component: binder.component)
            }
        }
    }
    func richTextSenderId() -> String {
        return self.entity.user?.userID ?? ""
    }
    /// 是否展示全文按钮
    var showMore: Bool = false {
        didSet {
            if showMore != oldValue {
                // 更新数据
                binder.update(with: self)
                // 刷新UI,此处使用全部刷新。全文会另起一行，即便动画设置为none，只更新一行，效果仍然不对，仍能看到“残影”效果
                self.update(component: binder.component, mode: .reloadAllData)
            }
        }
    }

    var translationShowMore: Bool = false {
        didSet {
            if translationShowMore != oldValue {
                // 更新数据
                binder.update(with: self)
                // 刷新UI,此处使用全部刷新。全文会另起一行，即便动画设置为none，只更新一行，效果仍然不对，仍能看到“残影”效果
                self.update(component: binder.component, mode: .reloadAllData)
            }
        }
    }

    var richTextParser: RichTextAbilityParser

    var translationRichTextParser: RichTextAbilityParser

    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var translateService: MomentsTranslateService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?
    @ScopedInjectedLazy private var passportUserService: PassportUserService?

    var displayRule: RustPB.Basic_V1_DisplayRule {
        guard let userGeneralSettings else { return .unknownRule }
        return self.entity.post.getDisplayRule(userGeneralSettings: userGeneralSettings)
    }

    var needToShowTranslate: Bool {
        guard let userGeneralSettings, let fgService else { return false }
        return self.entity.post.shouldShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
    }

    var imageList: [RawData.ImageSet] {
        return self.entity.post.postContent.imageSetList
    }

    var imageListMaxWidth: CGFloat {
        let padding: CGFloat
        switch self.scene {
        case .feed, .profile, .categoryDetail, .hashTagDetail:
            padding = 64 + 16
            return self.context.maxCellWidth - padding
        case .postDetail:
            padding = 16 * 2
            return self.context.maxCellWidth - padding
        case .unknown:
            return 0
        }
    }

    var hostSize: CGSize {
        return self.context.pageAPI?.hostSize ?? .zero
    }

    var videoCoverImageMaxWidth: CGFloat {
        return self.imageListMaxWidth
    }

    var imageInfoProps: [ImageInfoProp] {
        return self.imageList.map { [weak self] (imageSet) -> ImageInfoProp in
            let originSize = CGSize(width: CGFloat(imageSet.origin.width), height: CGFloat(imageSet.origin.height))
            let infoProp = ImageInfoProp(originSize: originSize, setImageAction: self?.getImageAction()) { (index, imageViews) in
                self?.showImagePerviewWithSelectedIndex(index, imageViews: imageViews)
            }
            return infoProp
        }
    }

    lazy var onTranslateFeedBack: (() -> Void) = { [weak self] in
        guard let self = self,
              let from = self.context.pageAPI,
              let translateService = self.translateService else { return }
        translateService.showTranslateFeedbackView(content: self.richTextParser.attributedString.string,
                                                   translation: self.translationRichTextParser.attributedString.string,
                                                   targetLanguage: self.entity.post.translationInfo.targetLanguage,
                                                   from: from)
    }

    func getImageAction() -> SetImageAction {
        return { [weak self] imageView, index, completionHandler in
            guard let imageList = self?.imageList, index < imageList.count, let self = self else {
                return
            }
            let imageSet = imageList[index]
            var key = MomentsDataConverter.getImageSetThumbnailKey(imageSet: imageSet)
            /// 这里使用小图
            if !imageSet.imageLocalPath().isEmpty, LarkImageService.shared.isCached(resource: .default(key: imageSet.imageLocalPath())) {
                key = imageSet.imageLocalPath()
            }
            if imageList.count == 1 {
                imageView.startSkeleton()
                imageView.bt.setLarkImage(with: .default(key: key),
                                          trackStart: {
                                              TrackInfo(scene: .Moments, fromType: .image)
                                          },
                                          completion: { result in
                                              imageView.stopSkeleton()
                                              switch result {
                                              case let .success(imageResult):
                                                  completionHandler(imageResult.image, nil)
                                              case let .failure(error):
                                                  completionHandler(nil, error)
                                              }
                                          })
            } else {
                if let animatedImageView = imageView as? ByteImageView {
                    animatedImageView.autoPlayAnimatedImage = false
                }
                imageView.startSkeleton()
                imageView.bt.setLarkImage(with: .default(key: key),
                                          options: [.onlyLoadFirstFrame],
                                          trackStart: {
                                            return TrackInfo(scene: .Moments, fromType: .image)
                                          },
                                          completion: { result in
                                            imageView.stopSkeleton()
                                            switch result {
                                            case .success(let imageResult):
                                                completionHandler(imageResult.image, nil)
                                            case .failure(let error):
                                                completionHandler(nil, error)
                                            }
                                          })
            }
        }
    }

    /// 展示图片
    /// - Parameter index: 选中index
    private func showImagePerviewWithSelectedIndex(_ index: Int, imageViews: [UIImageView]) {
        guard index < self.imageList.count,
              self.imageList.count == imageViews.count,
              let pageAPI = self.context.pageAPI else {
            return
        }
        var assets: [Asset] = []

        for (index, imageSet) in self.imageList.enumerated() {
            var asset = Asset(sourceType: .image(imageSet))
            asset.visibleThumbnail = imageViews[index]
            /// 这个key是用户用来保存图片的key 使用原图的
            asset.key = imageSet.middle.key
            asset.originKey = imageSet.origin.key
            asset.forceLoadOrigin = true
            asset.isAutoLoadOrigin = true
            asset.intactKey = imageSet.intact.key
            asset.placeHolder = imageViews[index].image
            assets.append(asset)
        }
        let sendSuccess = self.entity.post.localStatus == .success
        //PreviewImagesBody 底层调用 setImageMessage & forceOrigin: true 使用原图
        let body = MomentsPreviewImagesBody(postId: entity.postId,
                                            assets: assets,
                                            pageIndex: index,
                                            hideSavePhotoBut: !sendSuccess,
                                            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        userResolver.navigator.present(body: body, from: pageAPI)
    }

    /// 视频的处理
    lazy var mediaInfo: RawData.Media? = {
            let postContent = self.entity.post.postContent
            /// 有视频 且 URL不为空
            if !postContent.media.driveURL.isEmpty || !postContent.media.localURL.isEmpty {
                return postContent.media
            }
            return nil
        }()

    lazy var videoCoverImageAction: SetImageAction = {
        return { [weak self] imageView, _, completion in
            guard let mediaInfo = self?.mediaInfo, let self = self else {
                return
            }
            /// 需要处理清楚缓存的情况
            var key = MomentsDataConverter.getImageSetThumbnailKey(imageSet: mediaInfo.cover)
            if !mediaInfo.cover.imageLocalPath().isEmpty, LarkImageService.shared.isCached(resource: .default(key: mediaInfo.cover.imageLocalPath())) {
                key = mediaInfo.cover.imageLocalPath()
            }
            imageView.startSkeleton()
            imageView.bt.setLarkImage(with: .default(key: key),
                                      trackStart: {
                                          TrackInfo(scene: .Moments, fromType: .cover)
                                      },
                                      completion: { result in
                                          imageView.stopSkeleton()
                                          switch result {
                                          case let .success(imageResult):
                                              completion(imageResult.image, nil)
                                          case let .failure(error):
                                              completion(nil, error)
                                          }
                                      })
        }
    }()

    /// 视频点击
    lazy var videoCoverImageClick: ((UIImageView) -> Void)? = {
        return { [weak self] (imageView) in
            self?.showVideoPerviewWith(imageView: imageView)
        }
    }()

    /// 展示视频
    private func showVideoPerviewWith(imageView: UIImageView?) {
        guard let mediaInfo = self.mediaInfo, let pagaAPI = self.context.pageAPI else {
            return
        }
        let mediaInfoItem = MediaInfoItem(key: "",
                                          videoKey: "",
                                          coverImage: mediaInfo.cover,
                                          url: "",
                                          videoCoverUrl: "",
                                          localPath: "",
                                          size: Float(mediaInfo.size),
                                          messageId: "",
                                          channelId: "",
                                          sourceId: "",
                                          sourceType: .typeFromUnkonwn,
                                          needAuthentication: false,
                                          downloadFileScene: nil,
                                          duration: mediaInfo.durationSec,
                                          isPCOriginVideo: false)
        var asset = Asset(sourceType: .video(mediaInfoItem))
        if mediaInfo.hasLocalURL, Path(mediaInfo.localURL).exists {
            asset.isLocalVideoUrl = true
            asset.videoUrl = mediaInfo.localURL
        } else {
            asset.videoUrl = mediaInfo.driveURL
            asset.duration = mediaInfoItem.duration
        }
        asset.visibleThumbnail = imageView
        asset.isVideo = true
        asset.extraInfo["videoUrl"] = mediaInfo.driveURL
        let body = MomentsPreviewImagesBody(postId: entity.postId,
                                            assets: [asset],
                                     pageIndex: 0,
                                     canSaveImage: false,
                                     canEditImage: false,
                                     hideSavePhotoBut: true)
        userResolver.navigator.present(body: body, from: pagaAPI)
    }

    init(userResolver: UserResolver, entity: RawData.PostEntity, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        self.userResolver = userResolver
        let numberOfLines: Int
        let scene = context.pageAPI?.scene ?? .unknown
        switch scene {
        case .feed, .profile, .categoryDetail, .hashTagDetail:
            numberOfLines = 8
        case .postDetail, .unknown:
            numberOfLines = 0
        }
        func generateRichTextParser(richText: RustPB.Basic_V1_RichText, useTranslation: Bool) -> RichTextAbilityParser {
            return RichTextAbilityParser(userResolver: userResolver,
                                         dependency: context,
                                         richText: richText,
                                         font: UIFont.systemFont(ofSize: 17, weight: .regular),
                                         iconColor: UIColor.ud.textLinkNormal,
                                         tagType: .link,
                                         numberOfLines: numberOfLines,
                                         richTextSenderId: entity.user?.userID ?? "",
                                         contentLineSpacing: 4,
                                         urlPreviewProvider: { elementID, customAttributes in
                                          return context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                                postEntity: entity,
                                                                                                useTranslation: useTranslation,
                                                                                                customAttributes: customAttributes)
                                         })
        }
        self.richTextParser = generateRichTextParser(richText: entity.post.postContent.content, useTranslation: false)
        var translationRichText = entity.post.translationInfo.contentTranslation
        if translationRichText.elements.isEmpty,
           !entity.post.translationInfo.urlPreviewTranslation.isEmpty,
           entity.post.translationInfo.hasContentTranslation {
            translationRichText = entity.post.postContent.content
        }
        self.translationRichTextParser = generateRichTextParser(richText: translationRichText, useTranslation: true)

        super.init(entity: entity, context: context, binder: binder)
        self.richTextParser.showMoreCallBack = { [weak self] (showMore) in
            self?.showMore = showMore
        }
        self.translationRichTextParser.showMoreCallBack = { [weak self] (translationShowMore) in
            self?.translationShowMore = translationShowMore
        }

        func configDidClickHashTag(richTextParser: RichTextAbilityParser) {
            richTextParser.didClickHashTag = { [weak self] (_) in
                guard let self = self else {
                    return
                }
                if let scene = self.context.pageAPI?.scene {
                    switch scene {
                    case .feed(let postTab):
                        MomentsTracer.trackFeedPageViewClick(.hashtag,
                                                             circleId: self.entity.post.circleID,
                                                             postId: self.entity.post.id,
                                                             type: .tabInfo(postTab),
                                                             detail: nil)
                    case .categoryDetail(let index, let categoryId):
                        MomentsTracer.trackFeedPageViewClick(.hashtag,
                                                             circleId: self.entity.post.circleID,
                                                             postId: self.entity.post.id,
                                                             type: .category(categoryId),
                                                             detail: index == 1 ? .category_post : .category_comment)
                    case .hashTagDetail(let index, let hashtagId):
                        MomentsTracer.trackFeedPageViewClick(.hashtag,
                                                             circleId: self.entity.post.circleID,
                                                             postId: self.entity.post.id,
                                                             type: .hashtag(hashtagId),
                                                             detail: index == 1 ? .hashtag_new : .hashtag_hot)
                    case .profile:
                        let dataSource = context.dataSourceAPI
                        let info: MomentsTracer.ProfileInfo = MomentsTracer.ProfileInfo(profileUserId: dataSource?.getTrackValueForKey(.profileUserId) as? String ?? "",
                                                                                        isFollow: dataSource?.getTrackValueForKey(.isFollow) as? Bool ?? false,
                                                                                        isNickName: entity.post.isAnonymous,
                                                                                        isNickNameInfoTab: false)
                        MomentsTracer.trackFeedPageViewClick(.hashtag,
                                                             circleId: self.entity.post.circleID,
                                                             postId: self.entity.post.id,
                                                             type: .moments_profile,
                                                             detail: nil,
                                                             profileInfo: info)

                    default:
                        break
                    }
                }
            }
        }

        configDidClickHashTag(richTextParser: self.richTextParser)
        configDidClickHashTag(richTextParser: self.translationRichTextParser)
    }

    public override func willDisplay() {
        if let mediaInfo = self.mediaInfo {
            VideoPreloadManager.shared.preloadVideoIfNeeded(mediaInfo,
                                                            currentAccessToken: self.passportUserService?.user.sessionKey,
                                                            userResolver: self.userResolver)
        }
        isDisplay = true
        super.willDisplay()
    }

    public override func didEndDisplay() {
        if let mediaInfo = self.mediaInfo {
            VideoPreloadManager.shared.cancelPreloadVideoIfNeeded(mediaInfo, currentAccessToken: self.passportUserService?.user.sessionKey)
        }
        isDisplay = false
        super.didEndDisplay()
    }

    public override func update(entity: RawData.PostEntity) {
        self.richTextParser.update(richText: entity.post.postContent.content,
                                   urlPreviewProvider: { [weak self] elementID, customAttributes in
                                        return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                                    postEntity: entity,
                                                                                                    customAttributes: customAttributes)
                                    })
        var translationRichText = entity.post.translationInfo.contentTranslation
        if translationRichText.elements.isEmpty,
           !entity.post.translationInfo.urlPreviewTranslation.isEmpty,
           entity.post.translationInfo.hasContentTranslation {
            translationRichText = entity.post.postContent.content
        }
        self.translationRichTextParser.update(richText: translationRichText,
                                  urlPreviewProvider: { [weak self] elementID, customAttributes in
                                    return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                                postEntity: entity,
                                                                                                useTranslation: true,
                                                                                                customAttributes: customAttributes)
                                  })
        super.update(entity: entity)
    }
}
