//
//  Userprofile.swift
//  LarkModel
//
//  Created by 姚启灏 on 2021/9/9.
//

import Foundation
import RustPB
import SwiftProtobuf

public enum UserProfileField {
    case cAlias(RustPB.Contact_V2_GetUserProfileResponse.Text)
    case link(RustPB.Contact_V2_GetUserProfileResponse.Href)
    case linkList(RustPB.Contact_V2_GetUserProfileResponse.HrefList)
    case sDepartment(RustPB.Contact_V2_GetUserProfileResponse.Department)
    case sFriendLink(RustPB.Contact_V2_GetUserProfileResponse.Href)
    case sPhoneNumber(RustPB.Contact_V2_GetUserProfileResponse.PhoneNumber)
    case text(RustPB.Contact_V2_GetUserProfileResponse.Text)
    case textList(RustPB.Contact_V2_GetUserProfileResponse.TextList)
    case unknow

    public static func transformPB(type: UserProfileField) -> RustPB.Contact_V2_GetUserProfileResponse.Field.FieldType {
        switch type {
        case .cAlias:
            return .cAlias
        case .link:
            return .link
        case .linkList:
            return .linkList
        case .sDepartment:
            return .sDepartment
        case .sFriendLink:
            return .sFriendLink
        case .sPhoneNumber:
            return .sPhoneNumber
        case .text:
            return .text
        case .textList:
            return .textList
        case .unknow:
            return .unknown
        default:
            return .unknown
        }
    }

    public func transformPB() -> RustPB.Contact_V2_GetUserProfileResponse.Field.FieldType {
        switch self {
        case .cAlias:
            return .cAlias
        case .link:
            return .link
        case .linkList:
            return .linkList
        case .sDepartment:
            return .sDepartment
        case .sFriendLink:
            return .sFriendLink
        case .sPhoneNumber:
            return .sPhoneNumber
        case .text:
            return .text
        case .textList:
            return .textList
        case .unknow:
            return .unknown
        default:
            return .unknown
        }
    }
}

public extension RustPB.Contact_V2_GetUserProfileResponse {
    func getFields() -> [UserProfileField] {
        var fields: [UserProfileField] = []

        for field in self.fieldOrders {
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true

            switch field.fieldType {
            case .cAlias:
                if let text = try? RustPB.Contact_V2_GetUserProfileResponse.Text(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.cAlias(text))
                }
            case .link:
                if let link = try? RustPB.Contact_V2_GetUserProfileResponse.Href(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.link(link))
                }
            case .linkList:
                if let hrefList = try? RustPB.Contact_V2_GetUserProfileResponse.HrefList(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.linkList(hrefList))
                }
            case .sDepartment:
                if let departments = try? RustPB.Contact_V2_GetUserProfileResponse.Department(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.sDepartment(departments))
                }
            case .sFriendLink:
                if let link = try? RustPB.Contact_V2_GetUserProfileResponse.Href(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.link(link))
                }
            case .sPhoneNumber:
                if let phoneNumber = try? RustPB.Contact_V2_GetUserProfileResponse.PhoneNumber(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.sPhoneNumber(phoneNumber))
                }
            case .text:
                if let text = try? RustPB.Contact_V2_GetUserProfileResponse.Text(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.text(text))
                }
            case .textList:
                if let textList = try? RustPB.Contact_V2_GetUserProfileResponse.TextList(jsonString: field.jsonFieldVal,
                                                                                         options: options) {
                    fields.append(.textList(textList))
                }
            @unknown default:
                fields.append(.unknow)
            }
        }

        return fields
    }
}

public struct GetUserProfileField {
    public static func getFields(responseFileds: [RustPB.Contact_V2_GetUserProfileResponse.Field]) -> [UserProfileField] {
        var fields: [UserProfileField] = []
        for field in responseFileds {
            var options = JSONDecodingOptions()
            options.ignoreUnknownFields = true

            switch field.fieldType {
            case .cAlias:
                if let text = try? RustPB.Contact_V2_GetUserProfileResponse.Text(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.cAlias(text))
                }
            case .link:
                if let link = try? RustPB.Contact_V2_GetUserProfileResponse.Href(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.link(link))
                }
            case .linkList:
                if let hrefList = try? RustPB.Contact_V2_GetUserProfileResponse.HrefList(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.linkList(hrefList))
                }
            case .sDepartment:
                if let departments = try? RustPB.Contact_V2_GetUserProfileResponse.Department(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.sDepartment(departments))
                }
            case .sFriendLink:
                if let link = try? RustPB.Contact_V2_GetUserProfileResponse.Href(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.link(link))
                }
            case .sPhoneNumber:
                if let phoneNumber = try? RustPB.Contact_V2_GetUserProfileResponse.PhoneNumber(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.sPhoneNumber(phoneNumber))
                }
            case .text:
                if let text = try? RustPB.Contact_V2_GetUserProfileResponse.Text(jsonString: field.jsonFieldVal, options: options) {
                    fields.append(.text(text))
                }
            case .textList:
                if let textList = try? RustPB.Contact_V2_GetUserProfileResponse.TextList(jsonString: field.jsonFieldVal,
                                                                                         options: options) {
                    fields.append(.textList(textList))
                }
            @unknown default:
                fields.append(.unknow)
            }
        }
        return fields
    }
}
