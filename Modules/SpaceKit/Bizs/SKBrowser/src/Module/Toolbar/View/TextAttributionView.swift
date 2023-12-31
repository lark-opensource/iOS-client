//
//  TextAttributionView.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/6.
//
// doc text attribution setting panel view. it's the second level panel

import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import RxSwift

/// delegate
public protocol TextAttributionViewDelegate: AnyObject {

    /// report the delegate when the attributon button is pressed
    ///
    /// - Parameters:
    ///   - view: current attribution view
    ///   - button: attribution button which fires this event
    func didClickTxtAttributionView(view: TextAttributionView, button: AttributeButton)
}

public struct AttributeViewLayout {
    public var topBottomPadding: CGFloat = 16 // 整体工具栏跟屏幕边框的默认上下间距
    public var leftRightPadding: CGFloat = 16  // 整体工具栏
    public var linePadding: CGFloat = 16      // 工具栏行间距
    public var innerButtonPadding: CGFloat = 1      // 工具栏同组按钮的间距
    public var outButtonPadding: CGFloat = 10       // 工具栏同行、不同组之间的间距
    public var buttonHeight: CGFloat = 48            // 工具栏按钮高度
    public init() {}
}

public final class TextAttributionView: SKSubToolBarPanel {
    /// should show panel centered display, default is true
    public var shouldCenteredDisplay = true
    /// delegate
    public weak var delegate: TextAttributionViewDelegate?
    /// layouts about how to put button
    private var layouts: [ToolBarLineType]
    /// the base UI info about how to display all the attributon sub button
    private var statusInfos: [BarButtonIdentifier: ToolBarItemInfo]
    /// toolbar's top、bottom padding to superView, must be dynamic cacluated
    private var topBottomPadding: CGFloat = 16
    /// toolbar button's container view
    /// 边缘的边距信息
    private var edgeLayout: AttributeViewLayout = AttributeViewLayout()
    private var scrollView: UIScrollView { return _getScrollView() }
    private var _storedScrollView: UIScrollView?

    private var _cachedItems: [String: TextAttributionBaseItem] = [:]

    /// init the attribution view
    ///
    /// - Parameters:
    ///   - status: ui info about each sub item
    ///   - layouts: layout info about each sub item
    ///   - frame: init frame
    public init(status: [BarButtonIdentifier: ToolBarItemInfo], layouts: [ToolBarLineType], frame: CGRect, edgeInfo: AttributeViewLayout? = nil) {
        self.layouts = layouts
        self.statusInfos = status
        if let info = edgeInfo { edgeLayout = info }
        super.init(frame: frame)
        layoutToolButton()
    }

    public func updateLayouts(layouts: [ToolBarLineType]) {
        self.layouts = layouts
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layoutToolButton()
    }

    override public func updateStatus(status: [BarButtonIdentifier: ToolBarItemInfo]) {
        statusInfos = status
        _cachedItems.forEach { _, item in
            item.updateStatus(status)
        }
    }

    private func layoutToolButton() {
        resetTopBottomPaddingIfNeed()
        _layoutScrollView()
        var lineIndex = 1
        for oneLineDict in layouts {
            let uid = "Cached(\(lineIndex))"
            if let typekey = TextAttributionLayoutType.allCases.first(where: { return oneLineDict.keys.contains($0.rawValue) })?.rawValue,
                let layoutdata = oneLineDict[typekey] {
                let item = dequeueItems(uid, typeid: typekey)

                let yOffset = topBottomPadding + CGFloat(lineIndex - 1) * (edgeLayout.buttonHeight + edgeLayout.linePadding)
                item.frame = CGRect(x: 0, y: yOffset, width: frame.size.width, height: edgeLayout.buttonHeight)
                item.paint(layoutdata)
                if item.superview == nil {
                    self.scrollView.addSubview(item)
                }
                item.updateStatus(statusInfos)
            }
            lineIndex += 1
        }
    }

    private func resetTopBottomPaddingIfNeed() {
        let maxHeight = edgeLayout.buttonHeight * CGFloat(layouts.count) + edgeLayout.topBottomPadding * 2
        let lineHeight = (CGFloat(layouts.count) - 1) * edgeLayout.linePadding
        let toolBarMaxHeight = maxHeight + lineHeight
        let viewMaxHeight = self.frame.size.height - (self.window?.safeAreaInsets.bottom ?? 0.0)

        if viewMaxHeight > toolBarMaxHeight {
            let space: CGFloat = (viewMaxHeight - toolBarMaxHeight) / 2.0
            topBottomPadding = edgeLayout.topBottomPadding + (shouldCenteredDisplay ? space : 0)
        } else {
            topBottomPadding = edgeLayout.topBottomPadding
        }
    }

    private func _getScrollView() -> UIScrollView {
        if let sv = _storedScrollView {
            return sv
        }
        let scrollView = UIScrollView(frame: self.bounds)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = UIColor.ud.bgBody
        addSubview(scrollView)
        _layoutScrollView()
        _storedScrollView = scrollView
        return scrollView
    }

    private func _layoutScrollView() {
        guard let scrollView = _storedScrollView else { return }     // Only layout if scrollView is constructed
        let maxHeight = scrollViewMaxYContent()
        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        scrollView.contentSize = CGSize(width: self.frame.width, height: maxHeight)
    }

    private func scrollViewMaxYContent() -> CGFloat {
        let maxHeight = edgeLayout.buttonHeight * CGFloat(layouts.count) + topBottomPadding * 2
        let lineHeight = (CGFloat(layouts.count) - 1) * edgeLayout.linePadding
        return maxHeight + lineHeight + (self.window?.safeAreaInsets.bottom ?? 0.0)
    }

    private func didClickAttributeButton(sender: AttributeButton) {
        self.delegate?.didClickTxtAttributionView(view: self, button: sender)

        if let identifier = sender.itemInfo?.identifier,
            let barId = BarButtonIdentifier(rawValue: identifier),
            let item = statusInfos[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }

    public func disableScroll() {
        self.scrollView.isScrollEnabled = false
    }

    private func dequeueItems(_ uid: String, typeid: String) -> TextAttributionBaseItem {
        if let storedItem = _cachedItems[uid] {
            return storedItem
        }
        var item: TextAttributionBaseItem
        switch typeid {
        case TextAttributionLayoutType.singleLine.rawValue:
            item = TextAttributionSectionalItem()
        case TextAttributionLayoutType.scrollableLine.rawValue:
            item = TextAttributeionScrollableItem()
        default:
            DocsLogger.error("TextAttributionView recived an unexpected type", extraInfo: ["typeid": typeid, "uid": uid])
            item = TextAttributionBaseItem()    // Unexpected item type
        }
        _cachedItems[uid] = item
        item.buttonClickCallback = { [weak self] btn in self?.didClickAttributeButton(sender: btn) }
        return item
    }
}

protocol AttributeButtonDelegate: AnyObject {
    func didClickAttributeButton(_ btn: AttributeButton)
}

public final class AttributeButton: UIButton {

    private enum DisplayMode {
        case normal
        case disabled
        case selected
    }

    //显示模式
    private var displayMode: DisplayMode = .normal
    private var modeBeforeTouch: DisplayMode = .normal
    weak var delegate: AttributeButtonDelegate?
    var quickTouchFireSelect: Bool = false //快速点击的时候是否要触发点击态
    let normalTint = UIColor.ud.iconN1
    var normalBg = UIColor.ud.bgBodyOverlay

    let selectTint = UIColor.ud.primaryContentDefault
    let selectBg = UIColor.ud.fillActive

    let disableTint = UIColor.ud.iconDisabled
    let disableBg = UIColor.ud.fillDisabled
    
    let normalFont = UIFont.systemFont(ofSize: 16)
    let selectFont = UIFont.systemFont(ofSize: 16, weight: .medium)

    /// all the info to display this button
    public var itemInfo: ToolBarItemInfo?

    /// imageView to display the icon
    var iconImageView: UIImageView

    private let hoverView: UIView

    private var hoverGesture: UIGestureRecognizer?

    private let disposeBag = DisposeBag()

    /// init button
    ///
    /// - Parameters:
    ///   - frame: desired frame
    ///   - info: display info
    init(frame: CGRect, info: ToolBarItemInfo?) {
        iconImageView = UIImageView()
        hoverView = UIView()
        super.init(frame: frame)
        addSubview(iconImageView)
        addSubview(hoverView)
        hoverView.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false
        iconImageView.snp.makeConstraints { (make) in
            make.width.equalTo(20)
            make.height.equalTo(20)
            make.center.equalToSuperview()
        }
        hoverView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        itemInfo = info
        loadStatus()
        addTarget(self, action: #selector(didReceiveTouchDown(sender:)), for: .touchDown)
        addTarget(self, action: #selector(didReceiveTouchUpInside(sender:)), for: .touchUpInside)
        addTarget(self, action: #selector(didReceiveTouchUpOutSide(sender:)), for: .touchUpOutside)
        addTarget(self, action: #selector(didReceiveTouchUpOutSide(sender:)), for: .touchCancel)
        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.hoverView.backgroundColor = UIColor.ud.fillHover
            case .ended, .cancelled:
                self.hoverView.backgroundColor = .clear
            default:
                break
            }
        }).disposed(by: disposeBag)
        hoverGesture = gesture
        addGestureRecognizer(gesture)
    }

    @objc
    func didReceiveTouchDown(sender: AttributeButton) {
        modeBeforeTouch = displayMode
        switchMode(.selected)
    }

    @objc
    func didReceiveTouchUpOutSide(sender: AttributeButton) {
        switchMode(modeBeforeTouch)
    }

    @objc
    func didReceiveTouchUpInside(sender: AttributeButton) {
        let delay = quickTouchFireSelect ? 0.05 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.switchMode(self.modeBeforeTouch)
            self.delegate?.didClickAttributeButton(self)
        }
    }

    /// display view from mode
    func loadStatus() {
        guard let info = itemInfo else {
            return
        }
        setTitle(info.title, for: .normal)
        setTitle(info.title, for: .highlighted)
        titleLabel?.font = UIFont.systemFont(ofSize: 16)
        if info.title == nil {
            iconImageView.image = info.image?.withRenderingMode(.alwaysTemplate)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        switchMode(.normal)
        if info.isSelected {
            switchMode(.selected)
        }
        if info.isEnable == false {
           switchMode(.disabled)
        }
        isUserInteractionEnabled = info.isEnable
        isAccessibilityElement = true
        accessibilityIdentifier = "sheets.toolkit.\(info.identifier)"
        accessibilityLabel = "sheets.toolkit.\(info.identifier)"
    }

    private func switchMode(_ mode: DisplayMode) {
        let nextTint: UIColor
        let nextBg: UIColor
        let nextFont: UIFont
        switch mode {
        case .normal:
            nextTint = normalTint
            nextBg = normalBg
            nextFont = normalFont
        case .selected:
            nextTint = selectTint
            nextBg = selectBg
            nextFont = selectFont
        case .disabled:
            nextTint = disableTint
            nextBg = disableBg
            nextFont = normalFont
        }
        displayMode = mode
        backgroundColor = nextBg
        iconImageView.tintColor = nextTint
        titleLabel?.font = nextFont
        setTitleColor(nextTint, for: .normal)
    }
}
