//
//  PSTNPhone.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// - GET_ADMIN_SETTINGS
/// - Videoconference_V1_PSTNPhone
public struct PSTNPhone: Equatable {
    public init(country: String, type: TypeEnum, number: String, numberDisplay: String, mobileCode: MobileCode? = nil) {
        self.country = country
        self.type = type
        self.number = number
        self.numberDisplay = numberDisplay
        self._mobileCode = mobileCode
    }

    /// 国家
    public var country: String

    /// 类型
    public var type: TypeEnum

    /// 号码
    public var number: String

    /// 号码加空格展示
    public var numberDisplay: String

    private var _mobileCode: MobileCode?

    /// 国家地区码信息
    public var mobileCode: MobileCode {
        _mobileCode ?? .emptyCode(country)
    }

    /// 国家地区名
    public var countryName: String { mobileCode.name }

    public enum TypeEnum: Int, Hashable {
        case unknown // = 0

        /// 免费电话
        case free // = 1

        /// 收费电话
        case charge // = 2
    }
}

extension PSTNPhone: CustomStringConvertible {
    public var description: String {
        String(indent: "PSTNPhone",
               "type: \(type)",
               "country: \(country)",
               "number: \(number.hash)",
               "mobileCode: \(_mobileCode)"
        )
    }
}
