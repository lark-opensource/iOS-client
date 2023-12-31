//
//  EffictiveLogger.swift
//  Calendar
//
//  Created by JackZhao on 2023/10/17.
//

import RxSwift
import Foundation
import LKCommonsLogging

// MARK: Eff = Effictive

public enum EffTask: String {
    case action
    case change
    case request
    case response
    case process
    case push
    case reload
    case `break`
    case `default`
    case end
    case abort
    case other
}

// 埋点时在各个流程间流转的模型协议
protocol EffLoggerModelProtocol {
    typealias Task = EffTask
    // 业务场景标识
    var biz: String { get }
    var descrpition: String { get }
    mutating func updateTask(_ task: Task)
    mutating func addAsyncTask(_ task: Task)
    func getCurrentTask() -> Task
    func getCurrentAsyncTask() -> Task?
    func getDescription() -> String
}

protocol EffLoggerProtocol {
    func log(model: EffLoggerModelProtocol, toast: String)
}

typealias CAValue<T> = EffValue<T, CaVCLoggerModel>

class EffValue<T, E: EffLoggerModelProtocol> {
    var value: T
    var loggerModel: E

    init(_ value: T, _ model: E) {
        self.value = value
        self.loggerModel = model
    }
}

// 统一埋点类
class EffLogger: EffLoggerProtocol {
    private static var isShowCost: Bool {
        #if DEBUG
        return true
        #endif
        return false
    }
    static var isCutLog: Bool {
        #if DEBUG
        return true
        #endif
        return false
    }
    static var shouldLog: Bool = false
    static var lastTime: TimeInterval?

    private static let logger = Logger.log(EffLogger.self, category: "lark.calendar")
    // 打日志方法
    func log(model: EffLoggerModelProtocol,
             toast: String) {
        Self.log(model: model, toast: toast, error: nil)
    }

    static func log(model: EffLoggerModelProtocol,
                    toast: String,
                    error: Error? = nil) {
        guard shouldLog else { return }
        if case .default = model.getCurrentTask() {
            return
        }
        var costDescription: String = ""
        if isShowCost {
            if let lastTime = lastTime, isShowCost {
                let cost = Int((CACurrentMediaTime() - lastTime) * 1000)
                costDescription = "🔥 cost = \(cost))"
            }
            lastTime = CACurrentMediaTime()
        }
        Self.logger.info("\(model.getDescription()) => \(toast)\(costDescription)")
    }
}

// 视图页埋点时在各个流程间流转的模型
// CaVC = CalendarViewController
struct CaVCLoggerModel: EffLoggerModelProtocol {
    typealias Task = EffTask
    // MARK: 计算属性
    var biz: String {
        "CaVC"
    }
    var header: String {
        "biz=\(biz)"
    }
    var descrpition: String {
        header + separator + flagDescription + separator + taskDescription
    }
    private var taskDescription: String {
        if let task = asyncTask { return "asyncTask={\(task.rawValue)}" }
        return "task={\(task.rawValue)}"
    }
    private var flagDescription: String { "flag = {\(flag)\(subFlags)}" }

    // MARK: 存储属性
    private var flag = ""
    private var task: Task
    private var subFlags = ""
    private var asyncTask: Task?
    private var asyncTasks: [Task] = []
    private let separator = ", "

    init(task: Task = .default,
         isGenerateFlag: Bool = true) {
        self.task = task
        if isGenerateFlag {
            self.flag = getNewFlag()
        }
    }
    // MARK: 修改结构体属性的方法
    mutating func addAsyncTask(_ task: Task) {
        self.asyncTask = task
        self.asyncTasks.append(task)
    }
    mutating func updateTask(_ task: Task) {
        if self.asyncTask != nil {
            self.asyncTask = task
        } else {
            self.task = task
        }
    }

    // MARK: 核心工具方法
    // 获取新的任务标识
    func createNewModelByAddAsyncTask(_ task: Task) -> CaVCLoggerModel {
        if case .default = self.task {
            assertionFailure("default task not been change")
            return CaVCLoggerModel(task: .default)
        }
        var new = self
        new.asyncTask = task
        new.subFlags += "-" + getNewFlag()
        new.asyncTasks.append(task)
        return new
    }

    func log(_ toast: String) {
        EffLogger.log(model: self, toast: toast)
    }

    func logEnd(_ toast: String) {
        var new = self
        new.task = .end
        EffLogger.log(model: new, toast: toast)
    }

    func createNewModelByTask(_ task: Task) -> CaVCLoggerModel {
        if case .default = self.task {
            assertionFailure("default task not been change")
            return CaVCLoggerModel(task: .default)
        }
        var new = self
        new.updateTask(task)
        return new
    }

    func getCurrentTask() -> Task {
        task
    }

    func getCurrentAsyncTask() -> Task? {
        asyncTask
    }

    private func getNewFlag() -> String {
        let length = 5
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%^&*"
        return String((0..<length).map { _ in letters.randomElement() ?? Character("") })
    }

    // MARK: 跨平台通信工具方法
    // 在多平台间通信时，获取头部信息
    // 即 "biz={业务}, task={任务:标识}, flag={{标识}-{标识}} =>" 部分
    func getDescription() -> String {
        return descrpition
    }

    // 通过字符串析构成当前结构体
    static func transformBy(_ str: String) -> CaVCLoggerModel {
        // TODO @jack: Rust层接入后进行实现
        CaVCLoggerModel(task: .other)
    }
}
