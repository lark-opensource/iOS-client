//
//  AtInputTextView.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/21.
//  
//  swiftlint:disable file_length

import Foundation
import RxSwift
import RxCocoa
import SnapKit
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignToast
import UniverseDesignColor
import Photos
import SpaceInterface
import SKCommon

enum CommentImagePickerResult {
    case pickPhoto(selectedAssets: [PHAsset], isOriginal: Bool)
    case takePhoto(UIImage)
    case cancel
}

protocol CommentTextViewTextChangeDelegate: AnyObject {
    func textViewDidChange(_ textView: UITextView)
    func imagePreviewDidChange()
    func textViewDidTriggerAtAction(_ textView: AtInputTextView, at rect: CGRect)
    // 出现@字符后需要刷新列表
    func atListViewShouldRefresh(_ keyword: String)
    func textViewDidTriggerInsertImageAction(maxCount: Int, _ callback: @escaping (CommentImagePickerResult) -> Void)
    func hideAtListView()
    func commentTextView(textView: UITextView, didMention atInfo: AtInfo)
    func keyboard(change option: Keyboard.KeyboardOptions, textView: AtInputTextView)
    func keyboard(change option: Keyboard.KeyboardOptions, textView: AtInputTextView, item: CommentItem)
    func textViewDidBeginEditing(_ textView: AtInputTextView)
    func textViewDidEndEditing(_ textView: AtInputTextView)
    func textViewShouldBeginEditing(_ textView: AtInputTextView) -> Bool
}

extension CommentTextViewTextChangeDelegate {
    func textViewDidChange(_ textView: UITextView) {}
    func imagePreviewDidChange() {}
    func textViewDidTriggerAtAction(_ textView: AtInputTextView, at rect: CGRect) {}
    func atListViewShouldRefresh(_ keyword: String) {}
    func textViewDidTriggerInsertImageAction(maxCount: Int, _ callback: @escaping (CommentImagePickerResult) -> Void) {}
    func hideAtListView() {}
    func commentTextView(textView: UITextView, didMention atInfo: AtInfo) {}
    func keyboard(change option: Keyboard.KeyboardOptions, textView: AtInputTextView) {}
    func keyboard(change option: Keyboard.KeyboardOptions, textView: AtInputTextView, item: CommentItem) {}
    func textViewDidBeginEditing(_ textView: AtInputTextView) {}
    func textViewDidEndEditing(_ textView: AtInputTextView) {}
    func textViewShouldBeginEditing(_ textView: AtInputTextView) -> Bool { return true }
}


public final class AtInputTextView: UIView {

    enum ClickSendButtonSource {
        case inputTextView
        case voiceCommentView
    }

    weak var dependency: AtInputTextViewDependency?
    weak var textChangeDelegate: CommentTextViewTextChangeDelegate?
    
    public var commentWrapper: CommentWrapper?

    public var isShowingAtListView: Observable<Bool> {
        return innerIsShowingAtListView.asObservable()
    }

    var isEditing: Observable<Bool> {
        return inputTextView?.isEditingObservable ?? .just(false)
    }

    var isNewInput: Bool = false
    var reloadingDataWhenFocus: Bool = false
    
    var atRange: NSRange?

    public var attributedText: NSAttributedString {
        return inputTextView?.textView.attributedText ?? NSAttributedString(string: "")
    }

    var inpuTextViewSnp: ConstraintViewDSL? {
        return inputTextView?.snp
    }

    var textViewInputAccessoryView: UIView? {
        return inputTextView?.textView.inputAccessoryView
    }

    public var focusType: AtInputFocusType = .new 

    var innerIsShowingAtListView: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    let disposeBag = DisposeBag()

    var keyword: BehaviorRelay<String> = BehaviorRelay(value: "")

    private(set) weak var hitTestAvoidView: UIView?

    private(set) lazy var containerView: UIView = {
        let _containerView = UIView()
        addSubview(_containerView)
        return _containerView
    }()
    
    private lazy var safeAreaButtomMask: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.isUserInteractionEnabled = false
        return view
    }()

    public private(set) var inputTextView: InputTextView?
    
    var isRecording: Bool = false

    private lazy var topLine: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        return lineView
    }()

    private lazy var blankView: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.inputTextView?.stopRecording()
            let inputViewDependency: AtInputTextViewDependency? = self.dependency
            inputViewDependency?.didTapBlankView(self)
            CommentTracker.log(.cancel_comment, atInputTextView: self)
        }).disposed(by: disposeBag)
        return button
    }()
    // @面板
    lazy var atListView: AtListView = setupAtListView()
    // 白色背景view
    public private(set) lazy var bgWhiteView: UIView = UIView()
    
    // 是TextView和Toolbar的容器，TextView和Toolbar两个控件都有可能不展示在AtInputTextView上
    private(set) lazy var toolContentView = UIView()
    
    // toolBar
    public private(set) lazy var toolBar: CommentToolBar = setupToolBarView()

    // atUser邀请view
    var inviteTipsView: AtUserInviteView?

    var lastTextViewSelectedRange: NSRange = NSRange(location: 0, length: 0)
    
    /// 是否全文评论
    public var isWhole: Bool = false

    /// 输入框字体大小
    var textFont: UIFont
    
    /// 解决iOS 16 iPad分屏模式下，外接键盘无法弹出图片选择器和语音输入的问题
    var fixPadKeyboardInputView = false {
        didSet {
            inputTextView?.fixPadKeyboardInputView = fixPadKeyboardInputView
        }
    }
    
    lazy var keyboard: Keyboard = {
        let _keyboard = Keyboard()
        _keyboard.trigger = "comment"
        return _keyboard
    }()
    
    /// 竖屏下的约束
    private var portraitScreenConstraints: [SnapKit.Constraint] = []
    
    /// 横屏下的约束
    private var landscapeScreenConstraints: [SnapKit.Constraint] = []
    
    /// 用于语音输入时将输入框撑到右边
    var strechWhenRecordConstraint: SnapKit.Constraint?
    /// 不支持横竖屏切换不要修改这个值
    var isChangeLandscape: Bool = false
    
    var showNoKeyboardView: Bool {
        return inputTextView?.showNoKeyboardView ?? false
    }
        
    private lazy var atListBlankView: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let inputViewDependency: AtInputTextViewDependency? = self.dependency
            inputViewDependency?.didTapBlankView(self)
        }).disposed(by: disposeBag)
        return button
    }()
    
    public init(dependency: AtInputTextViewDependency?, font: UIFont, ignoreRotation: Bool) {
        self.dependency = dependency
        self.textFont = font
        super.init(frame: .zero)
        let defaultTextView = InputTextView(inputTextFont: font)
        setupWithTextView(inputTextView: defaultTextView, ignoreRotation: ignoreRotation)
        monitorKeyboard()
    }

    func monitorKeyboard() {
        guard !keyboard.isListening, let textView = inputTextView?.textView else { return }
        keyboard.on(events: [.willShow, .didShow, .willHide, .didHide]) { [weak self] (options) in
            guard options.displayType != .floating else { return }
            guard let self = self,
                  let textView = self.inputTextView?.textView else {
                      return
            }
            if self.inputTextView?.isIniOS16TemporaryReloadStage == true {
                DocsLogger.info("in iOS16 temporary reloadStage: true", component: LogComponents.comment)
                return
            }
            let firstResponder = UIResponder.docsFirstResponder()
            let textChangeDelegate = self.textChangeDelegate
            // firstResponder === inputTextView 是为了兼容特殊原因导致的新建局部评论不拉起输入框的问题
            if let firstResponder = firstResponder,
               firstResponder === textView || firstResponder === self.inputTextView || firstResponder === textChangeDelegate {
                if let item = self.commentWrapper?.commentItem {
                    self.textChangeDelegate?.keyboard(change: options, textView: self, item: item)
                } else {
                    self.textChangeDelegate?.keyboard(change: options, textView: self)

                }
            }
        }
        keyboard.start()
        keyboard.addReponder(textView)
    }
    
    var ignoreRotation = false


    private func setupWithTextView(inputTextView: InputTextView, ignoreRotation: Bool = false) {
        self.inputTextView = inputTextView
        self.inputTextView?.docsListenToSuperViewResponder = true
        self.inputTextView?.fixPadKeyboardInputView = self.fixPadKeyboardInputView
        inputTextView.supportLandscapeConstraint = supportLandscapeConstraint
        self.inputTextView?.setupWith(dependency: self)
        self.inputTextView?.trackerParam = self
        self.inputTextView?.textView.commentDraftKeyProvider = self
        self.ignoreRotation = ignoreRotation
        if ignoreRotation {
            setupAsideStyleUI()
        } else {
            setupUI()
            if SKDisplay.pad {
                self.inputTextView?.setPlaceholderInset(insets: UIEdgeInsets(top: 7, left: 0, bottom: 0, right: 0))
            }
        }
        setupAtBind()
        monitorKeyboard()
        setupDraftEventReportBind()
    }

    public func updateFont(_ font: UIFont) {
        self.textFont = font
        self.inputTextView?.inputTextFont = font
        DocsLogger.info("updateFont", component: LogComponents.comment)
    }

    public func setHitTestAvoidView(view: UIView) {
        hitTestAvoidView = view
    }
    
    public var contentHeight: CGFloat {
        return toolContentView.bounds.height
    }
    
    public var isTextViewIFirstResponder: Bool {
        return inputTextView?.textView.isFirstResponder == true
    }
    
    public var isTextViewShow: Bool {
        return inputTextView?.superview != nil && inputTextView?.isHidden == false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
}

extension AtInputTextView {
    
    private func setupAsideStyleUI() {
        guard let inputTextView = inputTextView,
                  inputTextView.superview == nil else {
            return
        }
        containerView.addSubview(inputTextView)
        containerView.addSubview(toolBar)
        
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        inputTextView.backgroundColor = UIColor.ud.bgFloat
        inputTextView.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(40).priority(.required)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        toolBar.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.left.right.equalToSuperview().inset(-16)
            make.top.equalTo(inputTextView.snp.bottom).offset(10)
            make.bottom.equalToSuperview()
        }
        
        refreshPlaceholder(nil)

        _setupAccessibilityIdentifier()
    }
    
    private func setupUI() {
        
        let textViewInToolView = dependency?.textViewInToolView ?? false
        let atListViewInToolView = dependency?.atListViewInToolView ?? false
        /// add subviews
        
        inputTextView?.backgroundColor = UIColor.ud.bgBody
        inputTextView?.layer.cornerRadius = 8
        inputTextView?.layer.masksToBounds = true
        
        if DocsType.commentSupportLandscapaeFg {
            //需要在atListView之前添加，在底层
            containerView.addSubview(atListBlankView)
        }
        containerView.addSubview(atListView)
        
        if DocsType.commentSupportLandscapaeFg {
            //atListBlankView的布局，需要放在addSubview(atListView)之后
            atListBlankView.snp.makeConstraints { make in
                make.width.left.equalToSuperview()
                make.top.equalTo(atListView.snp.top)
                make.bottom.equalTo(atListView.snp.bottom)
            }
        }
        // 输入框
        if textViewInToolView {
            containerView.addSubview(toolContentView)
            toolContentView.backgroundColor = UIColor.ud.bgBody

            toolContentView.addSubview(topLine)
            
            if let inputTextView = inputTextView {
              toolContentView.addSubview(inputTextView)
            }
            toolContentView.addSubview(toolBar)
            toolBar.backgroundColor = UIColor.ud.bgBody
            
            topLine.snp.makeConstraints { (make) in
                make.height.equalTo(0.5)
                make.top.left.right.equalToSuperview()
            }
        } else {
            safeAreaButtomMask.backgroundColor = .clear
        }
        addSubview(safeAreaButtomMask)

        /// layout  -- 按顺序由上到下layout
        
        if dependency?.needBlankView ?? false {
            addSubview(blankView)
            blankView.snp.makeConstraints { (make) in
                make.right.equalToSuperview().offset(0)
                make.top.left.equalToSuperview()
                make.bottom.equalTo(containerView.snp.top)
                make.height.greaterThanOrEqualToSuperview().priority(.low)
            }
        }
        
        containerView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
            if containerView.subviews.isEmpty {
                make.height.equalTo(0)
            } else if dependency?.needMagicLayout == true {
                // 如果AtInputTextView的父view没有约束AtInputTextView.top，那么这里需要主动加个top约束
                make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            }
        }
        
        atListView.snp.makeConstraints { (make) in
            make.height.equalTo(0)
            make.top.equalToSuperview()
            portraitScreenConstraints.append(make.width.left.equalToSuperview().constraint)
            if let inputTextView = inputTextView, supportLandscapeConstraint {
                landscapeScreenConstraints.append(make.left.equalTo(inputTextView).constraint)
                landscapeScreenConstraints.append(make.width.equalTo(570).constraint)
            }
            if textViewInToolView {
                make.bottom.equalTo(toolContentView.snp.top).priority(.low)
            } else {
                make.bottom.equalToSuperview()
            }
        }

        if textViewInToolView {
            toolContentView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
            }
            inputTextView?.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(10)
                portraitScreenConstraints.append(make.height.greaterThanOrEqualTo(46).constraint)
                portraitScreenConstraints.append(make.left.width.equalToSuperview().constraint)

                if supportLandscapeConstraint {
                    landscapeScreenConstraints.append(make.height.greaterThanOrEqualTo(32).constraint)
                    landscapeScreenConstraints.append(make.bottom.equalToSuperview().offset(-10).priority(.required).constraint)
                    landscapeScreenConstraints.append(make.centerY.equalToSuperview().constraint)
                    landscapeScreenConstraints.append(make.left.equalToSuperview().offset(60).constraint)
                    landscapeScreenConstraints.append(make.right.equalTo(toolBar.snp.left).constraint)
                }
            }
            toolBar.snp.makeConstraints { (make) in
                if dependency?.textViewInToolView == true, let inputTextView = inputTextView {
                    portraitScreenConstraints.append(make.top.equalTo(inputTextView.snp.bottom).offset(3).constraint)
                    portraitScreenConstraints.append(make.bottom.equalToSuperview().offset(-7).constraint)
                    if supportLandscapeConstraint {
                        landscapeScreenConstraints.append(make.top.equalToSuperview().offset(0.5).constraint)
                        landscapeScreenConstraints.append(make.bottom.equalToSuperview().constraint)
                        landscapeScreenConstraints.append(make.right.equalToSuperview().constraint)
                    }
                    strechWhenRecordConstraint = make.width.equalTo(60).constraint
                } else {
                    make.top.equalToSuperview().offset(13)
                    make.bottom.equalToSuperview().offset(-10)
                }
                portraitScreenConstraints.append(make.height.equalTo(24).constraint)
                portraitScreenConstraints.append(make.width.equalToSuperview().constraint)
            }
        }
        strechWhenRecordConstraint?.deactivate()
        
        safeAreaButtomMask.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
            make.height.equalTo(self.safeAreaInsets.bottom)
        }
        
        updateConstraintsWhenOrientationChangeIfNeed(isManual: true)
        
        refreshPlaceholder(nil)

        _setupAccessibilityIdentifier()
    }

    private func setupDraftEventReportBind() {
        guard inputTextView != nil else { return }
        isEditing.filter { $0 }.subscribe(onNext: { [weak self] _ in
            self?.reportDraftEvent() // 键盘升起时上报
        }).disposed(by: disposeBag)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        ///特殊逻辑：原因是DocsToolContainer布局是不包含safeAreaInsets.bottom区域的，self.safeAreaInsets.bottom会=0，会导致docs里无编辑权限点击文字时的话，inputView底部是可以透视webview文字
        /// 优化方向：1，DocsToolContainer应该要盖住webView,不应该漏出safeAreaInsets.bottom区域，2，遮罩应该有上层如DocsToolContainer来加
        let selfFrameInWindow = self.convert(self.frame, to: nil)
        let currentWindow = self.window
        let currentWindowHeight = currentWindow?.bounds.size.height ?? 0
        let btnSafeAreaHeight = currentWindow?.safeAreaInsets.bottom
        if let btnSafeAreaHeight = btnSafeAreaHeight, round(currentWindowHeight - selfFrameInWindow.maxY) == round(btnSafeAreaHeight) {
            safeAreaButtomMask.snp.updateConstraints { (make) in
                make.height.equalTo(btnSafeAreaHeight)
            }
        } else {
            safeAreaButtomMask.snp.updateConstraints { (make) in
                make.height.equalTo(self.safeAreaInsets.bottom)
            }
        }
    }

    private func _setupAccessibilityIdentifier() {
        self.accessibilityIdentifier = "docs.comment.atInputTextView"
    }

}

extension AtInputTextView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == nil, let inviteTipsView = inviteTipsView, inviteTipsView.isHidden == false {
            let pointInInviteView = self.convert(point, to: inviteTipsView)
            let inviteViewHit = inviteTipsView.hitTest(pointInInviteView, with: event)
            if inviteViewHit != nil {
                return inviteViewHit
            }
        }

        if hitView == blankView,
           let hitTestAvoidView = hitTestAvoidView {
            let pointInView = self.convert(point, to: hitTestAvoidView)
            let result = hitTestAvoidView.hitTest(pointInView, with: event)
            if result != nil {
                return nil
            }
        }
        return hitView
    }
}

extension AtInputTextView {
    // 从InputSideCarView发送按钮触发的评论发送
    func didClickSendButtonFromeSideCar() {
        doSend()
    }

    func doSend(from source: ClickSendButtonSource = .inputTextView) {
        guard let inputTextView = inputTextView else {
            DocsLogger.error("inputTextView is nil", component: LogComponents.comment)
            return
        }

        let rawText = inputTextView.textView.text ?? ""
        let trimmingText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmingText.isEmpty && inputTextView.inputImageInfos.count == 0 {
            return
        }
        if inputTextView.textView.text.count >= 10000 {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Comment_Send_Limit_Fail, on: self.window ?? self)
            DocsLogger.error("text count is denied", component: LogComponents.comment)
            return
        }
        inputTextView.stopRecordingIfNeed()
        var isAudio = false
        if source == .voiceCommentView {
            isAudio = true
        }

        let encodeText = AtInfo.encodedString(attributedString: inputTextView.textView.attributedText).trimmingCharacters(in: .whitespacesAndNewlines)

        let content = CommentContent(content: encodeText, imageInfos: inputTextView.inputImageInfos, pcmData: nil, pcmDataTime: nil, attrContent: nil, isAudio: isAudio)

        // 发送前先判断能不能发送
        let sendCommentisOK = self.dependency?.willSendCommentContent(self, content: content) ?? false

        if sendCommentisOK {
            // 以下代码的顺序不要随意改,改了会影响草稿清除的逻辑
            NotificationCenter.default.post(name: NSNotification.Name.commentDraftClear, object: self.commentDraftKey)
            self.cleariPadInputContentAfterSendIfNeeded()
            self.dependency?.didSendCommentContent(self, content: content) // 发送内容

            if self.focusType == .edit {
                CommentTracker.log(.submit_re_edit, atInputTextView: self)
            } else {
                CommentTracker.log(.submit_comment, atInputTextView: self)
            }
        } else {
            DocsLogger.error("willSend is denied", component: LogComponents.comment)
        }
    }

}

extension AtInputTextView {
    
    var supportLandscapeConstraint: Bool {
        let docsInfo = dependency?.commentDocsInfo as? DocsInfo
        let supportCommentWhenLandscape = docsInfo?.inherentType.supportCommentWhenLandscape ?? false
        /// iPad 不需要横屏UI样式
        return !SKDisplay.pad && supportCommentWhenLandscape
    }
    
    /// 根据是否支持横屏下评论和当前设备横竖屏状态更改
    public func updateConstraintsWhenOrientationChangeIfNeed(isManual: Bool = false) {
        guard supportLandscapeConstraint else { return }
        guard dependency?.atListViewInToolView == true else { return }
        self.isChangeLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        if isChangeLandscape {
            portraitScreenConstraints.forEach { $0.deactivate() }
            landscapeScreenConstraints.forEach { $0.activate() }
            inputTextView?.backgroundColor = UDColor.udtokenInputBgDisabled
        } else {
            landscapeScreenConstraints.forEach { $0.deactivate() }
            portraitScreenConstraints.forEach { $0.activate() }
            inputTextView?.backgroundColor = UIColor.ud.bgBody
        }
        // 要立即更新布局，否则下面获取高度不准确
        self.setNeedsLayout()
        self.layoutIfNeeded()
        // 当前正在语音输入时的特殊处理
        updateTextViewStatus(isRecord: isRecording)

        // 转屏时高度拿不准，需要延后再拿
        let duration = isManual ? 0 : 550
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(duration)) { [weak self] in
            guard let self = self else { return }
            self.updateAtListViewWhenOrientationChange()
            self.toolBar.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: self.isChangeLandscape)
            self.inputTextView?.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: self.isChangeLandscape)
            self.atListView.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: self.isChangeLandscape)
            self.inviteTipsView?.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: self.isChangeLandscape)
        }
    }
    
    /// 旋转屏幕键盘改变
    public func performActionWhenKeyboard(didTrigger event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        //多刷新一次，防止竖屏切横屏的时候，横屏下计算高度拿到的键盘高度是竖屏的键盘高度
        if event == .didShow {
            self.updateAtListViewWhenOrientationChange()
            atListView.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: isChangeLandscape)
        }
    }
    
    /// 旋转屏幕@ 人 高度处理
    private func updateAtListViewWhenOrientationChange() {
        if supportLandscapeConstraint && dependency?.atListViewInToolView == true && atListView.isHidden == false {
            let atListViewHeight = self.calculateAtListViewHeight()
            atListView.snp.updateConstraints { (make) in
                make.height.equalTo(atListViewHeight)
            }
            atListView.layoutIfNeeded()
        }
    }
    
    // 横屏情况下，语音输入时工具栏toolBar是隐藏的，此时需要把inputTextView往右撑
    public func updateTextViewStatus(isRecord: Bool) {
        if isRecord && isChangeLandscape {
            strechWhenRecordConstraint?.activate()
        } else {
            strechWhenRecordConstraint?.deactivate()
        }
    }
}

extension AtInputTextView: AtInputViewType {
    public func textviewBecomeFirstResponder() {
        self.textviewBecomeFirstResponder(.new)
    }
    
    public func forceVoiceButtonHidden(isHidden: Bool) {
        toolBar.forceVoiceButtonHidden = isHidden
    }
    
    public func update(imageList: [CommentImageInfo], attrText: NSAttributedString) {
        textViewSet(attributedText: attrText)
        inputTextView?.updatePreviewWithImageInfos(imageList)
    }
    
    public func textViewResignFirstResponder() {
        textViewResignFirstResponder(.new)
    }
    
    public func shrinkTextView(maxHeight: CGFloat) {
        self.inputTextView?.textView.maxHeight = maxHeight
        self.inputTextView?.shrinkTextView()
    }
}
