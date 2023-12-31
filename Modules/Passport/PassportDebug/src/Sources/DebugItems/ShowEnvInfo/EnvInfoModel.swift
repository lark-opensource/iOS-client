//
//  EnvInfoModel.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/22.
//

import Foundation
import LarkEnv
import LarkContainer
import LarkAccountInterface


final class EnvInfoModel {
    @Provider var account: AccountService
    
    private var items: [EnvInfo] = []
    
    func getNewInfo() -> String {
        return items.reduce("", { $0 + $1.name + ($1.getNewDescription() ?? "") + "\n" })
    }
    
    init() {
        let updateIsLogin = { [weak self] () -> String in
            let text: String
            if let user = self?.account.foregroundUser {
                return "true"
            } else {
                return "false"
            }
        }
        let updateEnvType = { () -> String in
            let type: Env.TypeEnum = EnvManager.env.type
            let text: String
            switch type {
            case .release:
                return "release"
            case .staging:
                return "staging"
            case .preRelease:
                return "preRelease"
            }
        }
        let updateUserUnit = { [weak self] () -> String in
            return self?.account.foregroundUserUnit ?? ""
        }
        let updateTenantBrand = { [weak self] () -> String in
            if self?.account.isFeishuBrand ?? true {
                return "feishu"
            } else {
                return "lark"
            }
        }
        let updateGeo = { [weak self] () -> String in
            return self?.account.foregroundUserGeo ?? ""
        }

        let updateTenantGeo = { [weak self] () -> String in
            return self?.account.foregroundTenant?.tenantGeo ?? ""
        }
        
        items.append(EnvInfo(name: "isLogin: ", getNewDescription: updateIsLogin))
        items.append(EnvInfo(name: "envType: ", getNewDescription: updateEnvType))
        items.append(EnvInfo(name: "userUnit: ", getNewDescription: updateUserUnit))
        items.append(EnvInfo(name: "tenantBrand: ", getNewDescription: updateTenantBrand))
        items.append(EnvInfo(name: "geo: ", getNewDescription: updateGeo))
        items.append(EnvInfo(name: "tenantGeo: ", getNewDescription: updateTenantGeo))

    }
    
}

struct EnvInfo {
    let name: String
    let getNewDescription: () -> String
}
