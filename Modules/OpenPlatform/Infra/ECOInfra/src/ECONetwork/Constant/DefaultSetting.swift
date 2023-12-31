//
//  DefaultSetting.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/14.
//

import Foundation

public let DefaultRequestSetting = ECONetworkRequestSetting(
    timeout: 60,
    cachePolicy: .useProtocolCachePolicy,
    enableComplexConnect: true,
    httpShouldUsePipelining: false
)
