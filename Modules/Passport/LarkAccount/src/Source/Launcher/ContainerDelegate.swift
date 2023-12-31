//
//  ContainerDelegate.swift
//  Lark
//
//  Created by liuwanlin on 2018/11/27.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import EEAtomic
import LarkContainer
import LarkSetting
import LKCommonsLogging
import Heimdallr
import LarkTracker
import LKCommonsTracker

public class BaseContainerDelegate: LarkContainerDelegate {

    static let logger = Logger.log(ContainerDelegate.self, category: "ContainerDelegate")
    let queue = DispatchQueue(label: "LarkContainerDelegate", target: DispatchQueue.global(qos: .background))

    init() {
        #if DEBUG || ALPHA
        precondition(!(UserStorageManager.delegate is BaseContainerDelegate), "should only have one instance")
        /// default init to placeholderUser, should same as passport
        precondition(UserStorageManager.shared.currentUserID == UserManager.placeholderUser.userID)
        #endif

        /// 默认的AccountServiceAdapter.shared.currentChatterId 可能触发对应的初始化，导致循环依赖
        /// 所以判断一下是否已经初始化
        var initialized = false
        FeatureGatingManager.currentChatterID = {
            if initialized {
                return PassportStore.shared.foregroundUserID ?? "" // user:current
            }
            return ""
        }
        /// 提前初始化，保证FG能即时拿到值。
        /// foregroundUserID启动流程中本身也会初始化，所以影响应该不大，只是提前了
        _ = PassportStore.shared.foregroundUserID // user:current
        initialized = true

        UserStorageManager.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    @objc func enterBackground() {
        // 进入后台提前清一遍数据, 稍微延迟一点，让短时间内的后台异常也一起上报
        queue.asyncAfter(wallDeadline: .now() + 2) { [self, bufferExceptionUploadCounter] in
            guard bufferExceptionUploadCounter == self.bufferExceptionUploadCounter else { return }
            clearBufferException()
        }
    }

    // MARK: LarkContainerDelegate
    /// 缓存避免频繁获取FG
    var uploadExceptionFG: Bool {
        if let val = _uploadExceptionFG { return val }
        let val = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.uploadException") // user:checked (setting)
        _uploadExceptionFG = val
        return val
    }
    fileprivate var _uploadExceptionFG: Bool?
    /// 全局禁用用户隔离拦截的FG，默认不开启，有问题时再考虑注入
    public var disabledUserFG: Bool {
        if let val = _disabledUserFG { return val }
        let val = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.disabled") // user:checked (setting)
        _disabledUserFG = val
        return val
    }
    fileprivate var _disabledUserFG: Bool?
    public var disabledVariableCompatibleUserID: Bool {
        if let val = _disabledVariableCompatibleUserID { return val }
        let val = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.variable.userid.disabled") // user:checked (setting)
        _disabledVariableCompatibleUserID = val
        return val
    }
    fileprivate var _disabledVariableCompatibleUserID: Bool?
    /// 全局禁用埋点上传的FG，默认不开启，有问题时再考虑注入
    var disabledExceptionUploadFG: Bool {
        if let val = _disabledExceptionUploadFG { return val }
        let val = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.upload.disabled") // user:checked (setting)
        _disabledExceptionUploadFG = val
        return val
    }
    fileprivate var _disabledExceptionUploadFG: Bool?

    var bufferException: [LarkContainer.UserExceptionInfo: UInt] = [:]
    var bufferExceptionUploadCounter = 0
    var inLogException: Bool {
        get { Thread.current.threadDictionary["ContainerDelegate.inLogException"] as? Bool ?? false }
        set { Thread.current.threadDictionary["ContainerDelegate.inLogException"] = newValue ? true : nil }
    }

    public func log(exception: LarkContainer.UserExceptionInfo) {
        // 避免循环调用
        if inLogException { return }
        inLogException = true; defer { inLogException = false }
        if exception.isError, exception.recordStack, uploadExceptionFG {
            // 现在因为迁移兼容当前user，异常上报非常多，**会非常耗性能**。
            // 先占位，随时可以通过FG小范围开启异常上报(仅应该开启受控内部范围内的)
            var filters: [String: String] = [:]
            if case let key = exception.key, !key.isEmpty { filters["key"] = key }
            let parameters = HMDUserExceptionParameter.initCurrentThreadParameter(
                withExceptionType: exception.scene, customParams: filters, filters: filters)
            HMDUserExceptionTracker.shared().trackThreadLog(with: parameters)
        }
        if disabledExceptionUploadFG { return }
        queue.async { [self] in
            let empty = bufferException.isEmpty
            bufferException[exception, default: 0] += 1
            if empty {
                // 收集一定时间后统一上报, 可以聚合减少上报次数.
                // 比如旧API懒加载RustService等等情况..
                queue.asyncAfter(wallDeadline: .now() + 30) { [bufferExceptionUploadCounter] in
                    // 如果被其他的提前触发上报，新的数据会触发新的延迟，本次调用就忽略掉..
                    guard bufferExceptionUploadCounter == self.bufferExceptionUploadCounter else { return }
                    self.clearBufferException()
                }
            }
        }
    }
    func clearBufferException() {
        #if DEBUG || ALPHA
        dispatchPrecondition(condition: .onQueue(queue))
        #endif
        bufferExceptionUploadCounter &+= 1
        while var (exception, count) = bufferException.popFirst() {
            // 遗留项太多，先不升级为error..
            Self.logger.log(level: .warn, // exception.isError ? .error : .warn,
                            "#\(count) for \(exception.description)")
            var params = exception.uploadParams
            params["count"] = count
            Tracker.post(TeaEvent("lark_ios_user_container_exception_dev", params: params))
        }
    }

    public func warn(_ message: String, file: String, line: Int) {
        Self.logger.warn(message, file: file, line: line)
    }
    public func info(_ message: String, file: String, line: Int) {
        Self.logger.info(message, file: file, line: line)
    }
}

public final class ContainerPassportDelegate: BaseContainerDelegate, PassportDelegate {
    public let name: String = "Container"
    let container: Container

    public init(container: Container) {
        self.container = container
        super.init()
    }
    public func userDidOnline(state: PassportState) {
        _uploadExceptionFG = nil
        _disabledUserFG = nil
        _disabledExceptionUploadFG = nil
        _disabledVariableCompatibleUserID = nil
    }
}

public final class ContainerDelegate: BaseContainerDelegate, LauncherDelegate { // user:checked
    public let name: String = "Container"
    public var lock = UnfairLockCell()
    let container: Container

    public init(container: Container) {
        self.container = container
        super.init()
    }
    deinit { lock.deallocate() }

    // private let container: Container
    func updateCurrentUserID(_ currentUserID: String) {
        // 目前对应的调用时机都重制容器，和原来一样。
        // 等以后passport出新的通知再对接正确的生命周期
        UserStorageManager.shared.makeStorage(userID: currentUserID)
        UserStorageManager.shared.currentUserID = currentUserID // 当前用户的兼容逻辑
        UserStorageManager.shared.keepStorages { $0 == currentUserID }

        _uploadExceptionFG = nil
        _disabledUserFG = nil
        _disabledExceptionUploadFG = nil
        _disabledVariableCompatibleUserID = nil
    }

    func resetUserStorage() {
        lock.withLocking {
            // 如果没有用户登录时，用placeholder用户代替。这时的用户存储是无意义的。
            updateCurrentUserID(AccountServiceAdapter.shared.currentAccountInfo.userID) // user:checked
        }
    }
    var uid: Int { AccountServiceAdapter.shared.currentAccountInfo.userID.hashValue } // user:checked

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        Self.logger.debug("ContainerDelegate: afterSwitchAccout \(error) \(uid)")
        if error == nil {
            resetUserStorage()
        } else if case .switchUserRustFailed(_)  = error as? AccountError {
            resetUserStorage()
        }
        return .just(())
    }

    public func afterLoginSucceded(_ context: LauncherContext) {
        Self.logger.debug("ContainerDelegate: afterLoginSucceded \(uid)")
        resetUserStorage()
    }
    public func afterLogout(_ context: LauncherContext) {
        Self.logger.debug("ContainerDelegate: afterLogout \(uid)")
        resetUserStorage()
    }
    public func fastLoginAccount(_ account: Account) {
        Self.logger.debug("ContainerDelegate: fastLoginAccount \(uid)")
        resetUserStorage()
        // 这个是新加的重置时机。这个时机开始后uid才一致.
        // 以前的启动没有这个回调，在这之前的用户服务会被清理掉。可能和预期不一致
    }
}
