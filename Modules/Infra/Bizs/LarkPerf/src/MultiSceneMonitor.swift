//
//  MultiSceneMonitor.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/6/7.
//
import Foundation
import LKCommonsLogging
import LKCommonsTracker
import AppContainer

public final class MultiSceneMonitor: BaseMonitor {
    public static let shared = MultiSceneMonitor()
    private static let metricValueForCount: Int = 0

    private let logger = Logger.log(MultiSceneMonitor.self, category: "MultiSceneMonitor")

    public enum Const: String {
        case scene = "scene"
        case type  = "type"
        case result = "result"
    }

    public enum Scene: String {
        case enterContact = "passport_enter_contact"
        case enterVerifyCode = "passport_enter_verify_code"
        case enterVerifyOTP = "passport_enter_verify_otp"
        case enterVerifyPWD = "passport_enter_verify_pwd"
        case setTenantName = "passport_set_tenant_name"
        case successB = "passport_success_b"
        case resetPWD = "passport_set_pwd"
        case chooseOrCreate = "passport_choose_or_create"
        case officialEmail = "passport_official_email"
        case dispatchNext = "passport_dispatch_next"
        case joinTenantCodeVerify = "passport_join_tenant_code_verify"
        case joinTenantCodeConfirm = "passport_join_tenant_code_confirm"
        case joinTenantScanVerify = "passport_join_tenant_scan_verify"
        case joinTenantScanConfirm = "passport_join_tenant_scan_confirm"
        case enterApp = "passport_enterapp"
        case idpEnter = "passport_idp_enter"
        case idpVerifyResult = "passport_idp_verify_result"
    }

    public enum MetricKey: String {
        case timespend = "timespend"
    }

    override func serviceName() -> String {
        return "passport_business_overall"
    }

    public func start(scene: Scene) {
        self.logger.debug("start: scene \(scene.rawValue)")
        self.start(monitor: scene.rawValue, key: MetricKey.timespend.rawValue)
    }

    public func end(scene: Scene) {
        self.logger.debug("start: scene \(scene.rawValue)")
        self.end(monitor: scene.rawValue, key: MetricKey.timespend.rawValue)
        self.upload(monitor: scene.rawValue)
    }

    public func record(scene: Scene,
                       categoryInfo: [String: Any] = [:],
                       metricInfo: [String: Any] = [:],
                       extraInfo: [String: Any] = [:]) {
        var defaultMetricInfo: [String: Any] = [
            scene.rawValue: MultiSceneMonitor.metricValueForCount,
            MetricKey.timespend.rawValue: MultiSceneMonitor.metricValueForCount
        ]

        defaultMetricInfo.merge(metricInfo) { (_, new) in new }

        self.addCategoryInfo(scene: scene, info: categoryInfo)
        self.addMetricInfo(scene: scene, info: defaultMetricInfo)
        self.addExtraInfo(scene: scene, info: extraInfo)
        self.upload(monitor: scene.rawValue)
    }

    public func addCategoryInfo(scene: Scene, info: [String: Any]) {
        self.logger.debug("scene \(scene.rawValue) , add category info: \(info)")
        self.addCategoryInfo(monitor: scene.rawValue, info: info)
    }

    public func addMetricInfo(scene: Scene, info: [String: Any]) {
        self.logger.debug("scene \(scene.rawValue) , add metric info: \(info)")
        self.addMetricInfo(monitor: scene.rawValue, info: info)
    }

    public func addExtraInfo(scene: Scene, info: [String: Any]) {
        self.logger.debug("scene \(scene.rawValue), add extra info: \(info)")
        self.addExtraInfo(monitor: scene.rawValue, info: info)
    }
}
