//
//  InlineAIPanelViewController.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/25.
//  


import UIKit
import SnapKit
import RxSwift
import UniverseDesignColor
import LarkKeyboardKit
import EENavigator
import LarkUIKit
import LarkBaseKeyboard
import EditTextView
import LarkModel
import LarkContainer
import UniverseDesignDialog
import UniverseDesignToast

class InlineAIPanelViewController: InlineAIPanelViewGragableViewController, SubPromptPanelViewDelegate {
    
    let viewModel: InlineAIPanelViewModel
    
    var disposeBag = DisposeBag()
    
    var lockScreen = true
    
    var subViewPanBeginOffset: CGFloat?
    
    let animationDuration: TimeInterval = 0.2
    
    private var contentCustomView: UIView?
    
    var config: InlineAIConfig

    var gestureBeginHeight: CGFloat = 0

    lazy var gestureUtils: LarkInlineGestureUtils = {
        let utils = LarkInlineGestureUtils(containerView: self.view, panelView: self.mainPanelView) { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .dragPanelConfirm:
                self.maskBgView.eventRelay.accept(.clickMaskErea)
            case .closePanel:
                //通知前端下掉面板
                self.closeAction()
            }
        }
        utils.delegate = self
        return utils
    }()

    init(viewModel: InlineAIPanelViewModel, contentCustomView: UIView?) {
        self.viewModel = viewModel
        self.config = viewModel.config
        self.contentCustomView = contentCustomView
        super.init()
        self.view.backgroundColor = .clear
        self.mainPanelView.gestureDelegate = self.gestureUtils
    }
    
    var currentTopMostVC: UIViewController? {
        let aiDelegate = self.viewModel.aiDelegate
        let aiFullDelegate = self.viewModel.aiFullDelegate
        return aiDelegate?.getShowAIPanelViewController() ?? aiFullDelegate?.getShowAIPanelViewController()
    }
    /// 整个面板容器
    lazy var mainPanelView: InlineAIMainPanelView = {
        var panelWidth: CGFloat?
        if let view = self.currentTopMostVC?.view {
            panelWidth = view.bounds.size.width - self.leftRightPanelInset
        }

        let view = InlineAIMainPanelView(contentCustomView: self.contentCustomView, panelWidth: panelWidth, settings: viewModel.settings)
        view.textInputView.didClickMentionedUser = { [weak self] uid in
            self?.handleClickMentionedUser(uid)
        }
        
        view.backgroundColor = UDColor.bgFloat
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.customHitTest = { [weak self] (point, event) in
            let viewController = self?.currentTopMostVC
            guard let self = self,
                  self.lockScreen == false,
                  let vc = viewController else {
                return nil
            }
            let vcPoint = self.mainPanelView.convert(point, to: vc.view)
            let hitView = vc.view.hitTest(vcPoint, with: event)
            return hitView
        }
        view.layoutSubviewCallback = { [weak self] in
            self?.panelHeightChange()
        }
        return view
    }()
    
    // 二级指令搜索面板
    lazy var overlapPromptView: InlineAIOverlapPromptView = {
        let view = InlineAIOverlapPromptView()
        view.alpha = 0
        return view
    }()
    
    lazy var overlapMaskView: UIView = {
        let overlapView = UIView(frame: .zero)
        overlapView.alpha = 0
        overlapView.backgroundColor = UDColor.bgMask
        overlapView.isUserInteractionEnabled = false
        return overlapView
    }()
    
    lazy var aroundPanelMaskView = InlineAIGradientView(direction: .vertical, colors: [UDColor.bgMask.withAlphaComponent(0.00), UDColor.bgMask.withAlphaComponent(0.2)])
    
    var keyboardInset: CGFloat = 0
    
    /// true：使用默认高度， false：使用拖拽高度（最后一次高度）
    var setPanelToDefaultHeight: Bool = true

    var maskType: InlineAIPanelModel.MaskType = .fullScreen

    var panGestureIsWorking = false {
        didSet {
            if panGestureIsWorking,
               self.setPanelToDefaultHeight,
               !viewModel.isKeyboardShow,
               gestureUtils.isDraggingDragBar {
                LarkInlineAILogger.info("setPanelToDefaultHeight false --panGestureIsWorking")
                self.setPanelToDefaultHeight = false
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 面板左右间距，iPad和iPhone不一样
    var leftRightPanelInset: CGFloat {
        if let leftAndRight = self.config.panelMargin?.leftAndRight {
            return leftAndRight
        }
        return 8
    }
    
    deinit {
        LarkInlineAILogger.info("InlineAIPanelViewController deinit")
    }
    
    override func viewDidLoad() {
        configureInput()
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.eventRelay.accept(.vcViewDidLoad)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    var animationControl = InlineAIAnimationControl()
    
    func setupUI() {
        basicContainerView.addSubview(aroundPanelMaskView)
        basicContainerView.sendSubviewToBack(aroundPanelMaskView)
        aroundPanelMaskView.snp.remakeConstraints { make in
           make.left.right.equalToSuperview()
           make.top.equalTo(self.mainPanelView.snp.top).offset(-64)
           make.bottom.equalTo(self.view.snp.bottom)
        }
        self.mainPanelView.snp.updateConstraints({ make in
            make.height.equalTo(0).priority(999)
            make.bottom.equalToSuperview().inset(self.panelBottomOffset)
            make.left.right.equalToSuperview().inset(self.leftRightPanelInset)
        })
    }
    
    override func willPresent() {
        LarkInlineAILogger.warn("willPresent")
        super.willPresent()
        if self.mainPanelView.contentView.show {
            setupLayout(contentRenderHeight)
            mainPanelView.contentView.preload()
        } else {
            setupLayout(defaultHeight)
        }
        aroundPanelMaskView.snp.remakeConstraints { make in
           make.left.right.equalToSuperview()
           make.top.equalTo(self.mainPanelView.snp.top).offset(-64)
           make.bottom.equalTo(self.view.snp.bottom)
        }
        mainPanelView.layoutFirstViewIfNeed()
        mainPanelView.layoutIfNeeded()
    }
    
    override func didPresentCompletion() {
        LarkInlineAILogger.warn("didPresentCompletion")
        super.didPresentCompletion()
        viewModel.eventRelay.accept(.vcPresented)
        if self.mainPanelView.contentView.show {
            setupLayout(contentRenderHeight)
        } else {
            setupLayout(defaultHeight)
        }
        self.lastPanelHeight = self.currentContainerView().frame.size.height
        LarkInlineAILogger.info("didPresentCompletion default height: \(self.lastPanelHeight)")
        mainPanelView.didPresentCompletion()
    }
    
    override func didDismissCompletion() {
        LarkInlineAILogger.info("didDismissCompletion recover height: \(self.lastPanelHeight)")
        mainPanelView.didDismissCompletion()
        viewModel.aiDelegate?.panelDidDismiss()
        viewModel.eventRelay.accept(.vcDismissed)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        LarkInlineAILogger.info("traitCollectionDidChange - updateTheme")
        //更新主题
        viewModel.eventRelay.accept(.updateTheme)
    }
    
    
    /// 更新AI面板布局
    /// - Parameters:
    ///   - height: 面板高度
    ///   - topOffSet: 大于0时表示做位移，而不是伸缩
    func setupLayout(_ height: CGFloat, topOffSet: CGFloat = 0, animation: Bool = false) {
        LarkInlineAILogger.info("setupLayout mainPanel height: \(height)")
        let layoutPanel = { [weak self] in
            guard let self = self else { return }
            self.mainPanelView.snp.updateConstraints({ make in
                make.height.equalTo(height).priority(999)
                var inset = self.panelBottomOffset
                if topOffSet > 0 {
                    inset = self.view.bounds.size.height - topOffSet - height
                }
                make.bottom.equalToSuperview().inset(inset)
            })
        }
        if animation {
            UIView.animate(withDuration: animationDuration) {
                layoutPanel()
                self.view.layoutIfNeeded()
            }
        } else {
            layoutPanel()
        }
    }
    
    var keyBoardHeight: CGFloat {
        viewModel.keyBoardHeight
    }
    
    /// 面板底部距离容器高度
    var panelBottomOffset: CGFloat {
        guard let panelMargin = self.config.panelMargin else {
            if let vc = self.presentedViewController,
               UIDevice.current.userInterfaceIdiom == .pad {
                return 8 + vc.view.safeAreaInsets.bottom
            }
            return 32
        }
        return panelMargin.bottomWithoutKeyboard
    }
    
    /// 面板底部距离容器高度
    var keyboardMargin: CGFloat {
        guard let panelMargin = self.config.panelMargin else {
            return 8
        }
        return panelMargin.bottomWithKeyboard
    }
    
    override func currentContainerView() -> UIView {
        return mainPanelView
    }
    
    override var defaultHeight: CGFloat {
        return min(mainPanelView.getCurrentShowPanelHeight(), self.view.frame.size.height * 0.6 - panelBottomOffset)
    }
    
    override var totalMinHeight: CGFloat {
        return min(mainPanelView.getCurrentShowPanelHeight(), self.view.frame.size.height * 0.3 - panelBottomOffset)
    }
    
    override var totalMaxHeight: CGFloat {
        min(self.view.frame.size.height * 0.8 - panelBottomOffset, mainPanelView.getCurrentShowPanelHeight())
    }
    
    var contentRenderHeight: CGFloat {
        let temp = max(mainPanelView.getCurrentShowPanelHeight(), self.view.frame.size.height * 0.3 - panelBottomOffset)
        return min(self.view.frame.size.height * 0.8 - panelBottomOffset, temp)
    }
    
    /// 结果页展示
    private var needFixPanelHeight: Bool {
        return mainPanelView.isContentViewShow()
    }
    
    func updateShowModel(_ model: InlineAIPanelModel) {
        viewModel.updateModel(model)
    }
    
    private func updateHeightIfNeed() {
        // Prompts自适应
        func updateHeightIfInSearchingPromptsView() -> Bool {
            if viewModel.modelDescription.isInSearchingPromptsView {
                // 更新高度
                let keyboardHeight = self.keyboardInset
                let ratio = viewModel.isKeyboardShow ? 0.8 : 0.6
                let maxPanelHeight = (self.view.frame.size.height - self.view.safeAreaInsets.top ) * ratio - keyboardHeight - 8
                let newHeight = min(mainPanelView.getCurrentShowPanelHeight(), maxPanelHeight)
                LarkInlineAILogger.info("searching maxPanelHeight: \(maxPanelHeight) newHeight:\(newHeight)")
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.mainPanelView.snp.updateConstraints({ make in
                        make.height.equalTo(newHeight).priority(999)
                        make.bottom.equalToSuperview().inset(max(self.keyboardInset + self.keyboardMargin, self.panelBottomOffset))
                    })
                    self.view.layoutIfNeeded()
                })
                return true
            } else {
                LarkInlineAILogger.info("no searching prompts change")
                return false
            }
        }
        
        
        /// 1. 如果loading中就重置为自适应
        /// 2. 上次有拖拽dragBar，使用拖拽后的位置
        /// 3. 拖动内容暂时取消自适应
        func updateHeightIfContentChange() {
//            let contentChange = viewModel.modelDescription.contentChange || viewModel.modelDescription.imagesChange
            if !panGestureIsWorking,
               !viewModel.isKeyboardShow,
               setPanelToDefaultHeight {
                var newHeight = contentRenderHeight
                if !mainPanelView.isContentSupportSelfAdaption {
                    newHeight = defaultHeight
                }
                self.lastPanelHeight = newHeight
                LarkInlineAILogger.info("updateHeight content change newHeight: \(newHeight)")
                self.mainPanelView.updateSubViewLayout()
                if viewModel.modelDescription.imagesChange {
                    UIView.animate(withDuration: 0.05, animations: {
                        self.mainPanelView.snp.updateConstraints({ make in
                            make.height.equalTo(newHeight).priority(999)
                        })
                        self.mainPanelView.layoutIfNeeded()
                    })
                } else {
                    self.mainPanelView.snp.updateConstraints({ make in
                        make.height.equalTo(newHeight).priority(999)
                    })
                    self.mainPanelView.layoutIfNeeded()
                }
            } else {
                LarkInlineAILogger.info("no content change: \(viewModel.modelDescription.changes) panIsWorking：\(panGestureIsWorking) isKeyboardShow:\(viewModel.isKeyboardShow) setPanelToDefaultHeight: \(setPanelToDefaultHeight)")
            }
        }
        
        let udpated = updateHeightIfInSearchingPromptsView()
        if !udpated {
            updateHeightIfContentChange()
        }
    }
    
    func updateBgMask(maskType: InlineAIPanelModel.MaskType) {
        switch maskType {
        case .fullScreen:
            maskBgView.backgroundColor = UDColor.bgMask
            aroundPanelMaskView.alpha = 0
        case .aroundPanel:
            maskBgView.backgroundColor = .clear
            aroundPanelMaskView.alpha = 1
        case .none:
            maskBgView.backgroundColor = .clear
            aroundPanelMaskView.alpha = 0
        }
        self.maskType = maskType
    }
    
    var prePanelHeight: CGFloat?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        panelHeightChange()
    }
    
    private func panelHeightChange() {
        // 确保当前不是在拖拽UI
//        guard panGestureIsWorking == false else { return }
        let height = view.bounds.height - mainPanelView.frame.origin.y
        // 高度有变化 通知业务方
        if height != prePanelHeight {
            prePanelHeight = height
            self.viewModel.eventRelay.accept(.panelHeightChange(height: height))
        }
    }
    
    private func getCurrentDefaultHeight() -> CGFloat {
        // 有键盘
        if viewModel.isKeyboardShow {
            var newHeight = 0.0
            let bottom = view.window?.safeAreaInsets.bottom ?? 0
            let inset = viewModel.keyBoardHeight + bottom
            // 如果有结果页
            if needFixPanelHeight {
                newHeight = self.view.frame.size.height - self.view.safeAreaInsets.top  - inset - keyboardMargin - 96
            } else {
                // 如果没有展示结果页，键盘+panel为80%
                newHeight = min(self.mainPanelView.frame.size.height, (self.view.frame.size.height - self.view.safeAreaInsets.top) * 0.8 - inset - keyboardMargin)
            }
            return newHeight
        } else {
        // 无键盘
            return self.view.frame.size.height * 0.6 - panelBottomOffset
        }
    }
    
    override func didClickMaskErea(gesture: UIGestureRecognizer) {
        let point = gesture.location(in: mainPanelView)
        LarkInlineAILogger.info("didClickMaskErea: \(point)")
        let size = mainPanelView.frame.size
        if point.x < 0 || point.x > size.width {
            LarkInlineAILogger.warn("didClickMaskErea on the side")
            return
        } else if point.y > size.height {
            LarkInlineAILogger.warn("didClickMaskErea on the bottom")
            return
        }
        // 键盘展示
        if viewModel.isKeyboardShow {
            LarkInlineAILogger.info("didClickMaskErea Keyboard show")
            KeyboardKit.shared.firstResponder?.resignFirstResponder()
        } else {
            if let panel = topPromptPanel() {
                panel.dissmiss()
            } else {
                maskBgView.eventRelay.accept(.clickMaskErea)
            }
        }
    }
    
    // 关闭流程
    func closeAction() {
        LarkInlineAILogger.info("closeAction")
        maskBgView.eventRelay.accept(.closePanel)
        dismiss(animated: true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // 拖拽过程以及输入过程暂时不允许横屏
        if viewModel.isKeyboardShow || panGestureIsWorking {
                return .portrait
        }
        if let ioMask = viewModel.aiDelegate?.supportedInterfaceOrientationsSetByOutsite, UIDevice.current.userInterfaceIdiom == .pad {
            return ioMask
        } else {
            return .portrait
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                self.mainPanelView.snp.updateConstraints({ make in
                    make.left.right.equalToSuperview().inset(self.leftRightPanelInset)
                    if self.mainPanelView.bounds.size.height > self.totalMaxHeight {
                        make.height.equalTo(self.totalMaxHeight).priority(999)
                        self.lastPanelHeight = self.totalMaxHeight
                    }
                })
            }
        }
    }
    
    override func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
       return InlineAIPanelDismissTransitioning(animateDuration: animateDuration, overwritingDismiss: true) { [weak self] in
            guard let self = self else { return }
            self.willDismiss()
            // 关闭时背景要固定
            self.aroundPanelMaskView.snp.remakeConstraints { make in
               make.left.right.equalToSuperview()
               make.height.equalTo(self.mainPanelView.snp.height).offset(64)
               make.bottom.equalTo(self.view.snp.bottom)
            }
        } animation: {[weak self] in
            guard let self = self else { return }
            let height = self.mainPanelView.bounds.size.height + self.panelBottomOffset
            self.mainPanelView.snp.updateConstraints { make in
                 make.bottom.equalToSuperview().inset(-height)
            }
            self.maskBgView.alpha = 0.0
            self.aroundPanelMaskView.alpha = 0.0
            self.view.layoutIfNeeded()
        } completion: {[weak self] in
            guard let self = self else { return }
            self.didDismissCompletion()
        }
    }
    
    func disableListContentPanGesture() {
        mainPanelView.disableListContentPanGesture()
    }
}


// MARK: - Bind

extension InlineAIPanelViewController {
    func bindViewModel() {
        viewModel.panelView = currentContainerView()
        // UI --> ViewModel
        mainPanelView.eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        overlapPromptView.eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        maskBgView.eventRelay.bind(to: viewModel.eventRelay).disposed(by: disposeBag)
        
        // ViewModel --> UI
        viewModel.output.skip(1).subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case let .updatePanelViewBottom(inset, duration):
                self.updatePanelViewBottom(inset: inset, duration: duration)
            case let .handlePanGestureRecognizer(gestureRecognizer: gestureRecognizer):
                self.handlePanGestureRecognizer(gestureRecognizer)
            case .textViewHeightChange:
                self.handleTextViewHeightChange()
            case .resignInputFirstResponder:
                self.mainPanelView.resignInputFirstResponder()
                self.dismissOverlapPromptView()
            case .hideAllSubPromptView:
                self.dissmissPromptPanel()
            case .clearTextView:
                self.handelClearTextView()
            case let .show(model):
                self.updateUI(with: model)
            case let .lockScreen(lock):
                self.lockScreen = lock
            case let .updateImageCheckbox(models):
                self.mainPanelView.updateImageCheckbox(models: models)
            case let .insertPickerItems(items, range):
                self.insertPickerItems(items: items, range: range)
            case let .presentVC(vc):
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true)
            case .statusChangeToLoading:
                LarkInlineAILogger.info("setPanelToDefaultHeight true --statusChangeToLoading")
                self.setPanelToDefaultHeight = true
                self.mainPanelView.enableContentAutolayout()
            case let .showErrorMsg(msg):
                UDToast.showFailure(with: msg, on: self.view.window ?? self.view)
            case let .showSuccessMsg(msg):
                UDToast.showSuccess(with: msg, on: self.view.window ?? self.view)
            case .dismissPanel:
                self.dismiss(animated: true)
            case .showAlert:
                self.showAlertDialog()
            case let .showFeedbackAlert(config):
                self.showFeedback(config: config) // 点踩弹框
            case let .showPromptPanel(model, dragBar):
                self.showPromptPanel(model, dragBar: dragBar)
            case .contentRenderEnd:
                self.handelContentRenderEnd()
            case let .debugInfo(task):
                self.viewModel.getDebugInfo(aiTask: task)
            case let .updateSubPromptPanel(prompts, dragBar):
                if topPromptPanel() != nil {
                    showPromptPanel(prompts, dragBar: dragBar, update: true)
                }
            case let .localResourceMapLoaded(map):
                mainPanelView.setFileNamePathsDict(map)
            default:
                break
            }
            
        }).disposed(by: disposeBag)
    }
    
    private func updateUI(with model: InlineAIModelWrapper) {
        let timing: InlineAIAnimationControl.Timing = viewModel.modelDescription.imagesChange ? .delay(.now() + 0.2) : .now
        animationControl.perform(with: timing) { [weak self] in
            guard let self = self else { return }
            self.mainPanelView.updateShowModel(model, description: self.viewModel.modelDescription)
            self.showOverlapPromptViewIfNeed(prompt: model.panelModel.prompts)
            self.updateHeightIfNeed()
            self.updateBgMask(maskType: model.panelModel.maskTypeEnum ?? .fullScreen)
        }
    }
    
    func maxPanelHeightWhenKeyboardShow(with inset: CGFloat) -> CGFloat {
        if needFixPanelHeight { // 如果有结果页
            let tempHeight = max(mainPanelView.getCurrentShowPanelHeight(), self.view.frame.size.height * 0.3 - panelBottomOffset)
            let navibarHeight: CGFloat = 44
            let topInset = max(self.view.safeAreaInsets.top, 20)
            let maxHeight = self.view.frame.size.height - inset - keyboardMargin - topInset - navibarHeight
            return min(maxHeight, tempHeight)

        } else {
            // 如果没有展示结果页，键盘+panel为80%
            return min(self.mainPanelView.frame.size.height, (self.view.frame.size.height - self.view.safeAreaInsets.top ) * 0.8 - inset - keyboardMargin)
        }
    }
    
    private func updatePanelViewBottom(inset: CGFloat, duration: Double) {
        guard self.vcWillDismiss == false else { return }
        self.keyboardInset = inset
        var newHeight = 0.0
        // 有键盘
        if inset > 0 {
            // 如果有结果页
            newHeight = maxPanelHeightWhenKeyboardShow(with: inset)
            LarkInlineAILogger.info("updatePanelViewBottom keyboard show inset:\(inset) newHeight:\(newHeight)")
            updateOverlapPromptConstraint(maxHeight: newHeight)
        } else {
            // 无键盘
            let panelheight = self.view.frame.size.height * 0.6 - panelBottomOffset
            updateOverlapPromptConstraint(maxHeight: panelheight)
            if needFixPanelHeight {
                let contentRenderHeight = self.contentRenderHeight
                if !setPanelToDefaultHeight,
                   lastPanelHeight > 0,
                   lastPanelHeight < contentRenderHeight {
                    newHeight = lastPanelHeight
                } else {
                    newHeight = contentRenderHeight
                }
            } else {
                newHeight = defaultHeight
            }
            LarkInlineAILogger.info("updatePanelViewBottom no keyboard inset:\(inset) newHeight:\(newHeight)")
        }
        LarkInlineAILogger.info("updatePanelViewBottom height: \(newHeight) keyboardShow")
        UIView.animate(withDuration: duration) {
            self.mainPanelView.snp.updateConstraints({ make in
                make.height.equalTo(newHeight).priority(999)
                if inset > 0 {
                    make.bottom.equalToSuperview().inset(inset + self.keyboardMargin)
                } else {
                    make.bottom.equalToSuperview().inset(self.panelBottomOffset)
                }
            })
            self.view.layoutIfNeeded()
        }
    }
    
    private func getPromptViewHeight() -> CGFloat {
        return mainPanelView.getPromptViewHeight()
    }
    
    private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        gestureUtils.handlePanGestureRecognizer(gestureRecognizer)
    }
    
    private func handleTextViewHeightChange() {
        var newHeight: CGFloat
        // 有键盘
        if keyboardInset > 0 {
            newHeight = maxPanelHeightWhenKeyboardShow(with: keyboardInset)
            self.mainPanelView.updateSubViewLayout()
            self.updateOverlapPromptConstraint(maxHeight: newHeight)
            LarkInlineAILogger.info("[text] handleTextViewHeightChange keyboard show inset:\(keyboardInset) newHeight:\(newHeight)")
        } else {
            // 无键盘
            newHeight = defaultHeight
            self.mainPanelView.updateSubViewLayout()
            LarkInlineAILogger.info("[text] handleTextViewHeightChange no keyboard inset:\(keyboardInset) newHeight:\(newHeight)")
        }
        LarkInlineAILogger.info("[text] update mainPanel newHeight: \(newHeight) text change")
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut) {
            self.mainPanelView.snp.updateConstraints { make in
                make.height.equalTo(newHeight).priority(999)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    private func handelClearTextView() {
        mainPanelView.clearTextView()
    }
    
    func showAlertDialog() {
        let dialog = UDDialog()
        let provideDialogConfig = config.quitConfirmDialogConfigProvider?.provideDialogConfig()
        let title = provideDialogConfig?.title ?? BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Quit_Title
        dialog.setTitle(text: title)
        
        let content = provideDialogConfig?.content ?? BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Custom_QuitNotSaved_Text(viewModel.nickName)
        dialog.setContent(text: content)

        let confirmText = provideDialogConfig?.confirmButton ?? BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Quit_Button
        dialog.addSecondaryButton(text: confirmText, dismissCompletion:  { [weak self] in
            guard let self = self else { return }
            self.viewModel.eventRelay.accept(.alertCancel)
        })
        
        let cancelText = provideDialogConfig?.cancelButton ?? BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Cancel_Button
        dialog.addPrimaryButton(text: cancelText, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.viewModel.eventRelay.accept(.alertContinue)
        })
        self.present(dialog, animated: true, completion: nil)
    }
}


// MARK: - SubPromptPanel

extension InlineAIPanelViewController {
    
    func createSubPromptPanel() -> InlineAISubPromptPanelView {
        let promptPanel = InlineAISubPromptPanelView(frame: .zero)
        if !mainPanelView.isPromptPanGestureEnable {
            promptPanel.disableListContentPanGesture()
        }
        promptPanel.delegate = self
        // 确保只绑定一次
        promptPanel.eventRelay.bind(to: viewModel.subPromptEventRelay).disposed(by: disposeBag)
        return promptPanel
    }
    
    func showPromptPanel(_ model: InlineAIPanelModel.Prompts, dragBar: InlineAIPanelModel.DragBar, update: Bool = false) {
        if model.show == false || model.data.isEmpty {
            LarkInlineAILogger.info("dissmissTopPromptPanel")
            dissmissTopPromptPanel()
            return
        } else if update, let panel = topPromptPanel() {
            LarkInlineAILogger.info("update subPanel count:\(model.data.count)")
            panel.update(groups: model, dragBar: dragBar, maskType: maskType, animate: false)
            return
        }

        LarkInlineAILogger.info("showPromptPanel")
        mainPanelView.resignInputFirstResponder()
        let promptPanel = createSubPromptPanel()
        promptPanel.show = true
        promptPanel.frame = self.view.bounds
        if promptPanel.superview == nil {
            basicContainerView.addSubview(promptPanel)
            promptPanel.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        promptPanel.update(groups: model, dragBar: dragBar, maskType: maskType)
    }

    func dissmissPromptPanel() {
        for child in self.basicContainerView.subviews where child is InlineAISubPromptPanelView {
            (child as? InlineAISubPromptPanelView)?.dissmiss()
        }
    }
    
    // 只dismiss顶层
    func dissmissTopPromptPanel() {
        let panel = topPromptPanel()
        panel?.dissmiss()
    }
    
    func topPromptPanel() -> InlineAISubPromptPanelView? {
        let view = self.basicContainerView.subviews.reversed().first { $0 is InlineAISubPromptPanelView }
        return view as? InlineAISubPromptPanelView
    }
}

// MARK: - Feedback

extension InlineAIPanelViewController {
    
    private func showFeedback(config: LarkInlineAIFeedbackConfig) {
        let body = MyAIAnswerFeedbackBody(aiMessageId: config.aiMessageId,
                                          scenario: config.scenario,
                                          mode: .inlineMode(queryMessageRawdata: config.queryRawdata,
                                                            ansMessageRawdata: config.answerRawdata))
        let response = self.config.userResolver.navigator.response(for: body)
        guard let feedBackVC = response.resource as? UIViewController else {
            LarkInlineAILogger.info("cannot get route for ai-feedback controller")
            return
        }
        if let presentedVC = self.presentedViewController, presentedVC.isKind(of: feedBackVC.classForCoder) {
            presentedVC.dismiss(animated: false) // 避免多次弹出
        }
        self.config.userResolver.navigator.present(
            feedBackVC,
            wrap: LkNavigationController.self,
            from: ControllerWrapper(self),
            prepare: {
                $0.transitioningDelegate = feedBackVC as? UIViewControllerTransitioningDelegate
                $0.modalPresentationStyle = .custom
            },
            animated: true
        )
    }
}

private class ControllerWrapper: NavigatorFrom {
    
    var fromViewController: UIViewController?
    
    var canBeStrongReferences: Bool { false }
    
    init(_ fromViewController: UIViewController) {
        self.fromViewController = fromViewController
    }
}

// MARK: - InputHandlers
extension InlineAIPanelViewController {
    
    private func configureInput() {
        self.mainPanelView.textInputView.supportAt = !viewModel.config.mentionTypes.isEmpty
        self.mainPanelView.textInputView.urlPreviewAPI = viewModel.urlPreviewAPI
        self.mainPanelView.textInputView.configureInputHandler()
    }
    
    private func insertPickerItems(items: [PickerItem]?, range: NSRange) {
        self.mainPanelView.textInputView.insertPickerItems(items: items, with: range)
    }
    
    private func handleClickMentionedUser(_ userID: String) {
        if let service = try? config.userResolver.resolve(assert: InlineAIMentionUserService.self) {
            service.onClickUser(chatterId: userID, fromVC: self)
        }
    }
}

extension InlineAIPanelViewController: LarkInlineGestureUtilsDelegate {
    var isDragBarShow: Bool {
        return mainPanelView.dragBar.show
    }
    
    var dragPanelNeedConfirm: Bool {
        return mainPanelView.dragPanelNeedConfirm()
    }
    
    var isKeyboardShow: Bool {
        return viewModel.isKeyboardShow
    }
    
    func getCurrentShowPanelHeight() -> CGFloat {
        return mainPanelView.getCurrentShowPanelHeight()
    }
    
    func disableContentAutolayout() {
        mainPanelView.disableContentAutolayout()
    }
    
    var isGenerating: Bool { viewModel.isGenerating }
}

// MARK: - 自适应
extension InlineAIPanelViewController {
    
    private func handelContentRenderEnd() {
        guard !panGestureIsWorking,
              !viewModel.isKeyboardShow else {
            LarkInlineAILogger.info("update render height fail, panIsWorking:\(panGestureIsWorking) isKeyboardShow:\(viewModel.isKeyboardShow) canSetDefaultHeight: \(setPanelToDefaultHeight)")
            return
        }
        
        if setPanelToDefaultHeight {
            LarkInlineAILogger.debug("contentRenderHeight")
            setupLayout(contentRenderHeight)
        } else {
            if contentRenderHeight >= lastPanelHeight {
                setupLayout(lastPanelHeight)
            } else {
                setupLayout(contentRenderHeight)
            }
        }
    }
    
}
