//
//  SheetStyleToolkitViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/11/11.
//

import Foundation
import SKCommon
import SKBrowser
import SKResource
import SKFoundation
import UniverseDesignColor

protocol SheetStyleToolkitViewControllerDelegate: AnyObject {
    func didRequestChangeStyle(identifier: String, value: Any?, controller: SheetStyleToolkitViewController)
}

final class SheetStyleToolkitViewController: SheetToolkitFacadeViewController {
    
    weak var delegate: SheetStyleToolkitViewControllerDelegate?
    override var resourceIdentifier: String {
        return BadgedItemIdentifier.toolkitStyle.rawValue
    }
    private lazy var edgeInfoCellManager: AttributeViewLayout = {
        var info = AttributeViewLayout()
        info.topBottomPadding = 2
        info.linePadding = 10
        info.buttonHeight = 56
        return info
    }()
    
    private lazy var edgeInfo: AttributeViewLayout = {
        var info = AttributeViewLayout()
        info.topBottomPadding = 8
        info.linePadding = 10
        info.buttonHeight = 56
        return info
    }()
    
    private var fontColorArrays: [String] = [String]()
    private var fontColorIndex: Int = 0
    private var clearBadgeIdentifiers = [String]()
    private var bgColorArrays: [String] = [String]()
    private var bgColorIndex: Int = 0
    
    private var bgColorIndexPath: IndexPath = ColorPickerCorePanel.Const.defaultUnselectIndexPath
    private var bgColorInfo: ToolBarItemInfo = ToolBarItemInfo(identifier: "")
    private var fontColorIndexPath: IndexPath = ColorPickerCorePanel.Const.defaultUnselectIndexPath
    private var fontColorInfo: ToolBarItemInfo = ToolBarItemInfo(identifier: "")
    private var borderInfo: BorderInfo = BorderInfo()
    
    weak var borderOperationVC: SheetBorderOperationViewController?
    weak var fontColorVC: SheetColorPickerViewContoller?
    weak var bgColorVC: SheetColorPickerViewContoller?
    
    private lazy var biusPanel: FontStylePanel = {
        let panel = FontStylePanel()
        panel.delegate = self
        return panel
    }()
    
    private lazy var alignmentPanel: AlignmentPanel = {
        let panel = AlignmentPanel()
        panel.delegate = self
        return panel
    }()
    
    private lazy var truncationPanel: FontStylePanel = {
        let panel = FontStylePanel()
        panel.delegate = self
        return panel
    }()
    
    private lazy var borderView: PickerAttributionPanelBorder = {
        let panel = PickerAttributionPanelBorder(frame: .zero,
                                                 value: "#F1F2F3",
                                                 title: "",
                                                 showsBottomLine: true,
                                                 normalBgColor: UDColor.bgBodyOverlay,
                                                 highlightedBgColor: UDColor.fillPressed)
        panel.delegate = self
        panel.layer.cornerRadius = 12
        panel.layer.maskedCorners = .top
        panel.layer.masksToBounds = true
        panel.isAccessibilityElement = true
        panel.accessibilityIdentifier = "sheets.toolkit.backgroundColor"
        panel.accessibilityLabel = "sheets.toolkit.backgroundColor"
        return panel
    }()
    
    private lazy var fontColorView: PickerAttributionPanel = {
        let panel = PickerAttributionPanel(frame: .zero,
                                           value: "#F1F2F3",
                                           title: BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtColor,
                                           showsBottomLine: true,
                                           normalBgColor: UDColor.bgBodyOverlay,
                                           highlightedBgColor: UDColor.fillPressed)
        panel.delegate = self
        panel.isAccessibilityElement = true
        panel.accessibilityIdentifier = "sheets.toolkit.foregroundColor"
        panel.accessibilityLabel = "sheets.toolkit.foregroundColor"
        return panel
    }()
    
    private lazy var bgColorView: PickerAttributionPanel = {
        let panel = PickerAttributionPanel(frame: .zero,
                                           value: "#F1F2F3",
                                           title: BundleI18n.SKResource.Doc_Doc_ToolbarCellBgColor,
                                           showsBottomLine: true,
                                           normalBgColor: UDColor.bgBodyOverlay,
                                           highlightedBgColor: UDColor.fillPressed)
        panel.delegate = self
        panel.isAccessibilityElement = true
        panel.accessibilityIdentifier = "sheets.toolkit.backgroundColor"
        panel.accessibilityLabel = "sheets.toolkit.backgroundColor"
        return panel
    }()
    
    private lazy var fontSizeView: AdjustAttributionPanel = {
        let titleTxt = BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtSize
        let panel = AdjustAttributionPanel(frame: .zero,
                                           value: "0",
                                           title: titleTxt,
                                           layout: fontLayout,
                                           showsBottomLine: false,
                                           bgColor: UDColor.bgBodyOverlay)
        panel.delegate = dataProvider
        panel.layer.cornerRadius = 12
        panel.layer.maskedCorners = .bottom
        panel.isAccessibilityElement = true
        panel.accessibilityIdentifier = "sheets.toolkit.font.size"
        panel.accessibilityLabel = "sheets.toolkit.font.size"
        return panel
    }()

    private lazy var dataProvider: AdjustAttributionPanelDataProvider = {
        let provider = AdjustAttributionPanelDataProvider()
        provider.delegate = self
        return provider
    }()
    
    private lazy var fontLayout: AdjustAttributionPanel.PanelLayout = {
        var layout = AdjustAttributionPanel.PanelLayout()
        layout.displayIcon = false
        return layout
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addStyleViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        update(tapItem)
    }

    private func addStyleViews() {
        NSLayoutConstraint.activate([
            contentView.contentLayoutGuide.widthAnchor.constraint(equalTo: contentView.frameLayoutGuide.widthAnchor)
        ])
        //bius
        contentView.addSubview(biusPanel)
        biusPanel.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(contentView.contentLayoutGuide).inset(itemSpacing)
            make.height.equalTo(itemHeight)
        }

        //对齐
        contentView.addSubview(alignmentPanel)
        alignmentPanel.snp.makeConstraints { (make) in
            make.left.right.equalTo(biusPanel)
            make.top.equalTo(biusPanel.snp.bottom).offset(itemSpacing)
            make.height.equalTo(itemHeight)
        }

        //截断
        contentView.addSubview(truncationPanel)
        truncationPanel.snp.makeConstraints { (make) in
            make.top.equalTo(alignmentPanel.snp.bottom).offset(itemSpacing)
            make.left.right.equalTo(alignmentPanel)
            make.height.equalTo(itemHeight)
        }

        //边框
        contentView.addSubview(borderView)
        borderView.snp.makeConstraints { (make) in
            make.left.right.equalTo(truncationPanel)
            make.height.equalTo(itemHeight)
            make.top.equalTo(truncationPanel.snp.bottom).offset(itemSpacing)
        }

        //字体颜色
        contentView.addSubview(fontColorView)
        fontColorView.snp.makeConstraints { (make) in
            make.left.right.equalTo(borderView)
            make.height.equalTo(itemHeight)
            make.top.equalTo(borderView.snp.bottom)
        }

        //背景颜色
        contentView.addSubview(bgColorView)
        bgColorView.snp.makeConstraints { (make) in
            make.left.right.equalTo(fontColorView)
            make.height.equalTo(itemHeight)
            make.top.equalTo(fontColorView.snp.bottom)
        }

        //文字字号
        contentView.addSubview(fontSizeView)
        fontSizeView.snp.makeConstraints { (make) in
            make.left.right.equalTo(bgColorView)
            make.height.equalTo(itemHeight)
            make.top.equalTo(bgColorView.snp.bottom)
            make.bottom.equalTo(contentView.contentLayoutGuide)
        }
    }
    
    override func update(_ tapItem: SheetToolkitTapItem) {
        super.update(tapItem)
        
        var updateIds: [BarButtonIdentifier] = [.bold, .italic, .underline, .strikethrough]
        var biusInfos = [ToolBarItemInfo]()
        for identifier in updateIds {
            if let item = tapItem.info(for: identifier.rawValue) {
                biusInfos.append(item)
            }
        }
        biusPanel.update(biusInfos)
        
        var alignmentInfos = [[ToolBarItemInfo]]()
        let aligmentIds: [[BarButtonIdentifier]] = [[.horizontalLeft, .horizontalCenter, .horizontalRight], [.verticalTop, .verticalCenter, .verticalBottom]]
        for identifiers in aligmentIds {
            var infos = [ToolBarItemInfo]()
            for identifier in identifiers {
                if let item = tapItem.info(for: identifier.rawValue) {
                    infos.append(item)
                }
            }
            alignmentInfos.append(infos)
        }
        alignmentPanel.update(alignmentInfos)
        
        //截断
        updateIds = [.autoWrap, .overflow, .clip]
        var truncationInfos = [ToolBarItemInfo]()
        for identifier in updateIds {
            if let item = tapItem.info(for: identifier.rawValue) {
                truncationInfos.append(item)
            }
        }
        truncationPanel.update(truncationInfos)
        
        //更新字体颜色
        updateFontColor(info: tapItem.info(for: BarButtonIdentifier.foreColor.rawValue))
        updateBgColor(info: tapItem.info(for: BarButtonIdentifier.backColor.rawValue))
        updateFontSize(info: tapItem.info(for: BarButtonIdentifier.fontSize.rawValue))
        updateBorder(info: tapItem.info(for: BarButtonIdentifier.borderLine.rawValue))
    }
    
    override func reset() {
        borderOperationVC?.borderPanel.reset()
    }
    
    private func updateFontColor(info: ToolBarItemInfo?) {
        guard let colorInfo = info else { return }
        let colorVal = (colorInfo.value ?? "#000000").lowercased()
        let currInfo = colorItemsHelper(colorVal)
        fontColorView.update(desc: currInfo.desc, color: currInfo.color)
        if colorInfo.colorList != nil {
            fontColorInfo = colorInfo
            fontColorVC?.pickerPanel.updateInfos(info: colorInfo)
        }
    }
    
    private func updateBgColor(info: ToolBarItemInfo?) {
        guard let colorInfo = info else { return }
        let colorVal = (colorInfo.value ?? "#000000").lowercased()
        let currInfo = colorItemsHelper(colorVal)
        bgColorView.update(desc: currInfo.desc, color: currInfo.color)
        if colorInfo.colorList != nil {
            bgColorIndexPath = colorInfo.getSelectIndexInfo()
            bgColorInfo = colorInfo
            bgColorVC?.pickerPanel.updateInfos(info: colorInfo)
        }
    }
    
    
    private func updateBorder(info: ToolBarItemInfo?) {
        guard let info = info else { return }
        if let borderInfo = info.borderInfo {
            self.borderInfo = borderInfo
            borderOperationVC?.borderPanel.updateInfos(info: borderInfo)
            borderView.updateBorder(borderInfo.defaultValue?.border)
        }
        borderView.title = info.title ?? ""
    }
    
    private func updateFontSize(info: ToolBarItemInfo?) {
        guard let fontInfo = info else { return }
        if let value = fontInfo.value {
            fontSizeView.updateValue(value: value)
        }
        if let list = fontInfo.valueList {
            dataProvider.fontArrays = list
        }
        fontSizeView.updateButtonStatus()
    }
    
    @inline(__always)
    private func colorItemsHelper(_ color: String) -> ColorPaletteItem {
        let type = ColorPaletteItemType.analysis(desc: color)
        switch type {
        case .RGB:      return ColorRGBPaletteItem(by: color)
        case .clear:   return ColorClearPalentteItem()
        }
    }
}

extension SheetStyleToolkitViewController: PickerAttributionPanelDelegate {
    func pickerAttributionWillWakeColorPickerUp(panel: PickerAttributionPanel) {
        if panel === fontColorView {
            let vc = SheetColorPickerViewContoller([], title: BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtColor)
            vc.pickerPanel.delegate = self
            tryPush(vc: vc, animated: true)
            vc.pickerPanel.updateInfos(info: fontColorInfo)
            fontColorVC = vc
            delegate?.didRequestChangeStyle(identifier: "foreColorBar", value: nil, controller: self)
        } else if panel === bgColorView {
            let vc = SheetColorPickerViewContoller([], title: BundleI18n.SKResource.Doc_Doc_ToolbarCellBgColor)
            vc.pickerPanel.delegate = self
            tryPush(vc: vc, animated: true)
            vc.pickerPanel.updateInfos(info: bgColorInfo)
            bgColorVC = vc
            delegate?.didRequestChangeStyle(identifier: "backColorBar", value: nil, controller: self)
        } else if panel == borderView {
            var title = ""
            if let info = self.tapItem.info(for: BarButtonIdentifier.borderLine.rawValue) {
                title = info.title ?? ""
            }

            let vc = SheetBorderOperationViewController(BorderInfo(), title: title)
            vc.borderPanel.delegate = self
            tryPush(vc: vc, animated: true)
            vc.borderPanel.updateInfos(info: borderInfo)
            borderOperationVC = vc
            delegate?.didRequestChangeStyle(identifier: "borderLine", value: nil, controller: self)
        }
    }
    
    func tryPush(vc: UIViewController, animated: Bool) {
        if let navigator = navigationController as? SheetToolkitNavigationController {
            navigator.docsPushViewController(vc, animated: animated)
        } else {
            navigationController?.pushViewController(vc, animated: animated)
        }
    }
}

extension SheetStyleToolkitViewController: ColorPickerPanelDelegate {
    func hasUpdate(color: ColorPaletteItem, in panel: ColorPickerPanel) {
        if panel === fontColorVC?.pickerPanel {
            delegate?.didRequestChangeStyle(identifier: BarButtonIdentifier.foreColor.rawValue, value: color.desc, controller: self)
        } else if panel === bgColorVC?.pickerPanel {
            delegate?.didRequestChangeStyle(identifier: BarButtonIdentifier.backColor.rawValue, value: color.desc, controller: self)
        }
    }
}

extension SheetStyleToolkitViewController: BorderOperationPanelDelegate {
    func hasUpdate(params: [String: Any], in panel: BorderOperationPanel) {
        delegate?.didRequestChangeStyle(identifier: BarButtonIdentifier.borderLine.rawValue, value: params, controller: self)
    }
}

extension SheetStyleToolkitViewController: AdjustPanelDataProviderDelegate {
    func didModifyToNewValue(value: String, provider: AdjustAttributionPanelDataProvider) {
        delegate?.didRequestChangeStyle(identifier: BarButtonIdentifier.fontSize.rawValue, value: value, controller: self)
    }
}

extension SheetStyleToolkitViewController: StyleBasePanelDelegate {
    func didClickStyleBasePanel(panel: StyleBasePanel, button: AttributeButton) {
        guard let identifier = button.itemInfo?.identifier else { return }
        delegate?.didRequestChangeStyle(identifier: identifier, value: nil, controller: self)
    }
}
