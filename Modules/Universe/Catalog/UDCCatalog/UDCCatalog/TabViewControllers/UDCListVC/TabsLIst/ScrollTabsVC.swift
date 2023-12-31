//
//  ScrollTabsVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/8.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTabs

class ScrollTabsVC: UIViewController, UDTabsListContainerViewDataSource {
    private var subViewControllers: [UDTabsListContainerViewDelegate] = []

    private let tabsView = UDTabsTitleView()

    private var titles: [String] = [] {
        didSet {
            tabsView.titles = titles
            tabsView.reloadData()
        }
    }

    private let count: Int

    private lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    init(count: Int) {
        self.count = count
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var i = 0
        while i < count {
            let vc = TabsVC(index: i)
            vc.callback = { text, index in
                self.titles[index] = text
            }
            vc.setBackgroundColor(UIColor.ud.N500.withAlphaComponent(0.1 * CGFloat(i)))
            let title = "tab：\(i)"
            titles.append(title)
            subViewControllers.append(vc)
            i += 1
        }

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .unspecified
        }
        let config = tabsView.getConfig()
        if subViewControllers.count > 5 {
            config.isShowGradientMaskLayer = true
            config.contentEdgeInsetLeft = 6
            config.itemSpacing = 24
            config.itemMaxWidth = 100
        } else {
            config.layoutStyle = .average
            config.isItemSpacingAverageEnabled = false
            config.itemSpacing = 0
            config.contentEdgeInsetLeft = 0
            config.titleNumberOfLines = 2
        }
        self.view.backgroundColor = UIColor.ud.N00
        config.isTitleColorGradientEnabled = false
        tabsView.titles = titles
        // 去除item之间的间距
        config.itemWidthIncrement = 0

        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2

        tabsView.backgroundColor = UIColor.ud.N00
        tabsView.indicators = [indicator]
        // 去除整体内容的左右边距
        config.contentEdgeInsetRight = 0

        tabsView.setConfig(config: config)

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(91)
            make.right.equalToSuperview()
            make.left.equalTo(18)
            make.height.equalTo(40)
        }

        tabsView.listContainer = listContainerView
        view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(tabsView.snp.bottom)
        }
    }

    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return subViewControllers.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView,
                           initListAt index: Int) -> UDTabsListContainerViewDelegate {
        return subViewControllers[index]
    }
}
