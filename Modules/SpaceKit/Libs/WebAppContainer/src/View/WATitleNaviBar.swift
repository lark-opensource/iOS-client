//
//  WATitleNaviBar.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/18.
//

import Foundation
import SKUIKit
import UniverseDesignColor
import SnapKit

class WATitleNaviBar: UIView {
    
    lazy var navigationBar: SKNavigationBar = SKNavigationBar()

    private lazy var statusBar = UIView().construct { (view) in
        view.backgroundColor = UDColor.bgBody
    }
    
    func setup() {
        
        backgroundColor = UIColor.ud.bgBody
        
        addSubview(statusBar)
        statusBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.top)
        }
        addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.top.equalTo(statusBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func update(titleBarConfig: WATitleBarConfig, target: AnyObject, selector: Selector) {
        var curLayoutAttributes = self.navigationBar.layoutAttributes
        if let size = titleBarConfig.titleType?.size {
            switch size {
            case .small:
                curLayoutAttributes.titleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            case .big:
                curLayoutAttributes.titleFont = UIFont.systemFont(ofSize: 20, weight: .medium)
            default:
                curLayoutAttributes.titleFont = UIFont.systemFont(ofSize: 17, weight: .medium)
            }
        }
        if let pos = titleBarConfig.titleType?.position {
            if pos == .left {
                curLayoutAttributes.titleHorizontalAlignment = .leading
            } else {
                curLayoutAttributes.titleHorizontalAlignment = .center
            }
            self.navigationBar.layoutAttributes = curLayoutAttributes
        }
        self.navigationBar.layoutAttributes = curLayoutAttributes
        
        var leadingBarButtonItems = [SKBarButtonItem]()
        var trailingBarButtonItems = [SKBarButtonItem]()
        if let leftItems = titleBarConfig.leftItems {
            leadingBarButtonItems = leftItems.compactMap {
                $0.toBarButtonItem(target: target, selector: selector)
            }
        }
        if let rightItems = titleBarConfig.rightItems {
            trailingBarButtonItems = rightItems.compactMap {
                $0.toBarButtonItem(target: target, selector: selector)
            }.reversed()
        }
        self.navigationBar.leadingBarButtonItems = leadingBarButtonItems
        self.navigationBar.trailingBarButtonItems = trailingBarButtonItems
    }
}
