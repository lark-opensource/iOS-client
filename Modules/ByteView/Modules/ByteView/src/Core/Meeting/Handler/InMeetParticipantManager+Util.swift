//
//  InMeetParticipantManager+Util.swift
//  ByteView
//
//  Created by wulv on 2023/3/29.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon

extension InMeetParticipantManager {

    func inviteUsers(userIds: [String] = [], roomIds: [String] = [], pstnInfos: [PSTNInfo] = [],
                     source: InviteVideoChatRequest.InviteType = .unknown,
                     completion: ((Result<InviteVideoChatResponse, Error>) -> Void)? = nil) {
        let sum = userIds.count + roomIds.count + pstnInfos.count
        let request = InviteVideoChatRequest(meetingId: meetingId, userIds: userIds, roomIds: roomIds, pstnInfos: pstnInfos, source: source)
        httpClient.getResponse(request) { [weak self] result in
            switch result {
            case .success(let resp):
                if source == .suggestList, resp.failedCount > 0 {
                    // 请求成功，但有邀请失败的人
                    if resp.failedCount < sum {
                        // 部分失败
                        VCTracker.post(name: .vc_meeting_onthecall_popup_view,
                                       params: [.content: "calling_failed", "fail_type": "part_fail", "fail_num": resp.failedCount])
                    } else {
                        // 全部失败
                        VCTracker.post(name: .vc_meeting_onthecall_popup_view,
                                       params: [.content: "calling_failed", "fail_type": "all_fail", "fail_num": resp.failedCount])
                    }
                }
            case .failure(let error):
                if source == .suggestList {
                    // 请求失败
                    VCTracker.post(name: .vc_meeting_onthecall_popup_view,
                                   params: [.content: "calling_failed", "fail_type": "all_fail", "fail_num": -99]) // -99表示人数未知
                } else {
                    // 单呼失败
                    VCTracker.post(name: .vc_meeting_onthecall_popup_view,
                                   params: [.content: "calling_failed", "fail_type": "one_person", "fail_num": 1])
                }
                let vcError = error.toVCError()
                if vcError == .newHitRiskControl, let monitor = vcError.rustError?.msgInfo?.monitor {
                    VCTracker.post(name: .vc_tns_intive_cross_border_view, params: [
                        .request_id: monitor.logID,
                        "invite_type": pstnInfos.isEmpty ? "1" : "2",
                        "owner_tenant_id": monitor.ownerTenantID
                    ])
                }
                if let self = self, let phoneNumber = pstnInfos.first?.mainAddress {
                    PhoneCallUtil.handleInviteError(error, phoneNumber: phoneNumber, dependency: self.service.currentMeetingDependency())
                }
            }
            completion?(result)
        }
    }

    /// 邀请用户电话入会
    func invitePSTN(userId: String, name: String, mainAddress: String? = nil) {
        func customToast(_ text: String) {
            let size = CGSize(width: 20, height: 20)
            let image = UDIcon.getIconByKey(.moreCloseOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.9), size: size)
            Toast.show(.richText(image, size, text))
        }

        func trackToast(_ name: String) {
            VCTracker.post(name: .vc_toast_status, params: ["toast_name": name])
        }

        var info = PSTNInfo(participantType: .pstnUser, mainAddress: mainAddress ?? "", displayName: name)
        info.bindId = userId
        info.bindType = .lark
        inviteUsers(pstnInfos: [info]) { result in
            guard let error = result.error else { return }
            Logger.meeting.info("convenience invite pstn fail error = \(error)")
            let vcError = error.toVCError()
            switch vcError {
            case .serverInternalError:
                // 电话时长已达上限，走通用错误处理 RustHandledError
                trackToast("call_length_reached_limit")
            case .pstnInviteNoPhonePermission:
                // 管理员已设置电话号码管控，无法电话呼叫 RCError
                customToast(vcError.description)
                trackToast("number_control")
            case .noPermissionToInvite:
                // 主持人已设置入会权限，暂不支持邀请用户入会，走通用错误处理 RustHandledError
                trackToast("no_permission_to_invite")
            case .pstnInviteNoPhoneNumber:
                // 该用户类型暂不支持电话呼叫 RCError
                customToast(vcError.description)
                trackToast("unable_call_user_type")
            case .PhonePermissionError:
                // 权限校验不通过
                Toast.show(I18n.View_MV_CallFailCantCallOthers_AdminSetToast, type: .error, duration: 6)
                trackToast("admin_set_no_auth_phone")
            default:
                break
            }
        }
    }
}
