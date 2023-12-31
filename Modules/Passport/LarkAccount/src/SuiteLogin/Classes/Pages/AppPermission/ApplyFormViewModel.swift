//
//  ApplyFormViewModel.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/12/12.
//

import LarkContainer
import RxSwift

class ApplyFormViewModel: V3ViewModel {

    @Provider private var loginAPI: LoginAPI

    let applyFormInfo: ApplyFormInfo

    init(step: String, stepInfo: ApplyFormInfo, context: UniContextProtocol) {
        self.applyFormInfo = stepInfo
        super.init(step: step, stepInfo: stepInfo, context: context)
    }

    func submit(reason: String) -> Observable<Void> {
        loginAPI
            .submitForm(approvalType: applyFormInfo.approvalType,
                        appID: applyFormInfo.appInfo.appID,
                        approvalCode: applyFormInfo.approvalCode,
                        approvalUserIDList: applyFormInfo.reviewers.map { $0.userID },
                        form: [
                            [
                                "id" : "approval_app_id",
                                "type" : "input",
                                "value" : applyFormInfo.appInfo.appID,
                            ],
                            [
                                "id" : "approval_app_name",
                                "type" : "input",
                                "value" : applyFormInfo.appInfo.appName,
                            ],
                            [
                                "id" : "approval_reason",
                                "type" : "input",
                                "value" : reason.trimmingCharacters(in: .whitespacesAndNewlines),
                            ]
                        ],
                        context: context)
            .post(context: context)
    }
}
