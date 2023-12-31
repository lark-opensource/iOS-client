//
//  WikiTreeViewController+Navigator.swift
//  SKWikiV2
//
//  Created by majie.7 on 2023/12/13.
//

import Foundation
import UniverseDesignIcon
import LarkTab
import SKCommon
import SKUIKit


extension WikiTreeCoverViewController: TabContainable {
    var tabID: String {
        viewModel.space.spaceID
    }
    
    var tabBizID: String {
        ""
    }
    
    var tabIcon: LarkTab.CustomTabIcon {
        return .iconName(.wikibookColorful)
    }
    
    var tabTitle: String {
        viewModel.space.spaceName
    }
    
    var tabURL: String {
        wikiSpaceUrl?.absoluteString ?? ""
    }
    
    var tabAnalyticsTypeName: String {
        "wikiSpace"
    }
    
    func willMoveToTemporary() {
        showCloseButton()
    }
    
    private func showCloseButton() {
        let closeButton = SKBarButtonItem(image: UDIcon.closeOutlined,
                                          style: .plain,
                                          target: self,
                                          action: #selector(closeButtonClickHandler))
        closeButton.id = .close
        navigationBar.leadingBarButtonItems = [closeButton]
        navigationBar.setNeedsLayout()
        
        coverNavigationBar.backBtn.isHidden = true
        coverNavigationBar.closeBtn.isHidden = false
    }
}
