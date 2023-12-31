//
//  TextAttributionView.swift
//  MailSDK
//
//

import UIKit
import UniverseDesignFont
import UniverseDesignButton
import UniverseDesignIcon

/// delegate
protocol TextAttributionViewDelegate: AnyObject {

    /// report the delegate when the attributon button is pressed
    ///
    /// - Parameters:
    ///   - view: current attribution view
    ///   - button: attribution button which fires this event
    func didClickTxtAttributionView(view: MailTextAttributionView, button: AttributeButton)
    func didClickFontButton()
    func didClickCloseTxtAttrPanelButton()
}

enum TextAttributionLayoutType: String, CaseIterable {
    case singleLine = "SingleLineKey"
    case scrollableLine = "ScrollableLineKey"
}

struct AttributeViewLayout {
    var topBottomPadding: CGFloat = 12 // 整体工具栏跟屏幕边框的默认上下间距
    var leftRightPadding: CGFloat = 16  // 整体工具栏
    var linePadding: CGFloat = 12      // 工具栏行间距
    var innerButtonPadding: CGFloat = 2      // 工具栏同组按钮的间距
    var outButtonPadding: CGFloat = 10       // 工具栏同行、不同组之间的间距
    var buttonHeight: CGFloat = 60            // 工具栏按钮高度
    var containerRadius: CGFloat = 8         // 工具栏组的外边框半径
    var naviHeight: CGFloat = 48         // 面板导航栏高度
}

class MailTextAttributionView: EditorSubToolBarPanel {
    /// should show panel centered display, default is true
    var shouldCenteredDisplay = true
    /// delegate
    weak var delegate: TextAttributionViewDelegate?
    /// layouts about how to put button
    private var layouts: [ToolBarLineType]
    /// the base UI info about how to display all the attributon sub button
    private var statusInfos: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]
    /// toolbar's top、bottom padding to superView, must be dynamic cacluated
    private var topBottomPadding: CGFloat = 20
    /// toolbar button's container view
    /// 边缘的边距信息
    private var edgeLayout: AttributeViewLayout = AttributeViewLayout()
    private var scrollView: UIScrollView { return _getScrollView() }
    private var _storedScrollView: UIScrollView?

    private var _cachedItems: [String: TextAttributionBaseItem] = [:]
    let fontStatusPanel = FontStatusPanel()
    var textNavigationBar = UIView()
    private var closeButton = UIButton()
    private var textNavigationTitleLabel = UILabel()
    private let shadowView = UIView()

    /// init the attribution view
    ///
    /// - Parameters:
    ///   - status: ui info about each sub item
    ///   - layouts: layout info about each sub item
    ///   - frame: init frame
    init(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo], layouts: [ToolBarLineType], frame: CGRect, edgeInfo: AttributeViewLayout? = nil) {
        self.layouts = layouts
        self.statusInfos = status
        if let info = edgeInfo { edgeLayout = info }
        super.init(frame: frame)
        layoutToolButton()
        fontStatusPanel.addTarget(self, action: #selector(didClickFontPanelButton), for: .touchUpInside)
        backgroundColor = UIColor.ud.bgBody
//        setupTextNaviBar()
//        UIApplication.shared.keyWindow?.isUserInteractionEnabled = true
    }

    @objc
    func didClickFontPanelButton() {
        delegate?.didClickFontButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutToolButton()
    }

    override func updateStatus(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        statusInfos = status
        _cachedItems.forEach { _, item in
            item.updateStatus(status)
        }
        fontStatusPanel.updateFont(status: status)
    }

    private func layoutToolButton() {
        resetTopBottomPaddingIfNeed()
        var layoutBottomY: CGFloat = 0
        for (idx, oneLineDict) in layouts.enumerated() {
            let lineIndex = idx + 1
            let uid = "Cached(\(lineIndex))"
            if let typekey = TextAttributionLayoutType.allCases.first(where: { return oneLineDict.keys.contains($0.rawValue) })?.rawValue,
                let layoutdata = oneLineDict[typekey] {
                let item = dequeueItems(uid, typeid: typekey)

                let yOffset = 12 + CGFloat(lineIndex - 1) * (edgeLayout.buttonHeight + edgeLayout.linePadding)
                item.frame = CGRect(x: 0, y: yOffset, width: UIScreen.main.bounds.size.width, height: edgeLayout.buttonHeight)
                item.paint(layoutdata)
                if item.superview == nil {
                    self.scrollView.addSubview(item)
                }
                item.updateStatus(statusInfos)
                layoutBottomY = item.frame.maxY
            }
        }
        let fontStatusY = layoutBottomY + 12
        fontStatusPanel.frame = CGRect(x: 16, y: fontStatusY, width: frame.width - 32, height: 48)
        _storedScrollView?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        _storedScrollView?.contentSize = CGSize(width: frame.width, //height: 336 + Display.bottomSafeAreaHeight)
                                                height: fontStatusPanel.frame.maxY + topBottomPadding +
                                                    edgeLayout.naviHeight + Display.bottomSafeAreaHeight)
        _storedScrollView?.backgroundColor = UIColor.ud.bgBody

        layoutTextNaviBar()
    }

    func layoutTextNaviBar() {
        textNavigationBar.frame = CGRect(x: 0, y: frame.height - scrollView.frame.height - Display.bottomSafeAreaHeight - 14,
                                         width: frame.width, height: edgeLayout.naviHeight)
        shadowView.frame = CGRect(x: 0, y: textNavigationBar.frame.origin.y - 5, width: frame.width, height: 5)
        closeButton.frame = CGRect(x: 16, y: (edgeLayout.naviHeight - 24) / 2.0, width: 24, height: 24)
        textNavigationTitleLabel.frame = CGRect(x: 52, y: (edgeLayout.naviHeight - 24) / 2.0, width: frame.width - 104, height: 24)
    }

    @objc
    func closeAttrPanel() {
        delegate?.didClickCloseTxtAttrPanelButton()
    }

    private func resetTopBottomPaddingIfNeed() {
        let maxHeight = edgeLayout.buttonHeight * CGFloat(layouts.count) + edgeLayout.topBottomPadding * 2
        let lineHeight = (CGFloat(layouts.count) - 1) * edgeLayout.linePadding
        let toolBarMaxHeight = maxHeight + lineHeight
        let viewMaxHeight = self.frame.size.height - Display.bottomSafeAreaHeight

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
        scrollView.addSubview(fontStatusPanel)

        _storedScrollView = scrollView
        return scrollView
    }

    private func didClickAttributeButton(sender: AttributeButton) {
        self.delegate?.didClickTxtAttributionView(view: self, button: sender)

        if let identifier = sender.itemInfo?.identifier,
            let barId = EditorToolBarButtonIdentifier(rawValue: identifier),
            let item = statusInfos[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }

    private func dequeueItems(_ uid: String, typeid: String) -> TextAttributionBaseItem {
        if let storedItem = _cachedItems[uid] {
            return storedItem
        }
        var item: TextAttributionBaseItem
        switch typeid {
        case TextAttributionLayoutType.singleLine.rawValue:
            item = TextAttributeionSectionalItem()
        case TextAttributionLayoutType.scrollableLine.rawValue:
            item = TextAttributeionScrollableItem()
        default:
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

class AttributeButton: UIButton {

    private enum DsplayModel {
        case normal
        case disable
        case selected
    }

    // 显示模式
    private var displayModel: DsplayModel = .normal
    private var touchBeforeMode: DsplayModel = .normal
    let label = UILabel()
    weak var delegate: AttributeButtonDelegate?
    var quickTouchFireSelect: Bool = false // 快速点击的时候是否要触发点击态
    let normalTint = UIColor.ud.iconN1
    let normalBg = UIColor.ud.bgBodyOverlay

    let selectTint = UIColor.ud.primaryContentPressed //textTitle
    let selectBg = UIColor.ud.primaryFillSolid02 // bgFiller

    let disableTint = UIColor.ud.textDisable
    let disableBg = UIColor.ud.bgBodyOverlay

    /// all the info to display this button
    var itemInfo: EditorToolBarItemInfo?

    /// imageView to display the icon
    var iconImageView: UIImageView

    /// init button
    ///
    /// - Parameters:
    ///   - frame: desired frame
    ///   - info: display info
    init(frame: CGRect, info: EditorToolBarItemInfo?) {
        iconImageView = UIImageView()
        super.init(frame: frame)
        self.addSubview(iconImageView)
        iconImageView.isUserInteractionEnabled = false
        iconImageView.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.center.equalToSuperview()
        }
        addSubview(label)
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .black
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        loadStatus()
        addTarget(self, action: #selector(didReceiveTouchDown(sender:)), for: .touchDown)

        addTarget(self, action: #selector(didReceiveTouchUpInside(sender:)), for: .touchUpInside)
        addTarget(self, action: #selector(didReceiveTouchUpOutSide(sender:)), for: .touchUpOutside)
        addTarget(self, action: #selector(didReceiveTouchUpOutSide(sender:)), for: .touchCancel)
    }

    /// default init
    ///
    /// - Parameter aDecoder: decoder
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didReceiveTouchDown(sender: AttributeButton) {
        touchBeforeMode = displayModel
        jumpModel(.selected)
    }

    @objc
    func didReceiveTouchUpOutSide(sender: AttributeButton) {
        self.jumpModel(self.touchBeforeMode)
    }

    @objc
    func didReceiveTouchUpInside(sender: AttributeButton) {
        let delay = quickTouchFireSelect ? 0.05 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.jumpModel(self.touchBeforeMode)
            self.delegate?.didClickAttributeButton(self)
        }
    }

    /// display view from model
    func loadStatus() {
        guard let info = itemInfo, let id = EditorToolBarButtonIdentifier(rawValue: info.identifier) else {
            return
        }
        let fontsConfig: [EditorToolBarButtonIdentifier] = [.fontHuge, .fontLarge, .fontNormal, .fontSmall]
        if fontsConfig.contains(id) {
            label.isHidden = false
            iconImageView.isHidden = true
            label.text = info.identifier
            let font = EditorToolBarButtonIdentifier(rawValue: info.identifier)
            switch font {
            case .fontHuge:
                label.text = BundleI18n.MailSDK.Mail_Toolbar_FontSizeHuge
                label.font = UIFont.systemFont(ofSize: CGFloat(EditorFontSize.fontHuge))
            case .fontLarge:
                label.text = BundleI18n.MailSDK.Mail_Toolbar_FontSizeLarge
                label.font = UIFont.systemFont(ofSize: CGFloat(EditorFontSize.fontLarge))
            case .fontNormal:
                label.text = BundleI18n.MailSDK.Mail_Toolbar_FontSizeNormal
                label.font = UIFont.systemFont(ofSize: CGFloat(EditorFontSize.fontNormal))
            case .fontSmall:
                label.text = BundleI18n.MailSDK.Mail_Toolbar_FontSizeSmall
                label.font = UIFont.systemFont(ofSize: CGFloat(EditorFontSize.fontSmall))
            default:
                label.text = "unknow"
            }
        } else {
            label.isHidden = true
            iconImageView.isHidden = false
        }
        label.textColor = UIColor.ud.textCaption
        iconImageView.image = info.image?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = UIColor.ud.iconN1
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.setTitle(info.title, for: .normal)
        self.setTitle(info.title, for: .highlighted)
        jumpModel(.normal)
        if info.isSelected {
            jumpModel(.selected)
        }
        if info.isEnable == false {
           jumpModel(.disable)
        }
        self.isUserInteractionEnabled = info.isEnable
    }

    private func jumpModel(_ model: DsplayModel) {
        var nextTint = UIColor.ud.textCaption
        var nextBg = UIColor.ud.bgBodyOverlay
        switch model {
        case .normal:
            nextTint = normalTint
            nextBg = normalBg
        case .selected:
            nextTint = selectTint
            nextBg = selectBg
        case .disable:
            nextTint = disableTint
            nextBg = disableBg
        }
        displayModel = model
        iconImageView.tintColor = nextTint
//        self.setTitleColor(nextTint, for: .normal)
        self.backgroundColor = nextBg
    }
}

class FontStatusCell: UITableViewCell {
    lazy var tickImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.image(named: "tb_font_selected"))
        imageView.isHidden = true
        return imageView
    }()

    override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(tickImageView)
        contentView.lu.addBottomBorder(leading: 16, color: UIColor.ud.lineDividerDefault)
        contentView.backgroundColor = UIColor.ud.bgBody
        textLabel?.textColor = UIColor.ud.textTitle
        textLabel?.font = UIFont.systemFont(ofSize: 16.0)
        tickImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.right.equalTo(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
