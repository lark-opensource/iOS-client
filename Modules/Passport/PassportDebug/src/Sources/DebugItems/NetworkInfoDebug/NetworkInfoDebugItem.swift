//
//  NetworkInfoDebugItem.swift
//  PassportDebug
//
//  Created by ZhaoKejie on 2023/3/30.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator
import LarkContainer

struct NetworkInfoDebugItem: DebugCellItem {
    let title = "Passport网络请求列表"

    @Provider var accountService: AccountService

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let networkInfoVC = NetworkInfoViewController(data: accountService.getNetworkInfoItem())
        networkInfoVC.modalPresentationStyle = .fullScreen
        Navigator.shared.present(networkInfoVC, from: debugVC)
    }

}
