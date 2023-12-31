//
//  VCError.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/9/16.
//

// 参考文档：https://docs.bytedance.net/doc/GcytE2me92uRt1m4z1lvPa

import Foundation
import RustPB

enum VCError: Error, Equatable {
    case unknown // 未知错误
}

extension VCError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknown:
            return String(format: BundleI18n.LarkLive.Common_G_FromView_OperationFailedCodePercentAt,
                          String(describing: errorCode))
        }
    }
}

extension VCError {
    var errorCode: Int {
        switch self {
        case .unknown: return 0
        }
    }
}
