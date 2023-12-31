//
//  MailManageTagViewController+UDTabs.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/7/19.
//

import Foundation
import UniverseDesignTabs

extension MailManageTagViewController: UDTabsViewDelegate {
}

extension MailManageTagViewController: UDTabsListContainerViewDataSource {
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return items.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        return items[index]
    }
}
