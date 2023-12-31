//
//  AppConfigImp.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/12.
//

import Foundation
import LarkAccountInterface
import SuiteAppConfig
import LarkContainer

class AppConfigImp: AppConfigProtocol {

    @InjectedLazy var appConfigService: AppConfigService // user:checked (global-resolve)

    func featureOn(for key: String) -> Bool {
        appConfigService.feature(for: key).isOn
    }
}
