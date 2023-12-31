//
//  CallOutHandler.swift
//  ByteView
//
//  Created by zfpan on 2020/9/24.
//

import Foundation
import ByteViewMeeting

class CallOutHandler: RouteHandler<CallOutBody> {

    override func handle(_ body: CallOutBody) -> UIViewController? {
        let session = body.session
        if let enterpriseCallParams = session.enterpriseCallParams, enterpriseCallParams.isEnterpriseDirectCall || enterpriseCallParams.idType == .ipPhoneNumber {
            Logger.phoneCall.info("CallOutHandler init params = \(enterpriseCallParams)")
            let handle: PhoneCallHandle
            let id = enterpriseCallParams.id
            switch enterpriseCallParams.idType {
            case .enterprisePhoneNumber:
                handle = .enterprisePhoneNumber(id)
            case .recruitmentPhoneNumber:
                handle = .recruitmentPhoneNumber(id)
            case .ipPhoneNumber:
                handle = enterpriseCallParams.calleeName?.isEmpty == false ? .ipPhoneBindLark(nil) : .ipPhone(id)
            case .candidateId:
                handle = .candidateID(id)
                Logger.phoneCall.info("CallOutHandler candidateID: \(id)")
            case .calleeUserId:
                handle = .userID(id)
                Logger.phoneCall.info("CallOutHandler userID: \(id)")
            }

            if let viewModel = EnterpriseCallViewModel(session: session, meeting: nil, handle: handle, avatarKey: enterpriseCallParams.calleeAvatarKey, userName: enterpriseCallParams.enterpriseCallUserName) {
                return EnterpriseCallPresentationViewController(viewModel: viewModel)
            }
        } else if let startCallParams = session.startCallParams, let viewModel = CallOutViewModel(session: session, isFromSecretChat: !startCallParams.secureChatId.isEmpty, isE2EeMeeting: startCallParams.isE2EeMeeting) {
            return CallOutPresentationViewController(viewModel: viewModel)
        }
        return nil
    }
}
