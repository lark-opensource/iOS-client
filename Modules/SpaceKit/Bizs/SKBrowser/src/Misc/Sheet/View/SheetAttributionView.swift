//
//  SheetAttributionView.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/23.
//

import Foundation
import SKCommon
import SKResource
import SKUIKit

protocol SheetAttributionViewDelegate: AnyObject {
    func sheetAttributionViewDidShowImagePicker(view: SheetAttributionView)
}

class SheetAttributionView: SKSubToolBarPanel {

    weak var delegate: SheetAttributionViewDelegate?
    var colorPickerPanel: ColorPickerPanel
    private var txtAttributionView: TextAttributionView
    private var fontColorArrays: [String] = [String]()
    private var itemStatus: [BarButtonIdentifier: ToolBarItemInfo]
    private var containerView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.showsVerticalScrollIndicator = false
        return view
    }()

    private lazy var fontDataProvider: AdjustAttributionPanelDataProvider = {
        let provider = AdjustAttributionPanelDataProvider()
        return provider
    }()

    private let fontView: AdjustAttributionPanel = {
       let titleTxt = BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtSize
       let panel = AdjustAttributionPanel(frame: .zero, value: "0", title: titleTxt)
       return panel
    }()

    private let colorView: PickerAttributionPanel = {
        let titleTxt = BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtColor
        let panel = PickerAttributionPanel(frame: .zero, value: "#EFF0F1", title: titleTxt)
        return panel
    }()

    private let lineView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    ///layout etc
    private let txtAttributionHeight: CGFloat = 256
    private let fontSizeLineHeight: CGFloat = 70
    private let foreColorLineHeight: CGFloat = 70
    private let spearateLineHeight: CGFloat = 1
    private let specialPadding: CGFloat = -18

    init(status: [BarButtonIdentifier: ToolBarItemInfo], frame: CGRect) {

        // create attribution view
        let attributionFrame = CGRect(x: 0, y: 0, width: 0, height: txtAttributionHeight)
        let layout = ToolBarLayoutMapping.sheetAttributeItems()
        txtAttributionView = TextAttributionView(status: status, layouts: layout, frame: attributionFrame)
        txtAttributionView.disableScroll()

        let colorFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        colorPickerPanel = ColorPickerPanel(frame: colorFrame, infos: [])
        colorPickerPanel.isHidden = true
        itemStatus = status
        super.init(frame: frame)
        self.addSubview(containerView)
        self.addSubview(colorPickerPanel)
        containerView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        colorPickerPanel.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        txtAttributionView.delegate = self
        fontView.delegate = fontDataProvider
        fontDataProvider.delegate = self
        colorView.delegate = self
        colorPickerPanel.delegate = self
        containerView.addSubview(txtAttributionView)
        containerView.addSubview(fontView)
        containerView.addSubview(colorView)
        containerView.addSubview(lineView)

        txtAttributionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(txtAttributionHeight)
            make.top.equalToSuperview().offset(0)
            make.width.equalToSuperview()
        }

        fontView.snp.makeConstraints { (make) in
            make.top.equalTo(txtAttributionView.snp.bottom).offset(specialPadding)
            make.left.equalToSuperview()
            make.height.equalTo(fontSizeLineHeight)
            make.width.equalToSuperview()
        }

        lineView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(8)
            make.width.equalToSuperview().inset(8)
            make.height.equalTo(spearateLineHeight)
            make.top.equalTo(fontView.snp.bottom)
        }

        colorView.snp.makeConstraints { (make) in
            make.top.equalTo(lineView.snp.bottom)
            make.left.equalToSuperview()
            make.height.equalTo(foreColorLineHeight)
            make.width.equalToSuperview()
        }

        containerView.contentSize = CGSize(width: 0, height: maxHeight())
        containerView.backgroundColor = UIColor.ud.N00

        updateFontSize(info: status[BarButtonIdentifier.fontSize])
        updateFontColor(info: status[BarButtonIdentifier.foreColor])
    }

    ///当前面板如果要完全展示所需要的高度
    ///
    /// - Returns: 最大高度
    private func maxHeight() -> CGFloat {
        return txtAttributionHeight + fontSizeLineHeight + foreColorLineHeight + spearateLineHeight + specialPadding
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateStatus(status: [BarButtonIdentifier: ToolBarItemInfo]) {
        itemStatus = status
        txtAttributionView.updateStatus(status: status)
        updateFontSize(info: status[BarButtonIdentifier.fontSize])
        updateFontColor(info: status[BarButtonIdentifier.foreColor])
    }

    private func updateFontSize(info: ToolBarItemInfo?) {
        guard let fontInfo = info else { return }
        if let value = fontInfo.value {
            fontView.updateValue(value: value)
        }
        if let list = fontInfo.valueList {
            fontDataProvider.fontArrays = list
        }
        fontView.updateButtonStatus()
    }

    private func updateFontColor(info: ToolBarItemInfo?) {
        guard let colorInfo = info else { return }
        let colorVal = (colorInfo.value ?? "#000000").lowercased()
        let currInfo = colorItemsHelper(colorVal)
        colorView.update(desc: currInfo.desc, color: currInfo.color)

        if colorInfo.colorList != nil {
            colorPickerPanel.updateInfos(info: colorInfo)
        }
    }

    @inline(__always)
    private func colorItemsHelper(_ color: String) -> ColorPaletteItem {
        let type = ColorPaletteItemType.analysis(desc: color)
        switch type {
        case .RGB:      return ColorRGBPaletteItem(by: color)
        case .clear:   return ColorClearPalentteItem()
        }
    }

    func showColorPicker(show: Bool) {
        colorPickerPanel.isHidden = !show
        containerView.isHidden = show
    }

    override func showRootView() {
        colorPickerPanel.isHidden = true
        containerView.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.contentSize = CGSize(width: frame.width, height: maxHeight())
    }
}

extension SheetAttributionView: TextAttributionViewDelegate {
    func didClickTxtAttributionView(view: TextAttributionView, button: AttributeButton) {
        guard let sId = button.itemInfo?.identifier, let barId = BarButtonIdentifier(rawValue: sId) else {
            return
        }

        if let item = itemStatus[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }
}

extension SheetAttributionView: AdjustPanelDataProviderDelegate {
    func didModifyToNewValue(value: String, provider: AdjustAttributionPanelDataProvider) {
        if let item = itemStatus[BarButtonIdentifier.fontSize] {
            panelDelegate?.select(item: item, update: value, view: self)
        }
    }
}

extension SheetAttributionView: PickerAttributionPanelDelegate {
    func pickerAttributionWillWakeColorPickerUp(panel: PickerAttributionPanel) {
        updateFontColor(info: itemStatus[BarButtonIdentifier.foreColor])
        colorPickerPanel.isHidden = false
        containerView.isHidden = true
        delegate?.sheetAttributionViewDidShowImagePicker(view: self)
    }
}

extension SheetAttributionView: ColorPickerPanelDelegate {
    func hasUpdate(color: ColorItemNew, in panel: ColorPickerPanel) {
        
    }
    
    func hasUpdate(color: ColorPaletteItem, in panel: ColorPickerPanel) {
        colorView.update(desc: color.desc, color: color.color)
        if let item = itemStatus[BarButtonIdentifier.foreColor] {
            panelDelegate?.select(item: item, update: color.desc, view: self)
        }
    }
}
