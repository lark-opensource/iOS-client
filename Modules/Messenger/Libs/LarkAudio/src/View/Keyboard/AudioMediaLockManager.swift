//
//  AudioMediaLockManager.swift
//  LarkAudio
//
//  Created by 李晨 on 2022/10/9.
//

import UIKit
import Foundation
import LarkMedia
import EENavigator
import UniverseDesignDialog
import LKCommonsLogging
import LarkNavigator
import LarkSetting
import LarkContainer

final class AudioMediaLockManager {
    private static let logger = Logger.log(AudioMediaLockManager.self, category: "Module.Inputs")

    static let shared: AudioMediaLockManager = AudioMediaLockManager()

    private var interruptedCallback: ((String?) -> Void)?
    private var from: NavigatorFrom?

    func unlock() {
        AudioMediaLockManager.logger.info("NewAudioRecord: lockManager unlock")
        LarkMediaManager.shared.unlock(scene: .imRecord)
    }

    /// - parameter callback: 执行时的回调，主线程回调
    /// - parameter interruptedCallback: 发生打断时的回调，主线程回调
    func tryLock(userResolver: UserResolver, from: NavigatorFrom?, callback: @escaping (Bool) -> Void, interruptedCallback: @escaping (String?) -> Void) {
        let navigator = userResolver.navigator
        self.from = from
        self.interruptedCallback = interruptedCallback
        let callback: (Bool) -> Void = { v in
            // 主线程回调
            DispatchQueue.main.async {
                callback(v)
            }
        }
        AudioMediaLockManager.logger.info("AudioMediaLockManager try Lock")
        // 这里使用同步接口是期望方法同步返回,避免频繁调用时由于异步导致的播放进度闪动/录音状态等时序问题
        let result: MediaMutexCompletion = LarkMediaManager.shared.tryLock(scene: .imRecord, observer: self)
        switch result {
        case .success(let resource):
            // 适配 iOS 17 硬件静音
            if #available(iOS 17, *),
               case .success = resource.microphone.requestMute(false) {
                AudioMediaLockManager.logger.info("NewAudioRecord: lockManager lock")
                callback(true)
            } else {
                AudioMediaLockManager.logger.info("NewAudioRecord: lockManager lock")
                callback(true)
            }
        case .failure(let error):
            AudioPlayMediatorImpl.logger.error("AudioPlayMediatorImpl try Lock failed \(error)")
            if case let MediaMutexError.occupiedByOther(context) = error {
                if let msg = context.1 {
                    self.showMediaLockAlert(navigator: navigator, msg: msg)
                }
                callback(false)
            } else {
                callback(true)
            }
        }
    }

    private static func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    private func showMediaLockAlert(navigator: Navigatable, msg: String) {
        Self.execInMainThread { [weak self] in
            guard let from = self?.from ?? UIApplication.shared.windows.first else {
                AudioMediaLockManager.logger.error("cannot find window")
                return
            }
            let dialog = UDDialog()
            dialog.setContent(text: msg)
            dialog.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            navigator.present(dialog, from: from)
        }
    }

}

extension AudioMediaLockManager: MediaResourceInterruptionObserver {

    public func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        DispatchQueue.main.async {
            self.interruptedCallback?(msg)
        }
    }

    public func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
    }
}
