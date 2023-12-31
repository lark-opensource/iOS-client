//
//  OPMockSingleLocationTask.swift
//  OPPlugin-Unit-Tests
//
//  Created by zhangxudong.999 on 2023/3/17.
//

import LarkCoreLocation
import CoreLocation
import Swinject
import LarkAssembler

struct LarkLocationMock {
    enum MockType {
        case success
        case failed(Error)
    }
}
let mockLocationError = LocationError(rawError: nil, errorCode: .timeout, message: "timeout")
var mockSingleLocationTaskResult: LarkLocationMock.MockType = .success
var mockContinueLocationTaskResult: LarkLocationMock.MockType = .success


final class OPSingleLocationTaskMockAssembly: LarkAssemblyInterface {
    public init() {}
    public func registContainer(container: Swinject.Container) {
        container.register(LocationAuthorization.self) { _ in
            OPMockLocationAuthorization()
        }.inObjectScope(.container)
        container.register(SingleLocationTask.self) {
            OPMockSingleLocationTask(locationRequest: $1)
        }
    }
}

final class OPContinueLocationTaskMockAssembly: LarkAssemblyInterface {
    public init() {}
    public func registContainer(container: Swinject.Container) {
        container.register(LocationAuthorization.self) { _ in
            OPMockLocationAuthorization()
        }.inObjectScope(.container)
        
        container.register(ContinueLocationTask.self) {
            OPMockContinueLocationTask(locationRequest: $1)
        }
    }
}

private let larkLocation: LarkCoreLocation.LarkLocation = {
    let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 80.0, longitude: 80.0),
                              altitude: 30,
                              horizontalAccuracy: 30,
                              verticalAccuracy: 30,
                              course: 30,
                              speed: 30,
                              timestamp: Date())
    return LarkCoreLocation.LarkLocation(location: location,
                                         locationType: .gcj02,
                                         serviceType: .aMap,
                                         time: Date(),
                                         authorizationAccuracy: AuthorizationAccuracy.full)
}()

final class OPMockContinueLocationTask: ContinueLocationTask {
    var request: LarkCoreLocation.LocationRequest
    
    var locationDidUpdateCallback: LarkCoreLocation.ContinueLocationTaskUpdateCallback?
    
    var locationDidFailedCallback: LarkCoreLocation.ContinueLocationDidFailedCallback?
    
    var taskID: AnyHashable  {
        return UUID()
    }
    
    var isLocating: Bool
    
    var locationStateDidChangedCallback: ((Bool) -> Void)?
    
    init(locationRequest: LarkCoreLocation.ContinueLocationRequest) {
        self.request = locationRequest
        self.isLocating = false
    }
    
    private var timer: Timer?
    
    func stopLocationUpdate() {
        timer?.invalidate()
        timer = nil
    }
  
    func startLocationUpdate(forToken: LarkCoreLocation.PSDAToken) throws {
        
        switch mockContinueLocationTaskResult {
        case .success:
            timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                self.locationDidUpdateCallback?(self,larkLocation, [larkLocation])
            })
        case .failed(let error):
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self,
                      let error = error as? LocationError else {
                    return
                }
                self.locationDidFailedCallback?(self, error)
            }
        }
        
    }
}


final class OPMockSingleLocationTask: SingleLocationTask {
    
    
    init(locationRequest: LarkCoreLocation.SingleLocationRequest) {
        self.locationRequest = locationRequest
        self.isLocating = false
    }
    
    
    var locationRequest: LarkCoreLocation.SingleLocationRequest
    
    var locationDidUpdateCallback: LarkCoreLocation.SingleLocationTaskUpdateCallback?
    
    var locationCompleteCallback: LarkCoreLocation.SingleLocationTaskComplete?
    var taskID: AnyHashable {
        return UUID()
    }
    var isLocating: Bool
    var locationStateDidChangedCallback: ((Bool) -> Void)?
    
    func resume(forToken: LarkCoreLocation.PSDAToken) throws {
        let result: LocationTaskResult
        switch mockSingleLocationTaskResult {
        case .success:
            result = .success(larkLocation)
        case .failed(let error):
            guard let error = error as? LocationError else {
                return
            }
            result = .failure(error)
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.locationCompleteCallback?(self, result)
        }
    }
    
    func cancel() {
        
    }
}
