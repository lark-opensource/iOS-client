//
//  FontColorPickerView.swift
//  SKCommon
//
//  Created by lizechuang on 2020/7/10.
//

import Foundation
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor

public final class FontColorPickerView: SKSubToolBarPanel {

    private let pickerViewHeight: CGFloat = 300
    private let navigationHeight: CGFloat = 48
    private let info: ToolBarItemInfo

    lazy private var colorPickerPanel: ColorPickerPanel = {
        let view = ColorPickerPanel(frame: .zero, infos: [])
        return view
    }()

    lazy private var colorPickerNavigationView: ColorPickerNavigationView = {
        let view = ColorPickerNavigationView(frame: .zero)
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    public init(info: ToolBarItemInfo) {
        self.info = info
        super.init(frame: .zero)
        setupSubViews()
    }

    public override func refreshViewLayout() {
        colorPickerPanel.refreshViewLayout()
    }

    public override func getCurrentDisplayHeight() -> CGFloat? {
        return pickerViewHeight + navigationHeight
    }
    public override func showRootView() {
        self.removeFromSuperview()
    }

    private func setupSubViews() {
        colorPickerPanel.delegate = self
        colorPickerNavigationView.delegate = self
        backgroundColor = .clear
        isUserInteractionEnabled = true
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        layer.shadowOffset = CGSize(width: 0, height: -6)
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 24
        contentView.backgroundColor = UDColor.bgBody

        addSubview(colorPickerNavigationView)
        addSubview(contentView)
        contentView.addSubview(colorPickerPanel)

        contentView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
        }

        colorPickerPanel.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
            make.height.equalTo(pickerViewHeight)
        }

        colorPickerNavigationView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(contentView.snp.top)
            make.height.equalTo(navigationHeight)
        }

        if info.identifier == BarButtonIdentifier.backColor.rawValue {
            self.colorPickerNavigationView.updateTitle(BundleI18n.SKResource.Doc_Doc_ToolbarCellBgColor)
        } else if info.identifier == BarButtonIdentifier.foreColor.rawValue {
            self.colorPickerNavigationView.updateTitle(BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtColor)
        }

        updateColor(info: info)
    }

    func updateColor(info: ToolBarItemInfo?) {
        guard let colorInfo = info else { return }

        colorPickerPanel.updateInfos(info: colorInfo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FontColorPickerView: ColorPickerPanelDelegate {
    public func hasUpdate(color: ColorPaletteItem, in panel: ColorPickerPanel) {
        if info.identifier == BarButtonIdentifier.backColor.rawValue
            || info.identifier == BarButtonIdentifier.foreColor.rawValue {
            panelDelegate?.select(item: info, update: color.desc, view: self)
        }
    }
}

extension FontColorPickerView: ColorPickerNavigationViewDelegate {
    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromLeft
        self.superview?.layer.add(transition, forKey: nil)
        self.removeFromSuperview()
    }
}
