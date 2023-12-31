//
//  InlineAIMainPanelView.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/4/25.
//

import Foundation
import UniverseDesignColor
import RxSwift
import RxRelay

class InlineAIMainPanelView: UIView {
    
    struct PanelLayout {
        static let marginBorder: CGFloat = 8
        static let contentMinHeight: CGFloat = 110
        static let dragBarHeight: CGFloat = 12
        static let gestureHeight: CGFloat = 20
        static let historyViewHeight: CGFloat = 38
        static let textInputViewHeight: CGFloat = 56
        static let prompViewBorder: CGFloat = 8
        static let sheetOperateViewHeight: CGFloat = 36 // 标签高度 24 + 12
        static let horizontalMargin: CGFloat = 10
        static let webviewPadding: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) = (0,18,0,18)
    }

    var eventRelay = PublishRelay<InlineAIEvent>()
    let disposeBag = DisposeBag()
    var customHitTest: ((_ point: CGPoint, _ event: UIEvent?) -> UIView?)?
    var layoutSubviewCallback: (() -> Void)?
    private var settings: InlineAISettings?

    weak var gestureDelegate: InlineAIViewPanGestureDelegate? {
        didSet {
            self.contentView.gestureDelegate = self.gestureDelegate
            self.promptView.gestureDelegate = self.gestureDelegate
        }
    }

    // 顶部拖拽bar
    lazy var dragBar: InlineAIDragBar = {
        let bar = InlineAIDragBar(frame: .zero)
        return bar
    }()
    
    // 顶部拖拽bar的手势
    private lazy var gestureView: UIView = {
        let gview = UIView(frame: .zero)
        gview.backgroundColor = .clear
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        gview.addGestureRecognizer(panGestureRecognizer)
        return gview
    }()
    
    // 历史记录
    private lazy var historyView: InlineAIHistoryItemView = {
        let historyView = InlineAIHistoryItemView(frame: .zero)
        return historyView
    }()
    
    // 提示信息，喜欢/不喜欢反馈
    private lazy var tipView: InlineAITipView = {
        let tipView = InlineAITipView(frame: .zero)
        tipView.leftRightInset = PanelLayout.horizontalMargin
        return tipView
    }()

    // 内容展示，临时展位
    lazy var contentView: InlineAIContentView = {
        let showView = InlineAIContentView(customContentView: self.contentCustomView, settings: self.settings)
        showView.gestureDelegate = self.gestureDelegate
        return showView
    }()
    
    lazy var overlapMaskView: UIView = {
        let overlapView = UIView(frame: .zero)
        overlapView.alpha = 0
        overlapView.backgroundColor = UDColor.bgMask
        overlapView.isUserInteractionEnabled = false
        return overlapView
    }()
    
    private lazy var operationView = InlineAIIOperationView()
    
    private lazy var sheetOperationView = InlineAISheetOperationView()
    
    private lazy var promptView: InlineAIItemPromptView = {
        let view = InlineAIItemPromptView(frame: .zero)
        view.gestureDelegate = self.gestureDelegate
        return view
    }()
    
    lazy var textInputView: InlineAIItemInputView = {
        let inputView = InlineAIItemInputView()
        inputView.parseEnable = settings?.xmlParseEnable ?? false
        return inputView
    }()
    
    private var contentCustomView: UIView?
    
    private lazy var borderView: FlowAnimationBorderView = {
        let borderWidth = FlowAnimationBorderView.defaultBorderWidth
        let flowView = FlowAnimationBorderView(borderWidth: borderWidth, backgroundColor: UDColor.bgFloat, cornerRadius: 6)
        return flowView
    }()

    var panelWidth: CGFloat?
    
    convenience init(contentCustomView: UIView?,
                     panelWidth: CGFloat?,
                     settings: InlineAISettings) {
        self.init(frame: .zero)
        self.settings = settings
        self.contentCustomView = contentCustomView
        self.panelWidth = panelWidth
        setupSubItemViews()
        gatherUIEvent()
        LarkInlineAILogger.info("InlineAIMainPanelView init")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
       
    }
    
    deinit {
        LarkInlineAILogger.info("InlineAIMainPanelView deinit")
    }
       
    
    func gatherUIEvent() {
        for view in subviews {
            guard let baseView = view as? InlineAIItemBaseView else { continue }
            baseView.eventRelay.bind(to: eventRelay).disposed(by: disposeBag)
            baseView.aiPanelView = self
            baseView.panelWidth = self.panelWidth
        }
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    @objc
    private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        dragBar.eventRelay.accept(.panGestureRecognizerChange(gestureRecognizer: gestureRecognizer))
    }

    private func setupBaseViewBottomRoundedCorner(baseView: InlineAIItemBaseView?, showCorner: Bool) {
        if baseView != dragBar {
            baseView?.setupBottomRoundedCorner(showCorner: showCorner)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let superHitTestView = super.hitTest(point, with: event)
        if let customHitTest = self.customHitTest,
           superHitTestView == nil,
           let view = customHitTest(point, event) {
            return view
        } else {
            return superHitTestView
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSubviewCallback?()
    }
    
    func disableListContentPanGesture() {
        contentView.disableListContentPanGesture()
        promptView.disableListContentPanGesture()
    }
    
    var isPromptPanGestureEnable: Bool {
        promptView.isPromptPanGestureEnable
    }
}

// MARK: - update

extension InlineAIMainPanelView {

    public func updateShowModel(_ modelWrapper: InlineAIModelWrapper, description: ModelDescription) {
        let model = modelWrapper.panelModel
        LarkInlineAILogger.info("update main UI")
        // 顶部bar是否展示
        if let dragBarModel = model.dragBar, dragBarModel.show {
            dragBar.show = true
            gestureView.isHidden = false
            dragBar.doubleConfirm = dragBarModel.doubleConfirm
        } else {
            dragBar.show = false
            gestureView.isHidden = true
        }

        if let content = model.content, content.isEmpty == false {
            contentView.show = true
            let isFinish = model.input?.status == 0
            contentView.updateContent(content,
                                      extra: model.extraParams,
                                      theme: model.theme ?? "",
                                      conversationId: model.conversationId,
                                      taskId: model.taskId,
                                      isFinish: isFinish)
        } else if !modelWrapper.imageModels.isEmpty {
            contentView.show = true
            contentView.updateImage(imageModels: modelWrapper.imageModels)
        } else {
            contentView.show = false
        }
        
        // 操作
        if let operates = model.operates, operates.show, !operates.data.isEmpty {
            operationView.show = true
            operationView.update(operates: model.operates)
        } else {
            operationView.show = false
        }
        
        // 指令
        if let prompts = model.prompts,
           prompts.show,
           !prompts.data.isEmpty,
           !prompts.overlap {
            promptView.show = true
        } else {
            promptView.show = false
        }
        promptView.update(groups: model.prompts)
        // 输入
        if let input = model.input, input.show {
            textInputView.show = true
            textInputView.update(model: input, fullRoundedcorners: !promptView.show)
        } else {
            textInputView.show = false
        }
        
        //sheet数据范围操作
        if let range = model.range, range.show, !range.text.isEmpty {
            sheetOperationView.show = true
            sheetOperationView.update(operate: model.range)
        } else {
            sheetOperationView.show = false
        }
        
        // 提示
        if model.tips?.show == true || model.feedback?.show == true {
            tipView.show = true
            var showThumbs = false
            if model.history == nil || model.history?.show == false ,
               model.feedback?.show == true {
                showThumbs = true
            }
            tipView.show = (showThumbs || model.tips?.show == true)
            tipView.updateTipContent(showTip: model.tips?.show == true , text: model.tips?.text ?? "", showThumbs: showThumbs, thumbsUp: model.feedback?.like ?? false , thumbsDown: model.feedback?.unlike ?? false)
        } else {
            tipView.show = false
        }

        // 历史记录
        if let history = model.history, history.show {
            historyView.show = true

            var like = false
            var unlike = false
            if let feedback = model.feedback, feedback.show {
                like = feedback.like
                unlike = feedback.unlike
            }
            let text = "\(String(model.history?.curNum ?? 0)) / \(String(model.history?.total ?? 0))"
            historyView.updateHistory(text: text, leftEnable: history.leftArrowEnabled, rightEnable: history.rightArrowEnabled, hideHistory: false, showThumbsBtn: true, like: like, unlike: unlike)
        } else {
            historyView.show = false
        }
        
        updateSubViewLayout()
        let needAnimation = model.input?.status == 1
        if needAnimation {
            self.borderView.startAuroraAnimate()
        } else {
            self.borderView.stopAnimate()
        }
    }
    
    func updateImageCheckbox(models: [InlineAICheckableModel]) {
        contentView.updateImageCheckbox(imageModels: models)
    }
    
    func setFileNamePathsDict(_ dict: [String: String]) {
        contentView.setFileNamePathsDict(dict)
    }
}

// MARK: - UI Layout
extension InlineAIMainPanelView {
    
    func getCurrentShowPanelHeight() -> CGFloat {
        var totalheight = PanelLayout.marginBorder
        var contentHeighRecord = "displayHeight >"
        if dragBar.show {
            totalheight += PanelLayout.dragBarHeight
            contentHeighRecord += "bar: \(PanelLayout.dragBarHeight)|"
        }
        if historyView.show {
            totalheight += PanelLayout.historyViewHeight
            contentHeighRecord += "history: \(PanelLayout.historyViewHeight)|"
        }
        if contentView.show {
            let displayHeight = contentView.getDisplayHeight()
            totalheight += displayHeight
            contentHeighRecord += "content: \(displayHeight)|"
        }
        if tipView.show {
            let displayHeight = tipView.getDisplayHeight()
            totalheight += displayHeight
            contentHeighRecord += "tip: \(displayHeight)｜"
        }

        if operationView.show {
            let displayHeight = operationView.getOperationViewHieght()
            totalheight += displayHeight
            contentHeighRecord += "operation: \(displayHeight)｜"
        }
        if promptView.show {
            let displayHeight = promptView.getPromptRealHeight()
            totalheight += displayHeight
            contentHeighRecord += "prompt: \(displayHeight)｜"
        }
        if sheetOperationView.show {
            let displayHeight = PanelLayout.sheetOperateViewHeight
            totalheight += displayHeight
            contentHeighRecord += "sheet: \(displayHeight)｜"
        }
        if textInputView.show {
            let displayHeight = (textInputView.getDisplayHeight() + PanelLayout.horizontalMargin)
            totalheight += displayHeight
            contentHeighRecord += "textInput: \(displayHeight)"
        }
        var onlyTextView = true
        for view in subviews {
            guard let baseView = view as? InlineAIItemBaseView else { continue }
            if let _ = baseView as? InlineAIItemInputView {
                //
            } else {
                onlyTextView = false
            }
        }
        if !onlyTextView {
            totalheight += (PanelLayout.horizontalMargin - PanelLayout.marginBorder)
        }
        LarkInlineAILogger.info(contentHeighRecord)
        return totalheight
    }
    
    func setupSubItemViews() {
        addSubview(borderView)
        addSubview(dragBar)
        addSubview(operationView)
        addSubview(promptView)
        addSubview(contentView)
        addSubview(tipView)
        addSubview(historyView)
        addSubview(sheetOperationView)
        addSubview(textInputView)
        addSubview(gestureView)
        setupStaticView() // 背景布局固定的，单独设置
    }
    
    func setupStaticView() {
        insertSubview(overlapMaskView, belowSubview: textInputView)
        overlapMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        borderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // nolint: long_function
    func updateSubViewLayout() {
        var lastDisplayView: InlineAIItemBaseView? = nil
        // 拖拽bar
        if dragBar.show {
            dragBar.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(PanelLayout.marginBorder)
                make.top.equalToSuperview().offset(PanelLayout.marginBorder)
                make.height.equalTo(PanelLayout.dragBarHeight)
            }
            lastDisplayView = dragBar
            gestureView.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.top.equalToSuperview().offset(0)
                make.centerX.equalToSuperview()
                make.height.equalTo(PanelLayout.gestureHeight + PanelLayout.marginBorder)
            }
        } else {
            dragBar.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }

        // 内容
        if contentView.show {
            contentView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(FlowAnimationBorderView.defaultBorderWidth)
                if let lastview =  lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom).offset(0)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.marginBorder)
                }
                make.height.greaterThanOrEqualTo(PanelLayout.contentMinHeight).priority(999)
            }
            lastDisplayView = contentView
        } else {
            contentView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(FlowAnimationBorderView.defaultBorderWidth)
                if let lastview =  lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom).offset(0)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.marginBorder)
                }
                make.height.equalTo(0.1) // 保证初始webView高度不为0，防止首次刷新不生效
            }
        }
        setupBaseViewBottomRoundedCorner(baseView: lastDisplayView, showCorner: false)
        
       // 提示
       if tipView.show {
           tipView.setContentHuggingPriority(.required, for: .vertical)
           let displayHeight = tipView.getDisplayHeight()
           tipView.snp.remakeConstraints { make in
               make.left.right.equalToSuperview().inset(PanelLayout.horizontalMargin)
               if let lastview =  lastDisplayView {
                   make.top.equalTo(lastview.snp.bottom).offset(0)
               } else {
                   make.top.equalToSuperview().offset(PanelLayout.marginBorder)
               }
               make.height.equalTo(displayHeight).priority(.required)
           }
           lastDisplayView = tipView
       } else {
           tipView.snp.remakeConstraints { make in
               make.left.right.equalToSuperview().inset(PanelLayout.horizontalMargin)
               if let lastview =  lastDisplayView {
                   make.top.equalTo(lastview.snp.bottom).offset(0)
               } else {
                   make.top.equalToSuperview().offset(PanelLayout.marginBorder)
               }
               make.height.equalTo(0)
           }
       }


        // 历史记录
        if historyView.show {
            historyView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(PanelLayout.marginBorder)
                if let lastview =  lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom).offset(0)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.marginBorder)
                }
                make.height.equalTo(PanelLayout.historyViewHeight)
            }
            lastDisplayView = historyView

        } else {
            historyView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }
        setupBaseViewBottomRoundedCorner(baseView: lastDisplayView, showCorner: false)
        
        // 操作
        if operationView.show {
            let oprateViewHeight = operationView.getOperationViewHieght()
            operationView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                if let lastview = lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom).offset(0)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.horizontalMargin)
                }
                make.height.equalTo(oprateViewHeight)
            }
            lastDisplayView = operationView
        } else {
            operationView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }

        // 指令上面只可能是bar或者conentView
        if promptView.show {
            let height = promptView.getPromptRealHeight()
            promptView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(PanelLayout.horizontalMargin)
                make.height.equalTo(height).priority(.medium)
                if let lastview =  lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom).offset(0)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.marginBorder)
                }
            }
            lastDisplayView = promptView
        } else {
            promptView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
            setupBaseViewBottomRoundedCorner(baseView: lastDisplayView, showCorner: true)
        }
        
        if sheetOperationView.show {
            sheetOperationView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview().inset(PanelLayout.horizontalMargin)
                if let lastview =  lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom).offset(0)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.marginBorder)
                }
                make.height.equalTo(PanelLayout.sheetOperateViewHeight)
            }
            lastDisplayView = sheetOperationView
        } else {
            sheetOperationView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }

        // 输入框
        if textInputView.show {
            let height = textInputView.getDisplayHeight()
            textInputView.snp.remakeConstraints { make in
                make.height.equalTo(height).priority(.required)
                make.left.right.equalToSuperview().inset(PanelLayout.horizontalMargin)
                make.bottom.equalToSuperview().inset(PanelLayout.horizontalMargin)
                if let lastview = lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.horizontalMargin)
                }
            }
            textInputView.setContentHuggingPriority(.required + 1, for: .vertical)
            textInputView.setContentCompressionResistancePriority(.required + 1, for: .vertical)
        } else {
            textInputView.snp.remakeConstraints { make in
                make.height.equalTo(0)
                if let lastview = lastDisplayView {
                    make.top.equalTo(lastview.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(PanelLayout.horizontalMargin)
                }
                make.bottom.equalToSuperview()//.inset(PanelLayout.horizontalMargin)
            }
        }
    }
    
    func layoutFirstViewIfNeed() {
        if self.promptView.show {
            self.promptView.layoutIfNeeded()
        }
        if self.textInputView.show {
            self.textInputView.layoutIfNeeded()
        }
    }
    
    
    func enableContentAutolayout() {
        contentView.enableAutolayout()
    }

    func disableContentAutolayout() {
        contentView.disableAutolayout()
    }
}

extension InlineAIMainPanelView {
    
    func getPromptViewHeight() -> CGFloat {
        return promptView.frame.size.height
    }
    
    func getTextViewHeight() -> CGFloat {
        return textInputView.getDisplayHeight()
    }
    
    func isContentViewShow() -> Bool {
        return contentView.show
    }

    var isContentSupportSelfAdaption: Bool {
        return contentView.supportSelfAdaption
    }

    func didDismissCompletion() {
        for view in subviews {
            guard let baseView = view as? InlineAIItemBaseView else { continue }
            baseView.didDismissCompletion()
        }
    }
    
    func didPresentCompletion() {
        for view in subviews {
            guard let baseView = view as? InlineAIItemBaseView else { continue }
            baseView.didPresentCompletion()
        }
    }
    
    func getCurrentInputText() -> String? {
        return textInputView.getText()
    }
    
    func dragPanelNeedConfirm() -> Bool {
        return dragBar.doubleConfirm
    }

    func resignInputFirstResponder() {
        textInputView.resignInputFirstResponder()
    }
    
    func clearTextView() {
        textInputView.clearTextView()
    }
}
