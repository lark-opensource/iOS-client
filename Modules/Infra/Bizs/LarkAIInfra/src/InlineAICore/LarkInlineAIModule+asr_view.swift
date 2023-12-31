//
//  LarkInlineAIModule+asr_view.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/26.
//

import Foundation
import UniverseDesignToast

extension InlineAIAsrSDKImpl {
    
    /// 展示浮窗视图
    func showPanel(title: String?, finishCallback: @escaping (String) -> Void) {
        
        guard let containerView = asrContainerView else {
            LarkInlineAILogger.error("asr container view not exist")
            return
        }
        
        // 移除可能残留的旧视图
        containerView.subviews.forEach { v in
            (v as? InlineAIVoiceContentView)?.removeFromSuperview()
        }
        
        let contentView = InlineAIVoiceContentView()
        voiceContentView = contentView
        
        containerView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.bottom.equalTo(containerView.safeAreaLayoutGuide)
        }
        
        bindUIEvent(callback: finishCallback)
        bindData()
        
        contentView.setTitle(title)
        contentView.setState(.idle)
        
        isShowing.accept(true)
        aiModule.viewModel.tracker.show(aiState: aiModule.viewModel.aiState)
    }
    
    private func bindUIEvent(callback: @escaping (String) -> Void) {
        
        let view = self.voiceContentView
        
        view?.onFinishClick = { [weak self] in
            guard let self = self else { return }
            let aiState = self.aiModule.viewModel.aiState
            self.aiModule.viewModel.tracker.resultActionClick(aiState: aiState, operationKey: "", isStopAction: false)
            let text = self.aiModule.viewModel.aiState.currentTask?.content ?? ""
            callback(text)
            self.hidePanel()
        }
        
        view?.onStopClick = { [weak self] in
            guard let self = self else { return }
            let aiState = self.aiModule.viewModel.aiState
            self.aiModule.viewModel.tracker.resultActionClick(aiState: aiState, operationKey: "", isStopAction: true)
            self.hidePanel()
        }
        
        view?.onCloseClick = { [weak self] in
            self?.hidePanel()
        }
        
        view?.onThemeChange = { [weak self] in
            guard var model = self?.aiModule.viewModel.model else { return }
            model.theme = self?.aiModule.viewModel.getCurrentTheme()
            let isFinish = model.input?.status == 0
            self?.voiceContentView?.updateContent(model.content ?? "",
                                                  theme: model.theme ?? "",
                                                  conversationId: model.conversationId,
                                                  taskId: model.taskId,
                                                  isFinish: isFinish)
        }
        
        view?.onAIEvent = { [weak self] event in
            if case .getEncryptId(let completion) = event {
                let id = self?.delegate?.getEncryptId()
                completion(id)
            }
        }
    }
    
    private func bindData() {
        
        disposeBag = .init() // 避免重复添加监听
        aiModule.viewModel.showPanelRelay.subscribe { [weak self] model in
            let isFinish = model.input?.status == 0
            self?.voiceContentView?.updateContent(model.content ?? "",
                                                  theme: model.theme ?? "",
                                                  conversationId: model.conversationId,
                                                  taskId: model.taskId,
                                                  isFinish: isFinish)
        }.disposed(by: disposeBag)
        
        aiModule.viewModel.output.subscribe(onNext: { [weak self] output in
            switch output {
            case .show(let model):
                self?.voiceContentView?.setState(.writing(model.panelModel))
            case .showErrorMsg(let msg):
                if let view = self?.asrContainerView {
                    UDToast.showFailure(with: msg, on: view.window ?? view)
                }
            case .dismissPanel:
                self?.hidePanel()
            default:
                break
            }
        }).disposed(by: disposeBag)
        
        aiModule.viewModel.aiState.statusObservable().subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            if status == .finished {
                self.voiceContentView?.setState(.finished(.success(())))
                
                let selectedPrompt = self.aiModule.viewModel.aiState.currentTask?.selectedPrompt
                let isSubPrompt = (selectedPrompt?.extraMap["parent_key"] as? String ?? "").isEmpty == false
                if isSubPrompt, let promptId = selectedPrompt?.id, let panelModel = self.aiModule.viewModel.model {
                    self.viewModel.saveResult(model: panelModel, for: promptId)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred() // 震动反馈
            }
        }).disposed(by: disposeBag)
    }
}

extension InlineAIAsrSDKImpl {
    
    /// 浮窗面板自定义view
    var voiceContentView: InlineAIVoiceContentView? {
        get {
            objc_getAssociatedObject(self, &contentViewKey) as? InlineAIVoiceContentView
        }
        set {
            objc_setAssociatedObject(self, &contentViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 外部传入的容器UIView，浮窗面板会加到该视图
    var asrContainerView: UIView? {
        get {
            (objc_getAssociatedObject(self, &containerViewKey) as? Weak<UIView>)?.value
        }
        set {
            let newObj = newValue.map { Weak<UIView>($0) }
            objc_setAssociatedObject(self, &containerViewKey, newObj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private var contentViewKey: UInt8 = 0
private var containerViewKey: UInt8 = 0

private class Weak<T: AnyObject>: NSObject {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}
