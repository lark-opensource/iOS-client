//
//  ClientMetricsUploagConfigItem.swift
//  LarkApp
//
//  Created by lixiaorui on 2019/12/19.
//

import UIKit
import Foundation
import LarkDebug
import EENavigator
import LarkSDKInterface
import Swinject

struct ClientMetricsUploagConfigItem: DebugCellItem {
    var title: String { return "Client Metrics 上传调试" }
    let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let vc = RustMetricUploadDebugViewController(logAPI: resolver.resolve(RustLogAPI.self)!)
        vc.modalPresentationStyle = .fullScreen
        Navigator.shared.present(UINavigationController(rootViewController: vc), from: debugVC)
    }
}
