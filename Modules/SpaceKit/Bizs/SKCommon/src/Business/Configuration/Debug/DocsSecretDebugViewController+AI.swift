//
//  DocsSecretDebugViewController+AI.swift
//  SKCommon
//
//  Created by huayufan on 2023/7/26.
//  
import LarkAIInfra
import ServerPB
import LarkContainer
import UniverseDesignToast
import UniverseDesignColor

#if BETA || ALPHA || DEBUG
extension DocsSercetDebugViewController: LarkInlineAISDKDelegate {
    
    public func getBizReportCommonParams() -> [AnyHashable : Any] {
        return [:]
    }
    
    func aiTest() {
        let config = InlineAIConfig(captureAllowed: true,
                                    scenario: .groupChat,
                                    maskType: .aroundPanel,
                                    panelMargin: .init(bottomWithKeyboard: 10, bottomWithoutKeyboard: 30, leftAndRight: 30),
                                    userResolver: Container.shared.getCurrentUserResolver())
        aiModule = LarkInlineAIModuleGenerator.createAISDK(config: config, customView: nil, delegate: self)
    
        aiModule?.getPrompt(triggerParamsMap: [:]) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(actions):
                var groups = [AIPromptGroup]()
                let prompts = actions.map {
                    AIPrompt(id: $0.id, icon: $0.icon, text: $0.name, templates: nil, callback: AIPrompt.AIPromptCallback(onStart: {
                        debugPrint("[hyf demo] start")
                        return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
                    }, onMessage: { msg in
                        debugPrint("[hyf demo] onMessage: \(msg)")
                    }, onError: { error in
                        debugPrint("[hyf demo] onError: \(error)")
                    }, onFinish: { code in
                        debugPrint("[hyf demo] onFinish: \(code)")
                        return []
                    }))
                }
                groups.append(AIPromptGroup(title: "测试", prompts: prompts))
                self.aiModule?.showPanel(promptGroups: groups)

            case let .failure(error):
                UDToast.showFailure(with: error.localizedDescription, on: self.view.window ?? self.view)
                debugPrint("ai err: \(error)")
            }
        }
    }
    
    func aiTestV2() {
        let myContainerView = UIView()
        myContainerView.backgroundColor = UDColor.bgBodyOverlay
        
        view.addSubview(myContainerView)
        myContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(330)
        }
        
        let config = InlineAIConfig(captureAllowed: true, userResolver: Container.shared.getCurrentUserResolver())
        
        self.aiAsrSDK = LarkInlineAIModuleGenerator.createAsrSDK(config: config, customView: myContainerView, delegate: nil)
        
        let helper = InlineAIAsrHelper()
        
        aiAsrSDK?.getPrompts(result: { [weak self] result in
            switch result {
            case .success(let group):
                debugPrint("[chensi demo], getPrompts success:\(group)")
                let lastPrompt = group.last?.prompts.last
                debugPrint("[chensi demo], lastPrompt, icon:\(lastPrompt?.icon), \(lastPrompt?.type)")
                self?.aiAsrSDK?.showPanel(prompt: lastPrompt, provider: helper, inlineAIAsrCallback: helper)
            case .failure(let error):
                debugPrint("[chensi demo], getPrompts error:\(error)")
            }
        })
        
        aiAsrSDK?.isShowing.skip(1).subscribe(onNext: {
            if $0 == false {
                myContainerView.removeFromSuperview()
            }
        }).disposed(by: aiAsrDisposeBag)
    }
    
    private class InlineAIAsrHelper: InlineAIAsrCallback, InlineAIAsrProvider {
        // 使用openWebContainer场景时，key是"text"、"msg"
        func getParam() -> [String: String] { ["voice_input_text": "让我们的笑容充满着青春的骄傲",
//                                               "im_chat_history_message_server": "osuheoiuhvcoisduhfco8useh",
//                                               "display_lang":"cn",
                                               "input_text": "让我们的笑容充满着青春的骄傲",
                                               "im_chat_chat_id": "7220996723861094420",
                                               "im_chat_chat_name": "Doc AI 体验",
                                               "im_chat_history_message_client": "{\"chat_id\":\"7220996723861094420\",\"direction\":\"up\",\"start_position\":10}"
        ] }
        func onSuccess(text: String) {
            debugPrint("[chensi demo], onSuccess:\(text)")
        }
        func onError(_ error: Error) {
            debugPrint("[chensi demo], onError:\(error)")
        }
    }
    
    public func getShowAIPanelViewController() -> UIViewController {
        return self
    }
    
    /// 横竖屏切换样式，目前iPhone不支持横屏，只有iPad会根据这个来设定，不返回默认不支持横屏
    public var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { return nil }
    
    
    public func onHistoryChange(text: String) {
        
    }
    
    /// 面板高度变化时通知业务方
    public func onHeightChange(height: CGFloat) {
        
    }
    
    func testPrompt(text: String) -> AIPrompt {
        let templates =  PromptTemplates(templatePrefix: "我是前缀", templateList: [PromptTemplate(templateName: "templateName", key: "key", placeHolder: "placeHolder", defaultUserInput: "defaultUserInput")])
        return AIPrompt(id: "123", icon: "", text: text, templates: nil, callback: .init(onStart: {
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
        }, onMessage: { _ in
            
        }, onError: { error in
            
        }, onFinish: { _ in
            return []
        }))
    }
    
    func testPrompt2(text: String) -> AIPrompt {
        let templates =  PromptTemplates(templatePrefix: "我是前缀", templateList: [PromptTemplate(templateName: "templateName", key: "key", placeHolder: "placeHolder", defaultUserInput: "defaultUserInput")])
        return AIPrompt(id: "520", icon: "", text: text, templates: templates, callback: .init(onStart: {
            return AIPrompt.PromptConfirmOptions(isPreviewMode: false, param: [:])
        }, onMessage: { _ in
            
        }, onError: { error in
            
        }, onFinish: { _ in
            return []
        }))
    }
    
    func retryButtonFunc() -> OperateButton {
        return OperateButton(key: "b", text: "重试", isPrimary: false) { [weak self] _, _ in
            self?.aiModule?.retryCurrentPrompt()
        }
    }
    
    func existButtonFunc() -> OperateButton {
        return OperateButton(key: "a", text: "退出", isPrimary: false) { [weak self] _, _ in
            guard let self else { return }
//            self?.aiModule?.hidePanel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self else { return }
                self.aiModule?.collapsePanel(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    guard let self else { return }
                    self.aiModule?.collapsePanel(false)
                }
            }
        }
    }
    
    public func getUserPrompt() -> AIPrompt {
        
        let retryButton = retryButtonFunc()
        
        let group = AIPromptGroup(title: "测试1", prompts: [testPrompt(text: "ABC"),
                                               testPrompt(text: "DEF"),
                                               testPrompt(text: "GHI"),
                                               testPrompt(text: "JKL"),
                                               testPrompt(text: "MNO")])
        let showSubPanelButton = OperateButton(key: "c", text: "二级面板", isPrimary: false, promptGroups: [group, group]) { _, _ in

        }
        
        let existButton = existButtonFunc()
        
        
        return AIPrompt(id: nil, icon: "", text: "", templates: nil, callback: AIPrompt.AIPromptCallback(onStart: {
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
        }, onMessage: { _ in
            
        }, onError: { _ in
            
        }, onFinish: { _ in
            return [existButton, showSubPanelButton, retryButton]
        }))
    }
}
#endif
