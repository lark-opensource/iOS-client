//
//  ColorPickerViewController.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/7/16.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColorPicker

class ColorEditViewController: BaseUIViewController {

    var colorSelectedHandler: ((_ index: Int) -> Void)?
    private(set) var colorPickerPanel: UDColorPickerPanel?
    private(set) var container = UIView()
    private var selectedIndex: Int

    private lazy var colorItems: [UDPaletteItem] = {
        return SkinColorHelper.colorsForPicker.map { .init(color: $0) }
    }()

    override var navigationBarStyle: NavigationBarStyle { .custom(.ud.bgBase) }

    init(selectedIndex: Int = 0) {
        self.selectedIndex = selectedIndex
        super.init(nibName: nil, bundle: nil)
        title = I18n.Calendar_Setting_CalendarColor
        let model = UDPaletteModel(
            category: .basic,
            title: "",
            items: colorItems,
            selectedIndex: selectedIndex
        )
        let config = UDColorPickerConfig(models: [model], backgroudColor: .ud.bgFloat)
        colorPickerPanel = UDColorPickerPanel(config: config)
        colorPickerPanel?.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let colorPickerPanel = colorPickerPanel else { return }
        container.backgroundColor = .ud.bgFloat
        container.layer.cornerRadius = 12
        container.addSubview(colorPickerPanel)
        colorPickerPanel.snp.makeConstraints {
            $0.leading.centerY.trailing.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(12)
        }

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(8)
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Color Picker Delegate

extension ColorEditViewController: UDColorPickerPanelDelegate {
    func didSelected(color: UIColor?, category: UDPaletteItemsCategory, in panel: UDColorPickerPanel) {
        guard let colorSelectedHandler = colorSelectedHandler,
              let color = color,
              let selectedIndex = colorItems.firstIndex(of: UDPaletteItem(color: color))else {
            assertionFailure("please set up the handler / cant get UIColor")
            return
        }
        colorSelectedHandler(selectedIndex)
        navigationController?.popViewController(animated: true)
    }
}

class ColorEditActionPanel: ColorEditViewController {

    private static let headerHeight: CGFloat = 48

    override func viewDidLoad() {
        super.viewDidLoad()
        guard !colorPickerPanel.isNil else { return }
        if Display.pad {
            container.snp.remakeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                make.trailing.equalToSuperview().inset(12)
                make.height.equalTo(128)
            }
            view.backgroundColor = container.backgroundColor
        } else {
            let header = ActionPanelHeader(title: I18n.Calendar_Setting_CalendarColor)
            header.addBottomBorder(lineHeight: CGFloat(1.0 / UIScreen.main.scale))
            header.closeCallback = { [weak self] in
                self?.dismissSelf()
            }
            view.addSubview(header)
            header.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(Self.headerHeight)
            }

            container.snp.updateConstraints { make in
                make.top.equalTo(16 + Self.headerHeight)
            }
            view.backgroundColor = .ud.bgFloatBase
        }
    }

    @objc
    private func dismissSelf() { dismiss(animated: true) }
}
