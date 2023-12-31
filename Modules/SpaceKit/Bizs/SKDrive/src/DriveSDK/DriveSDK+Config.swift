//
//  DriveSDK+Config.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/19.
//

import Foundation
import SpaceInterface
import SKCommon
import SKFoundation
import SKInfra
import LarkDocsIcon

enum DKConstant {
    /// AppSetings(drive_sdk_config) 上的 -2 代表原文件预览，目前 DriveSDK 中未使用到
    static let originFileSettingCode = -2
    static let disabledTextAlpha = 0.3
}

enum DKSupportType {
    case native
    case serverTransform(type: DrivePreviewFileType)
}

extension DKSupportType: Equatable {}

extension Array where Element == DKSupportType {

    fileprivate static func parseConfig(transforms: [String: Any]) -> [String: [DKSupportType]] {
        var result: [String: [DKSupportType]] = [:]
        transforms.forEach { (type, value) in
            guard let configs = value as? [Int] else { return }
            let supportTypes: [DKSupportType] = configs.compactMap { value in
                // mina 上的 -2 代码原文件预览，目前 DriveSDK 中未使用到
                if value == DKConstant.originFileSettingCode {
                    guard DriveFileType(fileExtension: type).isSupport else { return nil }
                    return .native
                }
                guard let serverType = DrivePreviewFileType(rawValue: value) else {
                    DocsLogger.error("drive-sdk.config --- unknown server type", extraInfo: ["value": value])
                    return nil
                }
                if serverType == .similarFiles {
                    // 如果 mina 上配置了 16 即源文件预览，但是实际格式本地不支持预览，会将 16 过滤掉
                    guard DriveFileType(fileExtension: type).isSupport else { return nil }
                }
                return .serverTransform(type: serverType)
            }
            guard !supportTypes.isEmpty else { return }
            result[type] = supportTypes
        }
        return result
    }

    fileprivate func convertToSupportOptions() -> DriveSDK.SupportOptions {
        var result: DriveSDK.SupportOptions = []
        let nativeSupport = contains { (supportType) -> Bool in
            if case .native = supportType { return true }
            return false
        }
        let serverSupport = contains { (supportType) -> Bool in
            if case .serverTransform = supportType { return true }
            return false
        }
        if nativeSupport { result.formUnion(.native) }
        if serverSupport { result.formUnion(.serverTransform) }
        return result
    }
}

protocol DKSupportStrategy {
    func supportTypes(for type: String) -> [DKSupportType]
    func supportOptions(for type: String) -> DriveSDK.SupportOptions
}

extension DKSupportStrategy {
    func supportOptions(for type: String) -> DriveSDK.SupportOptions {
        return supportTypes(for: type).convertToSupportOptions()
    }
}

struct DKAllowListStrategy: DKSupportStrategy {

    static let empty = DKAllowListStrategy(allowList: [:])

    var allowList: [String: [DKSupportType]]

    func supportTypes(for type: String) -> [DKSupportType] {
        let type = type.lowercased()
        guard let supportTypes = allowList[type] else { return [] }
        return supportTypes
    }
}

struct DKConfig {

    static let empty = DKConfig(strategies: [:])
    static let config: Self = {
        guard let configData = SettingConfig.driveSDKConfigData,
            let transformsData = configData["previewTransforms"] as? [String: Any] else {
                return .empty
        }
        var strategies: [String: DKSupportStrategy] = [:]
        transformsData.forEach { (appID, value) in
            guard let appConfig = value as? [String: Any] else { return }
            let allowList = [DKSupportType].parseConfig(transforms: appConfig)
            strategies[appID] = DKAllowListStrategy(allowList: allowList)
        }
        return DKConfig(strategies: strategies)
    }()
    // Key: AppID, value: Strategy
    private let strategies: [String: DKSupportStrategy]
    private let validAppIDs: [String]

    init(strategies: [String: DKSupportStrategy]) {
        self.strategies = strategies
        validAppIDs = Array(strategies.keys)
    }

    func isValid(appID: String) -> Bool {
        validAppIDs.contains(appID)
    }

    func canOpen(type: String, appID: String) -> DriveSDKSupportOptions {
        guard isValid(appID: appID) else {
            DocsLogger.driveInfo("drive.sdk.config --- canOpen check failed due to invalid appID", extraInfo: ["appID": appID])
            return []
        }
        guard let strategy = strategies[appID] else {
            DocsLogger.driveInfo("drive.sdk.config --- canOpen check failed, unable to retrive support strategy for appID", extraInfo: ["appID": appID])
            return []
        }
        let options = strategy.supportOptions(for: type)
        return enablePreviewAllfileIfNeed(appID: appID, options: options)
    }

    func supportTypes(for type: String, appID: String) -> [DKSupportType] {
        guard isValid(appID: appID), let strategy = strategies[appID] else { return [] }
        return strategy.supportTypes(for: type)
    }
    
    // 判断appid是否支持打开所有文件类型
    private func previewAllFile(appID: String) -> Bool {
        if appID == DKSupportedApp.im.rawValue {
            return true
        } else {
            return false
        }
    }
    
    private func enablePreviewAllfileIfNeed(appID: String, options: DriveSDKSupportOptions) -> DriveSDKSupportOptions {
        if previewAllFile(appID: appID) {
            return options.union(.native)
        } else {
            return options
        }
    }
}
