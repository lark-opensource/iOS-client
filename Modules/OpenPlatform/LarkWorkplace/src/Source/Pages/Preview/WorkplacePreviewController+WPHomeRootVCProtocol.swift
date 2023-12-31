//
//  WorkplacePreviewController+WPHomeRootVCProtocol.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/12.
//

import Foundation
import LarkUIKit
import LarkNavigation

extension WorkplacePreviewController: WPHomeRootVCProtocol {
    var tracker: WPHomeTracker {
        return WPHomeTracker()
    }

    var topNavH: CGFloat {
        return 0.0
    }

    var botTabH: CGFloat {
        return 0.0
    }
    
    var templatePortalCount: Int {
        return 1
    }

    func reportFirstScreenDataReadyIfNeeded() {}

    func rootReloadNaviBar() {
        naviBar.reloadNaviBar()
    }
}
