//
//  EMAPrelocationManager.swift
//  EEMicroAppSDK
//
//  Created by zhangxudong.999 on 2023/1/12.
//

import LarkContainer
import LarkCoreLocation
import LarkSetting
import Swinject
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkSensitivityControl
import OPFoundation

fileprivate let logger = Logger.oplog("EMAPreloadContinueLocation")

@objc(EMAPreloadContinueLocationFactory)
public class PreloadContinueLocationFactory: NSObject {
    @objc public static func createTask() -> EMAPreloadTask {
        return PreloadContinueLocationImp();
    }
}

/// 持续定位的预定位实现
final class PreloadContinueLocationImp: NSObject, PreloadContinueLocation, EMAPreloadTask {
    private var _locationTasks: SafeDictionary<OPAppUniqueID, ContinueLocationTask> = [:] + .readWriteLock
  
    @ProviderRawSetting(key: UserSettingKey.make(userKeyLiteral: "openplatform_gadget_preload")) private var preloadSetting: [String: Any]?
    
    public var locationTasks: [OPAppUniqueID: ContinueLocationTask] {
        get { _locationTasks.getImmutableCopy() }
        set { _locationTasks.replaceInnerData(by: newValue) }
    }
    
    private var _locationCaches: SafeDictionary<OPAppUniqueID, LarkLocation> = [:] + .readWriteLock
    public var locationCaches: [OPAppUniqueID: LarkLocation] {
        get { _locationCaches.getImmutableCopy() }
        set { _locationCaches.replaceInnerData(by: newValue) }
    }
    
    /// 定位认证
    @InjectedSafeLazy var locationAuth: LocationAuthorization
    
    private var desiredServiceType: LocationServiceType = FeatureGatingManager.shared.featureGatingValue(with: "openplatform.api_amap_location.disable") ? .apple : .aMap

    
    @objc public func preload(with uniqueID: OPAppUniqueID?) {
        guard let uniqueID = uniqueID, isOpenPreLocation(for: uniqueID) else { return }
        if let error = locationAuth.checkWhenInUseAuthorization() {
            logger.error("preLocation startPreload failed! check Authorization error: \(error) appid: \(uniqueID.appID)")
            return
        }
        // 清空之前小程序的缓存
        locationCaches[uniqueID] = nil
        let request = ContinueLocationRequest(desiredAccuracy: 100,
                                              desiredServiceType: desiredServiceType)
        guard let task = implicitResolver?.resolve(ContinueLocationTask.self, argument: request) else {
            logger.error("resolve ContinueLocationTask failed appid: \(uniqueID.appID)")
            return
        }
        
        locationTasks[uniqueID] = task
        // 定位过程中遇到的错误
        task.locationDidFailedCallback = { [weak self] task, error in
            logger.error("preLocation locationDidFailedCallback error \(error) appid: \(uniqueID.appID)")
            task.stopLocationUpdate()
            self?.locationTasks[uniqueID] = nil
        }
        // 持续定位任务更新回调
        task.locationDidUpdateCallback = { [weak self] task, larkLocation, _ in
            guard let self = self else { return }
            logger.info("preLocation location callback \(larkLocation)")
            task.stopLocationUpdate()
            self.locationTasks[uniqueID] = nil
            self.locationCaches[uniqueID] = larkLocation
        }
        do {
            let token = Token("LARK-PSDA-EMAPrelocationManagerImp-startPrelocation")
            try task.startLocationUpdate(forToken: token)
            logger.info("preLocation startLocationUpdate success appid: \(uniqueID.appID)")
        } catch {
            logger.error("preLocation startLocationUpdate failed! \(error) appid: \(uniqueID.appID)")
        }
    }
    
    public func fetchAndCleanCache(uniqueID: OPAppUniqueID) -> LarkLocation? {
        let result = locationCaches[uniqueID]
        if result != nil {
            locationCaches[uniqueID] = nil
        }
        return result
    }
    
    private func isOpenPreLocation(for uniqueID: OPAppUniqueID) -> Bool {
        let preloadContinueLocation = preloadSetting?["preloadContinueLocation"] as? [String: Any]
        return preloadContinueLocation?[uniqueID.appID] != nil
    }
}
