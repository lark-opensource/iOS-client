//
//  AudioUpdateService.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/26.
//

import UIKit
import Foundation
import LarkContainer
import RxSwift
import LarkModel
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import ThreadSafeDataStructure
import LarkSetting
import LarkSplitViewController

public final class AudioContentLifeService: PageService {

    private let disposeBag = DisposeBag()
    private let pushCenter: PushNotificationCenter
    private var barrierQueue = DispatchQueue(label: "AudioContentLifeService", attributes: .concurrent)
    private var audioPlayMediator: AudioPlayMediator?
    private var messageBurnService: MessageBurnService?
    var controllerProvider: () -> UIViewController?

    var audioKeys: SafeDictionary<String, String> = [:] + .readWriteLock

    init(
        pushCenter: PushNotificationCenter,
        messageBurnService: MessageBurnService?,
        audioPlayMediator: AudioPlayMediator?,
        controllerProvider: @escaping () -> UIViewController?) {
        self.pushCenter = pushCenter
        self.controllerProvider = controllerProvider
        self.audioPlayMediator = audioPlayMediator
        self.messageBurnService = messageBurnService
        self.setupListener()
    }

    /// 页面生命周期
    public func pageDidDisappear() {
        var needStopPlayAudio = true
        // iPad split 转化场景不停止音频播放
        if UIDevice.current.userInterfaceIdiom == .pad,
           let vc = self.controllerProvider(),
           let container = vc.parent,
           container.childrenIdentifier.contains(.isTransfering) {
            needStopPlayAudio = false
        }
        if needStopPlayAudio {
            self.audioPlayMediator?.stopPlayingAudio()
        }
    }

    private func setupListener() {
        self.pushCenter.observable(for: PushChannelMessages.self)
            .map({ (push) -> [Message] in
                return push.messages
            })
            .filter { !$0.isEmpty }
            .subscribe(onNext: { [weak self] (messages) in
                guard let `self` = self else { return }
                for message in messages {
                    self.stopAudioPlay(message: message)
                }
            }).disposed(by: self.disposeBag)

        // 失焦 暂停语音
        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.audioPlayMediator?.pausePlayingAudio()
            })
            .disposed(by: self.disposeBag)
    }

    //音频相关
    private func stopAudioPlay(message: Message) {
        guard message.content is AudioContent else { return }
        let isFileDeleted = message.fileDeletedStatus != .normal
        // 消息销毁
        guard message.isDeleted
            || message.isRecalled
            || isFileDeleted
            || messageBurnService?.isBurned(message: message) ?? false
            else { return }

        // 通过id 找key
        // Rust在销毁消息后，content会清空，通过messageID找key
        guard let key = audioKeys[message.id] else {
            // 异常 没找到key
            self.audioPlayMediator?.stopPlayingAudio()
            return
        }

        // 通过key暂停当前音频
        if self.audioPlayMediator?.isPlaying(key: key) ?? false {
            self.audioPlayMediator?.stopPlayingAudio()
        }
    }
}
