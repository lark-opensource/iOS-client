//
//  RedPacketReciableTrack.swift
//  LarkFinance
//
//  Created by ByteDance on 2023/6/27.
//

import UIKit
import Foundation
import AppReciableSDK
import LKCommonsLogging
import ThreadSafeDataStructure

public struct RedPacketReciableTrack {
    static let logger = Logger.log(RedPacketReciableTrack.self, category: "Module.Finance.RedPacketReciableTrack")

    struct RedPacketReceiveContext {
        /// 领红包开始时间
        var receiveStartTime: CFTimeInterval
        /// 领红包网络请求耗时
        var receiveRedPacketNetworkCost: Int

        init(receiveStartTime: CFTimeInterval = CACurrentMediaTime(),
             receiveRedPacketNetworkCost: Int = 0) {
            self.receiveStartTime = receiveStartTime
            self.receiveRedPacketNetworkCost = receiveRedPacketNetworkCost
        }
    }

    struct RedPacketSendContext {
        /// 发红包开始时间
        var sendStartTime: CFTimeInterval
        /// 发红包网络请求耗时
        var sendRedPacketNetworkCost: Int

        init(sendStartTime: CFTimeInterval = CACurrentMediaTime(),
             sendRedPacketNetworkCost: Int = 0) {
            self.sendStartTime = sendStartTime
            self.sendRedPacketNetworkCost = sendRedPacketNetworkCost
        }
    }

    // 红包打点相关配置
    private static var receiveRedPacketKey: DisposedKey?
    private static var receiveRedPacketTrackMap: SafeDictionary<DisposedKey, RedPacketReceiveContext> = [:] + .readWriteLock

    private static var sendRedPacketKey: DisposedKey?
    private static var sendRedPacketTrackMap: SafeDictionary<DisposedKey, RedPacketSendContext> = [:] + .readWriteLock

    public static func getReceiveRedPacketKey() -> DisposedKey? {
        return self.receiveRedPacketKey
    }

    private enum ReceiveRedPacketEvent: ReciableEventable {
        case receiveRedPacket
        var eventKey: String {
            switch self {
            case .receiveRedPacket:
                return "receive_red_packet"
            }
        }
    }

    public static func receiveRedPacketLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Chat,
                                              eventable: ReceiveRedPacketEvent.receiveRedPacket,
                                              page: "OpenRedPacketViewController")
        receiveRedPacketTrackMap.removeAll()
        var context = RedPacketReceiveContext()
        context.receiveStartTime = CACurrentMediaTime()
        receiveRedPacketTrackMap[key] = context
        self.receiveRedPacketKey = key
        Self.logger.info("Key: \(key), receiveRedPacket StratTime At: \(context.receiveStartTime)")
    }

    public static func updateReceiveRedPacketEndNetworkCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = receiveRedPacketKey else {
                return
            }
            receiveRedPacketTrackMap[disposedKey]?.receiveRedPacketNetworkCost = Int(cost * 1000)
            Self.logger.info("Key: \(disposedKey), update receive RedPacket SDK Network Cost: \(Int(cost * 1000))")
        }
    }

    public static func receiveRedPacketLoadTimeEnd(key: DisposedKey?) {
        guard let key = key,
            let context = receiveRedPacketTrackMap.removeValue(forKey: key) else {
            return
        }
        var latencyDetail: [String: Any] = [:]
        latencyDetail["sdk_cost_net"] = context.receiveRedPacketNetworkCost
        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: nil,
                          category: ["redPacket_type": 0])
        AppReciableSDK.shared.end(key: key, extra: extra)
        Self.logger.info("Key: \(key), receive RedPacket Load End")
    }

    public static func receiveRedPacketLoadNetworkError(errorCode: Int,
                                            errorMessage: String) {
        let extra = Extra(isNeedNet: true)
        let errorParams = ErrorParams(biz: .Messenger,
                                      scene: .Chat,
                                      eventable: ReceiveRedPacketEvent.receiveRedPacket,
                                      errorType: .Network,
                                      errorLevel: .Fatal,
                                      errorCode: errorCode,
                                      userAction: nil,
                                      page: "OpenRedPacketViewController",
                                      errorMessage: errorMessage,
                                      extra: extra)
        AppReciableSDK.shared.error(params: errorParams)
        guard let key = self.receiveRedPacketKey else { return }
        Self.logger.info("Key: \(key), receive RedPacket Load Network Error")
    }

    public static func getSendRedPacketKey() -> DisposedKey? {
        return self.sendRedPacketKey
    }

    private enum SendRedPacketEvent: ReciableEventable {
        case sendRedPacket
        var eventKey: String {
            switch self {
            case .sendRedPacket:
                return "send_red_packet"
            }
        }
    }

    public static func sendRedPacketLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Chat,
                                              eventable: SendRedPacketEvent.sendRedPacket,
                                              page: "SendRedPacketController")
        sendRedPacketTrackMap.removeAll()
        var context = RedPacketSendContext()
        context.sendStartTime = CACurrentMediaTime()
        sendRedPacketTrackMap[key] = context
        self.sendRedPacketKey = key
        Self.logger.info("Key: \(key), sendRedPacket StratTime At: \(context.sendStartTime)")
    }

    public static func updateSendRedPacketEndNetworkCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = sendRedPacketKey else {
                return
            }
            sendRedPacketTrackMap[disposedKey]?.sendRedPacketNetworkCost = Int(cost * 1000)
            Self.logger.info("Key: \(disposedKey), update send RedPacket SDK Network Cost: \(Int(cost * 1000))")
        }
    }

    public static func sendRedPacketLoadTimeEnd(key: DisposedKey?) {
        guard let key = key,
            let context = sendRedPacketTrackMap.removeValue(forKey: key) else {
            return
        }
        var latencyDetail: [String: Any] = [:]
        latencyDetail["sdk_cost_net"] = context.sendRedPacketNetworkCost
        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: nil,
                          category: ["redPacket_type": 0])
        AppReciableSDK.shared.end(key: key, extra: extra)
        Self.logger.info("Key: \(key), send RedPacket Load End")
    }

    public static func sendRedPacketLoadNetworkError(errorCode: Int,
                                                     errorMessage: String,
                                                     isCJPay: Bool) {
        let extra = Extra(isNeedNet: true)
        let errorParams = ErrorParams(biz: .Messenger,
                                      scene: .Chat,
                                      eventable: SendRedPacketEvent.sendRedPacket,
                                      errorType: .Network,
                                      errorLevel: .Fatal,
                                      errorCode: errorCode,
                                      userAction: isCJPay ? "CJPay" : "Native",
                                      page: "SendRedPacketController",
                                      errorMessage: errorMessage,
                                      extra: extra)
        AppReciableSDK.shared.error(params: errorParams)
        guard let key = self.sendRedPacketKey else { return }
        Self.logger.info("Key: \(key), send RedPacket Load Network Error")
    }
}

private func mainThreadExecuteTask(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async {
            task()
        }
    }
}
