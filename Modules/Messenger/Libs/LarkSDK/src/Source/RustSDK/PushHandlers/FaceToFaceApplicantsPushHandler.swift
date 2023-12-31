//
//  FaceToFaceApplicantsPushHandler.swift
//  LarkSDK
//
//  Created by 赵家琛 on 2021/1/5.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class FaceToFaceApplicantsPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushFaceToFaceApplicants) {
        self.pushCenter?.post(
            PushFaceToFaceApplicants(
                applicationId: message.applicationID,
                applicants: message.applicants
            )
        )
    }
}
