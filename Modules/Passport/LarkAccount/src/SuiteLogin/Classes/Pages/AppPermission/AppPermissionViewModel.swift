//
//  AppPermissionViewModel.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/12/12.
//

import UIKit
import LarkContainer
import RxSwift

class AppPermissionViewModel: V3ViewModel {
    @Provider private var switchUserService: NewSwitchUserService
    @Provider private var loginAPI: LoginAPI

    let appPermissionInfo: AppPermissionInfo

    init(step: String, stepInfo: AppPermissionInfo, context: UniContextProtocol) {
        self.appPermissionInfo = stepInfo
        super.init(step: step, stepInfo: stepInfo, context: context)
    }

    func switchTo(userID: String) {
        switchUserService.switchTo(userID: userID, complete: nil, context: UniContextCreator.create(.appPermission))
    }

    func applyForm() -> Observable<Void> {
        return loginAPI
            .applyForm(approvalType: appPermissionInfo.approvalType,
                       appID: appPermissionInfo.targetAppID,
                       context: context)
            .post(context: context)
    }
}
