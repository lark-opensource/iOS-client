//
//  BDPTimorStateBridge.swift
//  TTMicroApp
//
//  Created by MJXin on 2021/12/13.
//

import Foundation
import LarkRustClient
import RustPB
import RxSwift
import LarkContainer
import LKCommonsLogging
import OPSDK

public protocol BDPTimorStateListener {
    func setup()
    func registerTimorEnterListener()
    func registerTimorExitListener()
    func removeAllObserver()
}

public final class BDPTimorStateListenerImpl: BDPTimorStateListener {
    private static let logger = Logger.oplog(BDPTimorStateListenerImpl.self, category: "BDPTimorStateService")
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    private var rustService: RustService {
        Injected<RustService>().wrappedValue
    }
    
    private var apiContextDict: [OPAppUniqueID: Openplatform_Api_APIAppContext] = [:]
    
    private let disposeBag = DisposeBag()
    
    public init() {}
    
    public func setup() {
        registerTimorEnterListener()
        registerTimorExitListener()
    }
    
    public func registerTimorEnterListener() {
        Self.logger.info("registerTimorEnterListener")
        let name = Notification.Name(kBDPEnterNotification)
        // 防止多次注册，先取消已注册通知
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openAppEnter(notification:)), name: name, object: nil)
    }
    
    public func registerTimorExitListener() {
        Self.logger.info("registerTimorExitListener")
        let name = Notification.Name(kBDPExitNotification)
        // 防止多次注册，先取消已注册通知
        NotificationCenter.default.removeObserver(self, name: name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openAppExit(notification:)), name: name, object: nil)
    }
    
    @objc func openAppEnter(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let uniqueID = userInfo["uniqueID"] as? OPAppUniqueID
              else {
                  Self.logger.error("openAppEnter miss required userInfo or uniqueID is nil")
                  return
              }
        guard let apiContext = Openplatform_Api_APIAppContext.context(from: uniqueID) else {
            Self.logger.error("Create OpenAPIContext from UniqueID fail")
            return
        }
        apiContextDict[uniqueID] = apiContext
        var request = Openplatform_Api_SetOpenAppStateRequest()
        request.apiContext = apiContext
        request.appState = .created
        rustService.sendAsyncRequest(request)
            .subscribe (
                onNext: { (response: Openplatform_Api_SetOpenAppStateResponse) in
                    Self.logger.info("set open app state: created, success")
                },
                onError: { (error) in
                    Self.logger.error("set open app state: created, fail with error:\(error)")
                }
            )
            .disposed(by: self.disposeBag)
    }
    
    @objc func openAppExit(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any],
              let uniqueID = userInfo["uniqueID"] as? OPAppUniqueID else {
                  return
              }
        guard let apiContext = apiContextDict[uniqueID] else {
            Self.logger.error("Get OpenAPIContext from apiContextDict fail")
            return
        }
        apiContextDict.removeValue(forKey: uniqueID)
        var request = Openplatform_Api_SetOpenAppStateRequest()
        request.apiContext = apiContext
        request.appState = .destroyed
        rustService.sendAsyncRequest(request)
            .subscribe (
                onNext: { (response: Openplatform_Api_SetOpenAppStateResponse) in
                    Self.logger.info("set open app state: destroy, success")
                },
                onError: { (error) in
                    Self.logger.error("set open app state: destroy, fail with error:\(error)")
                }
            )
            .disposed(by: self.disposeBag)
    }
    
    public func removeAllObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    deinit { removeAllObserver() }
}
