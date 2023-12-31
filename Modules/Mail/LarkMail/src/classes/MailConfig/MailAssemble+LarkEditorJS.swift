//
//  MailAssemble+LarkEditorJS.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/7/30.
//

import Foundation
import LarkEditorJS
import LKCommonsLogging
import LarkFeatureGating
import Swinject
import AppContainer
import RunloopTools


extension MailAssemble {
    static func configLarkEditorJSHotpatcher() {
        let resolver = BootLoader.container
        RunloopDispatcher.shared.addTask {
            // 以防万一，再解一次。
            CommonJSUtil.unzipIfNeeded()
        }.waitCPUFree()
    }
}
