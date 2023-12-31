//
//  MailAddress.swift
//  MailSDK
//
//  Created by majx on 2019/8/13.
//

import Foundation
import RustPB

public struct MailAddress {
    var name: String
    var address: String
    var larkID: String = ""
    var tenantId: String = ""
    var displayName: String = ""
    var type: ContactType?

    var mailDisplayName: String {
        return displayName.isEmpty ? name : displayName
    }

    public init(name: String, address: String, larkID: String, tenantId: String, displayName: String, type: ContactType?) {
        self.name = name
        self.address = address
        self.larkID = larkID
        self.tenantId = tenantId
        self.displayName = displayName
        self.type = type
    }

    public init(with clientAddress: MailClientAddress) {
        var type: ContactType = .unknown
        switch clientAddress.larkEntityType {
        case .user:
            type = .chatter
        case .group:
            type = .group
        case .enterpriseMailGroup:
            type = .enterpriseMailGroup
        case .sharedMailbox:
            type = .sharedMailbox
        @unknown default:
            break
        }
        self.init(
            name: clientAddress.name,
            address: clientAddress.address,
            larkID: clientAddress.larkEntityIDString,
            tenantId: clientAddress.tenantID,
            displayName: clientAddress.displayName,
            type: type)
    }
}

extension MailAddress {
    func toPBModel() -> MailClientAddress {
        var clientAddress = MailClientAddress()
        clientAddress.name = name
        clientAddress.address = address
        clientAddress.larkEntityIDString = larkID
        if let type = self.type {
            switch type {
            case .chatter:
                clientAddress.larkEntityType = .user
            case .group:
                clientAddress.larkEntityType = .group
            case .enterpriseMailGroup:
                clientAddress.larkEntityType = .enterpriseMailGroup
            case .sharedMailbox:
                clientAddress.larkEntityType = .sharedMailbox
            @unknown default:
                break
            }
        }
        clientAddress.displayName = displayName
        clientAddress.tenantID = tenantId
        return clientAddress
    }
}

extension MailAddress: Equatable {
    public static func == (lhs: MailAddress, rhs: MailAddress) -> Bool {
        /// if address or larkID is same, return true
        if lhs.address != rhs.address { return false }
        return true
    }
}
