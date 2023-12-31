//
//  LKMetric+Invitation.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/29.
//

import Foundation
import LKMetric

extension LKMetric {
    typealias IO = InternalOrientation
    typealias IN = InternalNonDirectional
    typealias EO = ExternalOrientation
    typealias EN = ExternalNonDirectional
    typealias C = Contacts

    enum InternalOrientation {
        static func logInviteSuccess(loadCost: Int64) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.orientation),
                         type: .business,
                         id: MetricID.InternalOrientation.inviteSuccess.rawValue,
                         emitType: .timer,
                         emitValue: loadCost)
        }

        static func logInviteFailed(buzErrorCode: Int32) {
            let errorParams: [String: String] = [MetricConst.errorCode: String(buzErrorCode),
                                                 MetricConst.errorMsg: MetricParams.errorMsg(buzErrorCode)]
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.orientation),
                         type: .business,
                         id: MetricID.InternalOrientation.inviteFailed.rawValue,
                         emitType: .counter,
                         params: errorParams)
        }

        static func logInviteFailed(error: Error) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.orientation),
                         type: .business,
                         id: MetricID.InternalOrientation.inviteFailed.rawValue,
                         emitType: .counter,
                         error: error)
        }
    }

    enum InternalNonDirectional {
        static func getInviteInfoSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.getInviteInfoSuccess.rawValue,
            emitType: .counter)
        }

        static func getInviteInfoFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.getInviteInfoFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }

        static func refreshInviteInfoSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.refreshInviteInfoSuccess.rawValue,
            emitType: .counter)
        }

        static func refreshInviteInfoFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.refreshInviteInfoFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }

        static func saveQrCodePermissionSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.saveQrCodePermissionSuccess.rawValue,
            emitType: .counter)
        }

        static func saveQrCodePermissionFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.saveQrCodePermissionFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }

        static func copyLinkSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.copyLinkSuccess.rawValue,
            emitType: .counter)
        }

        static func copyTeamCodeSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.copyTeamCodeSuccess.rawValue,
            emitType: .counter)
        }
    }

    enum ExternalOrientation {
        static func inviteSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.external).s(External.orientation),
            type: .business,
            id: MetricID.ExternalOrientation.inviteSuccess.rawValue,
            emitType: .counter)
        }

        static func inviteFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.external).s(External.orientation),
            type: .business,
            id: MetricID.ExternalOrientation.inviteFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }
    }

    enum ExternalNonDirectional {
        static func getInviteInfoSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.external).s(External.nonDirectional),
            type: .business,
            id: MetricID.ExternalNonDirectional.getInviteInfoSuccess.rawValue,
            emitType: .counter)
        }

        static func getInviteInfoFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.external).s(External.nonDirectional),
            type: .business,
            id: MetricID.ExternalNonDirectional.getInviteInfoFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }

        static func loadQrCodeSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.external).s(External.nonDirectional),
            type: .business,
            id: MetricID.ExternalNonDirectional.loadQrCodeSuccess.rawValue,
            emitType: .counter)
        }

        static func loadQrCodeFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.external).s(External.nonDirectional),
            type: .business,
            id: MetricID.ExternalNonDirectional.loadQrCodeFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }

        static func saveQrCodePermissionSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.saveQrCodePermissionSuccess.rawValue,
            emitType: .counter)
        }

        static func saveQrCodePermissionFailed(errorMsg: String) {
            LKMetric.log(domain: Root.invite.s(Invitation.invite).s(Invite.interal).s(Internal.nonDirectional),
            type: .business,
            id: MetricID.InternalNonDirectional.saveQrCodePermissionFailed.rawValue,
            emitType: .counter,
            params: [MetricConst.errorMsg: errorMsg])
        }
    }

    enum Contacts {
        static func getContactsPermissionSuccess() {
            LKMetric.log(domain: Root.invite.s(Invitation.contacts),
            type: .business,
            id: MetricID.Contacts.getContactsPermissionSuccess.rawValue,
            emitType: .counter)
        }

        static func getContactsPermissionFailed() {
            LKMetric.log(domain: Root.invite.s(Invitation.contacts),
            type: .business,
            id: MetricID.Contacts.getContactsPermissionFailed.rawValue,
            emitType: .counter)
        }

        static func loadContacts(loadCost: Int64) {
            LKMetric.log(domain: Root.invite.s(Invitation.contacts),
                         type: .business,
                         id: MetricID.Contacts.loadContacts.rawValue,
                         emitType: .timer,
                         emitValue: loadCost)
        }
    }
}
