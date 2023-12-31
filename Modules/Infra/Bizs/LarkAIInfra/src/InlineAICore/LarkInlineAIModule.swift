//
//  LarkInlineAIModule.swift
//  LarkInlineAI
//
//  Created by ByteDance on 2023/4/25.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RxCocoa
import EENavigator
import ServerPB

/// 仅提供UI层接口
public protocol LarkInlineAIUISDK: AnyObject {

    func showPanel(panel: InlineAIPanelModel)
    
    func hidePanel(animated: Bool)
    
    func showSubPromptsPanel(prompts: InlineAISubPromptsModel)
    
    func updateCaptureAllowed(allow: Bool)
    
    var isShowing: Bool { get }
}

/// 提供UI层+数据层接口
public protocol LarkInlineAISDK: AnyObject {

    /// My AI是否可用
    var isEnable: BehaviorRelay<Bool> { get }

    /// 获取指令
    /// - Parameters:
    ///   - triggerParamsMap: 快捷指令过滤参数，用于筛选出适合当前场景的快捷指令列表，参考：https://bytedance.feishu.cn/docx/LHdSd2GKtoH2evxmEkGcp8pTnpc
    ///   - result: 拉取指令的回调
    func getPrompt(triggerParamsMap: [String: String], result: @escaping (Result<[InlineAIQuickAction], Error>) -> Void)

    /// 业务方点击AI入口，展示AI指令面板
    func showPanel(promptGroups: [AIPromptGroup])
    
    func sendPrompt(prompt: AIPrompt, promptGroups: [AIPromptGroup]?)
    
    /// 关闭浮窗，内部会清空数据, quitType用于识别来源，用于埋点上报
    func hidePanel(quitType: String)
    
    /// 当浮窗展示时隐藏UI，隐藏并非真正关闭，数据仍会缓存，业务方仍需要主动hidePanel才能真正关闭浮窗
    /// - Parameter isCollapsed: true: 隐藏UI; false: 恢复显示UI
    func collapsePanel(_ isCollapsed: Bool)
    
    /// 重试当前执行的指令
    func retryCurrentPrompt()

    func updateCaptureAllowed(allow: Bool)
    
    var isPanelShowing: BehaviorRelay<Bool> { get }
}

/// InlineAI语音SDK: 业务在初始化sdk时,sdk会拉取指令列表缓存起来,便于AI入口的快速展示
public protocol InlineAIAsrSDK: AnyObject {

    /// My AI是否可用
    var isEnable: BehaviorRelay<Bool> { get }
    
    /// AI面板视图是否正在展示
    var isShowing: BehaviorRelay<Bool> { get }

    /// 返回指令列表，便于部分指令在业务入口直接展示
    func getPrompts(result: @escaping (Result<[AIPromptGroup], Error>) -> Void)

    /// 展示AI面板
    /// - Parameters:
    ///   - prompt: 如果传了prompt, 表示需要立刻执行该指令, 否则展示指令列表
    ///   - provider: 执行指令时必要的参数
    ///   - inlineAIAsrCallback: 回调
    func showPanel(prompt: AIPrompt?, provider: InlineAIAsrProvider, inlineAIAsrCallback: InlineAIAsrCallback)
    
    /// 关闭AI面板
    func hidePanel()
}

public protocol InlineAIAsrProvider {
    
    /// 执行指令时业务方携带的context
    func getParam() -> [String: String]
}

public protocol InlineAIAsrCallback: AnyObject {
    
    /// 点击替换按钮时返回给业务数据, markdown格式
    func onSuccess(text: String)
    
    /// AI输出中error
    func onError(_ error: Error)
}

final class LarkInlineAIModule: LarkInlineAIUISDK {
    
    /// 视图层类型
    enum ViewPresentation {
        /// 大部分场景使用的浮窗控制器,  customView: 自定义的容器view，不传用SDK默认方式展示
        case panelViewController(customView: UIView?)
        /// 使用自定义UIView呈现视图,  不使用控制器
        case customView
    }
    
    private let viewPresentation: ViewPresentation
    
    /// viewPresentation为控制器时才初始化
    private(set) var panelVC: InlineAIPanelViewController?
    
    private weak var delegate: LarkInlineAIUIDelegate?
    
    private weak var aiFullDelegate: LarkInlineAISDKDelegate?
    
    var config: InlineAIConfig
    
    /// onboarding服务
    var aiOnboardingService: MyAIOnboardingService?
    
    lazy var viewModel: InlineAIPanelViewModel = {
        let panelViewModel = InlineAIPanelViewModel(aiDelegate: self.delegate,
                                      aiFullDelegate: self.aiFullDelegate,
                                      config: self.config)
        panelViewModel.showPanelRelay.subscribe { [weak self] model in
            self?.showPanel(panel: model)
        }.disposed(by: self.disposeBag)
        return panelViewModel
    }()
    
    var disposeBag = DisposeBag()
    
    private var onBoardingDisposeBag = DisposeBag()

    init(viewPresentation: ViewPresentation, aiDelegate: LarkInlineAIUIDelegate?, aiFullDelegate: LarkInlineAISDKDelegate?, config: InlineAIConfig) {
        self.viewPresentation = viewPresentation
        self.delegate = aiDelegate
        self.aiFullDelegate = aiFullDelegate
        self.config = config
        LarkInlineAILogger.info("[life] init \(ObjectIdentifier(self))")
    }
    
    func showPanel(panel: InlineAIPanelModel) {
        checkNeedOnboarding(finishOnboarding: { [weak self] in
            self?.internalShowPanel(panel: panel)
        })
    }
    
    private func internalShowPanel(panel: InlineAIPanelModel) {
        if !panel.show {
            LarkInlineAILogger.info("panel show is false")
            panelVC?.dismiss(animated: true)
            return
        }

        if panelVC == nil {
            if case .panelViewController(let customView) = self.viewPresentation {
                LarkInlineAILogger.info("create panelVC")
                if self.config.isFullSDK {
                    panelVC = InlineAIPanelViewController(viewModel: self.viewModel, contentCustomView: customView)
                } else {
                    let viewModel = InlineAIPanelViewModel(aiDelegate: self.delegate,
                                                           aiFullDelegate: nil,
                                                           config: self.config)
                    panelVC = InlineAIPanelViewController(viewModel: viewModel, contentCustomView: customView)
                }
            }
            panelVC?.setCaptureAllowed(config.captureAllowed)
        }
        
        if let panelVC = panelVC {
            panelVC.updateShowModel(panel)
            if panelVC.presentingViewController == nil,
               let vc = delegate?.getShowAIPanelViewController() ?? aiFullDelegate?.getShowAIPanelViewController() {
                LarkInlineAILogger.info("present panelVC")
                if panel.input?.showKeyboard == true {
                    panelVC.showAnimation = false
                } else {
                    panelVC.showAnimation = true
                }
                checkListContentPanGesture(hostVC: vc)
                panelVC.modalPresentationStyle = .overCurrentContext
                vc.present(panelVC, animated: true)
            }
        } else {
            // 视图层不是ViewController, 也要更新viewModel
            viewModel.updateModel(panel)
        }
    }
    
    private func checkListContentPanGesture(hostVC: UIViewController) {
        if let root = hostVC.navigationController, root.children.first?.modalPresentationStyle == .formSheet ||
            root.modalPresentationStyle == .formSheet {
            panelVC?.disableListContentPanGesture()
        } else if hostVC.modalPresentationStyle == .formSheet {
            panelVC?.disableListContentPanGesture()
        }
    }
    
    func showSubPromptsPanel(prompts: InlineAISubPromptsModel) {
        guard let panelVC = self.panelVC else {
            LarkInlineAILogger.error("show list menu fail, panelVC is nil")
            return
        }
        let data = prompts.data ?? []
        let model = InlineAIPanelModel.Prompts(show: !data.isEmpty, overlap: false, data: data)
        panelVC.showPromptPanel(model, dragBar: prompts.dragBar, update: prompts.update ?? false)
    }
    
    var isShowing: Bool {
        guard let panelVC = self.panelVC else {
            return false
        }
        return panelVC.view.superview != nil &&
        panelVC.presentingViewController != nil &&
        panelVC.isBeingDismissed == false
    }
    
    func hidePanel(quitType: String) {
        self.hidePanel()
        viewModel.hidePanel(quitType: quitType)
    }
    
    func hidePanel(animated: Bool = true) {
        LarkInlineAILogger.info("hidePanel")
        panelVC?.dissmissPromptPanel()
        panelVC?.dismiss(animated: animated)
    }
    
    func updateCaptureAllowed(allow: Bool) {
        self.config.updateCaptureAllowed(allow: allow)
        panelVC?.setCaptureAllowed(config.captureAllowed)
    }
    
    deinit {
        LarkInlineAILogger.info("[life] deinit \(ObjectIdentifier(self))")
    }
}

// MARK: Onboarding

private extension LarkInlineAIModule {
    
    enum OnboardingError: LocalizedError {
        case viewControllerNotFound
        var errorDescription: String? { "viewController not found" }
    }
    
    func checkNeedOnboarding(finishOnboarding: @escaping () -> ()) {
         guard let needOnboardingObs = self.aiOnboardingService?.needOnboarding else {
            finishOnboarding()
            return
        }
        
        // 处理状态通知
        onBoardingDisposeBag = .init()
        needOnboardingObs.subscribe(onNext: { [weak self] in
            self?.delegate?.onNeedOnBoarding(needOnBoarding: $0) // 监听后续变化
        }).disposed(by: onBoardingDisposeBag)
        
        if !needOnboardingObs.value { // 无需onboarding
            finishOnboarding()
            return
        }
        
        var fromvc: UIViewController?
        
        if case .panelViewController(let customView) = viewPresentation, let vc = customView?.affiliatedViewController {
            fromvc = vc
        } else if let vc = delegate?.getShowAIPanelViewController() {
            fromvc = vc
        } else if let vc = aiFullDelegate?.getShowAIPanelViewController() {
            fromvc = vc
        }
        guard let fromvc = fromvc else {
            delegate?.onUserQuitOnboarding(code: -1, error: OnboardingError.viewControllerNotFound)
            return
        }
        // 进入onboarding
        aiOnboardingService?.openOnboarding(from: ControllerWrapper(fromvc), onSuccess: { [weak self] _ in
            LarkInlineAILogger.info("inlineAI onboarding succeed")
            if self?.aiOnboardingService?.needOnboarding.value == false {
                finishOnboarding()
            } else {
                self?.delegate?.onUserQuitOnboarding(code: -1, error: nil)
            }
        }, onError: { [weak self] error in
            self?.delegate?.onUserQuitOnboarding(code: -1, error: error)
        }, onCancel: { [weak self] in
            self?.delegate?.onUserQuitOnboarding(code: 0, error: nil)
        })
    }
}

private class ControllerWrapper: NavigatorFrom {
    var fromViewController: UIViewController? { vc }
    var canBeStrongReferences: Bool { false }
    private let vc: UIViewController
    init(_ vc: UIViewController) {
        self.vc = vc
    }
}
