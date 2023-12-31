//
//  MailAfterLoginStageTask.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/7/7.
//

import Foundation
import BootManager
import RunloopTools
import LarkPerf
import LarkContainer
import MailSDK
import LarkAccountInterface
import LarkFeatureGating
import LKCommonsLogging
import LKLoadable
import AppContainer
import RxSwift

/// 正常情况下，执行时机依然是AfterLogin，对于低端机会进行
class SetupMaiDelayableTask: UserFlowBootTask, Identifiable {
    static var identify: TaskIdentify = "SetupMaiDelayableTask"
    let disposeBag = DisposeBag()

    override var isLazyTask: Bool { return true } // 这里面的内容允许在必要时候放到delay执行。

    override var scope: Set<BizScope> {
        return [.mail]
    }

    let logger = Logger.log(SetupMaiDelayableTask.self, category: "Module.Mail")

    override class var compatibleMode: Bool { MailUserScope.userScopeCompatibleMode }

    override func execute(_ context: BootContext) {
        // from AccountLoaded
        MailAssemble.configLarkEditorJSHotpatcher()
    }
}
