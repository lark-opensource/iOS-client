//
//  TestAIViewController.swift
//  ByteView_Example
//
//  Created by kiri on 2023/11/9.
//

#if canImport(MessengerMod)
import Foundation
import LarkContainer
import ByteViewUI
import LarkAIInfra

final class TestAIViewController: BaseViewController {
    let resolver: UserResolver
    init(resolver: UserResolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Test AI"

        let startButton = UIButton(type: .system)
        startButton.setTitle("Start", for: .normal)
        startButton.addTarget(self, action: #selector(didStart(_:)), for: .touchUpInside)
        view.addSubview(startButton)
        startButton.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
    }

    @objc private func didStart(_ sender: Any?) {
        let prompt = self.createTestPrompt()
        self.aiModule.sendPrompt(prompt: prompt, promptGroups: nil)
    }

    private lazy var aiModule: LarkInlineAISDK = {
        var config = InlineAIConfig(userResolver: self.resolver)
        config.update(debug: true)
        let module = LarkInlineAIModuleGenerator.createAISDK(config: config, customView: nil, delegate: self)
        return module
    }()

    func sendTestPrompt(from: UIViewController) {
        let prompt = self.createTestPrompt()
        self.aiModule.sendPrompt(prompt: prompt, promptGroups: nil)
    }

    func createTestPrompt() -> LarkAIInfra.AIPrompt {
        let templates = PromptTemplates(templatePrefix: "", templateList: [])
        return LarkAIInfra.AIPrompt(id: nil, icon: PromptIcon.todo.rawValue, text: "你是一个bot吗？", templates: templates, callback: AIPrompt.AIPromptCallback(onStart: { [weak self] in
            self?.logger.info("AIPromptCallback.onStart")
            let params: [String: String] = [
                "region": "AI"
            ]
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: params)
        }, onMessage: {  [weak self] message in
            self?.logger.info("AIPromptCallback.onMessage \(message)")
        }, onError: { [weak self] error in
            self?.logger.info("AIPromptCallback.onError \(error)")
        }, onFinish: { [weak self] state in
            self?.logger.info("AIPromptCallback.onFinish \(state)")
            if let self = self {
                return [self.copyButton, self.retryButton, self.exitButton]
            } else {
                return []
            }
        }))
    }

    var copyButton: OperateButton {
        return OperateButton(key: "copy", text: "Copy") { [weak self] (key, content) in
            self?.logger.info("OperateButton.copy, key = \(key), content = \(content)")
        }
    }

    var retryButton: OperateButton {
        return OperateButton(key: "retry", text: "Retry") { [weak self] (key, content) in
            self?.logger.info("OperateButton.retry, key = \(key), content = \(content)")
            self?.aiModule.retryCurrentPrompt()
        }
    }

    var exitButton: OperateButton {
        return OperateButton(key: "quit", text: "Quit") { [weak self] (key, content) in
            self?.logger.info("OperateButton.quit, key = \(key), content = \(content)")
            self?.aiModule.hidePanel(quitType: "click_button_on_result_page")
        }
    }

    func hidePanel() {
        self.aiModule.hidePanel(quitType: "click_button_on_result_page")
    }
}

extension TestAIViewController: LarkInlineAISDKDelegate {
    func getShowAIPanelViewController() -> UIViewController {
        return self
    }

    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        .allButUpsideDown
    }

    func onHistoryChange(text: String) {
        self.logger.info("onHistoryChange \(text)")
    }

    func onHeightChange(height: CGFloat) {
    }

    func getUserPrompt() -> LarkAIInfra.AIPrompt {
        createTestPrompt()
    }

    func getBizReportCommonParams() -> [AnyHashable: Any] {
        [:]
    }
}
#endif
