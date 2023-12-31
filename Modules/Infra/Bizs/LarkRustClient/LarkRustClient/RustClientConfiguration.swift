//
//  RustClientConfiguration.swift
//  Lark-Rust
//
//  Created by Sylar on 2017/12/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// rust configurations
public struct RustClientConfiguration {
    /// env v2
    public typealias EnvV2 = InitSDKRequest.EnvV2
    /// 数据同步策略
    public typealias DataSynchronismStrategy = InitSDKRequest.DataSynchronismStrategy
    /// Frontier Config
    public typealias FrontierConfig = InitSDKRequest.FrontierConfig

    /// Seal Cert
    public typealias CertConfig = (hosts: [String], cert: Data, privateKey: Data)

    enum ProcessType: Int {
        case main = 1
        case child = 2
    }
    /// Client标识，目前应该仅用于日志区分
    let identifier: String
    let envV2: EnvV2
    let version: String
    let osVersion: String
    let userAgent: String
    let storagePath: URL
    let appId: String
    let localeIdentifier: String
    let clientLogStoragePath: String
    let dataSynchronismStrategy: DataSynchronismStrategy
    let deviceModel: String

    /// Frontiner 配置信息
    public var frontierConfig: FrontierConfig?

    /// 可选的预加载配置参数(3.6过渡，3.7会做成Packet配置)
    public var preloadConfig: InitSDKRequest.PreloadConfig?

    public var fetchFeedABTest = false

    /// 用户id
    public var userId: String?
    let processType: ProcessType
    let domainInitConfig: DomainInitConfig
    let mainThreadInt64: Int64

    /// 域名配置路径
    let domainConfigPath: String
    /// app_channel
    let appChannel: String

    let certConfig: CertConfig?

    let basicMode: Bool

    /// 环境相关header

    /// prerelease 压测tag
    let preReleaseStressTag: String
    /// prerelease fd value
    let preReleaseFdValue: [String]
    /// prerelease mock tag value
    let preReleaseMockTag: String
    /// boe fd value
    let boeFd: [String]
    /// x-tt-env value
    let xttEnv: String
    /// 任意门开关
    let isAnywhereDoorEnable: Bool
    let settingsQuery: [String: String]
    let devicePerfLevel: String?

    /// - Parameters:
    ///   - identifier: 日志标识
    ///   - storagePath: Rust数据保存位置
    ///   - version: 版本号
    ///   - userAgent: agent标识
    ///   - env: APP运行环境，线上还是开发环境
    ///   - appId: app对应的ID
    ///   - localeIdentifier: 语言环境
    ///   - userId: 当前登录用户id
    public init(
        identifier: String,
        storagePath: URL,
        version: String,
        osVersion: String,
        userAgent: String,
        envV2: EnvV2,
        appId: String,
        localeIdentifier: String,
        clientLogStoragePath: String,
        dataSynchronismStrategy: DataSynchronismStrategy = .broadcast,
        deviceModel: String,
        userId: String? = nil,
        domainInitConfig: DomainInitConfig,
        appChannel: String,
        frontierConfig: FrontierConfig? = nil,
        certConfig: CertConfig? = nil,
        domainConfigPath: String,
        basicMode: Bool,
        preReleaseStressTag: String,
        preReleaseFdValue: [String],
        preReleaseMockTag: String,
        xttEnv: String,
        boeFd: [String],
        isAnywhereDoorEnable: Bool,
        settingsQuery: [String: String],
        devicePerfLevel: String?
    ) {
        self.identifier = identifier
        self.storagePath = storagePath
        self.envV2 = envV2
        self.version = version
        self.osVersion = osVersion
        self.userAgent = userAgent
        self.appId = appId
        self.localeIdentifier = localeIdentifier
        self.clientLogStoragePath = clientLogStoragePath
        self.dataSynchronismStrategy = dataSynchronismStrategy
        self.deviceModel = deviceModel
        self.userId = userId
        self.processType = .main
        self.domainInitConfig = domainInitConfig
        self.appChannel = appChannel
        self.frontierConfig = frontierConfig
        self.mainThreadInt64 = M.getThreadInt64(Thread.main)
        self.certConfig = certConfig
        self.domainConfigPath = domainConfigPath
        self.basicMode = basicMode
        self.preReleaseStressTag = preReleaseStressTag
        self.preReleaseFdValue = preReleaseFdValue
        self.preReleaseMockTag = preReleaseMockTag
        self.xttEnv = xttEnv
        self.boeFd = boeFd
        self.isAnywhereDoorEnable = isAnywhereDoorEnable
        self.settingsQuery = settingsQuery
        self.devicePerfLevel = devicePerfLevel
    }
}
