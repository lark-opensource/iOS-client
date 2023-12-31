//
//  SheetBorderOperationViewController.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/13.
//  

import Foundation
import SKCommon
import SKBrowser
import SKUIKit

class SheetBorderOperationViewController: SheetScrollableToolkitViewController {

    var borderInfo = BorderInfo()
    var borderPanel: BorderOperationPanel

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.borderLine.rawValue
    }

    init(_ borderInfo: BorderInfo, title: String) {
        self.borderInfo = borderInfo
        borderPanel = BorderOperationPanel(frame: .zero)
        super.init()

        navigationBar.setTitleText(title)
        navigationBar.isAccessibilityElement = true
        navigationBar.accessibilityIdentifier = "sheets.toolkit.color.picker.back"
        navigationBar.accessibilityLabel = "sheets.toolkit.color.picker.back"
        
        scrollView.addSubview(borderPanel)
        borderPanel.snp.makeConstraints { (make) in
            make.left.top.right.equalTo(scrollView.contentLayoutGuide)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(itemSpacing)
        }
    }

    var customTitle: String = "" {
        didSet {
            navigationBar.setTitleText(customTitle)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
