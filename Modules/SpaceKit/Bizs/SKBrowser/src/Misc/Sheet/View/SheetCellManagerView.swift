//
//  SheetCellManagerView.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/24.
//

import Foundation
import SKCommon
import SKUIKit
import SKResource

protocol SheetCellManagerViewDelegate: AnyObject {
    func sheetCellManagerViewDidShowImagePicker(view: SheetCellManagerView)
}

/// sheet cell manager class, like cell merge
class SheetCellManagerView: SKSubToolBarPanel {

    weak var delegate: SheetCellManagerViewDelegate?
    private let txtAttributionHeight: CGFloat = 180
    private let backgroundColorLineHeight: CGFloat = 52
    private var itemStatus: [BarButtonIdentifier: ToolBarItemInfo]
    var items: [BarButtonIdentifier: DocsBaseToolBarItem]?
    private var txtAttributionView: TextAttributionView
    private(set) var colorPickerView: ColorPickerPanel = {
        let view = ColorPickerPanel(frame: .zero, infos: [])
        view.isHidden = true
        return view
    }()

    let containerView: UIScrollView = {
       let view = UIScrollView(frame: .zero)
        view.backgroundColor = UIColor.ud.N00
       return view
    }()

    private let colorView: PickerAttributionPanel = {
        let title = BundleI18n.SKResource.Doc_Doc_ToolbarCellBgColor
        let panel = PickerAttributionPanel(frame: .zero, value: "#EFF0F1", title: title)
        return panel
    }()
    
    weak var currentBackcolorPanel: FontColorPickerView?

    init(status: [BarButtonIdentifier: ToolBarItemInfo], frame: CGRect) {
        // create attribution view
        let attributionFrame = CGRect(x: 0, y: 0, width: 0, height: txtAttributionHeight)
        let layout = ToolBarLayoutMapping.sheetCellManagerItems()
        txtAttributionView = TextAttributionView(status: status, layouts: layout, frame: attributionFrame)
        txtAttributionView.disableScroll()
        itemStatus = status
        super.init(frame: frame)
        self.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        txtAttributionView.delegate = self
        colorView.delegate = self
        colorPickerView.delegate = self
        containerView.addSubview(txtAttributionView)
        containerView.addSubview(colorView)

        var bottom = self.safeAreaInsets.bottom
        if bottom < 0.01,
           let window = self.window {
            bottom = window.safeAreaInsets.bottom
        }
        let enoughHeight = self.maxHeight() + bottom
        //let topOffset = frame.height > enoughHeight ? (frame.height - enoughHeight)/2.0 : 0
        txtAttributionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(txtAttributionHeight)
            make.top.equalToSuperview().offset(0)
            make.width.equalToSuperview()
        }

        colorView.snp.makeConstraints { (make) in
            make.top.equalTo(txtAttributionView.snp.bottom)
            make.left.equalToSuperview()
            make.height.equalTo(backgroundColorLineHeight)
            make.width.equalToSuperview()
        }

        containerView.contentSize = CGSize(width: 0, height: enoughHeight)

        //color picker panel
        self.addSubview(colorPickerView)
        colorPickerView.snp.makeConstraints { (make) in
            make.top.right.bottom.left.equalToSuperview()
        }

        updateColor(info: status[BarButtonIdentifier.backColor])

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func maxHeight() -> CGFloat {
        return txtAttributionHeight + backgroundColorLineHeight
    }

    private func updateColor(info: ToolBarItemInfo?) {
        guard let colorInfo = info else { return }
        let colorVal = (colorInfo.value ?? "#ffffff").lowercased()
        let colorItem = colorItemsHelper(colorVal)
        colorView.update(desc: colorItem.desc, color: colorItem.color)
        
        colorPickerView.updateInfos(info: colorInfo)
        currentBackcolorPanel?.updateColor(info: colorInfo)
    }

    @inline(__always)
    private func colorItemsHelper(_ color: String) -> ColorPaletteItem {
        let type = ColorPaletteItemType.analysis(desc: color)
        switch type {
        case .RGB:      return ColorRGBPaletteItem(by: color)
        case .clear:   return ColorClearPalentteItem()
        }
    }

    override func updateStatus(status: [BarButtonIdentifier: ToolBarItemInfo]) {
        itemStatus = status
        txtAttributionView.updateStatus(status: status)
        updateColor(info: status[BarButtonIdentifier.backColor])
    }

    func showColorPicker(show: Bool) {
        colorPickerView.isHidden = !show
        containerView.isHidden = show
    }

    override func showRootView() {
        colorPickerView.isHidden = true
        containerView.isHidden = false
    }
}

extension SheetCellManagerView: PickerAttributionPanelDelegate {
    func pickerAttributionWillWakeColorPickerUp(panel: PickerAttributionPanel) {
        updateColor(info: itemStatus[BarButtonIdentifier.backColor])
        containerView.isHidden = true
        colorPickerView.isHidden = false
        delegate?.sheetCellManagerViewDidShowImagePicker(view: self)
    }
}

extension SheetCellManagerView: ColorPickerPanelDelegate {
    func hasUpdate(color: ColorPaletteItem, in panel: ColorPickerPanel) {
        colorView.update(desc: color.desc, color: color.color)
        if let item = itemStatus[BarButtonIdentifier.backColor] {
             panelDelegate?.select(item: item, update: color.desc, view: self)
        }
    }
}

extension SheetCellManagerView: TextAttributionViewDelegate {
    func didClickTxtAttributionView(view: TextAttributionView, button: AttributeButton) {
        guard let sId = button.itemInfo?.identifier, let barId = BarButtonIdentifier(rawValue: sId) else {
            return
        }
        if let item = itemStatus[barId] {
            panelDelegate?.select(item: item, update: nil, view: self)
        }
    }
}
