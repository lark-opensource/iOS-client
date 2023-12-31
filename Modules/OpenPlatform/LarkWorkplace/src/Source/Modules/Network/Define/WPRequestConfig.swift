//
//  WPRequestConfig.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/5/4.
//

import Foundation
import ECOInfra

protocol WPRequestConfig: ECONetworkRequestConfig {
    static var injectInfo: WPRequestInjectInfo { get }
}
