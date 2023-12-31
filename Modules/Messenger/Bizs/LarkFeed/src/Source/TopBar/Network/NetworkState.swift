//
//  NetworkState.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/22.
//

import UIKit
import Foundation
import RxCocoa
import LarkSDKInterface
import LarkModel

/// 设备网络状态
enum NetworkState {
    case normal
    case noNetwork
    case serviceUnavailable

    var icon: UIImage? {
        switch self {
        case .normal: return nil
        case .noNetwork: return Resources.status_net_error
        case .serviceUnavailable: return Resources.status_net_error
        }
    }

    var title: String? {
        switch self {
        case .normal: return nil
        case .noNetwork:
            return BundleI18n.LarkFeed.Lark_Legacy_NetConnectionError
        case .serviceUnavailable:
            return BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderServiceUnavailable
        }
    }
}
