//
//  PassportDIDUpgradeTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import BootManager
import LKCommonsLogging

class PassportDIDUpgradeTask: AsyncBootTask, Identifiable { // user:checked (boottask)

    static var identify = "PassportDIDUpgradeTask"
    
    static let logger = Logger.log(PassportDIDUpgradeTask.self, category: "PassportDIDUpgradeTask")
    
    private let upgradeService =  PassportDIDUpgradeService()

    override func execute(_ context: BootContext) {
        
        let loadingVC = PassportMigrationViewController()
        context.window?.rootViewController = loadingVC
        
        upgradeService.startUpgradeSession { [weak self] result in
            //如果当前对象已经释放，不再执行
            guard let self = self else { return }
            
            //这里要异步执行，同步执行会导致结束不了任务
            DispatchQueue.main.async {
                self.end()
                NewBootManager.shared.context.blockDispatcher = false
            }
            
            switch result {
            case .success():
                Self.logger.info("n_action_uni_did_upgrade_succ")
            case .failure(let error):
                Self.logger.error("n_action_uni_did_upgrade_fail", error: error)
            }
        }
    }
}
