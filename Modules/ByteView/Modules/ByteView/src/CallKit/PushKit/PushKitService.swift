//
//  PushKitService.swift
//  ByteView
//
//  Created by shin on 2023/09/12.
//

import ByteViewCommon
import Foundation
import PushKit

public struct PushKitToken {
    public let type: PKPushType
    public let token: String

    public init(type: PKPushType, token: String) {
        self.type = type
        self.token = token
    }
}

public struct PushPayloadRecord {
    public let date: Date
    public let payload: PKPushPayload

    public init(date: Date, payload: PKPushPayload) {
        self.date = date
        self.payload = payload
    }
}

public enum HandlerPriority: Int {
    /// 低优先级
    case low = 0
    /// 默认优先级
    case `default` = 1
    /// 高优先级，最先处理
    case high = 2
}

public protocol PushKitServiceHandler: AnyObject {
    func handlePayload(_ payload: PKPushPayload)
    func handleToken(_ token: PushKitToken)
    func didInvalidatePushTokenFor(type: PKPushType)
}

public extension PushKitServiceHandler {
    func handlePayload(_ payload: PKPushPayload) {}
    func handleToken(_ token: PushKitToken) {}
    func didInvalidatePushTokenFor(type: PKPushType) {}
}

public final class PushKitService: NSObject, PKPushRegistryDelegate {
    static let logger = Logger.getLogger("PushKitService")

    public typealias PushKitTransform<T> = (PKPushPayload) -> T

    public static let shared: PushKitService = .init()

    private struct WeakHandler {
        weak var ref: PushKitServiceHandler?
        let identifier: ObjectIdentifier
        let priority: HandlerPriority

        init(ref: PushKitServiceHandler, priority: HandlerPriority) {
            self.ref = ref
            self.identifier = ObjectIdentifier(ref)
            self.priority = priority
        }
    }

    private let instLock = NSLock()
    private var serviceHandlers: [WeakHandler] = []

    @RwAtomic
    private var _supportCache: Bool = true {
        didSet {
            PushKitService.logger.info("修改 supportCache \(supportCache)")
            if _supportCache == false {
                self.cleanAllCache()
            }
        }
    }

    public var supportCache: Bool {
        get {
            _supportCache
        }
        set {
            _supportCache = newValue
        }
    }

    @RwAtomic
    private var _tokenCache: [PKPushType: PushKitToken] = [:]
    public var tokenCache: [PKPushType: PushKitToken] { _tokenCache }

    @RwAtomic
    private var pushRegistry: PKPushRegistry?

    @RwAtomic
    private var queue: DispatchQueue?

    override init() {
        super.init()
    }

    public func registryPushKit(_ pushTypes: Set<PKPushType>, queue: DispatchQueue = DispatchQueue.main) {
        guard self.pushRegistry == nil else {
            PushKitService.logger.error("PushKit has registered")
            return
        }
        PushKitService.logger.info("registry push kit, types: \(pushTypes)")

        self.pushRegistry?.delegate = nil
        self.pushRegistry = nil

        let registerAction: () -> Void = { [weak self] in
            guard let self = self else {
                return
            }
            self.queue = queue
            let pushRegistry = PKPushRegistry(queue: queue)
            pushRegistry.delegate = self
            self.pushRegistry = pushRegistry
            pushRegistry.desiredPushTypes = pushTypes
        }

        let key = DispatchSpecificKey<Int>()
        let val = Int(bitPattern: Unmanaged.passUnretained(queue).toOpaque())
        queue.setSpecific(key: key, value: val)

        // 逆向分析发现 PKPushRegistry 在初始化的时候会立即检查 `com.apple.pushkit.launch.voip`，
        // 判断应用是否被 VoIP Push 唤醒，并在 delegateQueue 中，调用 delegate 协议方法。
        // 因此需要在相同的 queue 中初始化并设置 delegate, 避免遗漏 VoIP Push 引起崩溃
        if DispatchQueue.getSpecific(key: key) != nil {
            queue.setSpecific(key: key, value: nil)
            registerAction()
        } else {
            queue.setSpecific(key: key, value: nil)
            queue.async(execute: registerAction)
        }
    }

    public func unregistryPushKit() {
        PushKitService.logger.info("unregistryPushKit push kit")
        self.pushRegistry?.desiredPushTypes = []
        self.pushRegistry?.delegate = nil
        self.pushRegistry = nil
        self.queue = nil
    }

    public func cleanAllCache() {
        PushKitService.logger.info("clean all cache")
        self.cleanTokenCache()
    }

    public func cleanTokenCache() {
        PushKitService.logger.info("clean token cache")
        self._tokenCache.removeAll()
    }

    /// 添加 PushKit 事件 handler
    ///
    /// 如果是非 callkit 的 handler，请勿使用 high 优先级，默认 default 即可；
    /// 且非 callkit 的响应，请 dispatch 到别的 queue 处理，不要占用当前的 queue。
    /// - Parameters:
    ///   - handler: 接收 PushKit 事件的 handler
    ///   - priority: handler 优先级
    public func addHandler(_ handler: PushKitServiceHandler,
                           priority: HandlerPriority = .default)
    {
        let wrapper = WeakHandler(ref: handler, priority: priority)
        instLock.lock()
        serviceHandlers.removeAll(where: { $0.identifier == wrapper.identifier || $0.ref == nil })
        serviceHandlers.append(wrapper)
        instLock.unlock()
    }

    public func removeHandler(_ handler: PushKitServiceHandler) {
        let objIdentifier = ObjectIdentifier(handler)
        instLock.lock()
        serviceHandlers.removeAll(where: { $0.identifier == objIdentifier || $0.ref == nil })
        instLock.unlock()
    }

    public func pushRegistry(_ registry: PKPushRegistry,
                             didUpdate pushCredentials: PKPushCredentials, for type: PKPushType)
    {
        if registry != self.pushRegistry { return }
        PushKitService.logger.info("update push credentials")
        let tokenString = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        let token = PushKitToken(type: type, token: tokenString)
        instLock.lock()
        let handlers = self.serviceHandlers
        instLock.unlock()

        handlers.forEach { $0.ref?.handleToken(token) }

        if self.supportCache {
            self._tokenCache[type] = token
        }
    }

    public static let hasOutstandingVoIPPushKey = DispatchSpecificKey<Bool>()
    public static let forceDropExpiredVoIPPushKey = DispatchSpecificKey<Bool>()

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                             for type: PKPushType, completion: @escaping () -> Swift.Void)
    {
        if registry != self.pushRegistry {
            PushKitService.logger.error("incorrect registry")
            return
        }

        self.queue?.setSpecific(key: Self.hasOutstandingVoIPPushKey, value: true)
        self.queue?.setSpecific(key: Self.forceDropExpiredVoIPPushKey, value: false)
        PushKitService.logger.info("revice push")
        instLock.lock()
        serviceHandlers.removeAll(where: { $0.ref == nil })
        let handlers = self.serviceHandlers
        instLock.unlock()

        handlers.sorted(by: { $0.priority.rawValue > $1.priority.rawValue })
            .forEach { $0.ref?.handlePayload(payload) }

        // completion 执行完就应该内部直接调用结束，无需外部 handler 执行完调用。
        completion()
        let forceDrop = DispatchQueue.getSpecific(key: Self.forceDropExpiredVoIPPushKey) ?? false
        if let hasOutstandingVoIPPush = DispatchQueue.getSpecific(key: Self.hasOutstandingVoIPPushKey) {
            if hasOutstandingVoIPPush {
                PushKitService.logger.error("voip push is not consumed, handler count \(handlers.count), forceDrop=\(forceDrop)")
                assertionFailure("voip push is not consumed, handler count \(handlers.count), forceDrop=\(forceDrop)")
                #if DEBUG || INHOUSE || ALPHA
                // 命中 fatal 时，当前线程休眠 1s，保障现场日志能更多的保存
                Thread.sleep(forTimeInterval: 1)
                fatalError("voip push is not consumed, handler count \(handlers.count), forceDrop=\(forceDrop)")
                #endif
            }
        } else {
            assertionFailure()
            #if DEBUG || INHOUSE || ALPHA
            // 命中 fatal 时，当前线程休眠 1s，保障现场日志能更多的保存
            Thread.sleep(forTimeInterval: 1)
            fatalError("voip push is not consumed, handler count \(handlers.count), forceDrop=\(forceDrop)")
            #endif
        }

        #if !(DEBUG || INHOUSE || ALPHA)
        if forceDrop {
            // 线上强制丢弃过期 VoIP 时，当前线程休眠 1s，保障现场日志能更多的保存
            Thread.sleep(forTimeInterval: 1)
        }
        #endif
    }

    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        if registry != self.pushRegistry { return }
        PushKitService.logger.error("did invalidate push token")
        instLock.lock()
        serviceHandlers.removeAll(where: { $0.ref == nil })
        let handlers = self.serviceHandlers
        instLock.unlock()
        handlers.forEach { $0.ref?.didInvalidatePushTokenFor(type: type) }
    }
}
