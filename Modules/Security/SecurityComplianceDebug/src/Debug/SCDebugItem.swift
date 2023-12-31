//
//  SCDebugItem.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/8.
//

import LarkDebugExtensionPoint
import EENavigator
import LarkContainer

final class SCDebugItem: DebugCellItem {
    
    let resolver: UserResolver?
    
    init(resolver: UserResolver?) {
        self.resolver = resolver
    }

    var title: String = "Security & Compliance"

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        guard let resolver else { return }
        guard let vc = try? SCDebugViewController(resolver: resolver) else { return }
        vc.modalPresentationStyle = .fullScreen // 设置当前页面为全屏
        resolver.navigator.push(vc, from: debugVC)
    }
}
