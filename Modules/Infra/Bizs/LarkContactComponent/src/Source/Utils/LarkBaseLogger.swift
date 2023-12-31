//
//  LarkBaseLogger.swift
//  LarkContactComponent
//
//  Created by Yuri on 2023/5/10.
//
import Foundation
#if canImport(LKCommonsLogging)
import LKCommonsLogging
#endif

public protocol BaseLoggerModuleType {
    var value: String { get }
}
open class LarkBaseLogger {

    open var moduleName: String { "Base" }
    private let queue = DispatchQueue(label: "com.lark.logger.messenger")

    public init() {}

#if canImport(LKCommonsLogging)
    private let logger = Logger.log(LarkBaseLogger.self)
#endif

#if canImport(LKCommonsLogging)
    public func info(module: BaseLoggerModuleType, event: String, parameters: String? = nil) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            if let parameters = parameters {
                self.logger.info("[\(self.moduleName)]{\(module.value)}-\(event): \(parameters)")
            } else {
                self.logger.info("[\(self.moduleName)]{\(module.value)}-\(event)")
            }
        }
    }

    public func info(module: BaseLoggerModuleType, event: String, parametersHandler: @escaping (() -> String)) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            let parameters = parametersHandler()
            self.logger.info("[\(self.moduleName)]{\(module.value)}-\(event): \(parameters)")
        }
    }

    public func error(module: BaseLoggerModuleType, event: String, parameters: String? = nil) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            if let parameters = parameters {
                self.logger.error("[\(self.moduleName)]{\(module.value)}-\(event): \(parameters)")
            } else {
                self.logger.error("[\(self.moduleName)]{\(module.value)}-\(event)")
            }
        }
    }

    public func error(module: BaseLoggerModuleType, event: String, parametersHandler: @escaping (() -> String)) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            let parameters = parametersHandler()
            self.logger.error("[\(self.moduleName)]{\(module.value)}-\(event): \(parameters)")
        }
    }
#else
    public func info(module: BaseLoggerModuleType, event: String, parameters: String? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            print("info [\(self.moduleName)]{\(module.value)}-\(event): \(parameters ?? "")")
        }
    }

    public func error(module: BaseLoggerModuleType, event: String, parameters: String? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            print("error [\(self.moduleName)]{\(module.value)}-\(event): \(parameters ?? "")")
        }
    }

    public func info(module: BaseLoggerModuleType, event: String, parametersHandler: @escaping (() -> String)) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            let parameters = parametersHandler()
            print("info [\(self.moduleName)]{\(module.value)}-\(event): \(parameters)")
        }
    }

    public func error(module: BaseLoggerModuleType, event: String, parametersHandler: @escaping (() -> String)) {
        queue.async { [weak self] in
            guard let self = self else {return}
            let parameters = parametersHandler()
            print("error [\(self.moduleName)]{\(module.value)}-\(event): \(parameters)")
        }
    }
#endif
}
