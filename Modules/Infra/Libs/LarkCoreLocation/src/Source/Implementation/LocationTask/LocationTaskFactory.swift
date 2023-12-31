//
//  LocationManager.swift
//  LarkCoreLocation
//
//  Created by zhangxudong on 3/29/22.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreLocation
import LKCommonsLogging
import ServerPB
import Swinject
import LarkContainer
/// 对提供的统一接口
struct LocationTaskFactory {

    /// 单次定位
    /// ⚠️调用方需要持有SingleLocationTask
    /// SingleLocationTask 需要调用 resume 方法才会真正的开启定位
    /// 在不用的时候需要 调用cancel, task 销毁时会自动cancel
    func singleLocationTask(request: SingleLocationRequest) -> SingleLocationTask {
        let observable = Self.observableAndCache(serviceType: request.desiredServiceType)
        let task = SingleLocationTaskImp(request: request,
                                      locationServerObservable: observable)
        return task
    }

    /// 持续定位
    /// ⚠️调用方需要持有ContinueLocationTask
    /// 此方法不会调用 startLocationUpdate 需要调用方在合适的时机调用 startLocationUpdate
    /// 记得定位结束后调用 stopLocationUpdate
    /// 在task被销毁时候会自动调用 stopLocationUpdate
    func continueLocationTask(request: ContinueLocationRequest) -> ContinueLocationTask {
        let observable = Self.observableAndCache(serviceType: request.desiredServiceType)
        let task = ContinueLocationTaskImp(request: request, locationServerObservable: observable)
        return task
    }
}

extension LocationTaskFactory {
    static private let semaphore = DispatchSemaphore(value: 1)
    private static var taskManagerMap: [LocationServiceType: () -> LocationServiceObservable?] = [:]

    /// location Service的简单工厂 同时也尽量复用 Service
    fileprivate static func observableAndCache(serviceType: LocationServiceType?) -> LocationServiceObservable {
        let serviceFactory = LocationServiceFactory()
        let serviceType = serviceFactory.getRightLocationServiceType(serviceType)
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        if let result = taskManagerMap[serviceType]?() {
            return result
        }
        let server = serviceFactory.getLocationService(type: serviceType)
        let result = LocationServiceManager(locationService: server)
        taskManagerMap[server.serviceType] = { [weak result] in
            return result
        }
        return result
    }
}
