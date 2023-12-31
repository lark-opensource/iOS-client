//
//  ProcessViewController.swift
//  FlowChartDev
//
//  Created by Bytedance on 2022/8/24.
//

import Foundation
import UIKit
import FlowChart

class ProcessInput: FlowChartInput {
    var extraInfo: [String: String] = [:]
}
typealias ProcessOutput = ProcessInput
class ProcessContext: FlowChartContext {
}

class Process1: FlowChartProcess<ProcessInput, ProcessOutput, ProcessContext> {
    override var identify: String { "Process1" }
    override func run(input: ProcessInput, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        let output = ProcessOutput()
        output.extraInfo = input.extraInfo
        output.extraInfo["step"] = self.identify
        self.accept(.success(output))
    }
}
class Process2: FlowChartProcess<ProcessInput, ProcessOutput, ProcessContext> {
    override var identify: String { "Process2" }
    override func run(input: ProcessInput, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        let output = ProcessOutput()
        output.extraInfo = input.extraInfo
        output.extraInfo["step"] = self.identify
        self.accept(.success(output))
    }
}
class Process3: FlowChartProcess<ProcessInput, ProcessOutput, ProcessContext> {
    override var identify: String { "Process3" }
    override func run(input: ProcessInput, _ resConsumer: @escaping ResponseConsumer = { _ in }) {
        let output = ProcessOutput()
        output.extraInfo = input.extraInfo
        output.extraInfo["step"] = self.identify
        self.accept(.success(output))
    }
}

class ProcessViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 手动组装Process，运行
        let process1 = Process1(context: ProcessContext())
        process1.next(Process2(context: ProcessContext())) { output in
            if case let .success(output) = output {
                let input = ProcessInput()
                input.extraInfo = output.extraInfo
                return input
            }
            // 返回nil，后续task不会继续执行
            return nil
        }.next(Process3(context: ProcessContext())) { output in
            if case let .success(output) = output {
                let input = ProcessInput()
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
        process1.run(input: ProcessInput())
    }
}
