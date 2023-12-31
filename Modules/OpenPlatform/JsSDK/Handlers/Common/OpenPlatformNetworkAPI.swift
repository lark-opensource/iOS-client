//
//  OpenPlatformNetworkAPI.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/17.
//

import Foundation
import Swinject
import RustPB
import LarkSetting

typealias DomainSettings = RustPB.Basic_V1_DomainSettings

class OpenPlatformNetworkAPI {

    private let resolver: Resolver

    var host: String {
        let str = DomainSettingManager.shared.currentSetting[.openAppFeed]?.first ?? ""
        return "https://\(str)/"
    }

    var openDetailURL: String {
        return host + "open-apis/mina/jssdk/get-userid"
    }

    var h5VerifyUrl: String {
        return host + "open-apis/mina/jssdk/verify"
    }

    init(resolver: Resolver) {
        self.resolver = resolver
    }

}
