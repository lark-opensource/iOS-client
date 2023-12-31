//
//  DebugEntry.swift
//  LarkSensitivityControl
//
//  Created by yifan on 2022/12/5.
//

import ThreadSafeDataStructure
import LarkSnCService

// ignoring lark storage check for psda debug entry
// lint:disable lark_storage_check

public let context = Context([AtomicInfo.Default.defaultAtomicInfo.rawValue])

/// 用于Debug环境下的校验等能力
@objc
public final class DebugEntry: NSObject {

    static var debugConfigs: [DebugTokenConfig] = []

    /// 获取DebugConfigs
    public static func getDebugConfigs() -> [DebugTokenConfig] {
        if !debugConfigs.isEmpty {
            return debugConfigs
        }

        TCM.getConfigDict().forEach { _, tokenConfig in
            let status: DebugTokenStatus = tokenConfig.status == .ENABLE ? .ENABLE : .DISABLE
            debugConfigs.append(DebugTokenConfig(identifier: tokenConfig.identifier, status: status))
        }

        return debugConfigs
    }

    /// 设置DebugConfigs
    public static func setDebugConfigs(identifier: String, status: DebugTokenStatus) {
        for (index, config) in debugConfigs.enumerated() where config.identifier == identifier {
            debugConfigs[index].status = status
        }
    }

    /// Debug环境下token校验
    public static func checkToken(forToken token: Token, context: Context = context) throws {
        let result = TCM.checkResult(ofToken: token, context: context)
        if result.code != .success {
            LSC.logger?.warn("token: \(token.identifier), error code: \(result.code.description).")
        }
        // 所有禁用开关判断
        if (try? (LSC.storage?.get(key: kTokenDisabledCacheKey)).or(false)) ?? false {
            throw CheckError(errorInfo: ErrorInfo.DISABLEDFORDEBUG.rawValue)
        }
        switch result.code {
        case .success:
            break
        case .notExist:
            throw CheckError(errorInfo: ErrorInfo.NONE.rawValue)
        case .atomicInfoNotMatch:
            throw CheckError(errorInfo: ErrorInfo.MATCH.rawValue)
        case .statusDisabled:
            throw CheckError(errorInfo: ErrorInfo.STATUS.rawValue)
        case .strategyIntercepted:
            throw CheckError(errorInfo: ErrorInfo.STRATEGY.rawValue)
        case .statusDisabledForDebug:
            throw CheckError(errorInfo: ErrorInfo.DISABLEDFORDEBUG.rawValue)
        }
    }

    /// 更新tokenConfig数据
    public static func addTokenConfig(token: Token, context: Context) {
        let tokenConfig = TokenConfig(identifier: token.identifier, atomicInfoList: context.atomicInfoList, status: .ENABLE)
        TCM.setConfigDict(identifier: token.identifier, tokenConfig: tokenConfig)
    }

    /// 拉取内置数据
    public static func getloadBuiltData() -> [DebugTokenConfig] {
        var localConfigList = [DebugTokenConfig]()
        var localData: Data?
        do {
            localData = try Bundle.LSCBundle?.readFileToData(forResource: "token_config_list", ofType: .zip)
        } catch {
            LSC.logger?.error("Error when SensitivityControllerDebug reads config files: \(error.localizedDescription)")
        }
        guard let localData = localData else {
            return localConfigList
        }
        do {
            try FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/token_config_list.json")
        } catch {
            LSC.logger?.error(error.localizedDescription)
        }
        guard let tokenConfigList = TokenConfig.createConfigs(with: localData) else {
            return localConfigList
        }
        for config in tokenConfigList {
            let status: DebugTokenStatus = config.status == .ENABLE ? .ENABLE : .DISABLE
            let config = DebugTokenConfig(identifier: config.identifier, status: status,
                                          atomicInfoList: config.atomicInfoList)
            localConfigList.append(config)
        }
        LSC.logger?.info("load token config build-in data.")
        return localConfigList
    }

    @objc
    public static func updateDisabledState(_ disabled: Bool) {
        Token.updateDisabledState(disabled)
    }
}

/// Debug环境下token的配置信息
public struct DebugTokenConfig {
    /// token的id
    public var identifier: String
    /// token的状态
    public var status: DebugTokenStatus
    /// token的atomicInfo信息
    public var atomicInfoList: [String]

    /// 构造器
    /// - Parameters:
    ///   - identifier: id
    ///   - status: 状态
    public init(identifier: String, status: DebugTokenStatus, atomicInfoList: [String] = []) {
        self.identifier = identifier
        self.status = status
        self.atomicInfoList = atomicInfoList
    }
}

/// Debug环境下token的状态
public enum DebugTokenStatus: String {
    case ENABLE = "有效"
    case DISABLE = "禁用"
}
