//
//  MeegoEnv.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/9/12.
//

import Foundation
import LarkStorage

public enum MeegoEnvDebugInteractType: String {
    case display
    case textEdit
    case `switch`
    case operation
}

public enum MeegoEnv {
    public enum MeegoDebugEnvKey: String {
        case isBoe = "is_boe"
        case deviceId = "did"
        case userId = "user_id"
        case session = "session"
        case tenantId = "tenant_id"
        case netProxy = "net_proxy"
        case ttEnv = "tt_env"
        case domainType = "domain_type"
        case usePPE = "tt_use_ppe"
        case rpcPDFD = "rpc_pdfd"
        case lang = "language"
        case clearFlutterCache = "clear_flutter_cache"
        case registerTopic = "register_push_topic"
        case unregisterTopic = "unregister_push_topic"
        case mgFeatureGatingDebug = "mg_feature_gating_debug"

        var kvKey: KVKey<String> { .init(rawValue, default: "") }

        public var description: String {
            switch self {
            case .isBoe: return "是否切换到boe环境"
            case .deviceId: return "设备id"
            case .userId: return "UserId"
            case .session: return "登录session"
            case .tenantId: return "租户id"
            case .netProxy: return "网络代理(格式ip:port)"
            case .ttEnv: return "服务端环境标"
            case .domainType: return "是否切换到外网环境（关闭则为内网）"
            case .usePPE: return "是否切换到ppe(boe>ppe)"
            case .rpcPDFD: return "rpc pdfd"
            case .lang: return "语言环境(标准locale格式)"
            case .clearFlutterCache: return "清除所有Flutter数据缓存"
            case .registerTopic: return "Subscribe Topic"
            case .unregisterTopic: return "Unsubscribe Topic"
            case .mgFeatureGatingDebug: return "FeatureGating Debug"
            }
        }

        public var cellType: MeegoEnvDebugInteractType {
            switch self {
            case .isBoe: return .switch
            case .deviceId: return .textEdit
            case .userId: return .textEdit
            case .session: return .textEdit
            case .tenantId: return .textEdit
            case .netProxy: return .textEdit
            case .ttEnv: return .textEdit
            case .domainType: return .switch
            case .usePPE: return .switch
            case .rpcPDFD: return .textEdit
            case .lang: return .textEdit
            case .clearFlutterCache: return .operation
            case .registerTopic: return .textEdit
            case .unregisterTopic: return .textEdit
            case .mgFeatureGatingDebug: return .operation
            }
        }
    }

    // 默认以飞书宿主为准，其余的debug选项会直接和飞书对齐
    public static var envKeyList: [MeegoEnv.MeegoDebugEnvKey] = [
        .usePPE, .ttEnv, .domainType, .netProxy, .clearFlutterCache, .registerTopic, .unregisterTopic, .mgFeatureGatingDebug
    ]

    public static func get(_ key: MeegoDebugEnvKey) -> String {
        return KVStores.Meego.global()[key.kvKey]
    }

    public static func set(_ key: MeegoDebugEnvKey, value: String) {
        KVStores.Meego.global().set(value, forKey: key.kvKey)
    }
}
