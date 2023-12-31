//
//  StrategyService.swift
//  Timor
//
//  Created by changrong on 2020/9/26.
//

import Foundation

public typealias CommandBlock = ([String: StrategyParam]) -> Void

public protocol StrategyServiceProtocol {
    
    /// 注册对应策略的command
    /// - Parameters:
    ///   - name: 策略名
    ///   - command: 执行block
    func register(name: String, with command: @escaping CommandBlock)

    
    /// 根据params执行策略内容
    /// - Parameter params: params
    func strategy(params: [StrategyParam]) -> OPError?

    
    /// 根据params和临时command执行策略内容
    /// - Parameters:
    ///   - command: 临时command map
    ///   - params: params
    func strategy(command: [String: CommandBlock], with params: [StrategyParam]) -> OPError?
    
    
    /// For Objective-C, 根据params和临时command执行策略内容
    /// - Parameters:
    ///   - command: 临时command map wrap
    ///   - params: params
    func strategy(command: [String: CommandBlockWrap], with params: [StrategyParam]) -> OPError?
}

@objcMembers
public final class StrategyService: NSObject {
    let strategy: StrategyConfig
    /// 这里默认会构造一个通用的操作系统参数，允许被替换 {"os": "iOS"}
    var commonParams: [StrategyParam] = [StrategyParam.buildParam("os", strValue: "iOS")]
    private var commandMap: [String: CommandBlock] = [:]

    /// 创建一个 StrategyService
    /// - Parameters:
    ///   - strategy: 规则Config
    ///   - commonParams: 执行命令，可以传入 []
    init(_ strategy: StrategyConfig, commonParams: [StrategyParam]) {
        self.strategy = strategy
        self.commonParams.append(contentsOf: commonParams)
        super.init()
    }
    
    
    /// 使用 configJson 创建一个空Command的 StrategyService
    public convenience init?(configJSON: String) {
        self.init(configJSON: configJSON, commonParams: [])
    }

    /// 使用 configJson 和 执行命令，创建一个 StrategyService
    public convenience init?(configJSON: String, commonParams: [StrategyParam]?) {
        guard let jsonData = configJSON.data(using: .utf8),
            let strategy = try? JSONDecoder().decode(StrategyConfig.self, from: jsonData) else {
            return nil
        }
        self.init(strategy, commonParams: commonParams ?? [])
    }
    
    
    /// 匹配规则 & run command 核心流程
    /// - Parameters:
    ///   - command: 所有可执行的command
    ///   - params: 执行参数
    /// - Returns: 执行错误返回的error
    private func run(command: [String: CommandBlock], with params: [StrategyParam]) -> OPError? {
        let param = buildParam(params)
        let commands = strategy.findCommands(param)
        do {
            var commandMap = self.commandMap
            commandMap.merge(command) { (_, new) in new }
            try runCommands(commands, commandMap: commandMap, paramMap: param)
        } catch {
            return error.newOPError(monitorCode: GDMonitorCode.strategy_run_command_fail)
        }
        return nil
    }
    
    
    /// 构造参数的工具方法
    private func buildParam(_ params: [StrategyParam]) -> [String: StrategyParam] {
        var result : [String: StrategyParam] = [:]
        for commonParam in commonParams {
            result[commonParam.type] = commonParam
        }
        for param in params {
            result[param.type] = param
        }
        return result
    }
}

/// 规则引擎对于外部API的抽象
extension StrategyService: StrategyServiceProtocol {
    public func register(name: String, with command: @escaping CommandBlock) {
        self.commandMap[name] = command
    }
    
    public func strategy(params: [StrategyParam]) -> OPError? {
        return run(command: [:], with: params)
        
    }
    
    public func strategy(command: [String: CommandBlock], with params: [StrategyParam]) -> OPError? {
        return run(command: command, with: params)
    }
    
    public func strategy(command: [String: CommandBlockWrap], with params: [StrategyParam]) -> OPError? {
        var commandMap: [String: CommandBlock] = [:]
        command.forEach { (key, wrap) in
            commandMap[key] = wrap.command
        }
        return run(command: commandMap, with: params)
    }
}

/// 规则引擎对于执行命令的抽象
extension StrategyService {
    func runCommands(_ commands: [[String]], commandMap: [String: CommandBlock], paramMap: [String: StrategyParam]) throws {
        if commands.count == 0 {
            BDPLogInfo(tag: .strategy, "command is empty, do nothing")
            return
        }
        for command in commands {
            do {
                let actions = try flatCommnad(command, commandMap: commandMap)
                try doActions(actions, paramMap: paramMap)
                BDPLogInfo(tag: .strategy, "do command: \(command)")
            } catch {
                BDPLogError(tag: .strategy, "do command fail, command: \(command), err=\(error)")
                throw error
            }
        }
    }

    
    /// 顺序执行Commands
    func doActions(_ actions: [CommandBlock], paramMap: [String: StrategyParam]) throws {
        actions.forEach { (action) in
            action(paramMap)
        }
    }

    /// 打平Command
    /// 由于command可能由不同的策略配置执行，且同一个Command可能执行多次，这里将所有的command找到，并整合为一维的顺序执行流程
    /// 注意：如果任何一个Command没有找到本地实现，则所有的Command均不执行
    /// - Parameters:
    ///   - command: 临时Command
    ///   - commandMap: Service持有的Command
    /// - Returns: 需要执行的一维Commands
    func flatCommnad(_ command: [String], commandMap: [String: CommandBlock]) throws -> [CommandBlock] {
        var actions: [CommandBlock] = []
        try command.forEach { (c) in
            guard let action = commandMap[c] else {
                throw OPError.error(monitorCode: GDMonitorCode.strategy_run_command_fail)
            }
            actions.append(action)
        }
        return actions
    }
}

/// 规则Param容器，用于扩展多种类型的 op 比较， 同时为 Swift 与 OC 提供不同的获取value的解决方案
/// 目前已支持:
///     - bool
///     - int
///     - float
///     - string
@objcMembers
public final class StrategyParam: NSObject {
    let type: String
    let value: StrategyValue
    
    private init(_ type: String, value: StrategyValue) {
        self.type = type
        self.value = value
        super.init()
    }
    
    public static func buildParam(_ type: String, boolValue value: Bool) -> StrategyParam {
        return StrategyParam(type, value: StrategyValue.bool(value))
    }
    
    public static func buildParam(_ type: String, strValue value: String) -> StrategyParam {
        return StrategyParam(type, value: StrategyValue.string(value))
    }
    
    public static func buildParam(_ type: String, intValue value: Int) -> StrategyParam {
        return StrategyParam(type, value: StrategyValue.number(Float(value)))
    }
    
    public static func buildParam(_ type: String, floatValue value: Float) -> StrategyParam {
        return StrategyParam(type, value: StrategyValue.number(value))
    }
    
    public func getValue() -> Any {
        switch value {
        case .bool(let v):
            return v
        case .number(let v):
            return v
        case .string(let v):
            return v
        }
    }
    
    public func getIntValue() -> Int {
        switch value {
        case .number(let v):
            return Int(v)
        default:
            return 0
        }
    }
    
    public func getFloatValue() -> Float {
        switch value {
        case .number(let v):
            return v
        default:
            return 0
        }
    }
    
    public func getStrValue() -> String {
        switch value {
        case .string(let v):
            return v
        default:
            return ""
        }
    }
    
    public func getBoolValue() -> Bool {
        switch value {
        case .bool(let v):
            return v
        default:
            return false
        }
    }
}

extension StrategyConfig {
    /// 查询所有符合条件的commands
    /// 规则: 1. options为二位数组; 2. 内层为 'and'; 3. 外层为 'or'
    /// 算法: 二维数组 -> map展开 -> map展开 -> 判断 -> &&取交 -> ||取或 -> 收集判断为true的commands
    ///
    /// DEMO: [[config1, config2], [config3, config 4]]
    /// 即满足 (config1 && config2) || (config3 && config4)
    func findCommands(_ paramMap: [String: StrategyParam]) -> [[String]] {
        let commands = actions.filter {
            $0.options.map {
                $0.map {
                    checkConfig($0, paramMap: paramMap)
                }.reduce(true, {$0 && $1})
            }.reduce(false, {$0 || $1})
        }.map { $0.commands }
        if commands.count == 0 {
            return []
        }
        switch actionMethod {
        case .actionBreak:
            return [commands[0]]
        default:
            return commands
        }
    }
    
    func checkConfig(_ key: String, paramMap:[String: StrategyParam]) -> Bool {
        guard let config = configs[key], let value = paramMap[config.type] else {
            return false
        }
        return config.compare(value.value)
    }
}

/// 兼容OC的CommandBlock包装容器，仅用于OC使用，Swift可直接使用 [CommandBlock]
@objcMembers
public final class CommandBlockWrap: NSObject {
    var command: CommandBlock

    init(_ command: @escaping CommandBlock) {
        self.command = command
        super.init()
    }
    
    public static func build(command: @escaping CommandBlock) -> CommandBlockWrap {
        return CommandBlockWrap(command)
    }
}
