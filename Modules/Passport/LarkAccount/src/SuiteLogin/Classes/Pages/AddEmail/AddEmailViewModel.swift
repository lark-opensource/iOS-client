//
//  AddEmailViewModel.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/3/3.
//

import Foundation
import RxSwift
import LarkContainer
import LarkPerf

class AddEmailViewModel: V3ViewModel {
    let addMailStepInfo: AddMailStepInfo
    let inputConfig: V3InputCredentialConfig
    
    @Provider var loginAPI: LoginAPI
    
    init(step: String,
         addMailStepInfo: AddMailStepInfo,
         inputConfig: V3InputCredentialConfig,
         context: UniContextProtocol) {
        self.addMailStepInfo = addMailStepInfo
        self.inputConfig = inputConfig
        super.init(step: step, stepInfo: addMailStepInfo, context: context)
    }
    
    func addMail(_ mailAddress: String) -> Observable<Void> {
        
        Self.logger.info("n_action_add_email_req_start")
        
        let mailCredentialType: Int = 2
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.enterContact.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "login",
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        
        return loginAPI
            .loginType(serverInfo: addMailStepInfo,
                       contact: mailAddress,
                       credentialType: mailCredentialType,
                       action: 0,
                       sceneInfo: sceneInfo,
                       forceLocal: false,
                       context: context)
            .post(additionalInfo, context: context)
            .do(onNext: { _ in
                Self.logger.info("n_action_add_email_succ")
            }, onError: { (error) in
                Self.logger.error("n_action_add_email_fail", error: error)
            })
    }
}
