//
//  OPNetStatusHelper.swift
//  OPFoundation
//
//  Created by yinyuan on 2021/1/12.
//

import Foundation
import RustPB
import TTNetworkManager
import LarkContainer
import LKCommonsLogging
import LarkRustClient

public typealias RustNetStatus = RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus
public typealias TTNetStatus = TTNetEffectiveConnectionType

private let OPFoundationFeatureGatingKeyTTNet = "openplatform.foundation.ttnet"

public final class OPNetStatusHelper: NSObject {
    private static let logger = Logger.oplog(OPNetStatusHelper.self, category: "OPNetStatusHelper")
    
    public enum OPNetStatus: String {
        case unavailable
        case weak
        case moderate
        case excellent
        case unknown
    }
    
    private static var service: OPNetStatusHelper {
        Injected<OPNetStatusHelper>().wrappedValue
    }
    
    public static func netStatusName() -> String {
        return service.status.rawValue
    }
    
    public private(set) var status: OPNetStatus = .unknown
    public private(set) var rustNetStatus: RustNetStatus = .evaluating
    public private(set) var ttNetStatus: TTNetStatus = .EFFECTIVE_CONNECTION_TYPE_UNKNOWN
    
    public override init() {
        super.init()
        guard EMAFeatureGating.boolValue(forKey: OPFoundationFeatureGatingKeyTTNet) else {
            return
        }
        updateTTNetStatus()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTTNetStatus), name: NSNotification.Name.ttNetConnectionType, object: nil)
    }
    
    private func mergeNetStatus(rustNetStatus: RustNetStatus?, ttnetNetStatus: TTNetStatus) -> OPNetStatus {
        var map: [TTNetStatus: OPNetStatus]
        switch rustNetStatus {
        case .netUnavailable, .serviceUnavailable, .offline:
            map = [
                .EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK: .unavailable,
                .EFFECTIVE_CONNECTION_TYPE_UNKNOWN: .unavailable,
                .EFFECTIVE_CONNECTION_TYPE_OFFLINE: .unavailable,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_3G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_MODERATE_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_GOOD_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G: .moderate
            ]
        case .weak:
            map = [
                .EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK: .weak,
                .EFFECTIVE_CONNECTION_TYPE_UNKNOWN: .weak,
                .EFFECTIVE_CONNECTION_TYPE_OFFLINE: .weak,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_3G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_MODERATE_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_GOOD_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G: .moderate
            ]
        case .excellent:
            map = [
                .EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK: .weak,
                .EFFECTIVE_CONNECTION_TYPE_UNKNOWN: .excellent,
                .EFFECTIVE_CONNECTION_TYPE_OFFLINE: .weak,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_3G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_MODERATE_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_GOOD_4G: .excellent,
                .EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G: .excellent
            ]
        case .evaluating, .none, .some(_):
            map = [
                .EFFECTIVE_CONNECTION_TYPE_FAKE_NETWORK: .unavailable,
                .EFFECTIVE_CONNECTION_TYPE_UNKNOWN: .unknown,
                .EFFECTIVE_CONNECTION_TYPE_OFFLINE: .unavailable,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_2G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_3G: .weak,
                .EFFECTIVE_CONNECTION_TYPE_SLOW_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_MODERATE_4G: .moderate,
                .EFFECTIVE_CONNECTION_TYPE_GOOD_4G: .excellent,
                .EFFECTIVE_CONNECTION_TYPE_EXCELLENT_4G: .excellent
            ]
        @unknown default:
            return .unknown
        }
        return map[ttnetNetStatus] ?? .unknown
    }
    
    private func updateOPNetStatus() {
        let newValue = mergeNetStatus(rustNetStatus: rustNetStatus, ttnetNetStatus: ttNetStatus)
        guard status != newValue else { return }
        status = newValue
        OPMonitor(name: nil, code: EPMClientOpenPlatformNetworkCode.network_quality_type_change)
            .addCategoryValue("rust_type", rustNetStatus.rawValue)
            .addCategoryValue("ttnet_type", ttNetStatus.rawValue)
            .addCategoryValue("final_type", status.rawValue)
            .flush()
        Self.logger.info("UpdateOPNetStatus rust_type:\(rustNetStatus.rawValue), ttnet_type:\(ttNetStatus.rawValue), final_type: \(status.rawValue)")
        NotificationCenter.default.post(name: Notification.Name.UpdateNetStatus, object: status)
    }
    
    @objc public func updateTTNetStatus() {
        guard EMAFeatureGating.boolValue(forKey: OPFoundationFeatureGatingKeyTTNet) else {
            return
        }
        ttNetStatus = TTNetworkManager.shareInstance().getEffectiveConnectionType()
        Self.logger.info("UpdateTTNetStatus ttnet_type:\(ttNetStatus.rawValue)")
        updateOPNetStatus()
    }
    
    public func updateNetStatus(netStatus: RustNetStatus) {
        rustNetStatus = netStatus
        Self.logger.info("UpdateRustStatus rust_type:\(rustNetStatus.rawValue)")
        updateOPNetStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension Notification.Name {
    public static let UpdateNetStatus = Notification.Name(rawValue: "op.network.updateStatus")
}

final public class RustNetStatusPushHandler: BaseRustPushHandler<RustPB.Basic_V1_DynamicNetStatusResponse> { // Global
    public override init() {}

    public override func doProcessing(message: RustPB.Basic_V1_DynamicNetStatusResponse) {
        let helper = Injected<OPNetStatusHelper>().wrappedValue // Global
        helper.updateNetStatus(netStatus: message.netStatus)
    }
}
