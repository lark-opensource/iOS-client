//
//  InlineAIViewController.swift
//  Calendar
//
//  Created by pluto on 2023/9/20.
//

import Foundation
import RxSwift
import RxCocoa
import LarkAIInfra
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkEMM

protocol InlineAIViewControllerDelegate: AnyObject {
    func checkIfNeedScrollToCenter(type: AIGenerateEventInfoType)
    
    func getShowPanelViewController() -> UIViewController
    
    func updateEventInfoFromAI(data: InlineAIEventInfo)
    
    func updateFullEventInfoFromAI(data: InlineAIEventFullInfo)
    
    func getCurrentEventInfo() -> InlineAIEventFullInfo
    
    func meetingNotesCreateHandler()
}

final class InlineAIViewController: UIViewController {
    let logger = Logger.log(InlineAIViewController.self, category: "Calendar.InlineAIViewController")

    weak var delegate: InlineAIViewControllerDelegate?

    lazy var inlineAIModule: LarkInlineAIUISDK = {
        let inlineConfig = InlineAIConfig(captureAllowed: true,
                                          mentionTypes: [.user],
                                          scenario: .calendar,
                                          maskType: .fullScreen,
                                          lock: .unLock,
                                          userResolver: viewModel.userResolver)
        return LarkInlineAIModuleGenerator.createUISDK(config: inlineConfig, customView: nil,
                                                       delegate: self)
    }()
    
    let viewModel: InlineAIViewModel
    let disposeBag: DisposeBag = DisposeBag()

    var inlineUIStatusCallBack: ((InlineNavItemStatus?) -> Void)?

    init(viewModel: InlineAIViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        updateUserInteractionEnabled(isEnable: false)
        bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel() {
        viewModel.rxToast
            .bind(to: rx.toast)
            .disposed(by: disposeBag)

        viewModel.rxRoute
            .subscribeForUI(onNext: {[weak self] route in
                guard let self = self else { return }
                switch route {
                case .hide:
                    self.hideInlineAIPanel()
                case .createMeetingNotes:
                    self.delegate?.meetingNotesCreateHandler()
                case let .panel(data):
                    self.showInlineAIPanel(data: data)
                case let .subPanel(data):
                    self.showInlineSubAIPanel(data: data)
                default: break
                }
            }).disposed(by: disposeBag)
        
        viewModel.rxAction
            .subscribe(onNext: {[weak self] route in
                guard let self = self else { return }
                switch route {
                case let .eventInfoStage(data):
                    self.delegate?.updateEventInfoFromAI(data: data)
                case let .eventInfoFull(data):
                    self.delegate?.updateFullEventInfoFromAI(data: data)
                case .eventCurInfoGet:
                    self.updateCurrentEventInfo()
                }
            }).disposed(by: disposeBag)
        
        viewModel.rxStatus
            .subscribeForUI(onNext: {[weak self] status in
                guard let self = self else { return }
                switch status {
                case .initial, .working:
                    self.updateUserInteractionEnabled(isEnable: true)
                case .finsish:
                    self.updateUserInteractionEnabled(isEnable: false)
                case .unknown:
                    self.viewModel.inlineNavItemStatus?.status = .unknown
                    self.inlineUIStatusCallBack?(self.viewModel.inlineNavItemStatus)
                default: break
                }
            }).disposed(by: disposeBag)
    }
    
    func inlineAIClickHandler() {
        viewModel.updateOriginalEventInfo()
        viewModel.showPanel()
        updateUserInteractionEnabled(isEnable: true)

        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("my_ai")
        }
    }
    
    func hideInlineAIPanel() {
        updateUserInteractionEnabled(isEnable: false)
        inlineAIModule.hidePanel(animated: true)
        getShowAIPanelViewController().view.endEditing(true)
    }
    
    func getAITaskStatusByNeedConfirm(needConfirm: Bool) -> AiTaskStatus {
        return viewModel.handleAiTaskStatusGetter(needConfirm)
    }

    func updateSaveItemEnableStatus(inlineNavItemStatus: InlineNavItemStatus) {
        viewModel.inlineNavItemStatus = inlineNavItemStatus
    }

    func updateSaveItemEnableStatus(isRightEnable: Bool) {
        viewModel.inlineNavItemStatus?.rightNavEnable = isRightEnable
    }

    func hidePanelBySecondVCTemporary() {
        inlineAIModule.hidePanel(animated: false)
    }

    func showPanelFromSecondVCBack() {
        viewModel.showFinishPanelFromSecondVCBack()
    }

    private func showInlineSubAIPanel(data: InlineAISubPromptsModel) {
        inlineAIModule.showSubPromptsPanel(prompts: data)
    }
    
    private func showInlineAIPanel(data: InlineAIPanelModel) {
        updateUserInteractionEnabled(isEnable: false)
        inlineAIModule.showPanel(panel: data)
    }
    
    private func updateCurrentEventInfo() {
        viewModel.updateCurrentEventFullInfo(info: self.delegate?.getCurrentEventInfo())
    }
    
    private func updateUserInteractionEnabled(isEnable: Bool) {
        view.isUserInteractionEnabled = isEnable
    }
}

