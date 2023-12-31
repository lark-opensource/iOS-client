//
//  NtpAPI.swift
//  LarkSDKInterface
//
//  Created by chengzhipeng-bytedance on 2018/7/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel

public protocol NTPAPI {
    func getNTPTime() -> Int64
}
