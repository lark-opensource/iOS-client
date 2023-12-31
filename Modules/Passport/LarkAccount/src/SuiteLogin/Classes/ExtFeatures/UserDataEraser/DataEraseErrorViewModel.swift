//
//  DataEraseErrorViewModel.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/5.
//

import Foundation
import UniverseDesignEmpty

class DataEraseErrorRebootViewModel: PassportEmptyViewModel {

    let cancelCallback: ()->Void

    init(cancelCallback: @escaping ()->Void ) {
        self.cancelCallback = cancelCallback
        super.init(type: .error, title: I18N.Lark_ClearLocalCacheAtLogOut_ClearFailureTitle, subTitle: I18N.Lark_ClearLocalCacheAtLogOut_ErrorRestartToTryAgainDescrip, primaryButtonTitle: I18N.Lark_ClearLocalCacheAtLogOut_RestartButton, secondaryButtonTitle: I18N.Lark_Login_Cancel)
    }

    override func handlePrimaryButtonAction() {
        //监控
        PassportMonitor.delayFlush(PassportMonitorMetaEraseData.eraser_retry,
                              eventName: ProbeConst.monitorEventName,
                              context: UniContextCreator.create(.eraseData))
        exit(0)
    }

    override func handleSecondaryButtonAction() {
        UserDataEraserHelper.shared.cancelEraseTask()
        cancelCallback()
    }

}

class DataEraseErrorResetViewModel: PassportEmptyViewModel {

    let resetCallback: ()->Void

    let cancelCallback: ()->Void

    init(resetCallback: @escaping ()->Void, cancellCallback: @escaping ()->Void) {
        self.resetCallback = resetCallback
        self.cancelCallback = cancellCallback
        super.init(type: .error, title: I18N.Lark_ClearLocalCacheAtLogOut_ClearFailureTitle, subTitle: I18N.Lark_ClearLocalCacheAtLogOut_ErrorResetToTryAgainDescrip, primaryButtonTitle: I18N.Lark_ClearLocalCacheAtLogOut_REsetButton, secondaryButtonTitle: I18N.Lark_Login_Cancel)
    }

    override func handlePrimaryButtonAction() {
        resetCallback()
    }

    override func handleSecondaryButtonAction() {
        UserDataEraserHelper.shared.cancelEraseTask()
        cancelCallback()
    }
}

class DataResetFinishViewModel: PassportEmptyViewModel {

    init() {
        super.init(type: .done, title: I18N.Lark_ClearLocalCacheAtLogOut_DataRecoveredTitle, subTitle: I18N.Lark_ClearLocalCacheAtLogOut_RecoveredCloseAndRestartDescrip + "\n" + I18N.Lark_ClearLocalCacheAtLogOut_AnyQContactSupportDescrip, primaryButtonTitle: I18N.Lark_ClearLocalCacheAtLogOut_CloseAppButton, secondaryButtonTitle: nil)
    }

    override func handlePrimaryButtonAction() {
        exit(0)
    }
}


