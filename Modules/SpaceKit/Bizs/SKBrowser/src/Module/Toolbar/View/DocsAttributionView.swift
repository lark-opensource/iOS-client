//
//  DocsAttributionView.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/4/1.
//

import UIKit
import SnapKit
import SwiftyJSON
import SKCommon
import SKResource
import SKFoundation
import SKUIKit
import EENavigator
import UniverseDesignColor

protocol DocsAttributionViewDelegate: AnyObject {
    @discardableResult
    func docsAttributionViewDidShowColorPicker(view: DocsAttributionView) -> ColorPickerNavigationView
    func docsAttributionView(change des: String, from panel: Bool)
    func docsAttributionView(getLarkFG key: String) -> Bool
}

private typealias Const = DocsAttributionViewConst
private struct DocsAttributionViewConst {
    static let attributionHeight: CGFloat = 324
    static let separateLineHeight: CGFloat = 1
    static let colorPickerHeight: CGFloat = 70
    static let separateLineHorPadding: CGFloat = 8
    static let separateLineVerPadding: CGFloat = 6
    static let attributeBottomMinusHeight: CGFloat = 18
}

class DocsAttributionView: SKSubToolBarPanel {
    weak var delegate: DocsAttributionViewDelegate? {
        didSet {
            _updateDelegate()
        }
    }
    // MARK: Data
    private var itemStatus: [BarButtonIdentifier: ToolBarItemInfo]
    // MARK: UI Widget
    private var realPanel: UIView {
        return colorPickerPanelV2
    }
    private(set) var pickerNavigationView: ColorPickerNavigationView?
    private(set) var colorPickerPanelV2: ColorPickerPanelV2
    private var containerView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.showsVerticalScrollIndicator = false
        return view
    }()
    private let attributionView: TextAttributionView
    private let topSeparateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()
    let colorView: PickerAttributionPanel = {
        let panel = PickerAttributionPanel(frame: .zero, value: "#EFF0F1")
        return panel
    }()
    private let bottomSeparateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    init(status: [BarButtonIdentifier: ToolBarItemInfo], frame: CGRect) {
        let attributionFrame = CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.width, height: Const.attributionHeight)
        let layout = ToolBarLayoutMapping.docsAttributeItems(status)
        attributionView = TextAttributionView(status: status, layouts: layout, frame: attributionFrame)
        colorPickerPanelV2 = ColorPickerPanelV2(frame: CGRect(origin: .zero, size: frame.size), data: [])
        itemStatus = status
        super.init(frame: frame)
        setupView()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateStatus(status: [BarButtonIdentifier: ToolBarItemInfo]) {
        itemStatus = status
        let layout = ToolBarLayoutMapping.docsAttributeItems(status)
        attributionView.updateLayouts(layouts: layout)
        attributionView.updateStatus(status: status)
        updateHighlightColor(info: status[BarButtonIdentifier.highlight])
    }

    override func showRootView() {
//        realPanel.isHidden = true
//        containerView.isHidden = false
        panelDelegate?.requestShowKeyboard()
    }

    private func _updateDelegate() {
        let title = BundleI18n.SKResource.Doc_Doc_ColorSelectTitle
        pickerNavigationView?.titleLabel.text = title
        colorView.title = title
        colorPickerPanelV2.removeFromSuperview()
        updateHighlightColor(info: itemStatus[BarButtonIdentifier.highlight])
        addSubview(realPanel)
        realPanel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func showColorPicker(toShow: Bool) {
        realPanel.isHidden = !toShow
        containerView.isHidden = toShow
    }

    func showColorPickerPanelV2(toShow: Bool) {
        if toShow {
            realPanel.isHidden = !toShow
            containerView.isHidden = toShow
        } else if !realPanel.isHidden {
            NotificationCenter.default.post(name: Notification.Name.NavigationShowHighlightPanel, object: nil)
            showRootView()
        }
    }

    func updateColorPickerPanelV2(_ models: [ColorPaletteModel]) {
        colorPickerPanelV2.update(models)
    }

    private func updateHighlightColor(info: ToolBarItemInfo?) {
        _updateHighlightColorV2(info)
    }

    private func _updateHighlightColorV2(_ info: ToolBarItemInfo?) {
        guard let value = info?.valueJSON else { return }
        colorView.updateHighlightPanel(info: value)
    }

//    @inline(__always)
//    private func colorItemsHelper(_ color: String) -> ColorPaletteItem {
//        let type = ColorPaletteItemType.analysis(desc: color)
//        switch type {
//        case .RGB:      return ColorRGBPaletteItem(by: color)
//        case .clear:   return ColorClearPalentteItem()
//        }
//    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.contentSize = CGSize(width: frame.width,
                                           height: preferedHeight())
    }
    
    override var canEqualToKeyboardHeight: Bool {
        return realPanel.isHidden
    }
    
    override var panelHeight: CGFloat? {
        if !realPanel.isHidden {
            return 340 + (Navigator.shared.mainSceneWindow?.safeAreaInsets.bottom ?? 0)
        }
        return nil
    }
}

extension DocsAttributionView: TextAttributionViewDelegate {
    func didClickTxtAttributionView(view: TextAttributionView, button: AttributeButton) {
        guard let sId = button.itemInfo?.identifier, let barId = BarButtonIdentifier(rawValue: sId) else {
            return
        }
        if let item = itemStatus[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }
}

extension DocsAttributionView: PickerAttributionPanelDelegate {
    func pickerAttributionWillWakeColorPickerUp(panel: PickerAttributionPanel) {
        if let item = itemStatus[BarButtonIdentifier.highlight] {
            panelDelegate?.select(item: item, update: item.jsonString, view: self)
        }
        delegate?.docsAttributionView(change: panel.desc, from: false)
        updateHighlightColor(info: itemStatus[BarButtonIdentifier.highlight])
//        realPanel.isHidden = false
//        containerView.isHidden = true
        pickerNavigationView = delegate?.docsAttributionViewDidShowColorPicker(view: self)
        let title = BundleI18n.SKResource.Doc_Doc_ColorSelectTitle
        pickerNavigationView?.titleLabel.text = title
    }

    func pickerAttributionWillWakeColorPickerUpV2() {
        if let item = itemStatus[BarButtonIdentifier.highlight] {
            panelDelegate?.select(item: item, update: item.jsonString, view: self)
        }
        delegate?.docsAttributionView(change: "", from: false)
        updateHighlightColor(info: itemStatus[BarButtonIdentifier.highlight])
//        realPanel.isHidden = false
//        containerView.isHidden = true
        pickerNavigationView = delegate?.docsAttributionViewDidShowColorPicker(view: self)
        let title = BundleI18n.SKResource.Doc_Doc_ColorSelectTitle
        pickerNavigationView?.titleLabel.text = title
    }

    func setColorPickerUpV2() {
        if let item = itemStatus[BarButtonIdentifier.highlight] {
            panelDelegate?.select(item: item, update: item.jsonString, view: self)
            _updateHighlightColorV2(item)
        }
    }
}

extension DocsAttributionView {
    private func setupView() {
        addSubview(containerView)

        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

//        containerView.addSubview(attributionView)
        containerView.addSubview(topSeparateLine)
        containerView.addSubview(colorView)
//        attributionView.snp.makeConstraints { (make) in
//            make.leading.equalToSuperview()
//            make.height.equalTo(Const.attributionHeight)
//            make.top.equalToSuperview()
//            make.width.equalToSuperview()
//        }
//        topSeparateLine.snp.makeConstraints { (make) in
//            make.leading.equalToSuperview().inset(Const.separateLineHorPadding)
//            make.top.equalTo(attributionView.snp.bottom)
//            make.height.equalTo(Const.separateLineHeight)
//            make.width.equalToSuperview().offset(-Const.separateLineHorPadding * 2)
//        }
        colorView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.top.equalTo(topSeparateLine.snp.bottom)
            make.height.equalTo(Const.colorPickerHeight)
            make.width.equalToSuperview()
        }
        containerView.backgroundColor = UIColor.ud.bgBody
        updateHighlightColor(info: itemStatus[BarButtonIdentifier.highlight])
    }

    private func configure() {
//        attributionView.disableScroll()
        colorPickerPanelV2.isHidden = true
//        attributionView.delegate = self
        colorView.delegate = self
    }

    private func preferedHeight() -> CGFloat {
        let pickerTotalHeight = Const.colorPickerHeight + Const.separateLineHeight * 2 + Const.separateLineVerPadding
        return Const.attributionHeight + pickerTotalHeight
    }
}
