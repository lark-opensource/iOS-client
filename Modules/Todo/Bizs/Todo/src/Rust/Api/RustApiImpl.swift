//
//  RustApi.swift
//  Todo
//
//  Created by 张威 on 2020/11/20.
//

import RxSwift
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker
import Swinject
import RustPB
import ServerPB
import EEAtomic

final class RustApiImpl {

    static let logger = Logger.log(RustApiImpl.self, category: "Todo.RustApi")

    let client: RustService

    init(client: RustService) {
        self.client = client
    }

    struct Transform<Input> {
        static func toVoid() -> (Input) -> Void {
            return { (_: Input) in void }
        }

        static func toKeyPath<V>(_ keyPath: KeyPath<Input, V>) -> (Input) -> V {
            return { (input: Input) in input[keyPath: keyPath] }
        }
    }

    // 随机产生 context id
    private static func generateContextId() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var ranStr = ""
        for _ in 0..<10 {
            let index = Int(arc4random_uniform(UInt32(characters.count)))
            ranStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
        }
        return ranStr
    }

    static func generateContext(file: String = #fileID, function: String = #function, line: Int = #line) -> ApiContext {
        return ApiContext(
            id: generateContextId(),
            file: file,
            function: function,
            line: line
        )
    }

    struct ApiContext {
        var cmd: RustPB.Basic_V1_Command = .unknownCommand
        var serverCmd: ServerPB.ServerPB_Improto_Command?
        var reqTimestamp: CFTimeInterval = 0

        fileprivate let id: String
        fileprivate let file: String
        fileprivate let function: String
        fileprivate let line: Int

        private var cmdName: String {
            if let serverCmd = serverCmd {
                return String(describing: serverCmd)
            } else {
                return String(describing: cmd)
            }
        }

        // Api slardar 上报: 耗时 + 错误
        private let slardarNames = (cost: "todo_api_cost", fail: "todo_api_fail")

        #if DEBUG
        var reqInvoked = AtomicBool(false)
        #endif

        mutating func logReq(_ msg: String) {
            #if DEBUG
            if serverCmd == nil { assert(cmd != .unknownCommand) }
            reqInvoked.exchange(true)
            #endif
            reqTimestamp = CACurrentMediaTime()
            RustApiImpl.logger.info("[cmd.\(cmdName).req] ctxId: \(id), msg: \(msg)", file: file, function: function, line: line)
        }

        func logRes(_ msg: String) {
            #if DEBUG
            if serverCmd == nil { assert(cmd != .unknownCommand) }
            assert(reqInvoked.compare(expected: true, replace: true))
            #endif
            if reqTimestamp > 1.0 {
                // api 请求耗时上报
                let cost = (CACurrentMediaTime() - reqTimestamp) * 1_000 // 单位 ms
                Tracker.post(SlardarEvent(
                    name: slardarNames.cost,
                    metric: ["cost": cost],
                    category: ["cmd": cmdName],
                    extra: [:]
                ))
            }
            RustApiImpl.logger.info("[cmd.\(cmdName).res] ctxId: \(id), msg: \(msg)", file: file, function: function, line: line)
        }

        func logRes(_ err: Error) {
            #if DEBUG
            if serverCmd == nil { assert(cmd != .unknownCommand) }
            assert(reqInvoked.compare(expected: true, replace: true))
            #endif
            RustApiImpl.logger.error("[cmd.\(cmdName).res] ctxId: \(id), err: \(err)", file: file, function: function, line: line)
            let event = SlardarEvent(
                name: slardarNames.fail,
                metric: [:],
                category: ["cmd": cmdName],
                extra: [:]
            )
            Tracker.post(event)
        }
    }

}

extension ObservableType {

    func log(with context: RustApiImpl.ApiContext, transform: @escaping (Self.Element) -> String) -> Observable<Self.Element> {
        return self.do(
            onNext: { context.logRes(transform($0)) },
            onError: { context.logRes($0) }
        )
    }

}
