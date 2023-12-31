//
//  CardBindable.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
//

/// view-vm bind protocol
import UIKit
import Foundation
protocol CardBindable: UIView {
    func bindWithModel(cardInfo: InviteAggregationInfo)
}

struct MemberInviteExtraInfo {
    let inviteMsg: String
    let urlForLink: String
    let urlForQRCode: String
    let expireDateDesc: String
    let teamCode: String
    let teamLogoURL: String
    let shareToken: String
}

struct ExternalInviteData {
    let token: String
    let inviteURL: String
    let inviteMsg: String
    let uniqueID: String
}

struct ExternalInviteExtraInfo {
    let canShareLink: Bool
    let linkInviteData: ExternalInviteData
    let qrcodeInviteData: ExternalInviteData
}

struct ParentInviteExtraInfo {
    let inviteURL: String
    let inviteQrURL: String
    let expireDateDesc: String
    let inviteMsg: String
}

/// invite context info
struct InviteAggregationInfo {
    let name: String
    let tenantName: String
    let avatarKey: String
    let memberExtraInfo: MemberInviteExtraInfo?
    let externalExtraInfo: ExternalInviteExtraInfo?
    let parentExtraInfo: ParentInviteExtraInfo?

    init(name: String,
         tenantName: String,
         avatarKey: String,
         memberExtraInfo: MemberInviteExtraInfo? = nil,
         externalExtraInfo: ExternalInviteExtraInfo? = nil,
         parentExtraInfo: ParentInviteExtraInfo? = nil
    ) {
        self.name = name
        self.tenantName = tenantName
        self.avatarKey = avatarKey
        self.memberExtraInfo = memberExtraInfo
        self.externalExtraInfo = externalExtraInfo
        self.parentExtraInfo = parentExtraInfo
    }

    static func emptyInviteInfo() -> InviteAggregationInfo {
        return InviteAggregationInfo(name: "",
                                     tenantName: "",
                                     avatarKey: "")
    }
}
