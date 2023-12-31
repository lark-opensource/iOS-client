//
//  SheetColorPickerViewContoller.swift
//  SpaceKit
//
//  Created by Webster on 2019/7/19.
//

import Foundation
import SKCommon
import SKBrowser
import SKUIKit

class SheetColorPickerViewContoller: SheetBaseToolkitViewController {

    var items = [ColorItemNew]()
    var pickerPanel: ColorPickerPanel

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.backgroundColor.rawValue
    }

    init(_ palletteItems: [ColorItemNew], title: String) {
        items = palletteItems
        pickerPanel = ColorPickerPanel(frame: .zero, infos: items)
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(navigationBar)
        navigationBar.setTitleText(title)
        navigationBar.isAccessibilityElement = true
        navigationBar.accessibilityIdentifier = "sheets.toolkit.color.picker.back"
        navigationBar.accessibilityLabel = "sheets.toolkit.color.picker.back"
        navigationBar.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(navigationBarHeight)
            make.top.equalToSuperview().offset(draggableViewHeight)
            make.left.equalToSuperview()
        }
        view.addSubview(pickerPanel)
        pickerPanel.snp.makeConstraints { (make) in
           make.top.equalToSuperview().offset(topPaddingWithHeader)
           make.width.equalToSuperview()
           make.left.equalToSuperview()
           make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
