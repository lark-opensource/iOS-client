//
//  OPJSSocketDebugModule.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/15.
//
// sockect debug的module，跟ide的调试

import Foundation
import LKCommonsLogging

public final class OPJSSocketDebugModule: NSObject, GeneralJSRuntimeModuleProtocol, BDPJSRuntimeSocketConnectionDelegate {
    static let logger = Logger.log(OPJSSocketDebugModule.self, category: "OPJSEngine")

    public weak var jsRuntime: GeneralJSRuntime?


    public override init() {
        super.init()
    }

    public func runtimeLoad() // js runtime初始化
    {
    }

    public func runtimeReady()
    {
    }

    @objc public var connection: BDPJSRuntimeSocketConnection?

    @objc public func createConnection(address: String) -> BDPJSRuntimeSocketConnection? {
        guard let dispatchQueue = self.jsRuntime?.dispatchQueue else {
            Self.logger.error("createConnection fail, dispatchQueue is nil")
            return nil
        }

        connection = BDPJSRuntimeSocketConnection.createConnection(withAddress: address, jsQueue: dispatchQueue, delegate: self)

        return connection;
    }


    @objc public func finishDebug() {
        let message = BDPJSRuntimeSocketMessage()
        message.name = "inspector"
        message.event = "end"
        connection?.send(message)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.connection?.disConnect()
        }
    }

    @objc public func createMessage(arguments: [Any]) -> BDPJSRuntimeSocketMessage {
        let message = BDPJSRuntimeSocketMessage()
        message.name = "subscribeHandler"
        if arguments.count >= 1 {
            if let event = arguments.first as? String {
                message.event = event
            }
        }
        if arguments.count >= 2 {
            let data = arguments[1]
            if let dataString = data as? String {
                message.data = dataString

            } else if let dataValue = data as? JSValue, let dataDict = OPJSEngineService.shared.utils?.convertJSValueToObject(dataValue) {
                message.data = dataDict.jsonRepresentation()
            } else if let dataDict = data as? NSDictionary {
                message.data = dataDict.jsonRepresentation()
            }
        }
        if arguments.count >= 3 {
            if let jsValue = arguments[2] as? JSValue, !jsValue.isUndefined {
                let webviewIdNumber = NSNumber(value: jsValue.toInt32())
                message.webviewId = webviewIdNumber
            } else if let webviewId = arguments[2] as? Int {
                if let webviewIdConvert = Int32(exactly: webviewId) {
                    let webviewIdNumber = NSNumber(value: webviewIdConvert)
                    message.webviewId = webviewIdNumber
                }
            }
        }
        return message
    }

    @objc public func sendMessage(message: BDPJSRuntimeSocketMessage) -> Bool {
        guard let connection = connection else {
            Self.logger.error("sendMessage fail, connection is nil")
            return false
        }

        return connection.send(message)
    }


    @objc public func sendMessage(name: String, event: String?, callbackId: NSNumber?, data: String?) -> Bool {
        return sendMessage(name: name, event: event, paramsDict: nil, callbackId: callbackId, result: nil, timerType: nil, timerId: nil, time: nil, workerInitParams: nil, data: data, webviewIds: nil)
    }

    public func sendMessage(name: String, event: String?, paramsDict: [AnyHashable : Any]?, callbackId: NSNumber?, result: String?, timerType: String?, timerId: Int?, time: Int?, workerInitParams: [AnyHashable : Any]?, data: String?, webviewIds: String?) -> Bool {
        guard let connection = connection else {
            Self.logger.error("sendMessage fail, connection is nil")
            return false
        }

        let message = BDPJSRuntimeSocketMessage()
        message.name = name
        if let event = event {
            message.event = event
        }
        if let paramsDict = paramsDict {
            message.paramsDict = paramsDict
        }
        if let result = result {
            message.result = result
        }

        if let timerType = timerType {
            message.timerType = timerType
        }
        if let timerId = timerId {
            message.timerId = timerId
        }
        if let time = time {
            message.time = time
        }
        if let workerInitParams = workerInitParams {
            message.workerInitParams = workerInitParams
        }
        if let webviewIds = webviewIds {
            message.webviewIds = webviewIds
        }
        if let data = data {
            message.data = data
        }
        if let callbackId = callbackId {
            message.callbackId = callbackId
        }
        return connection.send(message)
    }

    // 发送invoke消息给socket对端
    func invoke(message: BDPJSRuntimeSocketMessage) {
        let params = (jsRuntime?.jsonValue(message.params as NSString) as? [AnyHashable : Any]) ?? [:]
        let callbackIdString = message.callbackId.stringValue
        let result = self.jsRuntime?.invoke(event: message.event, param: params, callbackID: callbackIdString, extra: nil, isNewBridge:false) as? String
        let resultMessage = BDPJSRuntimeSocketMessage()
        resultMessage.name = message.name
        resultMessage.event = message.event
        resultMessage.params = message.params
        resultMessage.callbackId = message.callbackId
        if let messageResult = result {
            resultMessage.result = messageResult
        }
        connection?.send(resultMessage)
    }

    func call(message: BDPJSRuntimeSocketMessage) {
        let paramsDict = message.paramsDict
        let result = self.jsRuntime?.call(event: message.event, param: paramsDict, callbackID: message.callbackId)
        let resultMessage = BDPJSRuntimeSocketMessage()
        resultMessage.name = message.name
        resultMessage.event = message.event
        resultMessage.paramsDict = message.paramsDict
        resultMessage.callbackId = message.callbackId
        if let result = result {
            resultMessage.result = result.jsonRepresentation()
        }
        connection?.send(resultMessage)
    }

    // MARK: BDPJSRuntimeSocketConnectionDelegate
    public func connection(_ connection: BDPJSRuntimeSocketConnection, statusChanged status: BDPJSRuntimeSocketStatus) {
        guard let jsRuntime = jsRuntime else {
            Self.logger.error("connection statusChanged fail, jsRuntime is nil")
            return
        }
        jsRuntime.connection(connection, statusChanged: status)
    }

    public func connection(_ connection: BDPJSRuntimeSocketConnection, didReceive message: BDPJSRuntimeSocketMessage) {
        guard let jsRuntime = jsRuntime else {
            Self.logger.error("connection didReceive fail, jsRuntime is nil")
            return
        }
        if message.name == "invoke" {
            invoke(message: message)
            return
        } else if message.name == "call" {
            call(message: message)
            return
        } else if message.name == "setTimer" {
            jsRuntime.timerModule.setTimer(message: message)
            return
        } else if message.name == "clearTimer" {
            jsRuntime.timerModule.clearTimer(message: message)
            return
        }
        jsRuntime.connection(connection, didReceive: message)
    }


    public func socketDidConnected() {
        jsRuntime?.socketDidConnected()
    }

    public func socketDidFailWithError(_ error: Error) {
        jsRuntime?.socketDidFailWithError(error)
    }

    public func socketDidClose(withCode code: Int, reason: String, wasClean: Bool) {
        jsRuntime?.socketDidClose(withCode: code, reason: reason, wasClean: wasClean)
    }

}


