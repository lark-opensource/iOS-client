//
//  LarkInlineAIModule+Asr.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignToast

enum AIAsrSDKState {
    /// 还未开始执行指令
    case idle
    /// 执行指令中
    case writing(InlineAIPanelModel)
    /// 执行指令完成
    case finished(Swift.Result<(), Error>)
}

final class InlineAIAsrSDKImpl {
    
    let aiModule: LarkInlineAIModule
    
    private(set) weak var delegate: LarkInlineAISDKDelegate?
    
    let viewModel: InlineAIVoiceViewModel
    
    let isShowing = BehaviorRelay<Bool>(value: false) // 遵守InlineAIAsrSDK
    
    /// 缓存的指令列表
    private(set) var cachedPromptGroup = [AIPromptGroup]()
    
    var disposeBag = DisposeBag()
    
    init(aiModule: LarkInlineAIModule, delegate: LarkInlineAISDKDelegate?) {
        self.aiModule = aiModule
        self.delegate = delegate
        self.viewModel = InlineAIVoiceViewModel()
        // 埋点公参
        self.aiModule.viewModel.tracker.baseParqams = {
            delegate?.getBizReportCommonParams() ?? [:]
        }
    }
    
    func updatePromptsCache(_ list: [AIPromptGroup]) {
        cachedPromptGroup = list
    }
}

extension InlineAIAsrSDKImpl: InlineAIAsrSDK {
    
    var isEnable: BehaviorRelay<Bool> { aiModule.isEnable }

    func getPrompts(result: @escaping (Result<[AIPromptGroup], Error>) -> Void) {
        
        let useCache = (cachedPromptGroup.isEmpty == false)
        if useCache {
            result(.success(cachedPromptGroup))
            fetchPrompts(result: nil)
        } else {
            fetchPrompts(result: result)
        }
    }

    func showPanel(prompt: AIPrompt?, provider: InlineAIAsrProvider, inlineAIAsrCallback: InlineAIAsrCallback) {
        
        _hidePanel(updateShowingState: false) // 不需要触发isShowing变化
        
        asrCallback = inlineAIAsrCallback
        
        showPanel(title: prompt?.text, finishCallback: { [weak inlineAIAsrCallback] in
            inlineAIAsrCallback?.onSuccess(text: $0)
        })
        
        if let prompt = prompt { // 立即执行
            excutePrompt(prompt, param: provider.getParam(), callback: inlineAIAsrCallback)
        }
    }
    
    func hidePanel() {
        _hidePanel()
    }
    
    private func _hidePanel(updateShowingState: Bool = true) {
        aiModule.viewModel.hidePanel(quitType: "")
        voiceContentView?.removeFromSuperview()
        voiceContentView = nil
        if updateShowingState {
            isShowing.accept(false)
        }
    }
}

extension InlineAIAsrSDKImpl {
    
    /// 外部传入的回调对象
    private var asrCallback: InlineAIAsrCallback? {
        get {
            (objc_getAssociatedObject(self, &callbackKey) as? Strong<InlineAIAsrCallback>)?.value
        }
        set {
            let newObj = newValue.map { Strong<InlineAIAsrCallback>($0) }
            objc_setAssociatedObject(self, &callbackKey, newObj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var callbackKey: UInt8 = 0

private class Strong<T>: NSObject {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}
