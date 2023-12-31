//
//  AddressBookContact.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/26.
//

import Foundation
import Contacts
import UIKit

public final class AddressBookContact: Equatable {
    public let identifier: String
    public let firstName: String
    public let lastName: String
    public let phoneNumber: String?
    public let email: String?
    public let pinyinHead: String
    public let thumbnailProfileImage: UIImage?
    public let countryCode: String
    public let fullName: String
    public var contactPointType: ContactPointType = .phone

    public init(
        firstName: String,
        lastName: String,
        phoneNumber: String?,
        email: String?,
        pinyinHead: String,
        thumbnailProfileImage: UIImage?,
        countryCode: String,
        identifier: String
        ) {
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.pinyinHead = pinyinHead
        self.thumbnailProfileImage = thumbnailProfileImage
        self.countryCode = countryCode
        self.identifier = identifier
        self.fullName = AddressBookContact.fullName(firstName, lastName)
    }

    public static func == (lhs: AddressBookContact, rhs: AddressBookContact) -> Bool {
        return lhs.email == rhs.email
            && lhs.phoneNumber == rhs.phoneNumber
            && lhs.firstName == rhs.firstName
            && lhs.lastName == rhs.lastName
            && lhs.identifier == rhs.identifier
    }

    private static func fullName(_ firstName: String, _ lastName: String) -> String {
        if isLetterString(firstName), isLetterString(lastName) {
             return "\(lastName) \(firstName)"
        } else {
             return "\(firstName)\(lastName)"
        }
    }

    private static func isLetterString(_ str: String) -> Bool {
        let noWhitespace = str.replacingOccurrences(of: " ", with: "")
        guard !noWhitespace.isEmpty else {
            return false
        }

        var result = true
        for ch in noWhitespace {
            result = result && (isLetter(ch) || ch.isWhitespace)
            if !result {
                break
            }
        }
        return result
    }

    private static func isLetter(_ ch: Character) -> Bool {
        return ch >= "A" && ch <= "z"
    }
}
