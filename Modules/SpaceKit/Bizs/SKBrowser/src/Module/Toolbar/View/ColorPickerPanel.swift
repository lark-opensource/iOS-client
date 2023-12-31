//
//  ColorPickerPanel.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/25.
//

import Foundation
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon

// MARK: Color Palette Item Protocol Declearation
public enum ColorPaletteItemType {
    case RGB
    case clear

    func mappedValue() -> String {
        switch self {
        case .clear:    return "#clear"
        default:        return ""
        }
    }

    public static func analysis(desc: String) -> ColorPaletteItemType {
        let ldesc = desc.lowercased()
        if ldesc.elementsEqual(ColorPaletteItemType.clear.mappedValue()) {
            return .clear
        }
        return .RGB
    }
}

public protocol ColorPaletteItem {
    var type: ColorPaletteItemType { get }
    var color: UIColor { get }
    var desc: String { get }
}

public struct ColorRGBPaletteItem: ColorPaletteItem {
    public var type: ColorPaletteItemType { return .RGB }
    public var color: UIColor = .clear
    public var desc: String { return rgb }
    public var rgb: String {
        didSet {
            self.color = UIColor.docs.rgb(rgb)
        }
    }
    public init(by rgb: String) {
        self.rgb = rgb
        self.color = UIColor.docs.rgb(rgb)
    }
}

public struct ColorClearPalentteItem: ColorPaletteItem {
    public var type: ColorPaletteItemType { return .clear }
    public var color: UIColor = UIColor.ud.N00
    public var desc: String { return ColorPaletteItemType.clear.mappedValue() }
    public init() { }
}

// MARK: Color Picker Panel Impl
public protocol ColorPickerPanelDelegate: AnyObject {
    func hasUpdate(color: ColorPaletteItem, in panel: ColorPickerPanel)
}

public final class ColorPickerPanel: UIView {
    public weak var delegate: ColorPickerPanelDelegate?
    
    var colorPickCorePanel: ColorPickerCorePanel
    var lastHitIndexPath: IndexPath = IndexPath(row: -1, section: -1)
    
    var colorPickPanelHeight = 136
    
    var currentColor: String {
        colorPickCorePanel.currentColor
    }

    public init(frame: CGRect, infos: [ColorItemNew]) {
        colorPickCorePanel = ColorPickerCorePanel(frame: frame, infos: infos)
        super.init(frame: frame)

        addSubview(colorPickCorePanel)
        colorPickCorePanel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(colorPickPanelHeight)
        }
        colorPickCorePanel.delegate = self
    }

    public func updateInfos(info: ToolBarItemInfo) {
        colorPickCorePanel.updateInfos(info: info)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func refreshViewLayout() {
        colorPickCorePanel.refreshViewLayout()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension ColorPickerPanel: ColorPickerCorePanelDelegate {
    public func didChooseColor(panel: ColorPickerCorePanel, color: String, isTapDetailColor: Bool) {
        let item = ColorRGBPaletteItem(by: color)
        delegate?.hasUpdate(color: item, in: self)
    }
}

protocol ColorPickerNavigationViewDelegate: AnyObject {
    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView)
}

class ColorPickerNavigationView: PanelNavigationView {
    
    weak var delegate: ColorPickerNavigationViewDelegate?
    
    var exitAction: (() -> Void)?
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        exitAction?()
    }
    
    @objc
    override func didClickBackButton(sender: UIButton) {
        exitAction?()
        NotificationCenter.default.post(name: Notification.Name.NavigationShowHighlightPanel, object: nil)
        delegate?.colorPickerNavigationViewRequestExit(view: self)
    }
}
