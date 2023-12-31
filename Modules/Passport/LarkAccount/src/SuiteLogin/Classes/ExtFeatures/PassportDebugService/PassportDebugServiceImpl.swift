//
//  PassportDebugServiceImpl.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/10.
//

import Foundation
import LarkAccountInterface

#if DEBUG || BETA || ALPHA

class PassportDebugServiceDebugImpl: PassportDebugService {

    func removeGlobalStoreData() {
        PassportStore.shared.removeAllData()
        PassportStore.shared.deviceID = nil
        PassportStore.shared.installID = nil
        PassportStore.shared.universalDeviceServiceUpgraded = false
        PassportGray.shared.resetData()
    }
    
}

#endif

//此处需要空实现
class PassportDebugServiceDefaultImpl: PassportDebugService {

    func removeGlobalStoreData() {}
    
}
