//
//  OPMediaMutex.swift
//  OPFoundation
//
//  Created by baojianjun on 2022/9/13.
//

import Foundation
import LarkMedia
import LarkSetting
import ECOProbe
import LKCommonsLogging
import LarkOpenAPIModel
import UniverseDesignToast

// MARK: - OPMediaMutex

@objcMembers
public final class OPMediaMutex: NSObject {
    // TODOZJX
    @FeatureGatingValue(key: "openplatform.gadget.mediamutex.recordunmute.disable")
    private static var disableUnmute: Bool
    
    private static let logger = Logger.oplog(OPMediaMutex.self, category: "OPFoundation.OPMediaMutex")
    /// OC Async Interface
    @objc
    public static func tryLockAsync(scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver, completion: @escaping ((Bool, String?) -> Void)) {
        tryLock(scene: scene, observer: observer) { result in
            switch result {
            case .success:
                completion(true, nil)
            case .failure(let error):
                completion(false, error.errorInfo())
            }
        }
    }
    
    /// OC Sync Interface
    @objc
    public static func tryLockSync(scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver) -> String? {
        let result = tryLock(scene: scene, observer: observer)
        switch result {
        case .success:
            return nil
        case .failure(let error):
            Self.logger.error("scene: \(scene.rawValue), errorInfo: \(error.errorInfo())")
            return error.errorInfo()
        }
    }
    
    public static func tryLockAndUnmuteSync(scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver) -> String? {
        let result = tryLockSync(scene: scene, observer: observer)
        if #available(iOS 17.0, *),
           let id = observer.wrapper?.observerIdentifier,
           let resource = LarkMediaManager.shared.getMediaResource(for: scene.rawValue(id: id)) {
            guard !disableUnmute, result.isEmpty else {
                return result
            }
            let unmuteResult = resource.microphone.requestMute(false)
            switch unmuteResult {
            case .success():
                return nil
            case .failure(let error):
                if !scene.rawValue(id: id).isEnabled {
                    Self.logger.error("scene: \(scene.rawValue) fg disabled, unmute errorInfo: \(error.errorInfo())")
                    return nil
                } else {
                    Self.logger.error("scene: \(scene.rawValue), unmute errorInfo: \(error.errorInfo())")
                    return error.errorInfo()
                }
            }
        }
        return result
    }
    
    /// Swift Async Interface
    public static func tryLock(scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver? = nil, completion: @escaping (MediaMutexCompletion) -> Void) {
        guard let observer = getWrapper(with: observer, needGenerate: true) else {
            completion(.failure(.unknown))
            return
        }

        LarkMediaManager.shared.tryLock(scene: scene.rawValue(id: observer.observerIdentifier), observer: observer) { result in
            showToastIfNeeded(result: result)
            completion(result)
        }
    }
    
    /// Swift Sync Interface
    public static func tryLock(scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver? = nil) -> MediaMutexCompletion {
        guard let observer = getWrapper(with: observer, needGenerate: true) else {
            return .failure(.unknown)
        }

        let result = LarkMediaManager.shared.tryLock(scene: scene.rawValue(id: observer.observerIdentifier), observer: observer)
        showToastIfNeeded(result: result)
        return result
    }
    
    @objc
    public static func unlock(scene: OPMediaMutexScene, wrapper: OPMediaMutexObserveWrapper? = nil) {
        guard let wrapper else {
            return
        }
        LarkMediaManager.shared.unlock(scene: scene.rawValue(id: wrapper.observerIdentifier), options: .leaveScenarios)
    }

    public static func enter(scenario: AudioSessionScenario, scene: OPMediaMutexScene, observer: OPMediaResourceInterruptionObserver? = nil) {
        guard let observer = getWrapper(with: observer, needGenerate: true) else {
            return
        }
        let scene = scene.rawValue(id: observer.observerIdentifier)
        guard let resource = LarkMediaManager.shared.getMediaResource(for: scene) else {
            return
        }
        resource.audioSession.enter(scenario)
    }

    public static func leave(scenario: AudioSessionScenario, scene: OPMediaMutexScene, wrapper: OPMediaMutexObserveWrapper? = nil) {
        guard let wrapper else {
            return
        }
        let scene = scene.rawValue(id: wrapper.observerIdentifier)
        guard let resource = LarkMediaManager.shared.getMediaResource(for: scene) else {
            return
        }
        resource.audioSession.leave(scenario)
    }
    
    private static func getWrapper(with observer: OPMediaResourceInterruptionObserver?, needGenerate: Bool) -> OPMediaMutexObserveWrapper? {
        var wrapper: OPMediaMutexObserveWrapper? = nil
        if let observer = observer, observer.responds(to: #selector(setter: OPMediaResourceInterruptionObserver.wrapper)) {
            if let wrap = observer.wrapper {
                wrapper = wrap
                Self.logger.info("wrapper: \(wrap) of observer: \(observer) has init")
            } else if needGenerate {
                wrapper = generateWrapper(observer: observer)
            }
        } else {
            Self.logger.error(logId: "observer has not implementation wrapper")
        }
        return wrapper
    }
    
    private static func generateWrapper(observer: OPMediaResourceInterruptionObserver) -> OPMediaMutexObserveWrapper {
        let wrap = OPMediaMutexObserveWrapper()
        wrap.observerIdentifier = "\(wrap.hash)"
        wrap.observer = observer
        observer.wrapper = wrap
        return wrap
    }
    
    private static func showToastIfNeeded(result: MediaMutexCompletion) {
        if case .failure(let error) = result,
           case .occupiedByOther(_, let string) = error,
            let toast = string {
            // toast
            executeOnMainQueueAsync {
                if let window = OPWindowHelper.fincMainSceneWindow() {
                    UDToast.showFailure(with: toast, on: window)
                }
            }
        }
    }
}

// MARK: - OPMediaMutexScene

@objc
public enum OPMediaMutexScene: Int, RawRepresentable {
    case audioPlay
    case audioRecord

    public func rawValue(id: String) -> MediaMutexScene {
        switch self {
        case .audioPlay:
            return .microPlay(id: id)
        case .audioRecord:
            return .microRecord(id: id)
        }
    }
}

// MARK: - MediaMutexError

extension MediaMutexError {
    public func errorInfo() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .occupiedByOther(let scene, let string):
            return "scene: \(scene), \(string ?? "")"
        case .sceneNotFound:
            return "sceneNotFound"
        @unknown default:
            return "unknown"
        }
    }
}

// MARK: - MicrophoneMuteError

extension MicrophoneMuteError {
    public func errorInfo() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .mediaTypeInvalid:
            return "mediaTypeInvalid"
        case .noMediaLock:
            return "noMediaLock"
        case .operationNotAllowed:
            return "operationNotAllowed"
        case .systemError(let error):
            return "systemError \(error)"
        case .osError(let status):
            return "systemError \(status)"
        case .sceneNotFound:
            return "sceneNotFound"
        @unknown default:
            return "unknown"
        }
    }
}

// MARK: - OPMediaMutexObserveWrapper

@objcMembers
public final class OPMediaMutexObserveWrapper: NSObject, MediaResourceInterruptionObserver {
    @objc weak var observer: OPMediaResourceInterruptionObserver?
    /// 唯一标识符
    /// 用于单 scene 多实例的情况
    /// 标识符由使用方定义
    public var observerIdentifier: String = ""
    
    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        observer?.mediaResourceWasInterrupted(by: scene.description, msg: msg)
    }
    
    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        observer?.mediaResourceInterruptionEnd(from: scene.description)
    }
}

// MARK: - OPMediaResourceInterruptionObserver

@objc
public protocol OPMediaResourceInterruptionObserver: NSObjectProtocol {
    /// 开始打断
    /// 只对占用中并被打断的业务发送
    /// - Scene: 打断者
    /// - type: 具体被打断的媒体类型
    /// - msg: 打断通用文案
    @objc func mediaResourceWasInterrupted(by scene: String, msg: String?)

    /// 打断结束
    /// 只对被打断的业务发送
    /// - Scene: 打断结束者
    /// - type: 具体被释放的媒体类型
    @objc func mediaResourceInterruptionEnd(from scene: String)
    
    @objc var wrapper: OPMediaMutexObserveWrapper? { get set }
}
