//
//  手动缓存清理Demo.swift
//  LarkCacheDev
//
//  Created by Supeng on 2020/8/18.
//

import Foundation
import UIKit
import LarkCache

///// 注册逻辑应该写到各个模块的Assembly方法中
//let dummy: () = CleanTaskRegistry.register(cleanTask: TestTask())
//
//struct TestTask: CleanTask {
//    var name: String { "TestTask" }
//
//    let db = FakeDB()
//
//    func clean(config: CleanConfig, completion: @escaping Completion) {
//        db.cleanToTime(config.global.cacheTimeLimit, completion: completion)
//    }
//
//    func cancel() {
//        db.cancelClean()
//    }
//}
//
//class FakeDB {
//    lazy var cleanQueue: OperationQueue = OperationQueue()
//
//    /// 清理time时间之前的数据
//    func cleanToTime(_ time: Int, completion: @escaping CleanTask.Completion) {
//        cleanQueue.addOperation { print("clean data 1") }
//        cleanQueue.addOperation { print("clean data 2") }
//        cleanQueue.addOperation { print("clean data 3") }
//        if #available(iOS 13.0, *) {
//            cleanQueue.addBarrierBlock {
//                let result = TaskResult(completed: true,
//                                        costTime: 100,
//                                        size: .bytes(200))
//                completion(result)
//            }
//        }
//    }
//
//    func cancelClean() {
//        cleanQueue.cancelAllOperations()
//    }
//}
