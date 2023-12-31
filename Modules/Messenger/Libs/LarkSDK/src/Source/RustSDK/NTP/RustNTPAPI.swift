//
//  RustNTPAPI.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/7/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import RustSDK
import LarkModel
import LarkSDKInterface

final class RustNTPAPI: LarkAPI, NTPAPI {
    func getNTPTime() -> Int64 {
        return get_ntp_time()
    }
}
