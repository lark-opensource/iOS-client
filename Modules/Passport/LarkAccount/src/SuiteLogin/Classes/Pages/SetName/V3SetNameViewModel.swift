//
//  V3SetNameViewModel.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/1.
//

import Foundation
import RxSwift
import LarkContainer

class V3SetNameViewModel: V3ViewModel {

    let setNameInfo: V4SetNameInfo

    @Provider var api: LoginAPI

    init(
        step: String,
        setNameInfo: V4SetNameInfo,
        context: UniContextProtocol
    ) {
        self.setNameInfo = setNameInfo
        super.init(step: step, stepInfo: setNameInfo, context: context)
    }

    var userName: String = ""

    func setName(name: String, optIn: Bool) -> Observable<()> {
        // 当服务端 show_opt_in 为 false 的时候，不传 optIn
        let optInResult = setNameInfo.showOptIn ? optIn : nil
        Self.logger.info("n_action_set_name_req",
                         additionalData: ["show_opt_in": setNameInfo.showOptIn,
                                          "opt_in_checked": "\(optInResult)"])
        PassportMonitor.flush(PassportMonitorMetaStep.setNameCommitResult,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: self.setNameInfo.flowType],
                              context: self.context)
        let startTime = Date()
        return api
            .setName(
                serverInfo: setNameInfo,
                name: name,
                optIn: optInResult,
                context: context
            )
            .post(additionalInfo, context: context)
            .do(onNext: {[weak self] _ in
                guard let self = self else { return }
                Self.logger.info("n_action_set_name_succ")
                PassportMonitor.monitor(PassportMonitorMetaStep.setNameCommitResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.setNameInfo.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.context)
                .setResultTypeSuccess()
                .flush()
            }, onError: {[weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("n_action_set_name_error")
                PassportMonitor.monitor(PassportMonitorMetaStep.setNameCommitResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.setNameInfo.flowType],
                                              context: self.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
            })
    }
}

extension V3SetNameViewModel {
    var title: String {
        return setNameInfo.title
    }

    var subtitle: NSAttributedString {
        return attributedString(for: setNameInfo.subtitle ?? "")
    }

    var showOptIn: Bool {
        return setNameInfo.showOptIn
    }

    var optTitle: String {
        return setNameInfo.optTitle
    }

    var placeholderName: String? {
        if let placeholder = setNameInfo.nameInput?.placeholder {
            return placeholder
        } else {
            return I18N.Lark_Login_V3_Set_Name_Hint
        }
    }

    var nextButtonText: String {
        if let next = setNameInfo.nextButton?.text {
            return next
        } else {
            return I18N.Lark_Login_V3_Input_Tenant_Code_Next
        }
    }

    var isSingleInput: Bool {
        nameInputs.count == 1
    }

    var nameInputs: [InputInfo] {
        if (setNameInfo.nameType ?? .single) == .single, let nameInput = setNameInfo.nameInput {
            return [nameInput]
        } else {
            return setNameInfo.larkNameInput ?? []
        }
    }
}
