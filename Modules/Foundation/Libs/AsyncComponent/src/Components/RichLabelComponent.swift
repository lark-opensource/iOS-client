//
//  RichLabelComponent.swift
//  AsyncComponent
//
//  Created by qihongye on 2019/1/30.
//

import UIKit
import Foundation
import RichLabel
import EEAtomic

public class RichLabelProps: SafeASComponentProps {
    /// props存在多线程读写问题，需要防护
    private var _attributedText: NSAttributedString?
    public var attributedText: NSAttributedString? {
        get { return safeRead { self._attributedText } }
        set { safeWrite { self._attributedText = newValue } }
    }
    private var _backgroundColor = UIColor.clear
    public var backgroundColor: UIColor {
        get { return safeRead { self._backgroundColor } }
        set { safeWrite { self._backgroundColor = newValue } }
    }
    public var numberOfLines: Int = 0
    public var preferMaxLayoutWidth: CGFloat?
    public var autoDetectLinks: Bool = true
    private var _linkAttributes: [NSAttributedString.Key: Any] = [:]
    public var linkAttributes: [NSAttributedString.Key: Any] {
        get { return safeRead { self._linkAttributes } }
        set { safeWrite { self._linkAttributes = newValue } }
    }
    private var _activeLinkAttibutes: [NSAttributedString.Key: Any] = [:]
    public var activeLinkAttributes: [NSAttributedString.Key: Any] {
        get { return safeRead { self._activeLinkAttibutes } }
        set { safeWrite { self._activeLinkAttibutes = newValue } }
    }
    public var textCheckingDetecotor: NSRegularExpression?
    /// props存在多线程读写问题，需要防护
    private var _outOfRangeText: NSAttributedString?
    public var outOfRangeText: NSAttributedString? {
        get { return safeRead { self._outOfRangeText } }
        set { safeWrite { self._outOfRangeText = newValue } }
    }
    private var _font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    public var font: UIFont {
        get { return safeRead { self._font } }
        set { safeWrite { self._font = newValue } }
    }
    public var lineSpacing: CGFloat = 2
    public var tag: Int = 0
    public var textLinkList: [LKTextLink] = []
    public var rangeLinkMap: [NSRange: URL] = [:]
    public var tapableRangeList: [NSRange] = []
    public var invaildLinkMap: [NSRange: String] = [:]
    public var invaildLinkBlock: ((String) -> Void)?
    /// 是否开启模糊点击处理
    public var isFuzzyPointAt: Bool = true
    public weak var delegate: LKLabelDelegate?
    public var debugOptions: [LKLabelDebugOptions]?
}

public final class RichLabelComponent<C: Context>: ASComponent<RichLabelProps, EmptyState, LKLabel, C> {
    private let unfairLock: UnsafeMutablePointer<os_unfair_lock_s>
    /// layoutEngine
    private var layoutEngine: LKTextLayoutEngine
    /// textParser
    private var textParser: LKTextParser
    /// linkParser
    private var linkParser: LKLinkParserImpl

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override init(props: RichLabelProps, style: ASComponentStyle, context: C? = nil) {
        unfairLock = UnsafeMutablePointer.allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock_s())
        // layoutEngine init
        self.layoutEngine = LKTextLayoutEngineImpl()
        // textParser init
        self.textParser = LKTextParserImpl()
        // linkParser init
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        super.init(props: props, style: style, context: context)
    }

    deinit {
        unfairLock.deallocate()
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        os_unfair_lock_lock(unfairLock)
        let writeLayoutEngine = self.layoutEngine.clone() as? LKTextLayoutEngineImpl ?? LKTextLayoutEngineImpl()
        os_unfair_lock_unlock(unfairLock)
        let size = writeLayoutEngine.layout(size: size)
        os_unfair_lock_lock(unfairLock)
        self.layoutEngine = writeLayoutEngine
        os_unfair_lock_unlock(unfairLock)
        return size
    }

    public override func update(view: LKLabel) {
        super.update(view: view)
        view.delegate = props.delegate
        view.debugOptions = props.debugOptions
        view.activeLinkAttributes = props.activeLinkAttributes
        view.linkAttributes = props.linkAttributes
        view.textCheckingDetecotor = props.textCheckingDetecotor
        view.autoDetectLinks = props.autoDetectLinks
        view.numberOfLines = props.numberOfLines
        view.tag = props.tag
        view.isFuzzyPointAt = props.isFuzzyPointAt
        os_unfair_lock_lock(unfairLock)
        view.textParser = textParser
        view.linkParser = linkParser
        let engine = layoutEngine
        os_unfair_lock_unlock(unfairLock)
        view.setForceLayout(engine)
    }

    public override func render() -> BaseVirtualNode {
        var writeLayoutEngine: LKTextLayoutEngine = LKTextLayoutEngineImpl()
        var writeTextParser: LKTextParser = LKTextParserImpl()
        var writeLinkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        richLabelRender(props, textParser: &writeTextParser, linkParser: &writeLinkParser, layout: &writeLayoutEngine)
        os_unfair_lock_lock(unfairLock)
        self.textParser = writeTextParser
        self.linkParser = writeLinkParser
        self.layoutEngine = writeLayoutEngine
        os_unfair_lock_unlock(unfairLock)
        return super.render()
    }
}

public final class SelectionLabelComponent<C: Context>: ASComponent<
    SelectionLabelComponent.Props,
    EmptyState,
    LKSelectionLabel, C
> {
    public final class Props: RichLabelProps {
        public var pointerInteractionEnable: Bool = true
        public var options: SelectionLKLabelOptions?
        public var seletionDebugOptions: LKSelectionLabelDebugOptions?
        public weak var selectionDelegate: LKSelectionLabelDelegate?
    }

    private let unfairLock: UnsafeMutablePointer<os_unfair_lock_s>
    /// layoutEngine
    private var layoutEngine: LKTextLayoutEngine
    /// textParser
    private var textParser: LKTextParser
    /// linkParser
    private var linkParser: LKLinkParserImpl

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override init(props: SelectionLabelComponent.Props, style: ASComponentStyle, context: C? = nil) {
        unfairLock = UnsafeMutablePointer.allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock_s())
        // layoutEngine init
        self.layoutEngine = LKTextLayoutEngineImpl()
        // textParser init
        self.textParser = LKTextParserImpl()
        // linkParser init
        self.linkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        super.init(props: props, style: style, context: context)
    }

    deinit {
        unfairLock.deallocate()
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        os_unfair_lock_lock(unfairLock)
        let writeLayoutEngine = self.layoutEngine.clone() as? LKTextLayoutEngineImpl ?? LKTextLayoutEngineImpl()
        os_unfair_lock_unlock(unfairLock)
        let size = writeLayoutEngine.layout(size: size)
        os_unfair_lock_lock(unfairLock)
        self.layoutEngine = writeLayoutEngine
        os_unfair_lock_unlock(unfairLock)
        return size
    }

    public override func update(view: LKSelectionLabel) {
        super.update(view: view)
        if let opts = props.options {
            view.options = opts
        }
        view.delegate = props.delegate
        view.debugOptions = props.debugOptions
        view.activeLinkAttributes = props.activeLinkAttributes
        view.linkAttributes = props.linkAttributes
        view.textCheckingDetecotor = props.textCheckingDetecotor
        view.autoDetectLinks = props.autoDetectLinks
        view.selectionDelegate = props.selectionDelegate
        view.seletionDebugOptions = props.seletionDebugOptions
        view.numberOfLines = props.numberOfLines
        view.tag = props.tag
        view.isFuzzyPointAt = props.isFuzzyPointAt
        os_unfair_lock_lock(unfairLock)
        view.textParser = textParser
        view.linkParser = linkParser
        let engine = layoutEngine
        os_unfair_lock_unlock(unfairLock)
        view.setForceLayout(engine)
        view.pointerInteractionEnable = props.pointerInteractionEnable
    }

    public override func render() -> BaseVirtualNode {
        var writeLayoutEngine: LKTextLayoutEngine = LKTextLayoutEngineImpl()
        var writeTextParser: LKTextParser = LKTextParserImpl()
        var writeLinkParser = LKLinkParserImpl(linkAttributes: props.linkAttributes)
        richLabelRender(props, textParser: &writeTextParser, linkParser: &writeLinkParser, layout: &writeLayoutEngine)
        os_unfair_lock_lock(unfairLock)
        self.textParser = writeTextParser
        self.linkParser = writeLinkParser
        self.layoutEngine = writeLayoutEngine
        os_unfair_lock_unlock(unfairLock)
        return super.render()
    }
}

public func richLabelRender(
    _ props: RichLabelProps,
    textParser: inout LKTextParser,
    linkParser: inout LKLinkParserImpl,
    layout: inout LKTextLayoutEngine) {

    textParser.defaultFont = props.font
    linkParser.linkAttributes = props.linkAttributes
    linkParser.rangeLinkMapper = props.rangeLinkMap
    linkParser.tapableRangeList = props.tapableRangeList
    linkParser.textLinkList = props.textLinkList
    props.invaildLinkMap.forEach { (range, url) in
        var textLink = LKTextLink(range: range, type: .link)
        textLink.linkTapBlock = { (_, _) in
            props.invaildLinkBlock?(url)
        }
        linkParser.textLinkList.append(textLink)
    }

    linkParser.defaultFont = props.font

    textParser.originAttrString = props.attributedText
    textParser.parse()
    linkParser.originAttrString = textParser.renderAttrString
    linkParser.parserIndicesToOriginIndices = textParser.parserIndicesToOriginIndices
    linkParser.parse()
    layout.outOfRangeText = props.outOfRangeText
    layout.attributedText = linkParser.renderAttrString
    layout.preferMaxWidth = props.preferMaxLayoutWidth ?? -1
    layout.lineSpacing = props.lineSpacing
    layout.numberOfLines = props.numberOfLines
}
