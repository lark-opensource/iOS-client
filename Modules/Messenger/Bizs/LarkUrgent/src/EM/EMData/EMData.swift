//
//  EMManager.swift
//  LarkEM
//
//  Created by Saafo on 2021/12/1.
//

import Foundation
import CoreLocation

// MARK: - Data

protocol DataServiceDelegate: AnyObject {
    func dataService(_: DataService, dataChangedTo data: Data)
}

extension EMManager: DataServiceDelegate {
    func dataService(_: DataService, dataChangedTo data: Data) {
        internalLogger?.info("send data")
        network?.sendInfo(data, completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let date):
                self.lastSentTime = date
                self.dataService.fetchData(after: Self.Cons.sendInterval)
            case .failure(let error):
                if let error = error as? EMError, error == .alreadyDone {
                    self.active = false
                } else {
                    self.dataService.fetchData(after: Self.Cons.retryInterval)
                }
            }
        })
    }
}

final class DataService: NSObject, CLLocationManagerDelegate {
    let manager: CLLocationManager

    var currentLocation: CLLocation? {
        manager.location
    }

    var currentAuth: CLAuthorizationStatus? {
        didSet {
            if currentAuth != oldValue {
                NotificationCenter.default.post(
                    name: Notification.EM.authChanged.name, object: nil
                )
            }
        }
    }

    weak var delegate: DataServiceDelegate?

    private var requestingFull: Bool = false

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
    }

    func request(auth: EMManager.Auth) {
        if auth == .full && hasDeclareFullConfig {
            requestingFull = true
        }
        manager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        if hasDeclareFullConfig {
            manager.allowsBackgroundLocationUpdates = true
        }
        manager.pausesLocationUpdatesAutomatically = false
        manager.startUpdatingLocation()
    }

    func stopMonitoring() {
        manager.stopUpdatingLocation()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateData), object: nil)
    }

    func fetchData(after timeInterval: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            internalLogger?.info("fetch data after: \(timeInterval)")
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.updateData), object: nil)
            self.perform(#selector(self.updateData), with: nil, afterDelay: timeInterval)
        }
    }

    @objc
    private func updateData() {
        guard let currentLocation = currentLocation else {
            internalLogger?.error("Cannot find current data")
            return
        }
        let x = currentLocation.coordinate.longitude
        let y = currentLocation.coordinate.latitude
        let json: [String: [String: Double]] = ["point_info": ["px": x, "py": y]]
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            delegate?.dataService(self, dataChangedTo: data)
        } catch {
            internalLogger?.error("transform to JSON failed: \(error)")
        }
    }

    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationManager(manager, didChangeAuthorization: manager.authorizationStatus)
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        currentAuth = status
        internalLogger?.info("auth changed to \(status.rawValue)")

        if status == .authorizedWhenInUse && requestingFull && hasDeclareFullConfig {
            manager.requestAlwaysAuthorization()
            requestingFull = false
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        internalLogger?.error("dataManager didFailed: \(error)")
    }
}
