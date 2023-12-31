//
//  IMMentionTabsView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import UniverseDesignTabs
import UniverseDesignColor
import SnapKit

final class IMMentionTabsView: UIView {
    var tabItems: [IMMentionTabsContent]
    var didEndEditing: (() -> Void)?
    /// IMMentionTabsView 的 Tab 标题栏
    lazy var tabsTitleView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        let config = tabsView.getConfig()
        config.contentEdgeInsetLeft = 16
        config.contentEdgeInsetRight = 16
        config.isItemSpacingAverageEnabled = false
        config.titleNormalFont = UIFont.systemFont(ofSize: 16)
        config.titleSelectedFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        config.itemSpacing = 36
        config.itemMaxWidth = 250
        config.titleNumberOfLines = 1
        tabsView.backgroundColor = UIColor.ud.bgBody
        tabsView.titles = [BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_All_Tab,
                           BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_Members_Tab,
                           BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_Docs_Tab]
        tabsView.indicators = [CustomTabsIndicatorLineView()]
        tabsView.setConfig(config: config)
        tabsView.delegate = self
        tabsView.listContainer = tabsContainerView
        let divider = UIView()
        divider.backgroundColor = UIColor.ud.lineDividerDefault
        tabsView.insertSubview(divider, at: 0)
        divider.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return tabsView
    }()
    
    /// IMMentionTabsView 的 VC 容器
    lazy var tabsContainerView: UDTabsListContainerView = {
        let containerView = UDTabsListContainerView(dataSource: self)
        //containerView.delegate = self
        return containerView
    }()
    
    init() {
        tabItems = [IMMentionTabsContent(),
                    IMMentionTabsContent(),
                    IMMentionTabsContent()]
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(){
        addSubview(tabsTitleView)
        addSubview(tabsContainerView)
        tabsTitleView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.width.equalToSuperview()
            $0.height.equalTo(40)
            $0.top.equalToSuperview().offset(0)
        }

        tabsContainerView.snp.makeConstraints {
            $0.top.equalTo(tabsTitleView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

}


extension IMMentionTabsView: UDTabsListContainerViewDataSource {
    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        return tabItems[index]
    }
    
    public func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return tabItems.count
    }

}

extension IMMentionTabsView: UDTabsViewDelegate {
    public func tabsViewWillBeginDragging(_ tabsView: UDTabsView) {
        didEndEditing?()
    }
    
    public func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        didEndEditing?()
    }
}


// 横线
final class CustomTabsIndicatorLineView: UDTabsIndicatorLineView {
    override func commonInit() {
        super.commonInit()
        indicatorHeight = 2
    }

    override func refreshIndicatorState(model: UDTabsIndicatorParamsModel) {
        super.refreshIndicatorState(model: model)
        layer.cornerRadius = 2
        let preFrame = frame
        frame = CGRect(x: preFrame.minX, y: preFrame.minY, width: preFrame.width, height: 4)
    }
}


