//
//  FeedList.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/18.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTabs

class FeedList: UIViewController, UDTabsListContainerViewDataSource {
    private var subViewControllers: [UDTabsListContainerViewDelegate] = []

    private let tabsView = UDTabsTitleView()

    private var titles: [String] = []

    private lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    init(count: Int) {
        var i = 0
        while i < count {
            let vc = TabsVC(index: i)
            vc.setBackgroundColor(UIColor.gray.withAlphaComponent(0.1 * CGFloat(i)))
            if i != count {
                let title = "tab：\(i)"
                titles.append(title)
            } else {
                titles.append("···")
            }
            subViewControllers.append(vc)
            i += 1
        }

        super.init(nibName: nil, bundle: nil)

        tabsView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = tabsView.getConfig()
        if subViewControllers.count > 5 {
            config.isShowGradientMaskLayer = true
            config.contentEdgeInsetLeft = 6
            config.itemSpacing = 24
        } else {
            config.layoutStyle = .average
            config.itemSpacing = 0
            config.contentEdgeInsetLeft = 0
        }
        self.view.backgroundColor = .white
        config.isTitleColorGradientEnabled = false
        tabsView.titles = titles
        // 去除item之间的间距
        config.itemWidthIncrement = 0
        config.isSelectedAnimable = true

        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2

        tabsView.backgroundColor = UIColor.white
        tabsView.indicators = [indicator]
        config.isContentScrollViewClickTransitionAnimationEnabled = false
        // 去除整体内容的左右边距
        config.contentEdgeInsetRight = 0

        tabsView.setConfig(config: config)

        view.addSubview(tabsView)
        tabsView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(91)
            make.left.right.equalToSuperview()
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
        return subViewControllers.count - 1
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView,
                           initListAt index: Int) -> UDTabsListContainerViewDelegate {
        return subViewControllers[index]
    }
}

extension FeedList: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, canClickItemAt index: Int) -> Bool {
        if index == subViewControllers.count - 1 {
            self.navigationController?.pushViewController(FeedFilter(), animated: true)
            return false
        } else {
            return true
        }
    }
}
