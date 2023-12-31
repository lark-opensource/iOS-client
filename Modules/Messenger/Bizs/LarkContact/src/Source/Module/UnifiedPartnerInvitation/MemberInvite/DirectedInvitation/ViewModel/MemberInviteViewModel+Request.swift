//
//  MemberInviteViewModel+Request.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import Foundation
import RxSwift
import struct RustPB.Contact_V1_SetAdminInvitationResponse
import struct RustPB.Contact_V1_InviteInfo
import LKMetric
import LarkFoundation

enum AddMemberFieldError {
    case phone
    case email
    case name
    case dynamic // 按照当前操作页面来决定具体是 phone 还是 email
    case other   // 需要 toast 提示

    static func transform(error: MemberInviteAPI.AddMemberError?) -> AddMemberFieldError? {
        if let error = error {
            switch error {
            case .incorrectEmail: return .email
            case .incorrectPhone: return .phone
            case .userAlreadyJoined: return .dynamic
            case .nameLengthError, .noCompliantName: return .name
            case .sendFailed, .timeout, .createLinkFailed, .permissionDeny, .unknown: return .other
            }
        }
        return nil
    }
}

struct AddMemberFieldResult {
    let isSuccess: Bool
    let needApproval: Bool
    let errorType: AddMemberFieldError?
    let errorMsg: String?
}

extension MemberInviteViewModel {
    /// 目前单次添加有且仅能提交一位联系人
    func commitAdminInviteByField(inviteInfos: [String], names: [String], inviteWay: MemberInviteAPI.InviteWay) -> Observable<AddMemberFieldResult> {
        return memberInviteAPI.sendAddMemberInviteRequest(
            timeout: 5,
            inviteInfos: inviteInfos,
            names: names,
            inviteWay: inviteWay,
            departments: departments).map { (result) -> AddMemberFieldResult in
                return AddMemberFieldResult(isSuccess: result.isSuccess,
                                            needApproval: result.needApproval,
                                            errorType: AddMemberFieldError.transform(error: result.failContexts.first?.errorType),
                                            errorMsg: result.failContexts.first?.errorMsg)
        }
    }

}
