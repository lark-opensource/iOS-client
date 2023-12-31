//
//  InputTextView.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/20.
//
//  swiftlint:disable file_length

import Foundation
import RxSwift
import RxCocoa
import LarkLocalizations
import UniverseDesignActionPanel
import AVFoundation
import Speech
import SKFoundation
import SKUIKit
import SKResource
import LarkUIKit
import LarkAssetsBrowser
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignFont
import SnapKit
import SpaceInterface
import SKCommon
import SKInfra
import LarkSensitivityControl

protocol InputTextViewDependency: AnyObject {

    var docsInfo: DocsInfo? { get }
    var canSupportPic: Bool { get } // 场景是否支持图片
    var iPadNewStyle: Bool { get } // 编辑态是否展示边框
    var keyboardDidShowHeight: CGFloat? { get } // 普通键盘高度
    func textViewDidChange(_ textView: UITextView)
    func textViewDidChangeSelection(_ textView: UITextView)
    func textViewDidClickVoiceCancelButton(_ textView: UITextView)
    func textViewDidClickVoiceButton(_ textView: UITextView, isTap: Bool)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    func textViewDidBeginEditing(_ textView: UITextView)
    func textViewDidEndEditing(_ textView: UITextView)
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool
    func textViewDidCopyContent()
    func keyBoardEnterHandler()
    func voiceSendBtnHandler()
    func updateContentStatus(hasContent: Bool)
    func updateImageSelectStatus(select: Bool)
    func updateVoiceSelectStatus(select: Bool)
    
    func willTransformImageInfo()
    func finishTransformImageInfo()
    func imagePreviewDidChange()
    // 禁止textView显示多行，即：textView只能显示一行文字
    var diableTextMultiLine: Bool { get }
    func showMutexDialog(withTitle str: String)
    func clearVoiceText()
    // 媒体资源协同
    var mediaMutex: SKMediaMutexDependency? { get }
}


public final class InputTextView: UIView {

    static let voiceingTextColor = UIColor.ud.N500

    weak var trackerParam: AtInputTextView?

    var placeholder: String? {
        didSet {
            _refreshPlaceholder()
        }
    }
    
    weak var dependency: InputTextViewDependency?

    var textObservale: ControlProperty<String> {
        return textView.rx.text.orEmpty
    }

    var isEditingObservable: Observable<Bool> {
        return isEditing.asObservable()
    }

    var isRecordingObservable: Observable<Bool> {
        return isRecording.asObservable()
    }

    private(set) var isEditing: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private var isRecording: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var isLongPressVoicing: Bool = false // 长按识别，不会切换为语音界面
    var showingSelectImg: Bool = false //指inputView现在是图片选择器


    private var _startRecordingLocation = 0
    private var lastTextViewHeight: CGFloat = 0
    
    //是否横屏显示
    var isChangeLandscape: Bool = false

    // 松手时，语音识别结果延迟返回时，仍需要显示出来，除非手动输入或者关闭输入框后。
    var stopReceiveVoiceRecognize = true
    
    private var disposeBag: DisposeBag = DisposeBag()

    /// 输入框
    public private(set) lazy var textView: SKUDBaseTextView = setupTextView()
    public var canResignResponder: Bool = true {
        didSet {
            textView.canResign = canResignResponder
        }
    }

    /// 图片预览view
    public var inputImageInfos: [CommentImageInfo] = []
    var imageInfosChange: BehaviorRelay<Int> = BehaviorRelay(value: 0)
    private(set) lazy var imagesPreview: CommentInputImagesPreview = setupImagesPreview()
    private(set) lazy var openImagePlugin: CommentPreviewPicOpenImageHandler = {
        return CommentPreviewPicOpenImageHandler(transitionDelegate: self, docsInfo: dependency?.docsInfo)
    }()

    /// 输入框mask
    var maskButton: UIButton?

    var selectImgView: AssetPickerSuiteView?

    private var originPlaceholder: String?


    private(set) var voiceCommentView: VoiceCommentViewV2?
    
    /// 是否支持横屏布局
    var supportLandscapeConstraint = !SKDisplay.pad
    
    /// 竖屏下的约束
    private var portraitScreenConstraints: [SnapKit.Constraint] = []
    
    /// 横屏下的约束
    private var landscapeScreenConstraints: [SnapKit.Constraint] = []

    private var supportInsertPic: Bool {
        return dependency?.canSupportPic ?? false
    }

    private var supportShowPic: Bool {
        return dependency?.canSupportPic ?? false
    }

    var isIniOS16TemporaryReloadStage = false
    var fixPadKeyboardInputView = false

    /// 语音输入模块
    private lazy var rustRecognizer: AudioRecognizeService = {
        let r = AudioRecognizeService(audioAPI: DocsContainer.shared.resolve(AudioAPI.self)!)
        r.result.observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (result) in
            self?.handleAudioResult(result)
        }, onError: { (e) in
            DocsLogger.info("语音评论发生错误 \(e)")
        })
        .disposed(by: disposeBag)
        return r
    }()

    private var isRustRecognizerStart: Bool = false

    private var currentLanguage: Lang = {
        if let l = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.voiceCommentSelectLanguage) {
            return Lang(rawValue: l)
        } else {
            return DocsSDK.currentLanguage
        }
    }()

    var inputTextFont: UIFont {
        didSet {
            textView.font = inputTextFont
            restoreTypingAttributes()
            let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            attributedText.addAttributes([NSAttributedString.Key.font: inputTextFont],
                                         range: NSRange(location: 0,
                                         length: attributedText.length))
            textView.attributedText = attributedText
            // 触发label更新
            textView.placeholder = textView.placeholder
        }
    }

    private enum RecordState {
        case new
        case pause
        case stop
        case recording
    }

    private var _recordState: RecordState = .stop

    private var _startText: String = ""
    private var _endText: String = ""

    private var clickRecordCount = 0

    // use to shield text view, make the text view that can not respond to change selection event by user hits
    private weak var _blankView: UIView?

    private lazy var defaultTintColor = self.textView.tintColor

    init(inputTextFont: UIFont = UIFont.systemFont(ofSize: 16)) {
        self.inputTextFont = inputTextFont
        super.init(frame: .zero)
        setupNotification()
    }

    func setupWith(dependency: InputTextViewDependency) {
        self.dependency = dependency
        _setupUI()
        _setupBind()
        textView.accessibilityIdentifier = "docs.comment.textview.input"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("@")
    }

    func set(commentContent: CommentContent) {
        if let attrContent = commentContent.attrContent {
            textView.attributedText = attrContent
        } else {
            textView.text = commentContent.content
        }

        self.inputImageInfos = commentContent.imageInfos ?? []
        self.updateContentStatus()
        imageInfosChange.accept(self.inputImageInfos.count)
        imagesPreview.updateView(imageInfos: inputImageInfos)
    }

    func setPlaceholderInset(insets: UIEdgeInsets) {
        self.textView.placeholderTextView.textContainerInset = insets
    }

    public func updateContentStatus() {
        var stringContent = textView.attributedText.string
        stringContent = stringContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let textEmpty = stringContent.isEmpty
        let hasContent = (textEmpty == false) || (self.inputImageInfos.count > 0)
        self.dependency?.updateContentStatus(hasContent: hasContent)
    }

    func stopRecording(changeValue: Bool = true) {
        _stopRecordVoice()
        if changeValue {
            isRecording.accept(false)
        }
    }

    func stopRecordingIfNeed(changeValue: Bool = true) {
        if isRecording.value == true {
            stopRecording(changeValue: changeValue)
        }
    }

    deinit {
        _stopRecordVoice()
    }
    
    private func setupNotification() {
        guard supportLandscapeConstraint else { return }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(imagesCountHadChanged),
                                               name: NSNotification.Name(rawValue: "ImagesCountHadChanged"),
                                               object: nil)
    }
}

// MARK: - CommentPreviewPicOpenTransitionDelegate
extension InputTextView: CommentPreviewPicOpenTransitionDelegate {
    
    public func getTopMostVCForCommentPreview() -> UIViewController? {
        return UIViewController.docs.topMost(of: self.window?.rootViewController)
    }
}

// MARK: - UITextViewDelegate
extension InputTextView: UITextViewDelegate {
    public func textViewDidBeginEditing(_ textView: UITextView) {
        showBorderWhenEdit(show: true)
        isEditing.accept(true)
        dependency?.textViewDidBeginEditing(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if isIniOS16TemporaryReloadStage {
            DocsLogger.info("isIniOS16TemporaryReloadStage: true", component: LogComponents.comment)
            return
        }
        showBorderWhenEdit(show: false)
        isEditing.accept(false)
        dependency?.textViewDidEndEditing(textView)
        stopReceiveVoiceRecognize = true
    }

    public func textViewDidChange(_ textView: UITextView) {
        dependency?.textViewDidChange(textView)
        stopReceiveVoiceRecognize = true
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        restoreTypingAttributes()
        return dependency?.textView(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        textView.tintColor = defaultTintColor
        dependency?.textViewDidChangeSelection(textView)
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let canEdit = dependency?.textViewShouldBeginEditing(textView) ?? true
        if !canEdit {
            DocsLogger.warning("extView can not edit now", component: LogComponents.comment)
        }
        return canEdit
    }
}

extension InputTextView {
    private func _setupBind() {
        textView.rx.text
            .orEmpty
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.updateContentStatus()
            }).disposed(by: disposeBag)

        textView.rx.didChange.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.restoreTypingAttributes()
            }).disposed(by: disposeBag)

        textView.rx.didBeginEditing.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.restoreTypingAttributes()
            }).disposed(by: disposeBag)

        textView.rx.didChangeSelection.asDriver()
            .drive(onNext: { [weak self] (_) in
                self?.restoreTypingAttributes()
            }).disposed(by: disposeBag)
        
        isRecording.skip(1).asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isRecording) in
                if self?.isLongPressVoicing == true { return }
                if isRecording {
                    self?.setupMaskButton()
                }
                DispatchQueue.main.async {
                    ///为了让VoiceView的约束先执行，在下个任务再执行
                    isRecording ? self?._showVoiceCommentView() : self?._dismissVoiceCommentView()
                }
            }).disposed(by: disposeBag)


        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (_, isReachable) in
            if isReachable == false && self?.isRustRecognizerStart == true {
                let alertVC = UIAlertController(title: BundleI18n.SKResource.Doc_Comment_OfflineAudioDisabled, message: nil, preferredStyle: .alert)
                let confirm = UIAlertAction(title: BundleI18n.SKResource.Doc_Facade_Confirm, style: .default, handler: { (_) in
                })
                confirm.setValue(UIColor.ud.colorfulRed, forKey: "titleTextColor")
                alertVC.addAction(confirm)
                let selfRootVC = self?.window?.rootViewController
                let topMostVC = UIViewController.docs.topMost(of: selfRootVC)
                topMostVC?.present(alertVC, animated: true, completion: nil)
            }
        }

    }

    private func showBorderWhenEdit(show: Bool) {
        if dependency?.iPadNewStyle == true {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.layer.cornerRadius = 4
            self.layer.borderWidth = 1
            self.layer.masksToBounds = true
            if show {
                self.layer.ud.setBorderColor(UIColor.ud.colorfulBlue)
            } else {
                self.layer.ud.setBorderColor(UIColor.ud.N300)
            }
            CATransaction.commit()
        }
    }

    private var textViewMinHeight: CGFloat {
        return self.dependency?.iPadNewStyle == true ? 30 : 36
    }

    private var textViewMaxHeight: CGFloat {
        if self.dependency?.diableTextMultiLine == true { // 限制只显示单行
            return textViewMinHeight
        }
        return self.dependency?.iPadNewStyle == true ? 67 : 74
    }
    
    /// 横屏下textView的最大高度，约为两行半
    private var textViewMaxHeightLandscape: CGFloat { 40 }
    
    /// 横屏下imagesPreview的最大宽度
    private var imagesPreViewMaxWidthLandscape: CGFloat { 100 }

    private func _setupUI() {
        addSubview(textView)
        addSubview(imagesPreview)
        showBorderWhenEdit(show: false)

        // 这里的约束都是有用的
        // 约束 bottom 是为了可以支持 textView 高度自适应
        // 缺一不可 !!
        // 缺一不可 !!
        // 缺一不可 !!
        // 小康 Debug 了很久才发现的 O__O "…
        let textViewLeftRightGap: CGFloat = self.dependency?.iPadNewStyle == true ? 5 : 14
        let textViewTopGap: CGFloat = self.dependency?.iPadNewStyle == true ? 5 : 6
        let textViewBtmGap: CGFloat = self.dependency?.iPadNewStyle == true ? 5 : 4
        if self.dependency?.iPadNewStyle == true {
            textView.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        }
        textView.updatePlaceholderHeight(textViewMinHeight)
        textView.snp.makeConstraints { (make) in
            make.left.equalTo(textViewLeftRightGap)
            portraitScreenConstraints.append(make.right.equalTo(-textViewLeftRightGap).constraint)
            portraitScreenConstraints.append(make.height.lessThanOrEqualTo(textViewMaxHeight).constraint)
            
            if supportLandscapeConstraint {
                landscapeScreenConstraints.append(make.right.equalTo(imagesPreview.snp.left).offset(-5).constraint)
                landscapeScreenConstraints.append(make.height.lessThanOrEqualTo(textViewMaxHeightLandscape).constraint)
            }
            
            make.height.greaterThanOrEqualTo(textViewMinHeight)
            make.top.equalToSuperview().offset(textViewTopGap).priority(.required)
            if supportShowPic {
                portraitScreenConstraints.append(make.bottom.equalTo(imagesPreview.snp.top).offset(-textViewBtmGap).priority(.required).constraint)
                if supportLandscapeConstraint {
                    landscapeScreenConstraints.append(make.bottom.equalToSuperview().offset(-textViewBtmGap).priority(.required).constraint)
                }
            } else {
                make.bottom.equalToSuperview().offset(-textViewBtmGap).priority(.required) // <- 就是它，很重要的
            }
        }
        defaultTintColor = self.textView.tintColor

        let imageViewHorizentalOffset: CGFloat = 4
        imagesPreview.snp.remakeConstraints { (make) in
            portraitScreenConstraints.append(make.left.equalTo(textView).offset(imageViewHorizentalOffset).constraint)
            portraitScreenConstraints.append(make.right.equalTo(textView).offset(-imageViewHorizentalOffset).constraint)
            portraitScreenConstraints.append(make.bottom.equalToSuperview().constraint)

            if supportLandscapeConstraint {
                landscapeScreenConstraints.append(make.right.equalToSuperview().offset(-imageViewHorizentalOffset).constraint)
            }
            
            if !supportShowPic {
                make.height.equalTo(0)
                if supportLandscapeConstraint {
                    landscapeScreenConstraints.append(make.width.equalTo(0).constraint)
                }
            } else {
                portraitScreenConstraints.append(make.height.greaterThanOrEqualTo(0).constraint)

                if supportLandscapeConstraint {
                    landscapeScreenConstraints.append(make.width.lessThanOrEqualTo(imagesPreViewMaxWidthLandscape).constraint)
                }
            }
            if supportLandscapeConstraint {
                landscapeScreenConstraints.append(make.top.equalToSuperview().offset(5).priority(.required).constraint)
                landscapeScreenConstraints.append(make.bottom.equalToSuperview().offset(-5).priority(.required).constraint)
                landscapeScreenConstraints.append(make.right.equalToSuperview().constraint)
            }
        }
    }

    private func setupTextView() -> SKUDBaseTextView {
        let textView = SKUDBaseTextView()
        textView.delegate = self
        textView.font = inputTextFont
        textView.bounces = true
        textView.showsVerticalScrollIndicator = true
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        textView.maxHeight = textViewMaxHeight
        textView.textDragInteraction?.isEnabled = false
        textView.backgroundColor = .clear
        if SKDisplay.pad {
            let enterKey = UIKeyCommand(input: "\u{D}", modifierFlags: [], action: #selector(enterHandler(_:)))
            let shiftEnterKey = UIKeyCommand(input: "\u{D}", modifierFlags: .shift, action: #selector(shiftEnterHandler(_:)))
            textView.customKeyCommands.append(shiftEnterKey)
            textView.customKeyCommands.append(enterKey)
        }
        textView.copyOperation = { [weak self] _ in
            self?.dependency?.textViewDidCopyContent()
        }
        textView.cutOperation = { [weak self] _ in
            self?.dependency?.textViewDidCopyContent()
        }
        return textView
    }

    @objc
    private func enterHandler(_ command: UIKeyCommand) {
        /// 快捷键发送
        self.dependency?.keyBoardEnterHandler()
        self.placeholder = originPlaceholder
    }

    @objc
    private func shiftEnterHandler(_ command: UIKeyCommand) {
        /// 快捷键换行
        if textView.isFirstResponder {
            textView.insertText("\n")
        }
    }

    func setupMaskButton() {
        maskButton?.removeFromSuperview()
        maskButton = UIButton()
        addSubview(maskButton!)
        maskButton?.snp.makeConstraints { (make) in
            make.edges.equalTo(textView)
        }
        maskButton!.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.imagesPreview.isHidden = false
                if self.isRecording.value == true { // 录音中直接点击了按钮，先停止
                    self._stopRecordVoice()
                    self.isRecording.accept(false)
                }
                if self.selectImgView != nil, self.textView.inputView == self.selectImgView {
                    self.dismissSelectImageView()
                }

                if self.clickRecordCount != 0 {
                    self.track("text_edit")
                }
                self.maskButton?.removeFromSuperview()
            }.disposed(by: disposeBag)
    }

    private func setupImagesPreview() -> CommentInputImagesPreview {
        let view = CommentInputImagesPreview(supportEdit: supportInsertPic)
        view.delegate = self
        return view
    }

    private func requestPermission(_ callback: @escaping (Bool) -> Void) {
        // 申请权限
        // 录音权限
        do {
            try AudioRecordEntry.requestRecordPermission(forToken: Token(PSDATokens.Comment.docx_comment_click_microphone), session: AVAudioSession.sharedInstance()) { (recordGranted) in
                DispatchQueue.main.async {
                    if recordGranted {
                        callback(true)
                    } else {
                        DocsLogger.info("Audio permission granted is false")
                        callback(false)
                    }
                    CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.hadAskVoicePermission)
                }
            }
        } catch {
            DocsLogger.info("AudioRecordEntry requestRecordPermission error")
            callback(false)
        }
    }

    private func showAudioPermissionAlert() {
        let hadAsk = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.hadAskVoicePermission)
        guard hadAsk else { return }
        DispatchQueue.main.async {
            let selfRootVC = self.window?.rootViewController
            let topMostVC = UIViewController.docs.topMost(of: selfRootVC)
            let dialog = UDDialog()
            dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Docs_MicrophonePermission_Toast)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Settings, dismissCompletion: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            })
            topMostVC?.present(dialog, animated: true, completion: nil)
        }
    }

    func voiceTap(_ gesture: UITapGestureRecognizer) {
        requestPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                // 横屏下，禁用语音输入并弹toast提醒用户返回竖屏
                if UIApplication.shared.statusBarOrientation.isLandscape, self.supportLandscapeConstraint {
                    UDToast.showTips(with: BundleI18n.SKResource.LarkCCM_Docx_LandscapeMode_Dictate_Toast,
                                     operationText: BundleI18n.SKResource.LarkCCM_Docx_LandscapeMode_Switch_Button,
                                     on: self.window ?? self,
                                     operationCallBack: { _ in
                                        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                                            guard let self = self else { return }
                                            self.voiceTap(gesture)
                                        }
                    })
                } else {
                    DispatchQueue.main.async {
                        self.dependency?.textViewDidClickVoiceButton(self.textView, isTap: true)

                        if self.isRecording.value == true { // 录音中直接点击了按钮，先停止
                            self._stopRecordVoice()
                        }

                        self.isRecording.accept(!self.isRecording.value)
                    }
                }
                
                
                
            } else {
                DocsLogger.info("没有权限")
                self.showAudioPermissionAlert()
            }
        }
    }

    func voiceLongPress(_ gesture: UILongPressGestureRecognizer) {
        let state = gesture.state

        switch state {
        case .began:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isLongPressVoicing = true

            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                // 埋点
                self.requestPermission { granted in
                    if !granted {
                        DocsLogger.info("没有权限")
                        self.showAudioPermissionAlert()
                        return
                    } else {
                        DispatchQueue.main.async {
                            self.dependency?.textViewDidClickVoiceButton(self.textView, isTap: false)

                            DocsLogger.info("语音评论开始长按")

                            if self.dependency?.iPadNewStyle == false {
                                self.stretchTextView()
                            }

                            // 开始录音
                            self.isRecording.accept(true)
                            self._startRecordVoice()

                            if self.textView.text.isEmpty {
                                self.originPlaceholder = self.placeholder
                                self.placeholder = BundleI18n.SKResource.Doc_Comment_SpeakNow
                            }
                        }
                    }
                }
            }

        case .changed:
            break
        case .ended:
            DocsLogger.info("语音评论结束长按")
            isLongPressVoicing = false
            // 停止录音
            self.isRecording.accept(false)
            _stopRecordVoice()

            if textView.text.isEmpty {
                self.placeholder = self.originPlaceholder
            }
        default:
            break
        }
    }

    func stretchTextView() {
        self.imagesPreview.isHidden = true
        // 撑大 text view
//        let maxHeight = isChangeLandscape ? 60.0 : 150.0
//        textView.maxHeight = maxHeight
//        textView.snp.updateConstraints { (make) in
//            make.height.lessThanOrEqualTo(maxHeight)
//            make.height.greaterThanOrEqualTo(maxHeight - 1)
//        }
//
//        // 通知 Comment View 重新布局
//        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "COMMENT_VIEW_RE_LAYOUT"), object: nil)
    }

    func shrinkTextView() {
        self.imagesPreview.isHidden = false
        // 缩小 text view
        let maxHeight = isChangeLandscape && supportLandscapeConstraint ? textViewMaxHeightLandscape : textViewMaxHeight
        textView.maxHeight = maxHeight
        textView.snp.updateConstraints { (make) in
            make.height.lessThanOrEqualTo(maxHeight)
            make.height.greaterThanOrEqualTo(textViewMinHeight)
        }
            
        // 如果不异步调用setNeedsLayout，不会触发BaseTextView的layoutSubviews, 会导致语音评论完不能滚动问题
        DispatchQueue.main.async {
            self.textView.setNeedsLayout()
        }
    }
    
    func didClickSelectImgBtn(willShowImagePicker: () -> Bool ) -> Bool {
        if self.selectImgView != nil, self.textView.inputView == self.selectImgView {
            DocsLogger.info("didClickSelectImgBtn, dismiss")
            self.dismissSelectImageView()
            return false
        } else {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                guard validateUploadPermission() else {
                    return false
                }
            } else {
                guard legacyValidateUploadPermission() else {
                    return false
                }
            }

            DocsLogger.info("didClickSelectImgBtn, show")
            if willShowImagePicker() {
                // 横屏下，禁用图片选择器并弹toast提醒用户返回竖屏
                if isChangeLandscape, supportLandscapeConstraint {
                    UDToast.showTips(with: BundleI18n.SKResource.LarkCCM_Docx_LandscapeMode_AddPic_Toast,
                                     operationText: BundleI18n.SKResource.LarkCCM_Docx_LandscapeMode_Switch_Button,
                                     on: self.window ?? self,
                                     operationCallBack: { _ in
                                        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                                            guard let self = self else { return }
                                            let isInVC = self.dependency?.docsInfo?.isInVideoConference ?? false
                                            if isInVC {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                                                    self?.showSelectImageView()
                                                }
                                            } else {
                                                self.showSelectImageView()
                                            }
                                        }
                    })

                } else {
                    self.showSelectImageView()
                }
            }
            return true
        }
    }

    private func validateUploadPermission() -> Bool {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let request = PermissionRequest(token: "", type: .file, operation: .uploadAttachment, bizDomain: .ccm, tenantID: nil)
        let response = permissionSDK.validate(request: request)
        if let controller = getTopMostVCForCommentPreview() {
            response.didTriggerOperation(controller: controller)
        }
        return response.allow
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyValidateUploadPermission() -> Bool {
        let result = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmAttachmentUpload,
                                                           fileBizDomain: .ccm,
                                                           docType: .file,
                                                           token: nil)
        if result.allow == false {
            switch result.validateSource {
            case .fileStrategy:
                self.textView.resignFirstResponder() // 避免键盘遮挡Dialog
                CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmAttachmentUpload,
                                                             fileBizDomain: .ccm,
                                                             docType: .file,
                                                             token: nil)
            case .securityAudit:
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: self.window ?? self)
            case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                DocsLogger.info("unknown type or dlp type")
            }
            return false
        }

        // Admin权限管控
        if !AdminPermissionManager.adminCanUpload() {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: self.window ?? self)
            return false
        }
        return true
    }

    func closeInsertPicViewIfNeed() {
        if self.selectImgView != nil, self.textView.inputView == self.selectImgView {
            self.dismissSelectImageView()
        }
    }

    private func _refreshPlaceholder() {
        textView.placeholder = placeholder
        if originPlaceholder == nil {
            originPlaceholder = placeholder
        }
    }

    private func restoreTypingAttributes() {
        textView.typingAttributes = AtInfo.TextFormat.defaultAttributes(font: inputTextFont, textColor: UIColor.ud.textTitle)
    }

    private func _showVoiceCommentView() {
        voiceCommentView?.removeFromSuperview()
        voiceCommentView = nil
        clickRecordCount = 0
        voiceCommentView = newVoiceCommentViewV2().construct({
            $0.backgroundColor = UIColor.ud.bgBody
        })
        changeRecordLanguage(currentLanguage, save: false)
        UIView.performWithoutAnimation {
            self.textView.inputView = self.voiceCommentView
            self.textView.reloadInputViews()
            if #available(iOS 17.0, *), SettingConfig.ios17CompatibleConfig?.fixKeyboardIssue == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                    self.textView.resignFirstResponder()
                    self.textView.becomeFirstResponder()
                }
            } else {
                self.textView.becomeFirstResponder()
            }
        }
        let trimmingText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmingText.isEmpty {
            voiceCommentView?.showDeleteAndSendButton(animated: false)
        } else {
            voiceCommentView?.hideDeleteAndSendButton(animated: false)
        }
        fixiOS16InputViewShowInSplitScreen()
        guard supportLandscapeConstraint else { return }
        // 组件不支持，暂时打开强制竖屏
        NotificationCenter.default.post(name: Notification.Name.commentForcePotraint, object: nil)
    }

    private func newVoiceCommentViewV2() -> VoiceCommentViewV2 {
        let voiceCommentView = VoiceCommentViewV2()
        voiceCommentView.atInputTextView = trackerParam
        voiceCommentView.frame.size.height = 195 + self.safeAreaInsets.bottom

        voiceCommentView.selectLanguageButton.rx.tap
            .bind { [weak self] (_) in
                self?._showSelectLanguageAlert()
                self?.track("switch_lan")
            }.disposed(by: disposeBag)

        voiceCommentView.sendButton.rx.tap
            .bind { [weak self] (_) in
                self?.dependency?.voiceSendBtnHandler()
                self?.placeholder = self?.originPlaceholder
                self?.track("send")
            }.disposed(by: disposeBag)

        voiceCommentView.deleteButton.rx.tap
            .bind { [weak self] (_) in
                self?.voiceCommentView?.reset()
                self?.textView.text = ""
                self?.track("text_clear")
                self?.dependency?.clearVoiceText()
            }.disposed(by: disposeBag)

        voiceCommentView.isVoiceButtonOn
            .skip(1)
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (isOn) in
                guard let self = self else { return }

                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                    if isOn {
                        self._startRecordVoice()
                        if self.clickRecordCount != 0 { self.track("continue") }
                    } else {
                        self._stopRecordVoice()
                        self.refreshTextView()
                        if self.clickRecordCount != 0 { self.track("pause") }
                    }
                }
                self.clickRecordCount += 1
            }.disposed(by: disposeBag)

        Observable.combineLatest(voiceCommentView.isVoiceButtonOn.skip(1), textView.rx.text).bind { [weak self] (isOn, text) in
            guard let self = self else { return }
            guard let text = text else {
                self.placeholder = BundleI18n.SKResource.Doc_Comment_SpeakNow
                return
            }
            if text.isEmpty && isOn {
                self.originPlaceholder = self.placeholder
                self.placeholder = BundleI18n.SKResource.Doc_Comment_SpeakNow

            } else if text.isEmpty {
                self.placeholder = self.originPlaceholder
            }
        }.disposed(by: disposeBag)

        return voiceCommentView
    }

    private func track(_ op: String) {
        if let trackerParam = trackerParam {
            CommentTracker.log(.click_audiocomment_action, atInputTextView: trackerParam, extraInfo: ["operation": op])
        }
    }

    private func _showSelectLanguageAlert() {
        let selectLanguageAlert = _setupSelectLanguageAlert()
        let selfRootVC = self.window?.rootViewController
        let topMostVC = UIViewController.docs.topMost(of: selfRootVC)
        topMostVC?.present(selectLanguageAlert, animated: true, completion: nil)
    }

    private func _setupSelectLanguageAlert() -> UDActionSheet {
        let alert = UDActionSheet.actionSheet()

        //注意：这里所有action都需要加reloadInputViews，因为在ios14，larkApp里面键盘下去之后，就上不来了,根本原因未知
        alert.addItem(text: BundleI18n.SKResource.Doc_Doc_LanguageChineseMandarin) { [weak self] in
            self?.changeRecordLanguage(.zh_CN, save: true)
            self?.textView.reloadInputViews()
        }

        alert.addItem(text: BundleI18n.SKResource.Doc_Comment_English) { [weak self] in
            self?.changeRecordLanguage(.en_US, save: true)
            self?.textView.reloadInputViews()
        }

        alert.addItem(text: BundleI18n.SKResource.Doc_Facade_Cancel, style: .cancel) { [weak self] in
            self?.textView.reloadInputViews()
        }

        return alert
    }

    private func changeRecordLanguage(_ language: Lang, save: Bool) {
        currentLanguage = language

        switch language {
        case .zh_CN:
            voiceCommentView?.setSelectLanguageButtonTitle(BundleI18n.SKResource.Doc_Doc_LanguageChineseMandarin)
            voiceCommentView?.setCurrentLanguageLabel(BundleI18n.SKResource.Doc_Comment_ConvertAsChinese)
        case .en_US:
            voiceCommentView?.setSelectLanguageButtonTitle(BundleI18n.SKResource.Doc_Comment_English)
            voiceCommentView?.setCurrentLanguageLabel(BundleI18n.SKResource.Doc_Comment_ConvertAsEnglish)
        default:
            voiceCommentView?.setSelectLanguageButtonTitle(BundleI18n.SKResource.Doc_Comment_English)
            voiceCommentView?.setCurrentLanguageLabel(BundleI18n.SKResource.Doc_Comment_ConvertAsEnglish)
        }

        if save {
            _saveLast(language)
        }
    }

    private func _dismissVoiceCommentView() {
        placeholder = BundleI18n.SKResource.Doc_Doc_ReplyCommentDot

        dismissVoiceViewIfNeed()

        _stopRecordVoice()

        voiceCommentView?.removeFromSuperview()
        voiceCommentView = nil
        refreshTextView()
        
        guard supportLandscapeConstraint else { return }
        // 关闭强制竖屏
        NotificationCenter.default.post(name: Notification.Name.commentCancelForcePotraint, object: nil)
    }


    private func _startRecordVoice() {
        // 申请资源
        guard let mediaMutex = dependency?.mediaMutex else {
            DocsLogger.info("[LarkMedia] can't find SKMediaMutexDependency", component: LogComponents.comment)
            return
        }
        DocsLogger.info("[LarkMedia] request start record voice, begin tryLock.", component: LogComponents.comment)
        mediaMutex.tryLock(scene: .ccmRecord,
                           mixWithOthers: false,
                           mute: false,
                           observer: self) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                DocsLogger.info("[LarkMedia] tryLock success, ccm bigin record comment.", component: LogComponents.comment)
                self._recordState = .new
                self.rustRecognizer.startRecognizing(language: self.currentLanguage)
                self.isRustRecognizerStart = true
                self.stopReceiveVoiceRecognize = false
            case .occupiedByOther(let msg):
                guard let msg = msg else {
                    DocsLogger.info("[LarkMedia] occupied by other, --but NO msg--", component: LogComponents.comment)
                    self._recordState = .new
                    self.rustRecognizer.startRecognizing(language: self.currentLanguage)
                    self.isRustRecognizerStart = true
                    return
                }
                DocsLogger.info("[LarkMedia] occupied by other, msg:\(msg)", component: LogComponents.comment)
                self.dependency?.showMutexDialog(withTitle: msg)
            case .sceneNotFound, .unknown:
                DocsLogger.info("[LarkMedia] tryLock scene not found or unknown, res:\(result)",
                                component: LogComponents.comment)
                self._recordState = .new
                self.rustRecognizer.startRecognizing(language: self.currentLanguage)
                self.isRustRecognizerStart = true
            }
        }
    }

//    private func _pauseRecordVoice() {
//        DocsLogger.info("结束录音")
//
//        _recordState = .pause
//
//        if isRustRecognizerStart {
//            rustRecognizer.endRecord()
//        }
//
//        isRustRecognizerStart = false
//    }

    private func _stopRecordVoice() {
        if UIApplication.shared.statusBarOrientation.isLandscape, supportLandscapeConstraint {
            // 横屏下的布局不支持语音
            DocsLogger.info("[LarkMedia] The layout in landscape does not support voice", component: LogComponents.comment)
            return
        }
        // 释放资源
        defer {
            DocsLogger.info("[LarkMedia] ccm record comment end, release lock.", component: LogComponents.comment)
            dependency?.mediaMutex?.unlock(scene: .ccmRecord, observer: self)
        }
        _recordState = .stop

        if isRustRecognizerStart {
            rustRecognizer.endRecord()
        }

        isRustRecognizerStart = false
    }

    private func jointTextViewV2(_ text: String, finish: Bool) {
//        if _recordState == .stop {
//            return
//        }
        DocsLogger.info("语音输入录入文本， finish=\(finish)")

        let currentLocation = textView.selectedRange.location

        if _recordState == .new {
            _recordState = .recording
            _startRecordingLocation = currentLocation
        }
        
        let originAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)

        // 1. 先清除旧的输入
        let oldInputTextLength = currentLocation - _startRecordingLocation
        let replaceRange = NSRange(location: _startRecordingLocation, length: oldInputTextLength)
        let replaceString = NSMutableAttributedString(string: text)

        replaceString.setAttributes([.font: inputTextFont,
                                     .foregroundColor: UIColor.ud.textTitle], range: NSRange(location: 0, length: replaceString.length))

        let location = replaceString.length >= 2 ? replaceString.length - 2 : 0
        let length = replaceString.length >= 2 ? 2 : replaceString.length

        replaceString.addAttributes(
            [.foregroundColor: InputTextView.voiceingTextColor],
            range: NSRange(
                location: location,
                length: length
            )
        )
        guard replaceRange.location >= 0, replaceRange.length >= 0 else {
            DocsLogger.error("[LarkMedia] replaceRange is illegal", component: LogComponents.comment)
            return
        }
        if replaceRange.location + replaceRange.length > originAttributedText.length {
            DocsLogger.info("[LarkMedia] Voice input text out of bounds", component: LogComponents.comment)
            return
        }
        // 2. 替换原本的字符串
        originAttributedText.replaceCharacters(in: replaceRange, with: replaceString)

        textView.attributedText = originAttributedText

        textView.selectedRange = NSRange(location: _startRecordingLocation + replaceString.length, length: 0)

        textView.tintColor = .clear

        if finish {
            self.refreshTextView()
        }
        self.dependency?.textViewDidChange(textView)
    }

    private func refreshTextView() {
        DocsLogger.info("刷新文本")
        let originAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
        if originAttributedText.length > 0 {
            textView.attributedText.enumerateAttributes(in: NSRange(location: 0, length: originAttributedText.length), options: []) { (attributes, range, _) in
                if let color = attributes[.foregroundColor] as? UIColor, color.isEqual(InputTextView.voiceingTextColor) {
                    originAttributedText.addAttributes([.foregroundColor: UIColor.ud.N900], range: range)
                }
            }
            textView.attributedText = originAttributedText
            textView.tintColor = defaultTintColor
        }
    }

    private func _saveLast(_ language: Lang) {
        CCMKeyValue.globalUserDefault.set(language.localeIdentifier, forKey: UserDefaultKeys.voiceCommentSelectLanguage)
    }

    private func handleAudioResult(_ result: AudioRecognizeResult) {
        let isAtVoiceInputView: Bool = (self.textView.inputView != nil) && (self.textView.inputView == voiceCommentView)
        if isAtVoiceInputView ||
            self.isRecording.value == true ||
            !self.isRecording.value && !stopReceiveVoiceRecognize {
            self.jointTextViewV2(result.text, finish: result.finish)
        } else {
            refreshTextView()
        }
    }
}

extension InputTextView {
    /// 根据是否支持横屏下评论和当前设备横竖屏状态更改
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        guard supportLandscapeConstraint else { return }
        self.isChangeLandscape = isChangeLandscape
        let isRecord = isRecording.value
        
        if isChangeLandscape {
            portraitScreenConstraints.forEach { $0.deactivate() }
            landscapeScreenConstraints.forEach { $0.activate() }
            // 如果当前“长按开始说话”正在展示，输入框高度为撑开后的高度，横屏为60，约3行
            let maxHeight = isRecord ? 60.0 : textViewMaxHeightLandscape
            let minHeight = isRecord ? 59.0 : textViewMinHeight
            textView.maxHeight = maxHeight
            textView.snp.updateConstraints { (make) in
                make.height.lessThanOrEqualTo(maxHeight)
                make.height.greaterThanOrEqualTo(minHeight)
            }
        } else {
            landscapeScreenConstraints.forEach { $0.deactivate() }
            portraitScreenConstraints.forEach { $0.activate() }
            // 如果当前“长按开始说话”正在展示，输入框高度为撑开后的高度，竖屏为150
            let maxHeight = isRecord ? 150.0 : textViewMaxHeight
            let minHeight = isRecord ? 149.0 : textViewMinHeight
            textView.maxHeight = maxHeight
            textView.snp.updateConstraints { (make) in
                make.height.lessThanOrEqualTo(maxHeight)
                make.height.greaterThanOrEqualTo(minHeight)
            }
        }
        
        DispatchQueue.main.async {
            self.textView.setNeedsLayout()
        }
        
        imagesPreview.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: isChangeLandscape)
        self.textView.reloadInputViews()
    }
    
    @objc
    func imagesCountHadChanged() {
        // 横屏下，由于图片预览在输入框右边，因此图片数量变动时需要layout textView
        if isChangeLandscape {
            DispatchQueue.main.async {
                self.textView.setNeedsLayout()
            }
        }
    }
}

// MARK: - LarkMedia
// https://bytedance.feishu.cn/docx/doxcnCWWyShNCEQVhfzl27UcL7f
extension InputTextView: SKMediaResourceInterruptionObserver {

    /// 被打断
    /// 只对占用中并被打断的业务发送
    /// - Scene: 打断者
    /// - type: 具体被打断的媒体类型
    /// - msg: 打断通用文案
    public func mediaResourceInterrupted(with msg: String?) {
        self.isRecording.accept(false)
        self._stopRecordVoice()
    }
    
    /// 打断结束
    /// 只对被打断的业务发送
    /// - Scene: 打断结束者
    /// - type: 具体被释放的媒体类型
    public func meidaResourceInterruptionEnd() {
        // 语音输入被打断将终止录制并释放资源，释放资源后不会接收到恢复通知，此处不做处理
    }
}

