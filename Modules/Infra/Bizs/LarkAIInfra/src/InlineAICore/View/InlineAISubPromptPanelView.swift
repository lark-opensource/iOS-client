//
//  InlineAISubpromptViewView.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/4/28.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxRelay

protocol SubPromptPanelViewDelegate: AnyObject {
    var leftRightPanelInset: CGFloat { get }
    var panelBottomOffset: CGFloat { get }
    var keyBoardHeight: CGFloat { get }
}

class InlineAISubPromptPanelView: UIView {
    
    weak var delegate: SubPromptPanelViewDelegate?

    let animationDuration: TimeInterval = 0.2

    var panGestureIsWorking: Bool = false

    var setPanelToDefaultHeight = false

    var leftRightPanelInset: CGFloat {
        self.delegate?.leftRightPanelInset ?? 6
    }

    var panelBottomOffset: CGFloat {
        self.delegate?.panelBottomOffset ?? 32
    }
    
    var totalMaxHeight: CGFloat {
        min(self.frame.size.height * 0.8 - panelBottomOffset, getCurrentShowPanelHeight())
        
    }
    
    var defaultMinHeight: CGFloat {
        min(self.frame.size.height * 0.6 - panelBottomOffset, getCurrentShowPanelHeight())
    }

    var totalMinHeight: CGFloat {
        min(self.frame.size.height * 0.3 - panelBottomOffset, getCurrentShowPanelHeight())
    }

    struct PanelLayout {
        static let dragBarHeight: CGFloat = 12
        static let dragBarMargin: CGFloat = 8
    }
    
    var eventRelay = PublishRelay<InlineAIEvent>()
    let disposeBag = DisposeBag()
    var lastPanelHeight: CGFloat = 0 {
        didSet {
            LarkInlineAILogger.debug("[subPanel] didSet lastpromptViewHeight: \(lastPanelHeight)")
        }
    }
    var subViewPanBeginOffset: CGFloat?
    
    var gestureBeginHeight: CGFloat = 0

    var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = UDColor.bgFloat
        return view
    }()

    // 顶部拖拽bar
    lazy var dragBar: InlineAIDragBar = {
        let bar = InlineAIDragBar(frame: .zero)
        return bar
    }()
    
    // 手势
    lazy var gestureView: UIView = {
        let gview = UIView(frame: .zero)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        gview.addGestureRecognizer(panGestureRecognizer)
        return gview
    }()
    
    lazy var promptView: InlineAIItemPromptView = {
        let view = InlineAIItemPromptView()
        view.promptTextColor = UDColor.textTitle
        view.gestureDelegate = self.gestureUtils
        return view
    }()
    
    lazy var backgroudView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = UDColor.bgMask
        bgView.alpha = 0
        return bgView
    }()
    
    lazy var clickAreaView: UIControl = {
        let areaView = UIControl(frame: .zero)
        areaView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickMaskView)))
        return areaView
    }()
    
    lazy var aroundPanelMaskView: InlineAIGradientView = {
       let maskView = InlineAIGradientView(direction: .vertical, colors: [UDColor.bgMask.withAlphaComponent(0.00), UDColor.bgMask.withAlphaComponent(0.2)])
        maskView.alpha = 0
        return maskView
    }()

    var maskType: InlineAIPanelModel.MaskType = .fullScreen
    
    var show: Bool = false {
        didSet {
            promptView.show = self.show
        }
    }

    lazy var gestureUtils: LarkInlineGestureUtils = {
        let utils = LarkInlineGestureUtils(containerView: self, panelView: self.containerView) { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .dragPanelConfirm:
                break
            case .closePanel:
                //通知前端下掉面板
                self.dissmiss()
            }
        }
        utils.delegate = self
        return utils
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        backgroundColor = .clear
    
        addSubview(backgroudView)
        addSubview(aroundPanelMaskView)
        addSubview(clickAreaView)
        addSubview(containerView)
        containerView.addSubview(dragBar)
        containerView.addSubview(gestureView)
        containerView.addSubview(promptView)

        setupLayout()
        gatherUIEvent()
    }
    
    func setupLayout() {
        backgroudView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(self.leftRightPanelInset)
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
        aroundPanelMaskView.snp.remakeConstraints { make in
           make.left.right.equalToSuperview()
           make.top.equalTo(self.containerView.snp.top).offset(-64)
           make.bottom.equalTo(self.snp.bottom)
        }
        dragBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(PanelLayout.dragBarMargin)
            make.height.equalTo(PanelLayout.dragBarHeight)
        }
        gestureView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalToSuperview().offset(0)
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
        }
        promptView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(dragBar.snp.bottom)
            make.bottom.equalToSuperview().offset(0)
        }
        
        clickAreaView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(containerView.snp.top)
        }
    }
    
    @objc
    func statusBarOrientationChange() {
        containerView.snp.updateConstraints({ make in
            make.left.right.equalToSuperview().inset(self.leftRightPanelInset)
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func gatherUIEvent() {
        for view in containerView.subviews {
            guard let baseView = view as? InlineAIItemBaseView else { continue }
            baseView.eventRelay.bind(to: eventRelay).disposed(by: disposeBag)
        }
    }
    
    func getCurrentShowPanelHeight() -> CGFloat {
        return promptView.getPromptRealHeight() + PanelLayout.dragBarHeight + PanelLayout.dragBarMargin
    }
    
    func update(groups: InlineAIPanelModel.Prompts?, dragBar: InlineAIPanelModel.DragBar?, maskType: InlineAIPanelModel.MaskType, animate: Bool = true) {
        promptView.update(groups: groups, withoutAnimation: false)
        self.dragBar.show = dragBar?.show ?? false
        self.dragBar.doubleConfirm = false
        if animate {
            animateShowPanel()
        } else {
            let height = self.defaultMinHeight
            containerView.snp.updateConstraints({ make in
                make.height.equalTo(height).priority(.required)
            })
        }
        if maskType == .fullScreen {
            backgroudView.alpha = 1
            aroundPanelMaskView.alpha = 0
        } else {
            backgroudView.alpha = 0
            aroundPanelMaskView.alpha = 1
        }
        self.maskType = maskType
    }
    
    private func animateShowPanel() {
        let height = self.defaultMinHeight

        containerView.snp.updateConstraints({ make in
            make.left.right.equalToSuperview().inset(self.leftRightPanelInset)
            make.height.equalTo(height).priority(.required)
            make.bottom.equalToSuperview().inset(-height - self.panelBottomOffset)
        })
        self.layoutIfNeeded()
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
            self.backgroudView.alpha = 1
            self.setupLayout(height)
            self.layoutIfNeeded()
        }, completion: { _ in
            self.lastPanelHeight = height
        })
    }
    
    var willDismiss = false

    func dissmiss() {
        self.willDismiss = true
        LarkInlineAILogger.info("dissmisspromptView")
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
            self.backgroudView.alpha = 0
            self.aroundPanelMaskView.alpha = 0
            let height = self.containerView.frame.height
            self.containerView.snp.updateConstraints({ make in
                make.bottom.equalToSuperview().inset(-height - self.panelBottomOffset)
            })
            self.layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.willDismiss = false
            self?.promptView.show = false
            self?.removeFromSuperview()
        })
    }
    
    @objc
    private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        gestureUtils.handlePanGestureRecognizer(gestureRecognizer)
    }
    
    func setupLayout(_ height: CGFloat, topOffSet: CGFloat = 0, animation: Bool = false) {
        guard willDismiss == false else { return }
        LarkInlineAILogger.info("[subPanel] update height: \(height) topOffSet: \(topOffSet)")
        let layoutContainerView = { [weak self] in
            guard let self = self else { return }
            self.containerView.snp.updateConstraints( { make in
                make.height.equalTo(height).priority(.required)
                var inset = self.panelBottomOffset
                if topOffSet > 0 {
                    inset = self.bounds.size.height - topOffSet - height
                }
                make.bottom.equalToSuperview().inset(inset)
            })
        }
        if animation {
            UIView.animate(withDuration: animationDuration) {
                layoutContainerView()
                self.layoutIfNeeded()
            }
        } else {
            layoutContainerView()
        }
    }
    
    @objc
    func didClickMaskView() {
        dissmiss()
    }
    
    func disableListContentPanGesture() {
        promptView.disableListContentPanGesture()
    }
}

extension InlineAISubPromptPanelView: LarkInlineGestureUtilsDelegate {
    var dragPanelNeedConfirm: Bool {
        return false
    }
    
    var isDragBarShow: Bool {
        return true
    }

    var isKeyboardShow: Bool {
        return false
    }
    
    var keyBoardHeight: CGFloat {
        return 0
    }
    
    var keyboardMargin: CGFloat {
        return 0
    }
    
    var defaultHeight: CGFloat {
        return defaultMinHeight
    }
    
    func disableContentAutolayout() {
        
    }
    
    var isGenerating: Bool { return false }
    
    var contentRenderHeight: CGFloat {
        return getCurrentShowPanelHeight()
    }
}
