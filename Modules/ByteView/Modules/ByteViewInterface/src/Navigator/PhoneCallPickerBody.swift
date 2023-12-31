//
//  PhoneCallPickerBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/12/7.
//

import Foundation

/// 发起办公电话, /client/byteview/phonecallpicker
public struct PhoneCallPickerBody: CodablePathBody {
    public static let path: String = "/client/byteview/phonecallpicker"
    public let phoneNumber: String
    public let phoneType: PhoneType

    public init(phoneNumber: String, phoneType: PhoneType) {
        self.phoneNumber = phoneNumber
        self.phoneType = phoneType
    }

    public enum PhoneType: String, Codable, CustomStringConvertible {
        case ipPhone
        case recruitmentPhone
        case enterprisePhone

        public var description: String { rawValue }
    }
}

extension PhoneCallPickerBody: CustomStringConvertible {
    public var description: String {
        "PhoneCallPickerBody(phoneNumber: \(phoneNumber.hash), phoneType: \(phoneType))"
    }
}
