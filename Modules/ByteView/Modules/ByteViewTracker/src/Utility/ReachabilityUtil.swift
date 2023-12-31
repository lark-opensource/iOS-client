//
//  ReachabilityUtil.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import Reachability
import CoreTelephony
import ByteViewCommon

extension Reachability: VCExtensionCompatible {}

public extension VCExtension where BaseType == Reachability {
    static let shared: Reachability = Reachability()!
}

/// 网络类型小工具，提供获取当前网络状况的能力
public final class ReachabilityUtil {

    /// 是否有网络
    public static var isConnected: Bool {
        Reachability.vc.shared.connection != .none
    }

    /// 是否在使用流量网络
    public static var isCellular: Bool {
        Reachability.vc.shared.connection == .cellular
    }

    @RwAtomic
    private static var _ctNetowrkInfo: CTTelephonyNetworkInfo?
    private static var ctNetowrkInfo: CTTelephonyNetworkInfo? {
        if let info = _ctNetowrkInfo { return info }
        DispatchQueue.main.async {
            // CTTelephonyNetworkInfo单例需要提前初始化
            // https://bytedance.feishu.cn/docx/doxcnWAfkA6naxXOuWsYwqLkm6b
            if _ctNetowrkInfo == nil {
                _ctNetowrkInfo = CTTelephonyNetworkInfo()
            }
        }
        return nil
    }
    /// 当前网络类型
    public static var currentNetworkType: NetworkConnectionType {
        switch Reachability.vc.shared.connection {
        case .wifi:
            return .wifi
        case .cellular:
            if let info = ctNetowrkInfo {
                if #available(iOS 12.0, *) {
                    if let dict = info.serviceCurrentRadioAccessTechnology, let networkType = dict.values.first {
                        return mapCTTelephonyNetworkInfo(networkType)
                    } else {
                        return .others
                    }
                } else {
                    if let networkType = info.currentRadioAccessTechnology {
                        return mapCTTelephonyNetworkInfo(networkType)
                    } else {
                        return .others
                    }
                }
            } else {
                return .others
            }
        default:
            return .others
        }
    }

    /// 将RAT无线网络类型map成具体的流量类型
    /// - Parameter info: RAT无线网络类型
    /// - Returns: 流量类型
    static private func mapCTTelephonyNetworkInfo(_ info: String) -> NetworkConnectionType {
        if #available(iOS 14.3, *), info == CTRadioAccessTechnologyNRNSA || info == CTRadioAccessTechnologyNR {
            return .cell5G
        }
        switch info {
        case CTRadioAccessTechnologyLTE:
            return .cell4G
        case CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
        CTRadioAccessTechnologyeHRPD:
            return .cell3G
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            return .cell2G
        default:
            return .others
        }
    }
}

/// 移动网络连接类型
public enum NetworkConnectionType: Int, Codable, Hashable, CustomStringConvertible {
    /// 5G
    case cell5G
    /// 4G
    case cell4G
    /// 3G
    case cell3G
    /// 2G
    case cell2G
    /// Wi-Fi
    case wifi
    /// Other Network Type
    case others

    public var description: String {
        switch self {
        case .cell5G:
            return "5g"
        case .cell4G:
            return "4g"
        case .cell3G:
            return "3g"
        case .cell2G:
            return "2g"
        case .wifi:
            return "wifi"
        case .others:
            return "others"
        }
    }
}
