//
//  RichLabelComponent.swift
//  Pods-TangramComponent_iOS
//
//  Created by 袁平 on 2021/4/14.
//

import Foundation
import RichLabel
import TangramComponent
import UIKit

// swiftlint:disable all
public class RichLabelProps: Props {
    public var attributedText: EquatableWrapper<NSAttributedString?> = .init(value: nil)
    public var backgroundColor: UIColor = UIColor.clear
    public var numberOfLines: Int = 0
    public var preferMaxLayoutWidth: CGFloat?
    public var autoDetectLinks: Bool = true
    public var linkAttributes: EquatableWrapper<[NSAttributedString.Key: Any]> = .init(value: [:])
    public var activeLinkAttributes: EquatableWrapper<[NSAttributedString.Key: Any]> = .init(value: [:])
    public var textCheckingDetecotor: EquatableWrapper<NSRegularExpression?> = .init(value: nil)
    public var outOfRangeText: EquatableWrapper<NSAttributedString?> = .init(value: nil)
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    public var lineSpacing: CGFloat = 2
    public var tag: Int = 0
    public var textLinkList: [LKTextLink] = []
    public var rangeLinkMap: [NSRange: URL] = [:]
    public var tapableRangeList: [NSRange] = []
    public var invaildLinkMap: [NSRange: String] = [:]
    public var invaildLinkBlock: EquatableWrapper<((String) -> Void)?> = .init(value: nil)
    /// 是否开启模糊点击处理
    public var isFuzzyPointAt: Bool = true
    public var fuzzyEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: -5, left: -2, bottom: -5, right: -2)
    public var delegate: WeakEquatableWrapper<LKLabelDelegate> = .init(value: nil)
    public var debugOptions: EquatableWrapper<[LKLabelDebugOptions]> = .init(value: [])

    public init() {}

    public func clone() -> Self {
        let clone = RichLabelProps()
        clone.attributedText = attributedText
        clone.backgroundColor = backgroundColor.copy() as? UIColor ?? UIColor.clear
        clone.numberOfLines = numberOfLines
        clone.preferMaxLayoutWidth = preferMaxLayoutWidth
        clone.autoDetectLinks = autoDetectLinks
        clone.linkAttributes = linkAttributes
        clone.activeLinkAttributes = activeLinkAttributes
        clone.textCheckingDetecotor = textCheckingDetecotor
        clone.outOfRangeText = outOfRangeText
        clone.font = font.copy() as? UIFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        clone.lineSpacing = lineSpacing
        clone.tag = tag
        clone.textLinkList = textLinkList
        clone.rangeLinkMap = rangeLinkMap
        clone.tapableRangeList = tapableRangeList
        clone.invaildLinkMap = invaildLinkMap
        clone.invaildLinkBlock = invaildLinkBlock
        clone.isFuzzyPointAt = isFuzzyPointAt
        clone.fuzzyEdgeInsets = fuzzyEdgeInsets
        clone.delegate = delegate
        clone.debugOptions = debugOptions
        return clone as! Self
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? RichLabelProps else { return false }
        return attributedText == old.attributedText &&
            backgroundColor == old.backgroundColor &&
            numberOfLines == old.numberOfLines &&
            preferMaxLayoutWidth == old.preferMaxLayoutWidth &&
            autoDetectLinks == old.autoDetectLinks &&
            linkAttributes == old.linkAttributes &&
            activeLinkAttributes == old.activeLinkAttributes &&
            textCheckingDetecotor == old.textCheckingDetecotor &&
            outOfRangeText == old.outOfRangeText &&
            font == old.font &&
            lineSpacing == old.lineSpacing &&
            tag == old.tag &&
            textLinkList == old.textLinkList &&
            rangeLinkMap == old.rangeLinkMap &&
            tapableRangeList == old.tapableRangeList &&
            invaildLinkMap == old.invaildLinkMap &&
            invaildLinkBlock == old.invaildLinkBlock &&
            isFuzzyPointAt == old.isFuzzyPointAt &&
            fuzzyEdgeInsets == old.fuzzyEdgeInsets &&
            delegate == old.delegate &&
            debugOptions == old.debugOptions
    }
}

public final class RichLabelComponent<C: Context>: RenderComponent<RichLabelProps, LKLabel, C> {
    public override var isSelfSizing: Bool {
        true
    }
    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()
    /// layoutEngine
    private var layoutEngine: LKTextLayoutEngineImpl
    private var writeLayoutEngine: LKTextLayoutEngine
    /// textParser
    private var textParser: LKTextParserImpl
    private var writeTextParser: LKTextParser
    /// linkParser
    private var linkParser: LKLinkParserImpl
    private var writeLinkParser: LKLinkParserImpl

    public override init(layoutComponent: BaseLayoutComponent? = nil, props: RichLabelProps, style: RenderComponentStyle = RenderComponentStyle(), context: C? = nil) {
        pthread_rwlock_init(&rwlock, nil)
        // layoutEngine init
        self.layoutEngine = LKTextLayoutEngineImpl()
        self.writeLayoutEngine = LKTextLayoutEngineImpl()
        // textParser init
        self.textParser = LKTextParserImpl()
        self.writeTextParser = LKTextParserImpl()
        // linkParser init
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes.value)
        self.writeLinkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes.value)
        super.init(layoutComponent: layoutComponent, props: props, style: style, context: context)
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let size = self.writeLayoutEngine.layout(size: size)
        let layoutEngine = writeLayoutEngine.clone() as! LKTextLayoutEngineImpl
        pthread_rwlock_wrlock(&rwlock)
        self.layoutEngine = layoutEngine
        pthread_rwlock_unlock(&rwlock)
        return size
    }

    public override func update(_ view: LKLabel) {
        super.update(view)
        view.delegate = props.delegate.value
        view.debugOptions = props.debugOptions.value
        view.activeLinkAttributes = props.activeLinkAttributes.value
        view.linkAttributes = props.linkAttributes.value
        view.textCheckingDetecotor = props.textCheckingDetecotor.value
        view.autoDetectLinks = props.autoDetectLinks
        view.numberOfLines = props.numberOfLines
        view.tag = props.tag
        view.isFuzzyPointAt = props.isFuzzyPointAt
        view.fuzzyEdgeInsets = props.fuzzyEdgeInsets
        pthread_rwlock_rdlock(&rwlock)
        view.textParser = textParser
        view.linkParser = linkParser
        view.setForceLayout(layoutEngine)
        pthread_rwlock_unlock(&rwlock)
    }

    public override func render() -> BaseVirtualNode {
        richLabelRender(props, textParser: &writeTextParser, linkParser: &writeLinkParser, layout: &writeLayoutEngine)
        let textParser = writeTextParser.clone() as? LKTextParserImpl ?? LKTextParserImpl()
        let linkParser = writeLinkParser.clone() as? LKLinkParserImpl ?? LKLinkParserImpl(linkAttributes: [:])
        let layoutEngine = writeLayoutEngine.clone() as? LKTextLayoutEngineImpl ?? LKTextLayoutEngineImpl()
        pthread_rwlock_wrlock(&rwlock)
        self.textParser = textParser
        self.linkParser = linkParser
        self.layoutEngine = layoutEngine
        pthread_rwlock_unlock(&rwlock)
        return super.render()
    }
}

extension SelectionLabelComponent {
    public final class Props: RichLabelProps {
        public var options: EquatableWrapper<SelectionLKLabelOptions?> = .init(value: nil)
        public var seletionDebugOptions: EquatableWrapper<LKSelectionLabelDebugOptions?> = .init(value: nil)
        public var inSelectionMode: Bool = false
        public var initSelectedRange: NSRange?
        public var selectionDelegate: WeakEquatableWrapper<LKSelectionLabelDelegate> = .init(value: nil)

        // ⚠️: 继承的Props不可以调用super.clone
        public override func clone() -> Self {
            let clone = Props()
            // super.props
            clone.attributedText = attributedText
            clone.backgroundColor = backgroundColor.copy() as? UIColor ?? UIColor.clear
            clone.numberOfLines = numberOfLines
            clone.preferMaxLayoutWidth = preferMaxLayoutWidth
            clone.autoDetectLinks = autoDetectLinks
            clone.linkAttributes = linkAttributes
            clone.activeLinkAttributes = activeLinkAttributes
            clone.textCheckingDetecotor = textCheckingDetecotor
            clone.outOfRangeText = outOfRangeText
            clone.font = font.copy() as? UIFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            clone.lineSpacing = lineSpacing
            clone.tag = tag
            clone.textLinkList = textLinkList
            clone.rangeLinkMap = rangeLinkMap
            clone.tapableRangeList = tapableRangeList
            clone.invaildLinkMap = invaildLinkMap
            clone.invaildLinkBlock = invaildLinkBlock
            clone.isFuzzyPointAt = isFuzzyPointAt
            clone.fuzzyEdgeInsets = fuzzyEdgeInsets
            clone.delegate = delegate
            clone.debugOptions = debugOptions
            // SelectionLabelComponent props
            clone.options = options
            clone.seletionDebugOptions = seletionDebugOptions
            clone.inSelectionMode = inSelectionMode
            clone.initSelectedRange = initSelectedRange
            clone.selectionDelegate = selectionDelegate
            return clone as! Self
        }

        public override func equalTo(_ old: TangramComponent.Props) -> Bool {
            guard let old = old as? Props else { return false }
            return options == old.options &&
                seletionDebugOptions == old.seletionDebugOptions &&
                inSelectionMode == old.inSelectionMode &&
                initSelectedRange == old.initSelectedRange &&
                selectionDelegate == old.selectionDelegate &&
                super.equalTo(old)
        }
    }
}

public final class SelectionLabelComponent<C: Context>: RenderComponent<SelectionLabelComponent.Props, LKSelectionLabel, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()
    /// layoutEngine
    private var layoutEngine: LKTextLayoutEngineImpl
    private var writeLayoutEngine: LKTextLayoutEngine
    /// textParser
    private var textParser: LKTextParserImpl
    private var writeTextParser: LKTextParser
    /// linkParser
    private var linkParser: LKLinkParserImpl
    private var writeLinkParser: LKLinkParserImpl

    public override init(layoutComponent: BaseLayoutComponent? = nil, props: Props, style: RenderComponentStyle = RenderComponentStyle(), context: C? = nil) {
        pthread_rwlock_init(&rwlock, nil)
        // layoutEngine init
        self.layoutEngine = LKTextLayoutEngineImpl()
        self.writeLayoutEngine = LKTextLayoutEngineImpl()
        // textParser init
        self.textParser = LKTextParserImpl()
        self.writeTextParser = LKTextParserImpl()
        // linkParser init
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes.value)
        self.writeLinkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes.value)
        super.init(layoutComponent: layoutComponent, props: props, style: style, context: context)
    }

    // swiftlint:disable:next force_cast
    public override func sizeToFit(_ size: CGSize) -> CGSize {
        let size = self.writeLayoutEngine.layout(size: size)
        let layoutEngine = writeLayoutEngine.clone() as! LKTextLayoutEngineImpl
        pthread_rwlock_wrlock(&rwlock)
        self.layoutEngine = layoutEngine
        pthread_rwlock_unlock(&rwlock)
        return size
    }
    // swiftlint:enable:next force_cast

    public override func update(_ view: LKSelectionLabel) {
        super.update(view)
        if let opts = props.options.value {
            view.options = opts
        }
        view.delegate = props.delegate.value
        view.debugOptions = props.debugOptions.value
        view.activeLinkAttributes = props.activeLinkAttributes.value
        view.linkAttributes = props.linkAttributes.value
        view.textCheckingDetecotor = props.textCheckingDetecotor.value
        view.autoDetectLinks = props.autoDetectLinks
        view.inSelectionMode = props.inSelectionMode
        view.initSelectedRange = props.initSelectedRange
        view.selectionDelegate = props.selectionDelegate.value
        view.seletionDebugOptions = props.seletionDebugOptions.value
        view.numberOfLines = props.numberOfLines
        view.tag = props.tag
        view.isFuzzyPointAt = props.isFuzzyPointAt
        view.fuzzyEdgeInsets = props.fuzzyEdgeInsets
        pthread_rwlock_rdlock(&rwlock)
        view.textParser = textParser
        view.linkParser = linkParser
        view.setForceLayout(layoutEngine)
        pthread_rwlock_unlock(&rwlock)
    }

    public override func render() -> BaseVirtualNode {
        richLabelRender(props, textParser: &writeTextParser, linkParser: &writeLinkParser, layout: &writeLayoutEngine)
        let textParser = writeTextParser.clone() as? LKTextParserImpl ?? LKTextParserImpl()
        let linkParser = writeLinkParser.clone() as? LKLinkParserImpl ?? LKLinkParserImpl(linkAttributes: [:])
        let layoutEngine = writeLayoutEngine.clone() as? LKTextLayoutEngineImpl ?? LKTextLayoutEngineImpl()
        pthread_rwlock_wrlock(&rwlock)
        self.textParser = textParser
        self.linkParser = linkParser
        self.layoutEngine = layoutEngine
        pthread_rwlock_unlock(&rwlock)
        return super.render()
    }
}

func richLabelRender(
    _ props: RichLabelProps,
    textParser: inout LKTextParser,
    linkParser: inout LKLinkParserImpl,
    layout: inout LKTextLayoutEngine) {

    textParser.defaultFont = props.font
    linkParser.linkAttributes = props.linkAttributes.value
    linkParser.rangeLinkMapper = props.rangeLinkMap
    linkParser.tapableRangeList = props.tapableRangeList
    linkParser.textLinkList = props.textLinkList
    props.invaildLinkMap.forEach { (range, url) in
        var textLink = LKTextLink(range: range, type: .link)
        textLink.linkTapBlock = { (_, _) in
            props.invaildLinkBlock.value?(url)
        }
        linkParser.textLinkList.append(textLink)
    }

    linkParser.defaultFont = props.font

    textParser.originAttrString = props.attributedText.value
    textParser.parse()
    linkParser.originAttrString = textParser.renderAttrString
    linkParser.parserIndicesToOriginIndices = textParser.parserIndicesToOriginIndices
    linkParser.parse()
    layout.outOfRangeText = props.outOfRangeText.value
    layout.attributedText = linkParser.renderAttrString
    layout.preferMaxWidth = props.preferMaxLayoutWidth ?? -1
    layout.lineSpacing = props.lineSpacing
    layout.numberOfLines = props.numberOfLines
}
// swiftlint:enable all
