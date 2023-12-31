//
//  NewCommentCellViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/11/24.
//

import UIKit
import Foundation
import LarkMessageBase
import EEFlexiable
import AsyncComponent
import LarkModel
import LarkFoundation
import LarkCore
import LarkMessageCore
import LarkAccountInterface
import LarkContainer
import RichLabel
import LarkMessengerInterface
import LarkUIKit
import LarkSDKInterface
import EENavigator
import ByteWebImage
import UniverseDesignColor
import LarkFeatureGating
import LarkSetting

final class NewPostCommentCellViewModel: BaseMomentSubCellViewModel<RawData.PostEntity, BaseMomentContext>, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver, entity: RawData.PostEntity, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        self.userResolver = userResolver
        super.init(entity: entity, context: context, binder: binder)
    }

    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    public override var identifier: String {
        return "post_comments"
    }
    static let maxDisplayCount: Int = 5
    /// 当前的场景 feed还是detail
    fileprivate lazy var scene: MomentContextScene = {
        return self.context.pageAPI?.scene ?? .unknown
    }()

    var hostSize: CGSize {
        return context.pageAPI?.hostSize ?? .zero
    }

    var isDisplay: Bool = false {
        didSet {
            if isDisplay != oldValue, !comments.isEmpty {
                binder.update(with: self)
                update(component: binder.component)
            }
        }
    }
    var comments: [RawData.CommentEntity] {
        return Array(entity.comments.prefix(Self.maxDisplayCount))
    }
    var hasComment: Bool {
        return !self.comments.isEmpty
    }

    func getCommentAttributedStringWithComment(_ comment: RawData.CommentEntity) -> NSAttributedString? {
        let font = UIFont.systemFont(ofSize: 14)
        let textColor = UIColor.ud.textCaption
        guard let userGeneralSettings, let fgService else { return nil }
        let useTranslation = comment.comment.canShowTranslation(fgService: fgService, userGeneralSettings: userGeneralSettings)
        let urlPreviewProvider: LarkCoreUtils.URLPreviewProvider = { [weak self] elementID, customAttributes in
            return self?.context.inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID,
                                                                        commentEntity: comment,
                                                                        useTranslation: useTranslation,
                                                                        customAttributes: customAttributes)
        }
        let parser = RichTextAbilityParser(userResolver: userResolver,
                                           richText: comment.comment.getDisplayContent(fgService: fgService, userGeneralSettings: userGeneralSettings),
                                           font: font,
                                           showTranslatedTag: useTranslation,
                                           textColor: textColor,
                                           iconColor: textColor,
                                           tagType: .normal,
                                           numberOfLines: 2,
                                           needCheckFromMe: false,
                                           urlPreviewProvider: urlPreviewProvider)
        let attr = parser.attributedString
        return MomentsDataConverter.addAttributesForAttributeString(attr, font: font, textColor: textColor)
    }

    func coverImageActionForIndex(_ index: Int) -> SetImageAction {
        return { [weak self] imageView, _, completion in
            guard let self = self,
                  index < self.comments.count else {
                return
            }
            /// 这里优先使用本地图片
            let imageSet = self.comments[index].comment.content.imageSet
            var key = MomentsDataConverter.getImageSetThumbnailKey(imageSet: imageSet)
            let localPath = imageSet.imageLocalPath()
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
    }

    func coverImageClickForIndex(_ index: Int) -> ((UIImageView) -> Void)? {
        return { [weak self] (imageView) in
            self?.showImagePerviewWith(index: index, imageView: imageView)
        }
    }

    func commentClickForIndex(_ index: Int) -> (() -> Void)? {
        return { [weak self] in
            guard let self = self, index < self.comments.count else {
                return
            }
            self.pushToMomentDetailWithComment(self.comments[index])
        }
    }

    func pushToMomentDetailWithComment(_ comment: RawData.CommentEntity) {
        guard let pageAPI = self.context.pageAPI else {
            return
        }
        let body = MomentPostDetailByPostBody(post: self.entity,
                                              scrollState: .toCommentId(comment.id),
                                              source: MomentsDataConverter.transformSenceToPageSource(self.scene))
        userResolver.navigator.push(body: body, from: pageAPI)
    }

    /// 展示图片
    /// - Parameter index: 选中index
    private func showImagePerviewWith(index: Int, imageView: UIImageView?) {
        guard index < self.comments.count,
              let pageAPI = self.context.pageAPI else {
            return
        }
        let commentImage = self.comments[index].comment.content.imageSet
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
        userResolver.navigator.present(body: body, from: pageAPI)
    }

    public override func willDisplay() {
        isDisplay = true
        super.willDisplay()
    }

    public override func didEndDisplay() {
        isDisplay = false
        super.didEndDisplay()
    }
}

final class NewPostCommentCellViewModelBinder<C: BaseMomentContext>: ComponentBinder<C> {
    private let postCommentsComponentKey: String = "post_normal_comments"
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])
    public override var component: ComponentWithContext<C> {
        return _component
    }

    //bubble
    lazy var bubbleComponent: UIViewComponent<C> = {
        let props = ASComponentProps()
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.alignItems = .flexStart
        style.paddingLeft = 8
        style.paddingBottom = 12
        style.paddingRight = 8
        style.backgroundColor = UIColor.ud.N100
        style.cornerRadius = 4
        return UIViewComponent<C>(props: props, style: style)
    }()

    lazy var commentComponents: [NewPostCommentComponent<C>] = {
        var components: [NewPostCommentComponent<C>] = []
        for index in 0..<NewPostCommentCellViewModel.maxDisplayCount {
            let props = NewPostCommentComponent<C>.Props<C>()
            let style = ASComponentStyle()
            style.marginTop = index == 0 ? 12 : 8
            let component =
                NewPostCommentComponent(props: props, style: style)
            components.append(component)
        }
        return components
    }()

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? NewPostCommentCellViewModel else {
            assertionFailure()
            return
        }
        if vm.hasComment, (vm.scene.isFeed || vm.scene == .profile || vm.scene.isCategoryDetail || vm.scene.isHashTagDetail) {
            commentComponents.forEach { $0.style.display = .none }
            for (index, comment) in vm.comments.enumerated() where index < commentComponents.count {
                let props = commentComponents[index].props
                props.onClicked = vm.commentClickForIndex(index)
                configSelectionLabelProps(vm: vm, comment: comment, selectionLabelProps: props.selectionProps)
                configImageProps(vm: vm, comment: comment, imageComponentProps: props.imageProps, index: index)
                let component = commentComponents[index]
                component.props = props
                component.style.display = .flex
            }
            bubbleComponent.setSubComponents(commentComponents)
            self._component.style.display = .flex
        } else {
            bubbleComponent.setSubComponents([])
            self._component.style.display = .none
        }
    }

    private func configSelectionLabelProps(vm: NewPostCommentCellViewModel, comment: RawData.CommentEntity, selectionLabelProps: SelectionLabelComponent<C>.Props) {
        let commentAttrStr = NSMutableAttributedString()
        let nameFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        if comment.comment.isHot {
            let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
                return HopTipView()
            }, size: HopTipView.getSuggestSize())
            attachment.fontAscent = nameFont.ascender
            attachment.fontDescent = nameFont.descender
            commentAttrStr.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: [
                LKAttachmentAttributeName: attachment
            ]))
        }
        let nameString: String
        if let replyUser = comment.replyUser {
            nameString = BundleI18n.Moment.Moments_ReplyToThirdPerson_Tooltip(comment.userDisplayName, replyUser.displayName)
        } else {
            nameString = comment.userDisplayName
        }
        commentAttrStr.append(NSAttributedString(string: "\(nameString): ",
                                                 attributes: [
                                                    .foregroundColor: UIColor.ud.N700,
                                                    .font: nameFont
                                                   ]))

        if let attr = vm.getCommentAttributedStringWithComment(comment) {
            commentAttrStr.append(attr)
            selectionLabelProps.attributedText = commentAttrStr
            selectionLabelProps.autoDetectLinks = true
            selectionLabelProps.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: [
                .foregroundColor: UIColor.ud.textCaption,
                .font: UIFont.ud.title3
            ])
        } else {
            selectionLabelProps.attributedText = commentAttrStr
            selectionLabelProps.delegate = nil
        }
        selectionLabelProps.lineSpacing = 4
        selectionLabelProps.numberOfLines = 2
    }

    private func configImageProps(vm: NewPostCommentCellViewModel, comment: RawData.CommentEntity, imageComponentProps: MomentsSingleImageComponent<C>.Props, index: Int) {
        let imageSet = comment.comment.content.imageSet
        if !imageSet.origin.key.isEmpty || !imageSet.thumbnail.key.isEmpty {
            imageComponentProps.setImageAction = vm.coverImageActionForIndex(index)
            imageComponentProps.fixedSize = CGSize(width: 72, height: 72)
            imageComponentProps.hostSize = vm.hostSize
            imageComponentProps.imageClick = vm.coverImageClickForIndex(index)
            imageComponentProps.shouldAnimating = vm.isDisplay
        } else {
            imageComponentProps.shouldAnimating = false
            imageComponentProps.setImageAction = nil
            imageComponentProps.imageClick = nil
            imageComponentProps.originSize = .zero
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.flexDirection = .column
        self._component = ASLayoutComponent<C>(
            key: key ?? postCommentsComponentKey,
            style: style,
            context: context,
            [bubbleComponent]
        )
    }
}
final class NewPostCommentComponent<C: BaseMomentContext>: ASComponent<NewPostCommentComponent<C>.Props<C>, EmptyState, UIView, C> {

    final class Props<C: BaseMomentContext>: ASComponentProps {
        let selectionProps: SelectionLabelComponent<C>.Props = SelectionLabelComponent<C>.Props()
        let imageProps: MomentsSingleImageComponent<C>.Props = MomentsSingleImageComponent<C>.Props()
        var onClicked: (() -> Void)?
    }

    lazy var tapContainerComponent: TappedComponent<C> = {
        let props = TappedComponentProps()
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexWrap = .noWrap
        style.width = 100%
        return TappedComponent<C>(props: props, style: style)
    }()

    private lazy var selectionLabelProps: SelectionLabelComponent<C>.Props = {
        let selectionLabelProps = SelectionLabelComponent<C>.Props()
        selectionLabelProps.pointerInteractionEnable = false
        return selectionLabelProps
    }()

    //文字区
    private lazy var textComponent: SelectionLabelComponent<C> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        return SelectionLabelComponent<C>(
            props: self.selectionLabelProps,
            style: style
        )
    }()

    /// 图片区
    lazy var imageComponentConatiner: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        return ASLayoutComponent(style: style, [imageComponent])
    }()

    private lazy var imageComponentProps: MomentsSingleImageComponent<C>.Props = {
        return MomentsSingleImageComponent<C>.Props()
    }()

    private lazy var imageComponent: MomentsSingleImageComponent <C> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        style.cornerRadius = 4
        style.borderWidth = 0.5
        style.border = Border(BorderEdge(width: 0.5, color: UIColor.ud.N900.withAlphaComponent(0.15), style: .solid))
        return MomentsSingleImageComponent<C>(props: imageComponentProps, style: style)

    }()

    public override init(props: NewPostCommentComponent.Props<C>, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        tapContainerComponent.setSubComponents([textComponent, imageComponentConatiner])
        setSubComponents([
            tapContainerComponent
        ])
    }

    public override func willReceiveProps(_ old: NewPostCommentComponent.Props<C>,
                                          _ new: NewPostCommentComponent.Props<C>) -> Bool {
        textComponent.style.display = (new.selectionProps.attributedText?.length ?? 0) == 0 ? .none : .flex
        imageComponent.style.display = new.imageProps.setImageAction == nil ? .none : .flex
        textComponent.props = new.selectionProps
        imageComponent.props = new.imageProps
        tapContainerComponent.props.onClicked = new.onClicked
        let marginTop: CGFloat = imageComponent.style.display == .flex ? 6 : 0
        imageComponent.style.marginTop = CSSValue(cgfloat: marginTop)
        let marginBottom: CGFloat = imageComponent.style.display == .flex ? 2 : 0
        imageComponent.style.marginBottom = CSSValue(cgfloat: marginBottom)
        return true
    }

}

final class HopTipView: UIView {
    static let rightMagin: CGFloat = 6
    static func getSuggestSize() -> CGSize {
        BundleI18n.Moment.Lark_Community_HotComments
        let textWidth = MomentsDataConverter.widthForString(BundleI18n.Moment.Lark_Community_HotComments, font: UIFont.systemFont(ofSize: 12, weight: .medium))
        return CGSize(width: textWidth + 24 + rightMagin, height: 18)
    }
    lazy var icon: UIImageView = {
        let view = UIImageView()
        view.image = Resources.momentsHotComment
        view.contentMode = .scaleAspectFit
        return view
    }()
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.Y300 & UIColor.ud.Y100
        view.lu.addCorner(corners: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner], cornerSize: CGSize(width: 9, height: 9))
        return view
    }()
    lazy var label: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        view.textColor = UIColor.ud.Y800
        view.text = BundleI18n.Moment.Lark_Community_HotComments
        return view
    }()
    init() {
        super.init(frame: CGRect(origin: .zero, size: Self.getSuggestSize()))
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-Self.rightMagin)
            make.left.equalToSuperview().offset(8)
            make.height.equalTo(18)
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalTo(backgroundView)
            make.right.equalToSuperview().offset(-5 - Self.rightMagin)
        }
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
