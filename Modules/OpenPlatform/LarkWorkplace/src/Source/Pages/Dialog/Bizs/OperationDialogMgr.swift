//
//  OperationDialogMgr.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/19.
//

import Foundation
import RxSwift
import ByteWebImage
import LarkContainer
import LarkSetting
import LarkStorage
import LarkAccountInterface
import LKCommonsLogging

enum WPDialogError: Error {
    case server(code: Int, msg: String)
    case jsonDecode(error: Error?)
    case network(error: Error)
    case unavailableVersion
    case duplicateData
    case invalidData(_ error: Error?)
}

final class OperationDialogMgr {
    static let logger = Logger.log(OperationDialogMgr.self)
    // MARK: - public vars

    // MARK: - private vars
    private var disposeBag = DisposeBag()

    private let userService: PassportUserService
    private let traceService: WPTraceService
    private let configService: WPConfigService
    private let networkService: WPNetworkService

    private let imageFetcher: ImageManager

    // MARK: - life cycle
    init(
        userService: PassportUserService,
        traceService: WPTraceService,
        configService: WPConfigService,
        networkService: WPNetworkService
    ) {
        self.userService = userService
        self.traceService = traceService
        self.configService = configService
        self.networkService = networkService

        self.imageFetcher = WPCacheTool.imageFetcher(withSession: true, session: userService.user.sessionKey ?? "")
        self.imageFetcher.enableMemoryCache = false
    }

    // MARK: - public funcs

    /// 异步获取运营弹窗数据
    /// - Parameter callback: 主线程回调
    func getOperatingNotifications(_ callback: @escaping (Result<OperationDialogData, WPDialogError>) -> Void) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        net_getOperatingNotifications { result in
            switch result {
            case .success(let data):
                guard data.schemaVersion == OperationDialogData.kClientAcceptSchemaVer else {
                    DispatchQueue.main.async {
                        callback(.failure(.unavailableVersion))
                    }
                    Self.logger.info("[dialog] invalid version: \(data.schemaVersion)!")
                    return
                }
                // 检查弹窗是否已被消费，防止重复弹窗
                // swiftlint:disable unused_optional_binding
                if self.checkHasAckStateInCache(notificationId: data.notification.id) {
                // swiftlint:enable unused_optional_binding
                    self.ackOperatingNotification(data, callback: nil)
                    DispatchQueue.main.async {
                        callback(.failure(.duplicateData))
                    }
                    Self.logger.info("[dialog] skip: duplicate data!")
                    return
                }

                // 图片预加载
                let element = data.notification.content.parseElement
                if element.tag == .img, let str = element.imageUrl, let url = URL(string: str) {
                    Self.logger.info("[dialog] img preload start!")
                    self.imageFetcher.requestImage(url, completion: { (result) in
                        switch result {
                        case .success(let ret):
                            if ret.image != nil {
                                Self.logger.info("[dialog] img preload success!")
                                callback(.success(data))
                            } else {
                                Self.logger.error("[dialog] img preload fail: nil image!")
                                callback(.failure(.invalidData(nil)))
                            }
                        case .failure(let err):
                            Self.logger.error("[dialog] img preload fail: \(err)!")
                            callback(.failure(.invalidData(err)))
                        }
                    })
                    return
                }

                DispatchQueue.main.async {
                    callback(.success(data))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    callback(.failure(error))
                }
            }
        }
        // swiftlint:enable closure_body_length
    }

    func ackOperatingNotification(_ data: OperationDialogData, callback: ((WPDialogError?) -> Void)?) {
        // Compiler Protocol Init Violation: 
        // The initializers declared in compiler protocol ExpressibleByBooleanLiteral shouldn't be called directly.
        // swiftlint:disable compiler_protocol_init
        cacheAckState(notificationId: data.notification.id, ack: true)
        // swiftlint:enable compiler_protocol_init
        net_ackOperatingNotification(data.notification.id, callback: callback)
    }

    func cacheAckState(notificationId: String, ack: Bool) {
        let store = KVStores.in(space: .user(id: userService.user.userID), domain: Domain.biz.workplace).mmkv()
        store.set(ack, forKey: WPCacheKey.operationDialogMgrAck(notificationId: notificationId))
        Self.logger.info("[\(WPCacheKey.operationDialogMgrAck(notificationId: notificationId))] cache data.")
    }

    func checkHasAckStateInCache(notificationId: String) -> Bool {
        let store = KVStores.in(space: .user(id: userService.user.userID), domain: Domain.biz.workplace).mmkv()
        let isHit = store.contains(key: WPCacheKey.operationDialogMgrAck(notificationId: notificationId))
        Self.logger.info("[\(WPCacheKey.operationDialogMgrAck(notificationId: notificationId))] cache \(isHit ? "hit" : "miss").")
        return isHit
    }

    // MARK: - private funcs

    private func net_getOperatingNotifications(
        _ callback: @escaping (Result<OperationDialogData, WPDialogError>) -> Void
    ) {
        let context = WPNetworkContext(trace: traceService.currentTrace)
        networkService.request(
            WPGetOperationNotificationConfig.self,
            params: WPGeneralRequestConfig.legacyParameters,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
        .subscribe { json in
            guard let code = json["code"].int, code == 0 else {
                callback(.failure(.server(code: json["code"].intValue, msg: json["msg"].stringValue)))
                return
            }
            do {
                let data = try json["data"].rawData()
                let dialogData = try JSONDecoder().decode(OperationDialogData.self, from: data)
                callback(.success(dialogData))
            } catch {
                callback(.failure(.jsonDecode(error: error)))
            }
        } onError: { error in
            callback(.failure(.network(error: error)))
        }
        .disposed(by: disposeBag)
    }

    private func net_ackOperatingNotification(_ notifID: String, callback: ((WPDialogError?) -> Void)?) {
        let context = WPNetworkContext(trace: traceService.currentTrace)
        networkService.request(
            WPNotificationAckConfig.self,
            params: ["notificationId": notifID],
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global()))
        .subscribe { json in
            guard let code = json["code"].int, code == 0 else {
                callback?(.server(code: json["code"].intValue, msg: json["msg"].stringValue))
                return
            }
            callback?(nil)
        } onError: { error in
            callback?(.network(error: error))
        }
        .disposed(by: disposeBag)
    }
}
