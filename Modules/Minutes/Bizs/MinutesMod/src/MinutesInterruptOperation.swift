//
//  MinutesInterruptOperation.swift
//  LarkMinutes
//
//  Created by Todd Cheng on 2021/3/29.
//

import Foundation
import RxSwift
import Swinject
import Minutes
import EENavigator
import LarkAccountInterface
import LarkSceneManager
import LarkContainer
import LKCommonsLogging
import MinutesFoundation

// MARK: - 退出登录、切换租户

public final class MinutesInterruptOperation: InterruptOperation {
    /// 初始化方法
    let userResolver: UserResolver

    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }
    
    public init(resolver: UserResolver) {
        self.userResolver = resolver
        
        if let notificationName = dependency?.meeting?.mutexDidChangeNotificationName {
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeModule(_:)),
                                                   name: notificationName, object: nil)
        }
    }
    
    @objc private func didChangeModule(_ notification: Notification) {
        let key = dependency?.meeting?.mutexDidChangeNotificationKey
        let module = notification.userInfo?[key]
        if module == nil {
            MinutesAudioRecorder.shared.didChangeModuleAction()
        }
        MinutesLogger.record.info("didChangeModule, have to pause")
        MinutesAudioRecorder.shared.pause()
    }

    public func getInterruptObservable(type: LarkAccountInterface.InterruptOperationType) -> Single<Bool> {
        let podcast = getPodcastInterruptObservable(type: type).asObservable()
        let audioRecording = getAudioRecordingInterruptObservable(type: type).asObservable()
        return Observable.zip(podcast, audioRecording).map { $0 && $1 } .asSingle()
    }

    public func getPodcastInterruptObservable(type: LarkAccountInterface.InterruptOperationType) -> Single<Bool> {
        return Single<Bool>.create {(single) -> Disposable in
            // 结束播客小窗
            MinutesPodcastSuspendable.removePodcastSuspendable()
            MinutesPodcast.shared.stopPodcast()
            single(.success(true))
            return Disposables.create()
        }
    }

    public func getAudioRecordingInterruptObservable(type: LarkAccountInterface.InterruptOperationType) -> Single<Bool> {
        MinutesLogger.record.info("receive interrupt msg")
        // 结束录音小窗
        if MinutesAudioRecorder.shared.status == .idle {
            MinutesAudioRecorder.shared.stop()
            MinutesAudioDataUploadCenter.shared.stop()
            return .just(true)
        }

        let title: String
        if type == .switchAccount {
            title = MinutesOpenI18n.RecordingStopIfSwitch
        } else {
            title = MinutesOpenI18n.RecordingStopIfLogOut
        }

        let cancelAction = { (single: Single<Bool>.SingleObserver) in
            single(.success(false))
        }
        let commitAction = { (single: Single<Bool>.SingleObserver) in
            MinutesAudioRecorder.shared.stop()
            MinutesAudioDataUploadCenter.shared.stop()
            single(.success(true))
        }

        return Single<Bool>.create(subscribe: { (single) -> Disposable in
            DispatchQueue.main.async {
                let mainScene = Scene.mainScene()
                SceneManager.shared.active(scene: mainScene, from: nil) { (window, error) in
                    if let window = window, let vc = window.rootViewController, error == nil {
                        let alertController = UIAlertController(title: title, message: "", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: MinutesOpenI18n.Cancel, style: .cancel, handler: { _ in
                            cancelAction(single)
                        }))
                        let actionTitle: String = type == .switchAccount ? MinutesOpenI18n.Switch : MinutesOpenI18n.LogOut
                        alertController.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                            commitAction(single)
                        }))
                        self.userResolver.navigator.present(alertController, from: vc)
                    } else {
                        single(.success(false))
                    }
                }
            }
            return Disposables.create()
        })
    }
}
