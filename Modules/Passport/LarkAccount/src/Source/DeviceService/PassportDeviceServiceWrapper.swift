//
//  PassportDeviceService.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import LarkAccountInterface
import RxSwift
import LKCommonsLogging
import LarkEnv

class PassportDeviceServiceWrapper {
    
    static let logger = Logger.log(PassportDeviceServiceWrapper.self, category: "PassportDeviceServiceWrapper")
    
    public static let shared = PassportDeviceServiceWrapper()
    
    private var internalDeviceService: InternalDeviceServiceProtocol & PassportGlobalDeviceService
    //升级过程中assert 获取did等调用
    public var blockMode: Bool = false
    
    init(){
        if PassportStore.shared.universalDeviceServiceUpgraded {
            self.internalDeviceService = PassportUniversalDeviceService.shared
        } else {
            self.internalDeviceService = RangersAppLogDeviceServiceImpl.shared
        }
    }
    
    public func switchToUniversalDeviceService() {
        self.internalDeviceService = PassportUniversalDeviceService.shared
        PassportStore.shared.universalDeviceServiceUpgraded = true
        
        Self.logger.info("n_action_switch_to_uni_did_service")
    }
    
    public func switchToRangersDeviceService() {
        self.internalDeviceService = RangersAppLogDeviceServiceImpl.shared
        PassportStore.shared.universalDeviceServiceUpgraded = false
        
        Self.logger.info("n_action_switch_to_ranger_did_service")
    }
    
    public func makePackageDeviceInfoUniversal() -> Bool{
        let packageUnit = EnvManager.getPackageEnv().unit
        let deviceId = PassportStore.shared.getDeviceID(unit: packageUnit) ?? ""
        let installId = PassportStore.shared.getInstallID(unit: packageUnit) ?? ""
        if DeviceInfo.isDeviceIDValid(deviceId),
           DeviceInfo.isInstallIDValid(installId) {
            PassportUniversalDeviceService.shared.makeCurrentDeviceInfoUniversal(deviceId, installId)
            Self.logger.info("n_action_make_current_did_universal", body: deviceId)
            return true
        } else {
            Self.logger.warn("n_action_ranger_deviceInfo_invalid")
            return false
        }
    }
}

extension PassportDeviceServiceWrapper: PassportGlobalDeviceService {
    
    func getDeviceIdAndInstallId(unit: String) -> DeviceInfoTuple? {
        return internalDeviceService.getDeviceIdAndInstallId(unit: unit)
    }
}

extension PassportDeviceServiceWrapper: InternalDeviceServiceProtocol {
    
    func fetchDeviceId(_ callback: @escaping (DeviceInfoFetchResult) -> Void) {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        internalDeviceService.fetchDeviceId(callback)
    }
    
    func fetchDeviceIDMap() -> [String : String]? {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        //强制返回旧did服务的 did结构，即便已经切换到统一did
        return RangersAppLogDeviceServiceImpl.shared.fetchDeviceIDMap()
    }
    
    func universalDeviceID() -> String? {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        return internalDeviceService.universalDeviceID()
    }
    
    func reset() {
        internalDeviceService.reset()
    }
    
    func updateDeviceLoginId(_ deviceLoginId: String?) {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        internalDeviceService.updateDeviceLoginId(deviceLoginId)
    }
    
    func cacheDeviceIDUnit(_ unit: String, with host: String) {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        internalDeviceService.cacheDeviceIDUnit(unit, with: host)
    }
    
    var deviceInfo: LarkAccountInterface.DeviceInfo {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        return internalDeviceService.deviceInfo
    }
    
    var deviceInfoObservable: RxSwift.Observable<LarkAccountInterface.DeviceInfo?> {
        assert(!blockMode, "should not fetch deviceID during deviceID upgrading")
        return internalDeviceService.deviceInfoObservable
    }
}
