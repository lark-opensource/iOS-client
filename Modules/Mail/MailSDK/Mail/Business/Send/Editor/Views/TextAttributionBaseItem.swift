//
//  TextAttributionBaseItem.swift
//  MailSDK
//
//

import UIKit
import UniverseDesignIcon

private typealias layoutConst = TextAttributionBaseItem.LayoutConst
class TextAttributionBaseItem: UIView {
    class LayoutConst {
        static let horizMargin: CGFloat = 16
        static let itemPadding: CGFloat = 2
        static let buttonHeight: CGFloat = 60
        static let containerRadius: CGFloat = 12
    }

    var buttonClickCallback: ((AttributeButton) -> Void)?

    fileprivate var _cachedButton: [EditorToolBarButtonIdentifier: AttributeButton] = [:]
    fileprivate var _itemInfos: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo] = [:]

    func paint(_ layoutData: [[EditorToolBarButtonIdentifier]]) { }

    func updateStatus(_ status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        status.forEach { key, val in
            if let button = _cachedButton[key] {
                button.itemInfo = val
                button.loadStatus()
                updateQuickTouchHintSelect(btn: button)
            }
            if _itemInfos[key] != nil {
                _itemInfos[key] = val
            }
        }
    }
}

extension TextAttributionBaseItem: AttributeButtonDelegate {
    fileprivate func dequeueButton(identifier: EditorToolBarButtonIdentifier) -> AttributeButton {
        var button: AttributeButton
        if let btn = _cachedButton[identifier] {
            button = btn
            button.delegate = self
        } else {
            button = AttributeButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0), info: nil)
            button.delegate = self
        }
        if let info = _itemInfos[identifier] {
            button.itemInfo = info
            button.loadStatus()
        }
        if button.iconImageView.image == nil { button.iconImageView.image = EditorToolBarItemInfo.loadImage(by: identifier.rawValue) }
        button.iconImageView.tintColor = UIColor.ud.iconN1
        _cachedButton.updateValue(button, forKey: identifier)
        return button
    }

    func didClickAttributeButton(_ btn: AttributeButton) {
         buttonClickCallback?(btn)
    }

    func updateQuickTouchHintSelect(btn: AttributeButton) {
        guard let info = btn.itemInfo else { return }
        let quickFireIdentifiers: Set<String> = [EditorToolBarButtonIdentifier.copy.rawValue,
                                                 EditorToolBarButtonIdentifier.paste.rawValue,
                                                 EditorToolBarButtonIdentifier.cut.rawValue,
                                                 EditorToolBarButtonIdentifier.clear.rawValue]

        btn.quickTouchFireSelect = quickFireIdentifiers.contains(info.identifier)
    }

}

class TextAttributeionScrollableItem: TextAttributionBaseItem {
    fileprivate var _cachedScrollView: [String: UIScrollView] = [:]
    var contentClipsToMargin: Bool = false
    var fontSizePanel: FontSizePanelView?

    override func paint(_ layoutdata: [[EditorToolBarButtonIdentifier]]) {
        guard let data = layoutdata.first else { return }
        let widthPadding: CGFloat = 32 //两侧各16
        if let fontSizePanel = fontSizePanel {
            fontSizePanel.removeFromSuperview()
        }
        let fontSizePanel = FontSizePanelView(frame: CGRect(x: 16, y: 0, width: Display.width - widthPadding, height: 60), data: data)
        self.fontSizePanel = fontSizePanel
        fontSizePanel.delegate = self
        if fontSizePanel.superview == nil {
            addSubview(fontSizePanel)
        }
    }

    override func updateStatus(_ status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        super.updateStatus(status)
        fontSizePanel?.updateStatus(status)
    }
}

extension layoutConst {
    static let maxUnscrollableCount: CGFloat = 4
}

class TextAttributeionSectionalItem: TextAttributionBaseItem {
    fileprivate var _cachedContainer: [String: UIView] = [:]

    override func paint(_ layoutdata: [[EditorToolBarButtonIdentifier]]) {
        var secXOffset = layoutConst.horizMargin, secWidth: CGFloat, itemCnt: CGFloat
        let itemHeight = frame.size.height, itemWidth = _itemWidth(layoutdata)
        var secCon: UIView

        for (secIdx, items) in layoutdata.enumerated() {
            itemCnt = CGFloat(items.count)
            secWidth = itemWidth * itemCnt + layoutConst.itemPadding * (itemCnt - 1)
            secCon = _dequeueContainer("Cached(\(secIdx))")
            if secCon.superview == nil { addSubview(secCon) }
            secCon.frame = CGRect(x: secXOffset, y: 0, width: secWidth, height: frame.size.height)

            var innerXOffset: CGFloat = 0
            for item in items {
                let button = dequeueButton(identifier: item)
                button.frame = CGRect(x: innerXOffset, y: 0, width: itemWidth, height: itemHeight)
                if button.superview == nil { secCon.addSubview(button) }
                innerXOffset += itemWidth + layoutConst.itemPadding
            }
            secXOffset += itemWidth * itemCnt + layoutConst.itemPadding * (itemCnt - 1) + layoutConst.sectionPadding - layoutConst.itemPadding
        }
    }

    private func _itemWidth(_ layoutdata: [[EditorToolBarButtonIdentifier]]) -> CGFloat {
        let w = frame.size.width
        var sectionCnt = CGFloat(layoutdata.count), itemCnt: CGFloat = 0
        layoutdata.forEach { itemCnt += CGFloat($0.count) }

        let emptyWidth = w
            - layoutConst.horizMargin * 2
            - layoutConst.itemPadding * (itemCnt - sectionCnt)
            - layoutConst.sectionPadding * (sectionCnt - 1)
        return emptyWidth / itemCnt
    }

    private func _dequeueContainer(_ uid: String) -> UIView {
        if let scontainer = _cachedContainer[uid] {
            return scontainer
        }
        let con = UIView()
        con.layer.cornerRadius = layoutConst.containerRadius
        con.clipsToBounds = true
//        con.backgroundColor = UIColor.ud.bgBodyOverlay
        _cachedContainer[uid] = con
        return con
    }
}

extension layoutConst {
    static let sectionPadding: CGFloat = 10
}

class FontStatusPanel: UIButton {
//    override var isHighlighted: Bool {
//        didSet {
//            if self.isHighlighted {
//                backgroundColor = UIColor.ud.lineBorderCard
//            } else {
//                backgroundColor = UIColor.ud.bgBody
//            }
//        }
//    }

    func getDefaultFontString() -> String {
        let system = EditorToolBarButtonIdentifier.fontDisplayName(str: EditorToolBarButtonIdentifier.System.rawValue)
        let sansSerif = EditorToolBarButtonIdentifier.fontDisplayName(str: EditorToolBarButtonIdentifier.SansSerif.rawValue)
        return FeatureManager.open(.moreFonts) ? system : sansSerif
    }

    let fontLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBodyOverlay
        layer.cornerRadius = 10
        layer.masksToBounds = true

        let label = UILabel()
        label.text = BundleI18n.MailSDK.Mail_Compose_FontPanel
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(20)
        }

        let arrowImg = UIImageView(image: UDIcon.hideToolbarOutlined.withRenderingMode(.alwaysTemplate))
        arrowImg.tintColor = UIColor.ud.iconN3
        addSubview(arrowImg)
        arrowImg.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
            make.right.equalTo(-18)
        }
        fontLabel.font = UIFont.systemFont(ofSize: 16)
        fontLabel.textAlignment = .left
        fontLabel.textColor = UIColor.ud.textCaption
        fontLabel.text = self.getDefaultFontString()
        addSubview(fontLabel)
        fontLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(label.snp.right).offset(10)
            make.right.equalTo(arrowImg.snp.left).offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
// swiftlint:disable init_font_with_name
    func updateFont(status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        var selectedFont: String = FeatureManager.open(.moreFonts) ? EditorToolBarButtonIdentifier.System.rawValue :
            EditorToolBarButtonIdentifier.SansSerif.rawValue
        if let temFont = status.first(where: { (key, value) -> Bool in
            guard mailFontIdentifiers.contains(key), value.isSelected else { return false }
            return true
        }) {
            selectedFont = temFont.value.identifier
        }
        fontLabel.text = EditorToolBarButtonIdentifier.fontDisplayName(str: selectedFont)
        fontLabel.font = UIFont(name: selectedFont, size: 16)
        if fontLabel.font.pointSize != 16 {
            fontLabel.font = UIFont.systemFont(ofSize: 16)
        }
    }
// swiftlint:enable init_font_with_name
}

class FontPanelNavigationView: UIView {

    let backButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setImage(UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = UIColor.ud.iconN1
        return btn
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.text = BundleI18n.MailSDK.Mail_Compose_FontPanel
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(backButton)
        addSubview(titleLabel)
        backButton.snp.makeConstraints { (make) in
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(backButton.snp.right).offset(7)
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
