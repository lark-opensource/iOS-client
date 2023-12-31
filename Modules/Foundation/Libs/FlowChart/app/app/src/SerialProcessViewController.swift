//
//  SerialProcessViewController.swift
//  FlowChartDev
//
//  Created by Bytedance on 2022/8/25.
//

import Foundation
import UIKit
import FlowChart

class SerialProcessViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 利用提供的，内部已有组装逻辑的Process，直接设置Task，运行
        let taskProcess = FlowChartSerialProcess([Task1(context: TaskContext()), Task2(context: TaskContext()), Task3(context: TaskContext())], context: TaskContext())
        taskProcess.run(input: TaskInput()) { response in
            switch response {
            case .success(let idf, let extraInfo):
                print("success \(idf)")
            case .failure(let idf, let error):
                print("error \(idf))")
            }
        }
        print("-------------------------------")

        // process1 -> process2 -> process3 ->         conditionProcess            ->          serialProcess             -> process2
        //                                               serialProcess                 process1 -> process2 -> process3
        //                                      process1 -> process2 -> process3
        let processs = FlowChartSerialProcess([Process1(context: ProcessContext()), Process2(context: ProcessContext()), Process3(context: ProcessContext())], context: ProcessContext())
        processs.append(FlowChartConditionProcess(context: ProcessContext(), { output in
            return (FlowChartSerialProcess([Process1(context: ProcessContext()), Process2(context: ProcessContext()), Process3(context: ProcessContext())], context: ProcessContext()), output)
        }))
        processs.append(FlowChartSerialProcess([Process1(context: ProcessContext()), Process2(context: ProcessContext()), Process3(context: ProcessContext())], context: ProcessContext()))
        processs.append(Process2(context: ProcessContext()))
        processs.run(input: ProcessInput()) { response in
            switch response {
            case .success(let idf, let extraInfo):
                print("success \(idf)")
            case .failure(let idf, let error):
                print("error \(idf))")
            }
        }
        print("-------------------------------")

        let conProcess = FlowChartConditionProcess(context: ProcessContext(), { output in
            return (Process1(context: ProcessContext()), output)
        })
        conProcess.run(input: ProcessInput(), { response in
            switch response {
            case .success(let idf, let extraInfo):
                print("success \(idf)")
            case .failure(let idf, let error):
                print("error \(idf))")
            }
        })
        print("-------------------------------")
    }
}
