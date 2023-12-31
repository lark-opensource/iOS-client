//
//  FetchClientLog.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkDebugExtensionPoint
import LarkAccountInterface
import EENavigator
import RoundedHUD
import LarkContainer
import UniverseDesignToast

struct FetchClientLogItem: DebugCellItem {
    var title: String { return "获取设备本地日志" }
    var detail: String { return "" }
    
    var canPerformAction: ((Selector) -> Bool)?
    var perfomAction: ((Selector) -> Void)?
    @Provider var account: AccountService
    
    init() { }
    
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        if let topVC = Navigator.shared.mainSceneTopMost {
            DispatchQueue.main.async {
                let toast = UDToast.showDefaultLoading(on: topVC.view)
                account.fetchClientLog() { controller in
                    guard let vc = controller else {
                        return
                    }
                    toast.remove()
                    topVC.present(vc, animated: true, completion: nil)
                }
            }
        }
    }
}
