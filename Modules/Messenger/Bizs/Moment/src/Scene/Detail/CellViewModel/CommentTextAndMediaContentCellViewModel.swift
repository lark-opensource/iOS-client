//
//  CommentContentCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/7.
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
import EENavigator
import ByteWebImage
import LarkFeatureGating
import RustPB
import LarkSDKInterface
import LarkSetting

final class CommentTextAndMediaContentCellViewModel: BaseMomentSubCellViewModel<RawData.CommentEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver
    public override var identifier: String {
        return "text_media_content"
    }

    var isDisplay: Bool = false {
        didSet {
            if isDisplay != oldValue {
                binder.update(with: self)
                update(component: binder.component)
            }
        }
    }

    var hostSize: CGSize {
        return context.pageAPI?.hostSize ?? .zero
    }

    /// 评论是否有图片
    var commentImage: RawData.ImageSet? {
            let commentContent = self.entity.comment.content
        /// 当假消息上屏的时候(还未发送成功)，SDK返回的imageSet.origin.key，imageSet.thumbnail.key等都为空
        /// 只有imageSet.key有值，如果不添加!commentContent.imageSet.key.isEmpty的判断，评论发送中会不展示图片
        /// 只有发送成功回来之后 才会图片展示，滚动到最底部也会有问题
        if !commentContent.imageSet.key.isEmpty ||
            !commentContent.imageSet.origin.key.isEmpty ||
            !commentContent.imageSet.thumbnail.key.isEmpty {
                return commentContent.imageSet
            }
            return nil
        }

    lazy var imageMaxWidth: CGFloat = {
        let padding: CGFloat = 48 + 16
        return self.context.maxCellWidth - padding
    }()

    lazy var coverImageAction: SetImageAction = {
        return { [weak self] imageView, _, completion in
            guard let commentImage = self?.commentImage, let self = self else {
                return
            }
            /// 这里本地路径是否存在 存在且有效使用本地路径 否则使用小图
            var key = MomentsDataConverter.getImageSetThumbnailKey(imageSet: commentImage)
            let localPath = commentImage.imageLocalPath()
            if !localPath.isEmpty, LarkImageService.shared.isCached(resource: .default(key: localPath)) {
                key = localPath
            }
            imageView.startSkeleton()
            imageView.bt.setLarkImage(with: .default(key: key),
                                      trackStart: {
                                        return TrackInfo(scene: .Moments, fromType: .image)
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

    lazy var coverImageClick: ((UIImageView) -> Void)? = {
        return { [weak self] (imageView) in
            self?.showImagePerviewWith(imageView: imageView)
        }
    }()

    /// 展示图片
    private func showImagePerviewWith(imageView: UIImageView?) {
        guard let commentImage = self.commentImage, let pageAPI = self.context.pageAPI else {
            return
        }

        var asset = Asset(sourceType: .image(commentImage))
        asset.visibleThumbnail = imageView
        asset.key = commentImage.middle.key
        asset.originKey = commentImage.origin.key
        asset.forceLoadOrigin = true
        asset.isAutoLoadOrigin = true
        asset.intactKey = commentImage.intact.key
        asset.placeHolder = imageView?.image
        //PreviewImagesBody 底层调用 setImageMessage & forceOrigin: true 使用原图
        let body = MomentsPreviewImagesBody(postId: entity.postId,
                                            assets: [asset],
                                            pageIndex: 0,
                                            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        userResolver.navigator.present(body: body, from: pageAPI, animated: true, completion: nil)
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

    let richTextParser: RichTextAbilityParser

    var translationRichTextParser: RichTextAbilityParser

    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var translateService: MomentsTranslateService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    var displayRule: RustPB.Basic_V1_DisplayRule {
        guard let userGeneralSettings else { return .unknownRule }
        return self.entity.comment.getDisplayRule(userGeneralSettings: userGeneralSettings)
    }

    var needToShowTranslate: Bool {
        guard let userGeneralSettings, let fgService else { return false }
        return self.entity.comment.shouldShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
    }

    lazy var onTranslateFeedBack: (() -> Void) = { [weak self] in
        guard let self = self,
              let from = self.context.pageAPI,
              let translateService = self.translateService else { return }
        translateService.showTranslateFeedbackView(content: self.richTextParser.attributedString.string,
                                                   translation: self.translationRichTextParser.attributedString.string,
                                                   targetLanguage: self.entity.comment.translationInfo.targetLanguage,
                                                   from: from)
    }

    init(userResolver: UserResolver, entity: RawData.CommentEntity, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        self.userResolver = userResolver
        var numberOfLines = 0
        // 当前只有在新版profile页会出现评论
        if context.pageAPI?.scene == .profile {
            numberOfLines = 8
        }
        func generateRichTextParser(richText: RustPB.Basic_V1_RichText, useTranslation: Bool) -> RichTextAbilityParser {
            return RichTextAbilityParser(userResolver: userResolver,
                                         dependency: context,
                                         richText: richText,
                                         font: UIFont.systemFont(ofSize: 17),
                                         iconColor: UIColor.ud.textLinkNormal,
                                         tagType: .link,
                                         numberOfLines: numberOfLines,
                                         richTextSenderId: entity.user?.userID ?? "",
                                         contentLineSpacing: 4,
                                         urlPreviewProvider: { elementID, customAttributes in
                                          return context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                                commentEntity: entity,
                                                                                                useTranslation: useTranslation,
                                                                                                customAttributes: customAttributes)
                                         })
        }
        self.richTextParser = generateRichTextParser(richText: entity.comment.content.content, useTranslation: false)
        var translationRichText = entity.comment.translationInfo.contentTranslation
        if translationRichText.elements.isEmpty,
           !entity.comment.translationInfo.urlPreviewTranslation.isEmpty,
           entity.comment.translationInfo.hasContentTranslation {
            translationRichText = entity.comment.content.content
        }
        self.translationRichTextParser = generateRichTextParser(richText: translationRichText, useTranslation: true)

        super.init(entity: entity, context: context, binder: binder)
        self.richTextParser.showMoreCallBack = { [weak self] (showMore) in
            self?.showMore = showMore
        }
        self.translationRichTextParser.showMoreCallBack = { [weak self] (translationShowMore) in
            self?.translationShowMore = translationShowMore
        }
    }

    public override func willDisplay() {
        isDisplay = true
        super.willDisplay()
    }

    public override func didEndDisplay() {
        isDisplay = false
        super.didEndDisplay()
    }

    public override func update(entity: RawData.CommentEntity) {
        self.richTextParser.update(richText: entity.comment.content.content,
                                  urlPreviewProvider: { [weak self] elementID, customAttributes in
                                    return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                                commentEntity: entity,
                                                                                                customAttributes: customAttributes)
                                  })

        var translationRichText = entity.comment.translationInfo.contentTranslation
        if translationRichText.elements.isEmpty,
           !entity.comment.translationInfo.urlPreviewTranslation.isEmpty,
           entity.comment.translationInfo.hasContentTranslation {
            translationRichText = entity.comment.content.content
        }
        self.translationRichTextParser.update(richText: translationRichText,
                                             urlPreviewProvider: { [weak self] elementID, customAttributes in
                                               return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                                                           commentEntity: entity,
                                                                                                           useTranslation: true,
                                                                                                           customAttributes: customAttributes)
                                             })
        super.update(entity: entity)
    }
}
