//
//  TextAndMediaContentComponentBinder.swift
//  Moment
//
//  Created by zc09v on 2021/1/7.
//

import UIKit
import Foundation
import LarkMessageBase
import EEFlexiable
import AsyncComponent
import LarkMessageCore
//文字 + 图
final class PostTextAndMediaContentComponentBinder<C: BaseMomentContext>: ComponentBinder<C> {
    private let textAndMediaContentComponentKey: String = "text_media_content"
    private lazy var _component: ASLayoutComponent<C> = .init(key: "", style: .init(), context: nil, [])

    private lazy var selectionLabelProps: SelectionLabelComponent<C>.Props = {
        let selectionLabelProps = SelectionLabelComponent<C>.Props()
        selectionLabelProps.lineSpacing = 2
        selectionLabelProps.pointerInteractionEnable = false
        selectionLabelProps.outOfRangeText = self.getOutOfRangeAttributedString()
        return selectionLabelProps
    }()

    private lazy var translationSelectionLabelProps: SelectionLabelComponent<C>.Props = {
        let selectionLabelProps = SelectionLabelComponent<C>.Props()
        selectionLabelProps.lineSpacing = 2
        selectionLabelProps.pointerInteractionEnable = false
        selectionLabelProps.outOfRangeText = self.getOutOfRangeAttributedString()
        return selectionLabelProps
    }()

    /// 图片区props
    private lazy var gridViewProps: MomentsGridViewComponent<C>.Props = {
        let gridViewProps = MomentsGridViewComponent<C>.Props()
        return gridViewProps
    }()

    //文字区
    private lazy var contentComponent: SelectionLabelComponent<C> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        return SelectionLabelComponent<C>(
            props: self.selectionLabelProps,
            style: style
        )
    }()

    /// 分割style
    private lazy var centerStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.alignItems = .center
        style.height = 17
        style.width = 100%
        return style
    }()
    // 分割Component：line
    private lazy var centerLineComponent: UIViewComponent<C> = {
        let lineStyle = ASComponentStyle()
        lineStyle.flexGrow = 1
        lineStyle.height = CSSValue(cgfloat: 1 / UIScreen.main.scale)
        lineStyle.backgroundColor = .ud.lineDividerDefault
        return UIViewComponent<C>(props: .empty, style: lineStyle)
    }()
    private lazy var centerComponent: ASLayoutComponent<C> = {
        return ASLayoutComponent<C>(style: centerStyle, [centerLineComponent])
    }()

    //译文区
    private lazy var translationComponent: SelectionLabelComponent<C> = {
        var style = ASComponentStyle()
        style.backgroundColor = .clear
        return SelectionLabelComponent<C>(
            props: self.translationSelectionLabelProps,
            style: style
        )
    }()

    var onTranslateFeedBack: (() -> Void)?
    // 翻译反馈
    private lazy var translateFeedBackComponent: RightButtonComponent<C> = {
        return ChatViewTemplate<C>.createTranslateFeedbackButton(action: { [weak self] in
            self?.onTranslateFeedBack?()
        }, style: feedBackStyle)
    }()
    // 翻译反馈style
    private lazy var feedBackStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 6
        return style
    }()

    private lazy var translateStatusComponent: TranslateButtonComponent<C> = {
        let props = TranslateButtonComponent<C>.Props()
        props.text = BundleI18n.Moment.Moments_TranslationInProgress_Text
        props.translateStatus = .translating
        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        style.marginTop = 8
        style.marginBottom = 5
        return TranslateButtonComponent<C>(props: props, style: style)
    }()

    //全文按钮
    private lazy var fullTextComponent: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.text = BundleI18n.Moment.Lark_Community_FullText
        props.textColor = UIColor.ud.textLinkNormal
        props.isUserInteractionEnabled = false
        props.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        let style = ASComponentStyle()
        style.marginTop = 4
        style.backgroundColor = .clear
        return UILabelComponent(props: props, style: style)
    }()

    //全文按钮
    private lazy var translationFullTextComponent: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.text = BundleI18n.Moment.Lark_Community_FullText
        props.textColor = UIColor.ud.textLinkNormal
        props.isUserInteractionEnabled = false
        props.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        let style = ASComponentStyle()
        style.marginTop = 4
        style.backgroundColor = .clear
        return UILabelComponent(props: props, style: style)
    }()

    //图片区
    private lazy var gridViewComponent: MomentsGridViewComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 8
        return MomentsGridViewComponent<C>(
            props: self.gridViewProps,
            style: style
        )
    }()

    /// 视频区
    lazy var videoCoverConatiner: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 8
        return ASLayoutComponent(style: style, [videoCoverComponent])
    }()

    private lazy var videoCoverComponentProps: MomentsVideoCorveComponent<C>.Props = {
        return MomentsVideoCorveComponent<C>.Props()
    }()

    private lazy var videoCoverComponent: MomentsVideoCorveComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.cornerRadius = 4
        style.border = Border(BorderEdge(width: 0.5, color: UIColor.ud.N900.withAlphaComponent(0.15), style: .solid))
        let component = MomentsVideoCorveComponent<C>(props: self.videoCoverComponentProps, style: style)
        return component
    }()

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PostTextAndMediaContentCellViewModel else {
            assertionFailure()
            return
        }
        self.onTranslateFeedBack = vm.onTranslateFeedBack
        self.configSelectionLabelProps(vm: vm)
        self.configGridViewProps(vm: vm)
        self.configVideoProps(vm: vm)
    }

    private func configSelectionLabelProps(vm: PostTextAndMediaContentCellViewModel) {
        let displayRule = vm.displayRule
        let content = vm.richTextParser.attributedString
        let translation = vm.translationRichTextParser.attributedString
        let showContent: Bool
        let showTranslation: Bool
        if content.length == 0 {
            showContent = false
            showTranslation = false
        } else if translation.length == 0 || !vm.needToShowTranslate {
            showContent = true
            showTranslation = false
        } else {
            switch displayRule {
            case .onlyTranslation:
                showContent = false
                showTranslation = true
            case .withOriginal:
                showContent = true
                showTranslation = true
            @unknown default:
                assertionFailure("unexpected value")
                showContent = true
                showTranslation = false
            }
        }

        contentComponent.style.display = showContent ? .flex : .none
        fullTextComponent.style.display = (showContent && vm.showMore) ? .flex : .none
        centerComponent.style.display = (showContent && showTranslation) ? .flex : .none
        translationComponent.style.display = showTranslation ? .flex : .none
        translationFullTextComponent.style.display = showTranslation &&
        //如果原文也显示，译文的showMore跟随原文的showMore；否则译文自己判断showMore
        ((showContent && vm.showMore) || (!showContent && vm.translationShowMore)) ? .flex : .none

        translateFeedBackComponent.style.display = showTranslation ? .flex : .none
        translateStatusComponent.style.display = (!showTranslation && vm.needToShowTranslate) ? .flex : .none

        if showContent {
            configPropsWithRichTextParser(props: self.selectionLabelProps, richTextParser: vm.richTextParser)
            contentComponent.props = selectionLabelProps
        }
        if showTranslation {
            configPropsWithRichTextParser(props: self.translationSelectionLabelProps, richTextParser: vm.translationRichTextParser)
            translationComponent.props = translationSelectionLabelProps
        }
    }

    private func configPropsWithRichTextParser(props: SelectionLabelComponent<C>.Props,
                                               richTextParser: RichTextAbilityParser) {
        let contentAttributedString = richTextParser.attributedString
        if contentAttributedString.length != 0 {
            props.attributedText = contentAttributedString
            props.numberOfLines = richTextParser.numberOfLines
            props.autoDetectLinks = true
            props.linkAttributes = richTextParser.linkAttributes
            props.activeLinkAttributes = richTextParser.activeLinkAttributes
            props.rangeLinkMap = richTextParser.attributeElement.urlRangeMap
            let tapableRanges = richTextParser.attributeElement.atRangeMap.flatMap({ $0.value })
                + richTextParser.attributeElement.abbreviationRangeMap.compactMap({ $0.key })
                + richTextParser.attributeElement.mentionsRangeMap.compactMap({ $0.key })
                + richTextParser.attributeElement.hashTagMap.compactMap({ $0.key })
            props.tapableRangeList = tapableRanges
            props.textCheckingDetecotor = richTextParser.textCheckingDetecotor
            props.delegate = richTextParser
            props.font = richTextParser.font
            props.lineSpacing = richTextParser.contentLineSpacing
            props.textLinkList = richTextParser.textLinkList
        }
    }

    private func configGridViewProps(vm: PostTextAndMediaContentCellViewModel) {
        gridViewComponent.style.display = vm.imageInfoProps.isEmpty ? .none : .flex
        gridViewProps.imageInfoProps = vm.imageInfoProps
        gridViewProps.preferMaxWidth = vm.imageListMaxWidth
        gridViewProps.shouldAnimating = vm.isDisplay
        gridViewProps.hostSize = vm.hostSize
        gridViewComponent.props = gridViewProps
    }

    private func configVideoProps(vm: PostTextAndMediaContentCellViewModel) {
        if let mediaInfo = vm.mediaInfo {
            videoCoverComponentProps.preferMaxWidth = vm.videoCoverImageMaxWidth
            videoCoverComponentProps.videoTime = vm.mediaInfo?.durationSec
            videoCoverComponentProps.originSize = CGSize(width: CGFloat(mediaInfo.cover.origin.width), height: CGFloat(mediaInfo.cover.origin.height))
            videoCoverComponentProps.coverImage = Resources.momentVideoPlay
            videoCoverComponentProps.imageClick = vm.videoCoverImageClick
            videoCoverComponentProps.setImageAction = vm.videoCoverImageAction
            videoCoverComponent.props = videoCoverComponentProps
            videoCoverConatiner.style.display = .flex
        } else {
            videoCoverConatiner.style.display = .none
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.flexDirection = .column

        self._component = ASLayoutComponent<C>(
            key: key ?? textAndMediaContentComponentKey,
            style: style,
            context: context,
            [contentComponent,
             fullTextComponent,
             centerComponent,
             translationComponent,
             translationFullTextComponent,
             gridViewComponent,
             videoCoverConatiner,
            translateFeedBackComponent,
            translateStatusComponent]
        )
    }

    private func getOutOfRangeAttributedString() -> NSAttributedString {
        let text = "\u{2026} "
        let attributesNomal: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]
        return NSAttributedString(string: text, attributes: attributesNomal)
    }
}
