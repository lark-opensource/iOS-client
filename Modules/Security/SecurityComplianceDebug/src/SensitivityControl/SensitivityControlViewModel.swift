//
//  SensitivtyControlViewModel.swift
//  LarkSecurityCompliance
//
//  Created by bytedance on 2022/8/31.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface
import LarkUIKit
import UIKit
import UniverseDesignActionPanel
import UniverseDesignToast
import LarkSecurityComplianceInfra
import LarkSecurityCompliance
import LarkSensitivityControl
import LarkSnCService
import CoreLocation
import LarkEMM

final class SensitivityControlViewModel: BaseViewModel, UserResolverWrapper {

    @ScopedProvider private var service: SCDebugService?
    var tokenIdentifier: String?

    @ScopedProvider private var serviceImpl: SensitivityControlSnCService?

    let LSC = SensitivityManager.shared

    var dismissCurrentWindow: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.dismissCurrentWindowInner()
        }
    }

    var sensitivityControlPasteboardTest: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.sensitivityControlPasteboardTestInner()
        }
    }

    var sensitivityControlOriginPasteboardTest: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.sensitivityControlOriginPasteboardTestInner()
        }
    }

    var sensitivityControlLocationTest: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.sensitivityControlLocationTestInner()
        }
    }

    var sensitivityControlLocationLaterTest: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.serviceImpl?.logger?.debug("sensitivityControl get location will delay")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 6) {
                self?.serviceImpl?.logger?.debug("sensitivityControl get location delay 6s")
                self?.sensitivityControlLocationTestInner()
            }
        }
    }

    var sensitivityControlIPTest: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.sensitivityControlIPTestInner()
        }
    }

    var sensitivityControlIPLaterTest: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.serviceImpl?.logger?.debug("sensitivityControl get ip will delay")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 6) {
                self?.serviceImpl?.logger?.debug("sensitivityControl get ip delay 6s")
                self?.sensitivityControlIPTestInner()
            }
        }
    }
    
    let userResolver: UserResolver
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func dismissCurrentWindowInner() {
        serviceImpl?.logger?.log(level: .debug, "dismissCurrentWindowInner", file: "", line: 0, function: "")
        service?.dismissCurrentWindow()
    }

    func testTokenIdentifier() -> String {
        guard let identifier = tokenIdentifier else {
            return "LARKTEST-PSDA-PasteboardTest"
        }
        return "LARKTEST-PSDA-" + identifier
    }

    func sensitivityControlIPTestInner() {
        serviceImpl?.logger?.debug("sensitivityControl IPTest")
        do {
            var ifAddrsPtr: UnsafeMutablePointer<ifaddrs>?
            let IP = try DeviceInfoEntry.getifaddrs(forToken: Token(testTokenIdentifier()), &ifAddrsPtr)
            guard IP == 0 else {
                return
            }
            guard let firstAddr = ifAddrsPtr else {
                return
            }
            var address = [String]()
            for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
                let addr = ptr.pointee.ifa_addr
                let addrLen = ptr.pointee.ifa_addr.pointee.sa_len
                let addrFamily = ptr.pointee.ifa_addr.pointee.sa_family
                let name = String(cString: ptr.pointee.ifa_name)
                guard [AF_INET, AF_INET6].contains(Int32(addrFamily)), name == "en0" else {
                    continue
                }
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr, socklen_t(addrLen), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                address.append(String(cString: hostname))
                guard let view = coordinator?.view, String(cString: hostname).contains(".") else {
                    continue
                }
                let config = UDToastConfig(toastType: .info, text: String(cString: hostname), operation: nil)
                UDToast.showToast(with: config, on: view)
            }
            serviceImpl?.logger?.debug("sensitivityControl get address \(address)")
        } catch {
            let config = UDToastConfig(toastType: .error, text: "snc_service IP error:\(error)", operation: nil)
            if let view = coordinator?.view {
                UDToast.showToast(with: config, on: view)
            }
        }
    }

    func sensitivityControlLocationTestInner() {

        serviceImpl?.logger?.log(level: .debug, "sensitivityControl LocationTest", file: "", line: 0, function: "")
        do {
            let locationManager = CLLocationManager()
            locationManager.delegate = LocationManagerDelegate.instance
            try LocationEntry.requestWhenInUseAuthorization(forToken: Token(testTokenIdentifier()), manager: locationManager)
        } catch {
            let config = UDToastConfig(toastType: .error, text: "snc_service Location error:\(error)", operation: nil)
            if let view = coordinator?.view {
                UDToast.showToast(with: config, on: view)
            }
        }
    }

    func sensitivityControlPasteboardTestInner() {
        serviceImpl?.logger?.log(level: .debug, "sensitivityControl PasteboardTest", file: "", line: 0, function: "")
        do {
            try PasteboardEntry.setString(forToken: Token(testTokenIdentifier()), pasteboard: UIPasteboard.general, string: "abcd")
        } catch {
            let config = UDToastConfig(toastType: .error, text: "snc_service Pasteboard error:\(error)", operation: nil)
            if let view = coordinator?.view {
                UDToast.showToast(with: config, on: view)
            }
        }
    }

    func sensitivityControlOriginPasteboardTestInner() {
        serviceImpl?.logger?.log(level: .debug, "sensitivityControl OriginPasteboardTest", file: "", line: 0, function: "")
        let config = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
        SCPasteboard.general(config).string = "abcdef"
    }
}

final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    /// 单例
    static let instance = LocationManagerDelegate()

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError")
    }
}
