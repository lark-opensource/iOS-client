//
//  EnterpriseCallOutViewModel.swift
//  ByteView
//
//  Created by wangpeiran on 2021/8/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Action
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker

class EnterpriseCallOutViewModel {
    var avatarInfo: AvatarInfo {
        if let avatarKey = avatarKey, !avatarKey.isEmpty {
            return .remote(key: avatarKey, entityId: "")
        } else {
            return .asset(ByteViewCommon.BundleResources.ByteViewCommon.Avatar.unknown)
        }
    }

    let userName: String
    let avatarKey: String?
    let enterprisePhoneId: String
    let chatId: String?
    let matchID: String
    let trackType: String
    let httpClient: HttpClient

    let leaveRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    init(dependency: MeetingDependency, userName: String, avatarKey: String?, enterprisePhoneId: String, chatId: String?, matchID: String, trackType: String) {
        self.httpClient = dependency.httpClient
        self.userName = userName
        self.avatarKey = avatarKey
        self.enterprisePhoneId = enterprisePhoneId
        self.chatId = chatId
        self.matchID = matchID
        self.trackType = trackType

        ServerPush.enterprisePhone.inUser(dependency.account.userId).addObserver(self) { [weak self] in
            self?.didReceiveEnterprisePhoneNotify($0)
        }
        PhoneCall.shared.addObserver(self)
    }

    func cancelCallAction() {
        let request = CancelEnterprisePhoneRequest(enterprisePhoneId: enterprisePhoneId, chatId: chatId)
        httpClient.send(request) { result in
            switch result {
            case .success:
                Logger.enterpriseCall.debug("Cancel enterprise phone success")
            case .failure(let error):
                Logger.enterpriseCall.error("Cancel enterprise phone error: \(error)")
            }
        }
    }

    private func trackEnterpriseCallSuccess(matchID: String, startType: String) {
        VCTracker.post(name: .vc_business_phone_call_status, params: ["process": "end",
                                                                      "status": "success",
                                                                      "action_match_id": matchID,
                                                                      "is_two_way_call": "true",
                                                                      "initial_tab": startType])
    }
}

extension EnterpriseCallOutViewModel {
    func didReceiveEnterprisePhoneNotify(_ message: EnterprisePhoneNotify) {
        Logger.network.debug("Enterprise call push")
        if message.action == .callExceptionToastCallerUnreached {
            EnterpriseCallToastManager.shared.showToast(i18nKey: message.callerUnreachedToastData.key, httpClient: httpClient)
        } else {
            trackEnterpriseCallSuccess(matchID: matchID, startType: trackType)
            leaveRelay.accept(true)
        }
    }
}

extension EnterpriseCallOutViewModel: PhoneCallObserver {
    func didChangePhoneCallState(from: PhoneCall.State, to: PhoneCall.State, callUUID: UUID?) {
        if [.incoming, .dialing, .connected].contains(to) {
            leaveRelay.accept(true)
        }
    }
}
