//
//  ByteViewDebugItem.swift
//  LarkByteView
//
//  Created by CharlieSu on 11/28/19.
//

import Foundation
import LarkDebugExtensionPoint

public struct ByteViewDebugItem: DebugCellItem {
    public init() {}
    public let title: String = "视频会议"
    public let type: DebugCellType = .disclosureIndicator

    public func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        guard let from = self.topMost, let nav = (from as? UINavigationController) ?? from.navigationController else {
            return
        }
        let debugVC = DebugViewController()
        nav.pushViewController(debugVC, animated: true)
    }

    private var topMost: UIViewController? {
        if #available(iOS 13.0, *) {
            let windows = UIApplication.shared.windows
            let w = windows.first(where: { $0.isKeyWindow }) ?? windows.first
            return topMost(of: w?.rootViewController)
        } else {
            return topMost(of: UIApplication.shared.keyWindow?.rootViewController)
        }
    }

    private func topMost(of vc: UIViewController?) -> UIViewController? {
        if let vc = vc?.presentedViewController {
            return topMost(of: vc)
        }
        if let tab = vc as? UITabBarController {
            return topMost(of: tab.selectedViewController)
        }
        if let nav = vc as? UINavigationController {
            return topMost(of: nav.topViewController)
        }
        return vc
    }
}
