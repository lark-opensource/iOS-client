//
//  LarkPSDAServiceImpl.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/1/17.
//

import LarkSecurityComplianceInfra
import LarkSnCService
import LarkContainer

final class LarkPSDAServiceImpl: SnCService {
    let client: LarkSnCService.HTTPClient? = HTTPClientImp()
    let storage: Storage?
    let logger: LarkSnCService.Logger?
    let tracker: LarkSnCService.Tracker? = TrackerImpl()
    let monitor: LarkSnCService.Monitor? = MonitorImpl(business: .psda)
    let settings: LarkSnCService.Settings?
    let environment: Environment? = EnvironmentImpl()

    init(category: String) {
        logger = LoggerImpl(category: category)
        storage = SCStorageImpl(category: .sensitivityControl)
        settings = SettingsImpl()
    }
}
