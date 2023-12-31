//
//  TaskViewController.swift
//  FlowChartDev
//
//  Created by Bytedance on 2022/8/24.
//

import Foundation
import UIKit
import FlowChart

class TaskInput: FlowChartInput {
    var extraInfo: [String: String] = [:]
}
typealias TaskOutput = TaskInput
class TaskContext: FlowChartContext {
}

class Task1: FlowChartTask<TaskInput, TaskOutput, TaskContext> {
    override var identify: String { "Task1" }
    override func run(input: TaskInput) {
        let output = TaskOutput()
        output.extraInfo = input.extraInfo
        output.extraInfo["step"] = self.identify
        self.accept(.success(output))
    }
}
class Task2: FlowChartTask<TaskInput, TaskOutput, TaskContext> {
    override var identify: String { "Task2" }
    override func run(input: TaskInput) {
        let output = TaskOutput()
        output.extraInfo = input.extraInfo
        output.extraInfo["step"] = self.identify
        self.accept(.success(output))
    }
}
class Task3: FlowChartTask<TaskInput, TaskOutput, TaskContext> {
    override var identify: String { "Task3" }
    override func run(input: TaskInput) {
        let output = TaskOutput()
        output.extraInfo = input.extraInfo
        output.extraInfo["step"] = self.identify
        self.accept(.success(output))
    }
}

class TaskViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 手动组装Task，运行
        let task1 = Task1(context: TaskContext())
        task1.next(Task2(context: TaskContext())) { output in
            if case let .success(output) = output {
                let input = TaskInput()
                input.extraInfo = output.extraInfo
                return input
            }
            // 返回nil，后续task不会继续执行
            return nil
        }.next(Task3(context: TaskContext())) { output in
            if case let .success(output) = output {
                let input = TaskInput()
                input.extraInfo = output.extraInfo
                return input
            }
            // 返回nil，后续task不会继续执行
            return nil
        }.onEnd { output in
            if case let .success(output) = output {
                print("success \(output.extraInfo)")
            }
            if case let .error(error) = output {
                print("error \(error.getExtraInfo())")
            }
        }
        task1.run(input: TaskInput())
    }
}
