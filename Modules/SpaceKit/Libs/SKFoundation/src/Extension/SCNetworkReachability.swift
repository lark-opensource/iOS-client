//  Created by Songwen Ding on 2016/12/7.
//  Copyright © 2016年 DingSoung. All rights reserved.
//  Included OSS: DingSoung/Extension
//  Copyright (c) 2016 DingSoung
//  spdx license identifier: MIT

import Foundation
import SystemConfiguration

/*
extension SCNetworkReachability {
    public class func reachability(hostName: String) -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, hostName)
    }
    public class func reachability(hostAddress: inout sockaddr_in) -> SCNetworkReachability? {
        return withUnsafePointer(to: &hostAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        })
    }
    public class var reachabilityForInternetConnection: SCNetworkReachability? {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        return self.reachability(hostAddress: &zeroAddress)
    }
}

extension SCNetworkReachability {
    private static var updateCallBackKey: UInt8 = 0
    public var updateCallBack: ((SCNetworkReachability) -> Void)? {
        get { return objc_getAssociatedObject(self, &SCNetworkReachability.updateCallBackKey) as? (SCNetworkReachability) -> Void }
        set { objc_setAssociatedObject(self, &SCNetworkReachability.updateCallBackKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

extension SCNetworkReachability {
    @discardableResult
    public func start() -> Bool {
        var context = SCNetworkReachabilityContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        let callback: SCNetworkReachabilityCallBack = { _, _, info in
            guard let info = info else { return }
            let networkReachability = Unmanaged<SCNetworkReachability>.fromOpaque(info).takeUnretainedValue() as SCNetworkReachability
            networkReachability.updateCallBack?(networkReachability)
        }
        return SCNetworkReachabilitySetCallback(self, callback, &context)
            && SCNetworkReachabilityScheduleWithRunLoop(self, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
    public func stop() {
        SCNetworkReachabilityUnscheduleFromRunLoop(self, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
}

extension SCNetworkReachability {
    public enum Status: Int {
        case notReachable = 0
        case reachableViaWiFi
        case reachableViaWWAN
        case unknown
    }
    private func networkStatus(flags: SCNetworkReachabilityFlags) -> Status {
        guard flags.contains(.reachable) else { return .notReachable }
        var ret: Status = .notReachable
        if flags.contains(.connectionRequired) == false {
            ret = .reachableViaWiFi

        }
        if flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic) {
            if flags.contains(.interventionRequired) == false {
                ret = .reachableViaWiFi
            }
        }
        #if os(iOS)
        if flags.contains(SCNetworkReachabilityFlags.isWWAN) {
            ret = .reachableViaWWAN
        }
        #endif
        return ret
    }
    public var connectionRequired: Bool {
        var flags: SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(self, &flags)
        return flags.contains(.connectionRequired)
    }

    public var reachable: Bool {
        var flags: SCNetworkReachabilityFlags = []
        SCNetworkReachabilityGetFlags(self, &flags)
        return flags.contains(.reachable)
    }

    public var currentReachabilityStatus: Status {
        var flags: SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(self, &flags) {
            return self.networkStatus(flags: flags)
        }
        return .unknown
    }
}
*/
