//
//  BDPJSWorkerInterpreterManager.swift
//  TTMicroApp
//
//  Created by yi on 2021/7/28.
//

import Foundation
import LarkOpenPluginManager
import LKCommonsLogging

// js worker的解释器配置
@objcMembers
final class OpenJSWorkerInterpreters: NSObject {
    public var resource: OpenJSWorkerResourceProtocol?
    public var netResource: OpenJSWorkerNetResourceProtocol?

    public override init() {
        super.init()
    }

}

// js worker 解释器类型枚举
@objc enum OpenJSWorkerInterpreterType: Int {
    case resource = 1
    case netResource = 2

    static let descriptionMap = [
        Self.resource: "resource",
        Self.netResource: "netResource"
    ]

    func description() -> String {
        return Self.descriptionMap[self] ?? String(rawValue)
    }
}


// js worker 解释器管理类
@objcMembers
public final class OpenJSWorkerInterpreterManager: NSObject {
    public static let shared = OpenJSWorkerInterpreterManager()
    static let logger = Logger.log(OpenJSWorkerInterpreterManager.self, category: "Worker")

    var configs: [AnyHashable: Any] = [:]

    // 注册js worker 解释器
    func register(name: String?, types: [AnyClass]?) {
        guard let name = name, let types = types, !name.isEmpty else {
            Self.logger.warn("register interpreter fail, name/types is nil")
            return
        }
        var interpreters = configs[name] as? [String: AnyClass] ?? [:]
        for typeName in types {
            var success = false
            for protocolKey in protocols().keys {
                if let protocolName = protocols()[protocolKey] {
                    if let transformTypeName = typeName as? NSObject.Type {
                        if transformTypeName.conforms(to: protocolName) {
                            interpreters[protocolKey] = typeName
                            success = true
                        }
                    } else {
                        Self.logger.warn("register interpreter, typeName error, typeName is \(typeName)")
                    }
                } else {
                    Self.logger.warn("register interpreter, get protocols by protocolKey\(protocolKey) fail")
                }
            }
            if !success {
                Self.logger.warn("register interpreter, can not find right protocol, typeName \(typeName)")
            }
        }
        configs[name] = interpreters
    }

    func getInterpreter(workerName: String, interpreterType: OpenJSWorkerInterpreterType) -> AnyClass? {
        let type = interpreterType.description()
        return getInterpreter(workerName: workerName, protocolName: type)
    }

    // 获取解释器
    func getInterpreter(workerName: String, protocolName: String) -> AnyClass? {
        guard let interperters = configs[workerName] as? [String: AnyClass] else {
            Self.logger.warn("getInterpreter fail, workerName\(workerName), protocolName\(protocolName)")
            return nil
        }
        let interperter = interperters[protocolName]
        return interperter
    }

    // 支持的解释器
    func protocols() -> [String: Protocol] {
        return [OpenJSWorkerInterpreterType.resource.description(): OpenJSWorkerResourceProtocol.self,
                OpenJSWorkerInterpreterType.netResource.description(): OpenJSWorkerNetResourceProtocol.self
        ]
    }

    public func register(configs: [AnyHashable: Any]) {
        for workerName in configs.keys {
            register(name: workerName as? String, types: configs[workerName] as? [AnyClass])
        }
    }
}
