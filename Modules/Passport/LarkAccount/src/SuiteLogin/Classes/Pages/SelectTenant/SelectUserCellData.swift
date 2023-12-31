//
//  SelectUserCellData.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/2.
//

import Foundation

struct SelectUserCellData {
    let userId: String
    let tenantId: String
    let type: V4UserItem.ItemType
    let userName: String?
    let tenantName: String?
    let iconUrl: String
    let tag: String?
    let status: Int?
    let enableBtnInfo: V4ButtonInfo?
    let excludeLogin: Bool
    var canEdit: Bool = false
    var isSelected: Bool = false
    let isValid: Bool
    let isCertificated: Bool
    
    var isInReview: Bool {
        return V4UserItem.getStatus(from: status) == .reviewing
    }

    var defaultIcon: UIImage {
        return Resource.V3.default_avatar
    }

    init(
        userId: String,
        tenantId: String,
        type: V4UserItem.ItemType,
        userName: String?,
        iconUrl: String,
        tenantName: String?,
        status: Int?,
        enableBtnInfo: V4ButtonInfo?,
        excludeLogin: Bool,
        tag: String?,
        isValid: Bool,
        isCertificated: Bool
    ) {
        self.userId = userId
        self.tenantId = tenantId
        self.type = type
        self.userName = userName
        self.iconUrl = iconUrl
        self.tenantName = tenantName
        self.tag = tag
        self.status = status
        self.enableBtnInfo = enableBtnInfo
        self.excludeLogin = excludeLogin
        self.isValid = isValid
        self.isCertificated = isCertificated
    }

    static func placeholder() -> SelectUserCellData {
        return SelectUserCellData(
            userId: "0",
            tenantId: "0",
            type: .normal,
            userName: "",
            iconUrl: "",
            tenantName: "",
            status: nil,
            enableBtnInfo: V4ButtonInfo.placeholder,
            excludeLogin: false,
            tag: nil,
            isValid: false,
            isCertificated: false
        )
    }
}

extension SelectUserCellData: CustomStringConvertible, LogDesensitize {
    struct Const {
        static let itemType: String = "itemType"
        static let tag: String = "tag"
        static let status: String = "status"
        static let empty: String = "empty"
    }

    var description: String {
        return "\(desensitize())"
    }

    func desensitize() -> [String: String] {
        let tagValue: String
        if let t = tag {
            tagValue = t
        } else {
            tagValue = Const.empty
        }
        let statusValue: String
        if let status = status {
            statusValue = "\(status)"
        } else {
            statusValue = Const.empty
        }
        return [
            Const.itemType: "\(type)",
            Const.tag: tagValue,
            Const.status: statusValue
        ]
    }
}

extension V4UserItem {
    func toCellData() -> SelectUserCellData {
        return SelectUserCellData(
            userId: user.id,
            tenantId: user.tenant.id,
            type: type ?? .normal,
            userName: user.getCurrentLocalDisplayName(),
            iconUrl: user.tenant.iconURL,
            tenantName: user.tenant.getCurrentLocalName(),
            status: user.status.rawValue,
            enableBtnInfo: button,
            excludeLogin: user.excludeLogin ?? false,
            tag: tagDesc,
            isValid: isValid,
            isCertificated: user.tenant.isCertificated ?? false
        )
    }
}
