//
//  VerificationBaseViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/11/6.
//

import Foundation
import libPhoneNumber_iOS

public class VerificationBaseViewModel {
    static let chinaPhoneNumberRegex: String = "^[1]\\d{10}$"
    static let overseaPhoneNumberRegex: String = "^\\d{1,14}$"
    static let chinaPhoneNumberPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", chinaPhoneNumberRegex)
    static let overseaPhoneNumberPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", overseaPhoneNumberRegex)
    static let emailRegex: String = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
    static let emailPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
    private let isOversea: Bool

    public init(isOversea: Bool) {
        self.isOversea = isOversea
    }

    // MARK: - Verify Op
    func verifyPhoneNumberValidation(_ origin: String, countryCode: String? = nil) -> Bool {
        let purePhoneNumber = getPurePhoneNumber(origin)
        if purePhoneNumber.isEmpty { return false }

        if let code = countryCode {
            if code == "+86" {
                return VerificationBaseViewModel.chinaPhoneNumberPredicate.evaluate(with: purePhoneNumber)
            } else {
                return VerificationBaseViewModel.overseaPhoneNumberPredicate.evaluate(with: purePhoneNumber)
            }
        } else {
            let (code, phoneNumber) = getDisassemblePhoneNumber(content: getFixPhoneNumber(origin))
            if code == "+86" {
                return VerificationBaseViewModel.chinaPhoneNumberPredicate.evaluate(with: phoneNumber)
            } else {
                return VerificationBaseViewModel.overseaPhoneNumberPredicate.evaluate(with: phoneNumber)
            }
        }
    }

    func verifyEmailValidation(_ origin: String) -> Bool {
        let pureEmail = getPureEmail(origin)
        if pureEmail.isEmpty { return false }

        return VerificationBaseViewModel.emailPredicate.evaluate(with: pureEmail)
    }

    // MARK: - Extract Op
    func getDisassemblePhoneNumber(content: String) -> (countryCode: String, phoneNumber: String) {
        let pureNumber = getPurePhoneNumber(content)
        if pureNumber.hasPrefix("+") {
            var nationalNumber: NSString?
            let countryCode: String? = NBPhoneNumberUtil().extractCountryCode(pureNumber, nationalNumber: &nationalNumber)?.stringValue
            /// Implicit logic: extractCountryCode returns 0 means there is no correct country code
            if let code = countryCode,
                let codeNumber = Int(code),
                codeNumber > 0 {
                return ("+\(code)", pureNumber[code.count + 1..<pureNumber.count])
            } else {
                /// generate default country code
                return (defaultCountryCode(isOversea: isOversea), pureNumber)
            }
        } else {
            /// generate default country code
            return (defaultCountryCode(isOversea: isOversea), pureNumber)
        }
    }

    func getPureEmail(_ origin: String) -> String {
        let whitespace = NSCharacterSet.whitespacesAndNewlines
        return origin.trimmingCharacters(in: whitespace)
    }

    func getPurePhoneNumber(_ origin: String) -> String {
        let fixedPhoneNumber = getFixPhoneNumber(origin)
        let numberArray = fixedPhoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted)
        return origin.hasPrefix("+") ?
            "+\(numberArray.joined(separator: ""))" :
            numberArray.joined(separator: "")
    }

    func getFixPhoneNumber(_ origin: String) -> String {
        /// Prevent problems with hidden characters in the ios system
        let fixedContent = origin.replacingOccurrences(of: "\\p{Cf}", with: "", options: .regularExpression)
        return fixedContent.replacingOccurrences(of: " ", with: "", options: .regularExpression)
    }

    func defaultCountryCode(isOversea: Bool) -> String {
        if isOversea {
            return "+1"
        } else {
            return "+86"
        }
    }
}
