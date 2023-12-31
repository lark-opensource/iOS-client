//
//  H323Info.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/6/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

struct H323Info {
    var ip: String
    /// 经过 i18n 转换过的 country 名称
    var country: String
}

struct H323AccessList {
    var h323Infos: [H323Info]
}
