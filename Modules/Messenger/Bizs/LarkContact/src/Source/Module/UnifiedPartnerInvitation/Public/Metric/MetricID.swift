//
//  MetricID.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/29.
//

import Foundation

enum MetricID {
    enum InternalOrientation: Int32 {
        case inviteSuccess = 1
        case inviteFailed = 2
    }

    enum InternalNonDirectional: Int32 {
        case getInviteInfoSuccess = 1
        case getInviteInfoFailed = 2
        case refreshInviteInfoSuccess = 3
        case refreshInviteInfoFailed = 4
        case loadQrCodeSuccess = 11
        case loadQrCodeFailed = 12
        case shareQrCodeSuccess = 13
        case shareQrCodeFailed = 14
        case saveQrCodePermissionSuccess = 15
        case saveQrCodePermissionFailed = 16
        case copyLinkSuccess = 21
        case shareLinkSuccess = 23
        case shareLinkFailed = 24
        case copyTeamCodeSuccess = 31
        case shareTeamCodeSuccess = 32
        case shareTeamCodeFailed = 33
    }

    enum ExternalOrientation: Int32 {
        case inviteSuccess = 1
        case inviteFailed = 2
    }

    enum ExternalNonDirectional: Int32 {
        case getInviteInfoSuccess = 1
        case getInviteInfoFailed = 2
        case loadQrCodeSuccess = 11
        case loadQrCodeFailed = 12
        case shareQrCodeSuccess = 13
        case shareQrCodeFailed = 14
        case saveQrCodePermissionSuccess = 15
        case saveQrCodePermissionFailed = 16
        case copyLinkSuccess = 21
        case shareLinkSuccess = 23
        case shareLinkFailed = 24
    }

    enum Contacts: Int32 {
        case getContactsPermissionSuccess = 1
        case getContactsPermissionFailed = 2
        case loadContacts = 5
    }

}
