//
//  FileCryptoCleanTmpFileTask.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/29.
//

import UIKit
import BootManager
import LarkContainer
import LarkPreload

final class FileCryptoCleanTmpFileTask: UserFlowBootTask, Identifiable {
    
    static var identify = "FileCryptoCleanTmpFileTask"
    
    override var runOnlyOnce: Bool { true }
    
    override var scheduler: BootManager.Scheduler { .concurrent }
    
    override var triggerMonent: PreloadMoment { .startOneMinute }
    
    override func execute() throws {
        let pool = try userResolver.resolve(type: FileMigrationPool.self)
        pool.cleanExpiredMigrationFiles()
    }
}
