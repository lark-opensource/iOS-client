//
//  PassportMonitorTask.swift
//  LarkAccount
//
//  Created by bytedance on 2022/8/23.
//

import Foundation
import BootManager
import LarkEnv
import LarkAccountInterface
import ECOProbeMeta

class PassportMonitorTask: FlowBootTask, Identifiable { // user:checked (boottask)

    static var identify = "PassportMonitorTask"

    override var scheduler: Scheduler { return .concurrent }

    override func execute(_ context: BootContext) {

        guard let foregroundUser = UserManager.shared.foregroundUser else { // user:current
            return
        }
        //监控env和前台用户是否一致
        let env = EnvManager.env
        if foregroundUser.user.unit != env.unit || // user:current
           foregroundUser.user.tenant.brand != AccountServiceAdapter.shared.foregroundTenantBrand || // user:current
           foregroundUser.user.geo != env.geo { // user:current

            //上报监控
            PassportMonitor.flush(EPMClientPassportMonitorUnspecifiedCode.env_not_equal_to_foreground_user,
                                  categoryValueMap: ["env_value": "\(env.unit)_\(AccountServiceAdapter.shared.foregroundTenantBrand)_\(env.geo)", // user:current
                                                     "user_value": "\(foregroundUser.user.unit)_\(foregroundUser.user.tenant.brand.rawValue)_\(foregroundUser.user.geo)"], context: UniContextCreator.create(.unknown)) // user:current
        }

        // 监控前台用户 session 是否匿名
        if foregroundUser.isAnonymous { // user:current
            PassportMonitor.flush(PassportMonitorMetaCommon.foregroundUserIsAnonymous, // user:current
                                  eventName: ProbeConst.monitorEventName,
                                  context: UniContextCreator.create(.unknown))
        }
    }
}
