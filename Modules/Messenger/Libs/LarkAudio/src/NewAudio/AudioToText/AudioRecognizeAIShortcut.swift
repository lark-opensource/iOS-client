//
//  AudioRecognizeAIShortcut.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/20.
//

import RxSwift
import RxCocoa
import LarkModel
import Foundation
import LarkAIInfra
import LarkContainer
import LKCommonsLogging
import UniverseDesignColor

final class AudioRecognizeAIShortcut {
    let userResolver: UserResolver
    // 可以展示的时候 add 在 view 上，不可以展示的时候 remove 掉
    var isShowingButton: ((Bool, UIView) -> Void)?
    // UIView不为空的时候，把 view add 在合适的位置。UIView为空的时候，remove 掉
    var isShowingPreview: ((Bool, UIView) -> Void)?
    var aiResultCallback: ((String) -> Void)?
    var inputText: (() -> String)?
    private static let logger = Logger.log(AudioRecognizeAIShortcut.self, category: "NewRecordView")
    private let chat: Chat
    private let aiContainerView = UIView()
    private let aiCollectionView = AudioShortcutCollectionView()
    private lazy var aiAsrSDK: InlineAIAsrSDK = {
        let config = InlineAIConfig(captureAllowed: true, userResolver: self.userResolver)
        return LarkInlineAIModuleGenerator.createAsrSDK(config: config, customView: aiContainerView, delegate: InlineAISDKDelete())
    }()
    private var canShowButton: Bool = false
    private var disposeBag = DisposeBag()
    init(userResolver: UserResolver,
         chat: Chat) {
        self.chat = chat
        self.userResolver = userResolver
        setup()
    }

    private func setup() {
        guard userResolver.fg.dynamicFeatureGatingValue(with: "messenger.input.audio.ai") else { return }
        aiContainerView.backgroundColor = UDColor.bgBodyOverlay
        aiAsrSDK.getPrompts(result: { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let group):
                if let prompts = group.last?.prompts.filter({ ($0.extraMap["is_visible"] != nil) == true }) {
                    self.aiCollectionView.dataSource = prompts
                    self.handleAIButton()
                }
            case .failure(let error):
                Self.logger.error("ai.asr.sdk: ai_error: \(error)")
                break
            }
        })
        aiCollectionView.clickCallback = { [weak self] in self?.aiButtonClick(prompt: $0) }
        aiAsrSDK.isShowing.asObservable().subscribe(onNext: { [weak self] isShowing in
            guard let self, !isShowing else { return }
            self.isShowingPreview?(false, self.aiContainerView)
        }).disposed(by: disposeBag)
    }

    private func aiButtonClick(prompt: AIPrompt) {
        isShowingPreview?(true, aiContainerView)
        let helper = InlineAIAsrCallbackImpl(chat: chat,
                                             inputText: inputText?() ?? "",
                                             callback: { [weak self] aiResultStr in
            self?.aiResultCallback?(aiResultStr)
            self?.aiAsrSDK.hidePanel()
        })
        aiAsrSDK.showPanel(prompt: prompt, provider: helper, inlineAIAsrCallback: helper)
        AudioTracker.inlineAIEntranceClick(type: prompt.type)
        Self.logger.info("ai.asr.sdk: button click \(prompt.type)")
    }

    private func handleAIButton() {
        let isDataEmpty = !aiCollectionView.dataSource.isEmpty
        if isDataEmpty, canShowButton {
            AudioTracker.inlineAIEntranceView()
            isShowingButton?(true, aiCollectionView)
        } else {
            isShowingButton?(false, aiCollectionView)
        }
    }

    // displayState == .end && hasRecognizeResult && 输入框有文字
    func canShowButton(show: Bool) {
        if show != canShowButton {
            self.canShowButton = show
            handleAIButton()
        }
    }

    func reset() {
        isShowingButton?(false, aiCollectionView)
        isShowingPreview?(false, aiContainerView)
    }
}
