//
//  CalendarRustService.swift
//  Calendar
//
//  Created by zhuheng on 2022/4/18.
//

import Foundation
import CalendarFoundation
import RxSwift
import LarkRustClient
import RustPB
import LarkLocalizations
import ServerPB
import LKCommonsLogging
import SwiftProtobuf

// https://bytedance.feishu.cn/docx/doxcnwEFBQsb4Tx7YKDc6o2skRc
class CalendarRustService {
    class ApiStage {
        var requestMsg: String {
            "\(name) onRequest"
        }

        var responseMsg: String {
            "\(name) onResponse"
        }

        var disposeMsg: String {
            "\(name) onDispose"
        }

        var errorMsg: String {
            "\(name) onError"
        }

        private let name: String

        init(name: String) {
            self.name = name
        }
    }

    private let rustService: RustService
    let logger = Logger.log(CalendarRustService.self, category: "CalendarRustService")

    init(rustService: RustService) {
        self.rustService = rustService
    }

    private func makeContextID() -> String {
        let characters =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var ranStr = ""
        for _ in 0..<10 {
            let index = Int(arc4random_uniform(UInt32(characters.count)))
            ranStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
        }
        return ranStr
    }

}

// MARK: 异步请求
extension CalendarRustService {
    /// 生成异步请求，忽略 response
    /// - Parameters:
    ///   - message: Rust 请求 message
    ///   - debugParams: 打印自定义请求参数
    func async(message: Message,
               debugParams: [String: String]?,
               barrier: Bool = false,
               file: String = #fileID,
               function: String = #function,
               line: Int = #line) -> Observable<Void> {
        let contextID = makeContextID()
        let reqMsgName = type(of: message.self).protoMessageName
        let apiStage = ApiStage(name: reqMsgName)
        if let data = debugParams?.merging(["contextID": contextID]) { (l, _) -> String in
            return l
        } {
            // RustClient 里有打印 request，如无参数就不必打印了
            self.logger.info(apiStage.requestMsg,
                             additionalData: data,
                             file: file,
                             function: function,
                             line: line)
        }

        var packet = RequestPacket(message: message)
        packet.parentID = contextID
        packet.barrier = barrier

        return rustService.async(packet)
            .do(onDispose: { [weak self] in
                self?.logger.info(apiStage.disposeMsg,
                                  additionalData: ["contextID": contextID],
                                  file: file,
                                  function: function,
                                  line: line)
            })

    }

    /// 生成异步请求
    /// - Parameters:
    ///   - message: Rust 请求 message
    ///   - debugParams: 打印自定义请求参数
    ///   - debugResponse: 打印自定义返回值
    func async<R: Message>(message: Message,
                           debugParams: [String: String]?,
                           debugResponse: ((R) -> [String: String]?)?,
                           barrier: Bool = false,
                           file: String = #fileID,
                           function: String = #function,
                           line: Int = #line) -> Observable<R> {
        let contextID = makeContextID()
        let reqMsgName = type(of: message.self).protoMessageName

        let apiStage = ApiStage(name: reqMsgName)

        if let data = debugParams?.merging(["contextID": contextID]) { (l, _) -> String in
            return l
        } {
            // RustClient 里有打印 request，如无参数就不必打印了
            self.logger.info(apiStage.requestMsg,
                             additionalData: data,
                             file: file,
                             function: function,
                             line: line)
        }

        return rustService.async(message: message, parentID: contextID, barrier: barrier)
            .do(onNext: { [weak self] (response: R) in
                if let data = debugResponse?(response)?.merging(["contextID": contextID]) { (l, _) -> String in
                    return l
                } {
                    // RustClient 里有打印 success，如无参数就不必打印了
                    self?.logger.info(apiStage.responseMsg,
                                      additionalData: data,
                                      file: file,
                                      function: function,
                                      line: line)
                }
            }, onDispose: { [weak self] in
                self?.logger.info(apiStage.disposeMsg,
                                  additionalData: ["contextID": contextID],
                                  file: file,
                                  function: function,
                                  line: line)
            })
    }

    /// 生成异步透传请求
    /// - Parameters:
    ///   - message: Rust 请求 message
    ///   - debugParams: 打印自定义请求参数
    ///   - debugResponse: 打印自定义返回值
    func sendPassThroughAsyncRequest<R: SwiftProtobuf.Message>(
        _ message: SwiftProtobuf.Message,
        serCommand: ServerPB_Improto_Command,
        debugParams: [String: String]?,
        debugResponse: ((R) -> [String: String]?)?,
        barrier: Bool = false,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) -> Observable<R> {

        let contextID = makeContextID()
        let reqMsgName = type(of: message.self).protoMessageName
        let apiStage = ApiStage(name: reqMsgName)

        if let data = debugParams?.merging(["contextID": contextID]) { (l, _) -> String in
            return l
        } {
            // RustClient 里有打印 request，如无参数就不必打印了
            self.logger.info(apiStage.requestMsg,
                             additionalData: data,
                             file: file,
                             function: function,
                             line: line)
        }

        var packet = RequestPacket(message: message)
        packet.parentID = contextID
        packet.barrier = barrier
        packet.serCommand = serCommand

        return rustService.async(packet)
            .do(onNext: { [weak self] (response: R) in
                if let data = debugResponse?(response)?.merging(["contextID": contextID]) { (l, _) -> String in
                    return l
                } {
                    // RustClient 里有打印 success，如无参数就不必打印了
                    self?.logger.info(apiStage.responseMsg,
                                      additionalData: data,
                                      file: file,
                                      function: function,
                                      line: line)
                }

            }, onDispose: { [weak self] in
                self?.logger.info(apiStage.disposeMsg,
                                  additionalData: ["contextID": contextID],
                                  file: file,
                                  function: function,
                                  line: line)
            })
    }
}

// MARK: 同步请求
extension CalendarRustService {
    /// 生成同步请求
    /// - Parameters:
    ///   - message: Rust 请求 message
    ///   - debugParams: 打印自定义请求参数
    ///   - debugResponse: 打印自定义返回值
    func sync<R: Message>(message: Message,
                          debugParams: [String: String]?,
                          debugResponse: ((R) -> [String: String]?)?,
                          allowOnMainThread: Bool = false,
                          file: String = #fileID,
                          function: String = #function,
                          line: Int = #line) throws -> R {
        let contextID = makeContextID()
        let reqMsgName = type(of: message.self).protoMessageName

        let apiStage = ApiStage(name: reqMsgName)

        if let data = debugParams?.merging(["contextID": contextID]) { (l, _) -> String in
            return l
        } {
            // RustClient 里有打印 request，如无参数就不必打印了
            self.logger.info(apiStage.requestMsg,
                             additionalData: data,
                             file: file,
                             function: function,
                             line: line)
        }

        let response: R = try rustService.sync(message: message, parentID: contextID, allowOnMainThread: allowOnMainThread)

        if let data = debugResponse?(response)?.merging(["contextID": contextID]) { (l, _) -> String in
            return l
        } {
            // RustClient 里有打印 success，如无参数就不必打印了
            self.logger.info(apiStage.responseMsg,
                              additionalData: data,
                              file: file,
                              function: function,
                              line: line)
        }

        self.logger.info(apiStage.disposeMsg,
                          additionalData: ["contextID": contextID],
                          file: file,
                          function: function,
                          line: line)
        return response
    }

    /// 生成同步请求，返回 Observable
    /// - Parameters:
    ///   - message: Rust 请求 message
    ///   - debugParams: 打印自定义请求参数
    ///   - debugResponse: 打印自定义返回值
    func sync<R: Message>(message: Message,
                          debugParams: [String: String]?,
                          debugResponse: ((R) -> [String: String]?)?,
                          allowOnMainThread: Bool = false,
                          file: String = #fileID,
                          function: String = #function,
                          line: Int = #line) -> Observable<R> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let `self` = self else { return Disposables.create() }
            do {
                let res: R = try self.sync(message: message, debugParams: debugParams, debugResponse: debugResponse, allowOnMainThread: allowOnMainThread, file: file, function: function, line: line)
                observer.onNext(res)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}
