//
//  NetFlowMonitor.swift
//  LarkPerf
//
//  Created by sniperj on 2020/6/23.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker

public protocol NetworkDelegate: NSObjectProtocol {
    func networkDidCatch(with request: URLRequest?, response: URLResponse?, data: Data?)
}

extension URLSession {

    private static var isSwizzledKey: Void?
    private static var isSwizzled: Bool {
        set {
            objc_setAssociatedObject(self, &isSwizzledKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            let result = objc_getAssociatedObject(self, &isSwizzledKey) as? Bool
            if result == nil {
                return false
            }
            return result!
        }
    }

    class func start() {
        if self.isSwizzled == false {
            hook()
            self.isSwizzled = true
        }
    }

    class func end() {
        if self.isSwizzled == true {
            hook()
            self.isSwizzled = false
        }
    }

    class private func hook() {
        let orig = Selector(("initWithConfiguration:delegate:delegateQueue:"))
        let alter = #selector(URLSession.init(configurationMonitor:delegate:delegateQueue:))
        swizzling(forClass: URLSession.self, originalSelector: orig, swizzledSelector: alter)
    }

    @objc
    convenience init(configurationMonitor: URLSessionConfiguration,
                     delegate: URLSessionDelegate?,
                     delegateQueue queue: OperationQueue?) {
        if configurationMonitor.protocolClasses != nil {
            configurationMonitor.protocolClasses!.insert(LKNetworkProtocol.self, at: 0)
        } else {
            configurationMonitor.protocolClasses = [LKNetworkProtocol.self]
        }
        self.init(configurationMonitor: configurationMonitor, delegate: delegate, delegateQueue: queue)
    }

    class private func swizzling(
        forClass: AnyClass,
        originalSelector: Selector,
        swizzledSelector: Selector) {

        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
        if class_addMethod(
            forClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
            ) {
            class_replaceMethod(
                forClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

final class LKNetworkProtocol: URLProtocol {
    fileprivate static let AppNetworkGreenCard = "AppNetworkGreenCard"
    fileprivate var connection: NSURLConnection?
    fileprivate var caRequest: URLRequest?
    fileprivate var caResponse: URLResponse?
    fileprivate var caData: Data?
    fileprivate static weak var delegate: NetworkDelegate?

    class func start() {
        URLProtocol.registerClass(LKNetworkProtocol.self)
    }

    class func end() {
        URLProtocol.unregisterClass(LKNetworkProtocol.self)
    }
}

extension LKNetworkProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme else {
            return false
        }
        guard scheme == "http" || scheme == "https" else {
            return false
        }
        guard URLProtocol.property(forKey: AppNetworkGreenCard, in: request) == nil else {
            return false
        }
        return true
    }

    // swiftlint:disable force_cast
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        let req = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: AppNetworkGreenCard, in: req)
        return req.copy() as! URLRequest
    }
    // swiftlint:enable force_cast

    override func startLoading() {
        let request = LKNetworkProtocol.canonicalRequest(for: self.request)
        self.connection = NSURLConnection(request: request, delegate: self, startImmediately: true)
        self.caRequest = self.request
    }

    override func stopLoading() {
        self.connection?.cancel()
        DispatchQueue.main.async {
            LKNetworkProtocol.delegate?.networkDidCatch(with: self.caRequest,
                                                        response: self.caResponse,
                                                        data: self.caData)
        }
    }
}

extension LKNetworkProtocol: NSURLConnectionDelegate {
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.client?.urlProtocol(self, didFailWithError: error)
    }

    func connectionShouldUseCredentialStorage(_ connection: NSURLConnection) -> Bool {
        return true
    }

    func connection(_ connection: NSURLConnection, didReceive challenge: URLAuthenticationChallenge) {
        self.client?.urlProtocol(self, didReceive: challenge)
    }

    func connection(_ connection: NSURLConnection, didCancel challenge: URLAuthenticationChallenge) {
        self.client?.urlProtocol(self, didCancel: challenge)
    }
}

extension LKNetworkProtocol: NSURLConnectionDataDelegate {

    func connection(_ connection: NSURLConnection,
                    willSend request: URLRequest,
                    redirectResponse response: URLResponse?) -> URLRequest? {
        if response != nil {
            self.caResponse = response
            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response!)
        }
        return request
    }

    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: URLCache.StoragePolicy.allowed)
        self.caResponse = response
    }

    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
        if self.caData == nil {
            self.caData = data
        } else {
            self.caData!.append(data)
        }
    }

    func connection(_ connection: NSURLConnection,
                    willCacheResponse cachedResponse: CachedURLResponse) -> CachedURLResponse? {
        return cachedResponse
    }

    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        self.client?.urlProtocolDidFinishLoading(self)
    }
}

/// RustFlowCallback
public typealias RustFlow = (() -> Int64?)
public final class NetFlowMonitor: NSObject {
    private static let serviceName = "app_network_cost"
    public static let shared = NetFlowMonitor()
    private var byte: CLongLong = 0
    private var isRunning = false
    private var getRustNetFlow: RustFlow?
    public func start() {
//        if !isRunning {
//            LKNetworkProtocol.start()
//            LKNetworkProtocol.delegate = self
//            URLSession.start()
//            isRunning = true
//        }
    }

    public func end() {
//        if isRunning {
//            LKNetworkProtocol.end()
//            URLSession.end()
//            LKNetworkProtocol.delegate = nil
//            isRunning = false
//            uploadData()
//        }
    }

    func updateRustFlow(rustFlow: RustFlow?) {
        getRustNetFlow = rustFlow
    }

    public func getDataByte() -> CLongLong {
        return byte
    }

    private func uploadData() {
        DispatchQueue.global().async {
            let sinceStartup = CACurrentMediaTime() * 1_000 - AppMonitor.getStartupTimeStamp()
            let sinceLatestEnterForeground = CACurrentMediaTime() * 1_000 - AppMonitor.getEnterForegroundTimeStamp()
            Tracker.post(SlardarEvent(name: NetFlowMonitor.serviceName,
                                      metric: ["native_cost": self.byte,
                                               "rust_cost": self.getRustNetFlow?() ?? 0,
                                               "time": sinceLatestEnterForeground / 3_600.0 / 1_000.0],
                                      category: [:],
                                      extra: ["since_startup": sinceStartup,
                                              "since_latest_enter_foreground": sinceLatestEnterForeground]))
            self.byte = 0
        }
    }
}

extension NetFlowMonitor: NetworkDelegate {

    public func networkDidCatch(with request: URLRequest?, response: URLResponse?, data: Data?) {
        byte += Int64((data?.count ?? 0))
    }
}
