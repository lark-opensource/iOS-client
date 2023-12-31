//
//  AsyncGetDomainTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation
import LarkEnv
import LarkAccountInterface

func asyncGetDomainTask(context: UniContextProtocol) -> Task<((Env, TenantBrand), DomainAliasKey), String, Error> {
    Task { info in
        return SideEffect { successCallback, failCallback in

            PassportMonitor.flush(PassportMonitorMetaMonad.asyncGetDomainStart, context: context)

            let env = info.0
            let domainKey = info.1
            ServerInfoProvider().asyncGetDomain(env.0, brand: env.1.rawValue, key: domainKey) { domainValue in
                if let domain = domainValue.value {
                    PassportMonitor.monitor(PassportMonitorMetaMonad.asyncGetDomainResult, context: context).setResultTypeSuccess()

                    successCallback(domain)
                } else {
                    PassportMonitor.monitor(PassportMonitorMetaMonad.asyncGetDomainResult, context: context).setResultTypeFail()
                    failCallback(V3LoginError.clientError("get domain failed"))
                }
            }
        }
    } rollback: { _ in
        //不需要回滚
        return SideEffect(success:())
    }
}
