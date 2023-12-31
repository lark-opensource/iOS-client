//
//  PhoneNumberUtil.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class PhoneNumberUtil {

    /*
     - 08位：xxxx xxxx
     - 10位：xxx xxx xxxx
     - 11位：xxx xxxx xxxx
     - 12位：xxxx xxxx xxxx
     - 13位：+86 10 xxxx xxxx
     - 14位：+86 xxx xxxx xxxx 或 0086 10 xxxx xxxx
     - 15位：0086 xxx xxxx xxxx
     */
    public static func format(_ origin: String?) -> String? {
        guard let phoneNumber = origin?.replacingOccurrences(of: " ", with: "") else { return nil }
        guard isNumber(phoneNumber) else { return phoneNumber}
        guard !phoneNumber.contains(where: { $0 == "*" || $0 == "#" }) else { return phoneNumber }
        var prefix: String = ""
        var number: String = phoneNumber
        if number.prefix(3) == "+86" {
            prefix += "+86 "
            number = String(number.dropFirst(3))
            if number.prefix(2) == "10" {
                prefix += "10 "
                number = String(number.dropFirst(2))
            }
        } else if number.prefix(2) == "00" {
            prefix += "00"
            number = String(number.dropFirst(2))
            if number.prefix(2) == "86" {
                prefix += "86 "
                number = String(number.dropFirst(2))
                if number.prefix(2) == "10" {
                    prefix += "10 "
                    number = String(number.dropFirst(2))
                }
            }
        }
        if isDomesticPhoneNumber(number), let num = format344(number) {
            number = num
        } else {
            switch number.count {
            case 8, 12:
                number = format444(number) ?? number
            case 10:
                number = format334(number) ?? number
            case 11:
                number = format344(number) ?? number
            default:
                break
            }
        }
        return prefix + number
    }

    private static func format334(_ origin: String?) -> String? {
        return format(origin, regex: "(\\d{3})(\\d{0,3})(\\d{0,4})", replace: "$1 $2 $3")
    }

    private static func format344(_ origin: String?) -> String? {
        return format(origin, regex: "(\\d{3})(\\d{0,4})(\\d{0,4})", replace: "$1 $2 $3")
    }

    private static func format444(_ origin: String?) -> String? {
        return format(origin, regex: "(\\d{4})(\\d{0,4})(\\d{0,4})", replace: "$1 $2 $3")
    }

    private static func format(_ origin: String?, regex: String, replace: String) -> String? {
        guard let origin = origin else { return nil }
        let format = origin.replacingOccurrences(of: regex,
                                                 with: replace,
                                                 options: .regularExpression,
                                                 range: Range(uncheckedBounds: (origin.startIndex, origin.endIndex)))
        return format
    }

    private static func isDomesticPhoneNumber(_ phoneNumber: String?) -> Bool {
        guard let phoneNumber = phoneNumber, phoneNumber.count < 12 else { return false }
        let regex = try? NSRegularExpression.init(pattern: "^1(3\\d|4[5-9]|5[0-35-9]|6[2567]|7[0-8]|8\\d|9[0-35-9])", options: .caseInsensitive)
        return regex?.firstMatch(in: phoneNumber, options: .reportCompletion, range: NSRange(location: 0, length: phoneNumber.count)) != nil
    }

    private static func isNumber(_ number: String?) -> Bool {
        guard let number = number else { return false }
        let regex = try? NSRegularExpression.init(pattern: "^(\\+|[0-9])[0-9]*$", options: .caseInsensitive)
        return regex?.firstMatch(in: number, options: .reportCompletion, range: NSRange(location: 0, length: number.count)) != nil
    }
}
