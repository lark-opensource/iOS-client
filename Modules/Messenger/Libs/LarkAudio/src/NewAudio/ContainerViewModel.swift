//
//  ContainerViewModel.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/15.
//

import RxSwift
import RxCocoa
import LarkModel
import Foundation
import LarkSendMessage
import LarkKeyboardView
import LarkBaseKeyboard
import LKCommonsLogging
import LarkContainer

public final class AudioContainerViewModel {
    public weak var keyboard: AudioSendMessageDelegate? {
        didSet {
            addObservable()
        }
    }
    let updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?
    var viewModels: [(KeyboardProvider, RecognizeLanguageManager.RecognizeType)] = []
    let iconColor: UIColor
    // 可以语音转文字
    let recognizeEnable: Bool
    // 可以语音加文字
    let audioWithTextEnable: Bool
    // 是否可以流式上传录音
    let supportStreamUpLoad: Bool
    let chat: Chat

    private let userResolver: UserResolver
    private var activeViewModel: KeyboardProvider?
    private var disposeBag = DisposeBag()
    static let logger = Logger.log(AudioContainerViewModel.self, category: "AudioContainerViewModel")

    public init(recognizeEnable: Bool, audioWithTextEnable: Bool, supportStreamUpLoad: Bool, chat: Chat,
                iconColor: UIColor, userResolver: UserResolver, updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?) {
        self.userResolver = userResolver
        self.recognizeEnable = recognizeEnable
        self.audioWithTextEnable = audioWithTextEnable
        self.supportStreamUpLoad = supportStreamUpLoad
        self.chat = chat
        self.iconColor = iconColor
        self.updateIconCallBack = updateIconCallBack
    }

    func addObservable() {
        guard recognizeEnable || audioWithTextEnable else { return }
        self.disposeBag = DisposeBag()
        RecognizeLanguageManager.shared.typeSubject
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] type in
                guard let self else { return }
                let icons = LarkBaseKeyboard.LarkKeyboard.keyboard(
                    iconColor: self.iconColor,
                    recognizeEnable: self.recognizeEnable,
                    audioWithTextEnable: self.audioWithTextEnable
                ).icons
                self.updateIconCallBack?(icons)
                if let vm = viewModels.first(where: { (_, vmType) in
                    return vmType == type
                }) {
                    activeViewModel = vm.0
                }
            }).disposed(by: self.disposeBag)
    }
}

extension AudioContainerViewModel: KeyboardProvider {
    public func cleanMaskView() {
        // keyboard frame Change
        Self.logger.info("cleanMaskView")
        activeViewModel?.cleanMaskView()
    }

    public func trackAudioRecognizeIfNeeded() {
        // 发送文字时会被调用
        Self.logger.info("trackAudioRecognizeIfNeeded")
        activeViewModel?.trackAudioRecognizeIfNeeded()
    }

    public func cleanAudioRecognizeState() {
        // 点击发送文字
        // 点击展开按钮时
        // onKeyboardJobChanged
        Self.logger.info("cleanAudioRecognizeState")
        activeViewModel?.cleanAudioRecognizeState()
    }
}
