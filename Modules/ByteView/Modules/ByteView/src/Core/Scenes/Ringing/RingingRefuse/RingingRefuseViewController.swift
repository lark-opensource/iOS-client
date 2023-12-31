//
//  RingingRefuseViewController.swift
//  ByteView
//
//  Created by wangpeiran on 2023/3/19.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewUI

class RingingRefuseViewController: BaseViewController {

    enum Layout {
        static let defaultWidth: CGFloat = 351.0
        static let defaultMargin: CGFloat = 12.0
        static let RegularTopMargin: CGFloat = 40.0
        static let timeInterval: TimeInterval = 3.0
    }

    private lazy var refuseNoticeView: RefuseNoticeView = {
        let view = RefuseNoticeView(delegate: self)
        view.isHidden = true
        view.tapBlock = { [weak self] in
            Logger.ringRefuse.info("tap noticeView")
            let params: TrackParams = [
                "conference_id": self?.body.meetingId ?? "",
                .click: "send_msg"
            ]
            VCTracker.post(name: .vc_meeting_callee_mobile_refusenotes_click, params: params)
            self?.refuseNoticeView.isHidden = true
            self?.invalidateTimer()
            self?.showReasonView()
        }
        return view
    }()

    private lazy var refuseReasonView: RefuseReasonView = {
        let view = RefuseReasonView(delegate: self)
        view.isHidden = true
        view.body = self.body
        view.setTitle(name: body.inviterName)
        view.tapBlock = {[weak self] (item: RefuseReasonItem?) in
            guard let self = self else { return }
            if let item = item { // 点击选项
                Logger.ringRefuse.info("tap custom reason")
                if item.isCustom { // 自定义出键盘
                    self.showCustomRefuse()
                } else {  // 已有选项，掉接口
                    Logger.ringRefuse.info("tap origin reason")
                    self.requestRefuseReply(refuseReply: item.title)
                    self.refuseReasonView.isHidden = true
                }
            } else { // 点击关闭
                Logger.ringRefuse.info("tap close reason")
                self.refuseReasonView.isHidden = true
                self.hide()
                self.trackForClose()
            }
        }
        return view
    }()

    private lazy var refuseResView: RefuseResView = {
        let view = RefuseResView(delegate: self)
        view.isHidden = true
        return view
    }()

    private lazy var maskView: UIControl = {
        let view = UIControl()
        view.isHidden = true
        view.backgroundColor = .ud.bgMask
        view.addTarget(self, action: #selector(handleMaskViewTap), for: .touchUpInside)
        return view
    }()

    private lazy var refuseInputView: RefuseInputView = {
        let view = RefuseInputView(frame: .zero)
        view.isHidden = true
        view.sendKeyBlock = {[weak self] (string: String) in
            guard let self = self else { return }
            self.requestRefuseReply(refuseReply: string)
            self.hideCustomRefuse()
            self.refuseReasonView.isHidden = true
            self.trackForCustomClick()
        }
        return view
    }()

    let body: RingRefuseBody
    let httpClient: HttpClient
    var phoneSupportOrientation: UIInterfaceOrientationMask = .portrait

    private var panY: Double = 0.0
    private var timer: Timer?

    // MARK: - Init & deinit
    init(body: RingRefuseBody, httpClient: HttpClient) {
        self.body = body
        self.httpClient = httpClient
        super.init(nibName: nil, bundle: nil)

        // 1.点击本view后，自己变成keywindow，导致getReallyResponder找到的是自己，错误的win和vc
        // 2.使用UIApplication.shared.windows.reversed().first(where: { ($0.windowLevel < RingingRefuseManager.ringRefuseWindowlevel) && !$0.isHidden })，找到的可能是比较奇怪的window，比如inputwindow
        if let responder = getReallyResponderViewController() {
            self.phoneSupportOrientation = responder.supportedInterfaceOrientations
            Logger.ringRefuse.info("now Orientation \(self.phoneSupportOrientation) \(responder.description)")
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        invalidateTimer()
        Logger.ringRefuse.info("RingingRefuseViewController deinit")
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard !Display.pad else {
            return .all
        }
        return phoneSupportOrientation
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        showNoticeView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_: )),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame(_:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_: )),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func setupViews() {
        self.view.backgroundColor = .clear

        view.addSubview(refuseNoticeView)
        view.addSubview(refuseReasonView)
        view.addSubview(maskView)
        view.addSubview(refuseInputView)
        view.addSubview(refuseResView)

        layoutViews()
        refuseInputView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.snp.bottom)
        }
        maskView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.layoutViews()
    }

    func showNoticeView() {
        refuseNoticeView.isHidden = false
        refuseNoticeView.alpha = 0
        VCTracker.post(name: .vc_meeting_callee_mobile_refusenotes_view, params: ["conference_id": body.meetingId])

        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.20, delay: 0.3, options: [.curveEaseInOut], animations: {
            self.refuseNoticeView.alpha = 1
        }, completion: { _ in
            self.timer = Timer.scheduledTimer(withTimeInterval: Layout.timeInterval, repeats: false, block: { [weak self] (_) in
                guard let self = self else { return }
                self.refuseNoticeView.isHidden = true
                self.hide()
            })
        })
    }

    func showReasonView() {
        refuseReasonView.isHidden = false
        /* 1.如果键盘已经弹起来，这样keyboardWillHide、keyboardDidChangeFrame不会走，导致refuseInputView出不来。如果用view.vc.debounceKeyboardLayoutGuide.snp.top，会出现refuseInputView光标闪动文字出现在下面视图。
            2. 所以先将已经存在的键盘关闭，这里最好放在showCustomRefuse中，但是存在时序问题keyboardWillHide可能会出现在show后面
            3. 注意dismissKeyboard会收到keyboardWillHide、keyboardDidChangeFrame，会影响逻辑
        */
        Util.dismissKeyboard()
        VCTracker.post(name: .vc_meeting_callee_msgnotes_view, params: ["conference_id": body.meetingId])
    }

    func showCustomRefuse() {
        maskView.isHidden = false
        refuseInputView.isHidden = false
        refuseInputView.textView.becomeFirstResponder()
    }

    func hideCustomRefuse() {
        refuseInputView.textView.resignFirstResponder()
        maskView.isHidden = true
        refuseInputView.isHidden = true
    }

    func showRefuseResView(title: String, isSuccess: Bool) {
        refuseResView.isHidden = false
        refuseResView.setTitle(title, isSuccess: isSuccess)
        self.timer = Timer.scheduledTimer(withTimeInterval: Layout.timeInterval, repeats: false, block: { [weak self] (_) in
            guard let self = self else { return }
            self.hideRefuseResView()
        })
    }

    func hideRefuseResView() {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.refuseResView.alpha = 0
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.refuseResView.alpha = 1
            self.refuseResView.isHidden = true
            self.hide()
        })
    }

    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc func handleMaskViewTap() {
        hideCustomRefuse()
    }

    @objc func hide() {
        Logger.ringRefuse.info("RingingRefuseViewController hide")
        RingingRefuseManager.shared.hideRingRefuse()
    }

    func touchInRefuseView(hitView: UIView) -> Bool {
        if !refuseNoticeView.isHidden {
            return hitView.isDescendant(of: refuseNoticeView)
        }
        // 下面这3个顺序不能调换，因为maskView出来了，refuseReasonView也一定出现了
        if !maskView.isHidden {
            return true
        }
        if !refuseReasonView.isHidden {
            return hitView.isDescendant(of: refuseReasonView)
        }
        if !refuseResView.isHidden {
            return hitView.isDescendant(of: refuseResView)
        }
        return false
    }

    func requestRefuseReply(refuseReply: String) {
        Logger.ringRefuse.info("begin request")
        let request = RefuseReplyRequest(meetingID: body.meetingId, refuseReply: refuseReply, isSingleMeeting: body.isSingleMeeting, inviterUserID: body.inviterUserId)
        httpClient.getResponse(request) { [weak self] (result) in
            Util.runInMainThread {
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    Logger.ringRefuse.info("refuseReply success \(response.singleStatus) \(response.groupStatus)")
                    let successTitle: String = self.body.isSingleMeeting ? I18n.View_G_SetMessageSentToVaryName(self.body.inviterName) : I18n.View_G_NameWillReceiveMessage(self.body.inviterName)
                    let failTitle: String = I18n.View_G_NetworkErrorUnableSend
                    if self.body.isSingleMeeting {
                        switch response.singleStatus {
                        case .singleSuccess:
                            self.showRefuseResView(title: successTitle, isSuccess: true)
                        case .baseSingleFail:
                            self.showRefuseResView(title: failTitle, isSuccess: false)
                        @unknown default:
                            self.hide()
                        }
                    } else {
                        switch response.groupStatus {
                        case .groupSuccess:
                            self.showRefuseResView(title: successTitle, isSuccess: true)
                        case .baseGroupFail:
                            self.showRefuseResView(title: failTitle, isSuccess: false)
                        case .meetingEnd:
                            self.showRefuseResView(title: I18n.View_G_MeetingEndNoMoreWaitMessage, isSuccess: false)
                        case .inviteIdle:
                            self.showRefuseResView(title: I18n.View_G_VaryNameLeftNoMoreWaitMessage(name: self.body.inviterName), isSuccess: false)
                        @unknown default:
                            self.hide()
                        }
                    }
                case .failure(let error):
                    Logger.ringRefuse.info("refuseReply error \(error)")
                    self.showRefuseResView(title: I18n.View_G_NetworkErrorUnableSend, isSuccess: false)
                }
            }
        }
    }

    //取底层window的top most作为实际代理者
    private func getReallyResponderViewController() -> UIViewController? {
        guard let kw = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                let root = kw.rootViewController,
                root != self,
                kw != self.view.window else {
            return nil
        }
        return root.vc.topMost
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if Display.phone {
            self.refuseInputView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(endFrame.size.height)
            }
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.4) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardDidChangeFrame(_ notification: Notification) {
        guard let info = notification.userInfo,
              let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        let isFloatingKeyBoard = (endFrame.size.width != view.frame.size.width)
        if Display.pad {  // ipad上奇怪的键盘不会走keyboardWillShow
            if endFrame.size.height == 0 { // 蓝牙键盘
                self.refuseInputView.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
            } else if isFloatingKeyBoard { // 悬浮键盘
                self.refuseInputView.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
            } else {  // 正常键盘和拆分键盘
                let h = view.frame.height - endFrame.maxY
                self.refuseInputView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview().inset(h + endFrame.size.height)
                }
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        hideCustomRefuse()
    }

    func trackForCustomClick() {
        let params: TrackParams = [
            "conference_id": body.meetingId,
            "caller_user_id": body.inviterUserId,
            .click: "customized_reply"
        ]
        VCTracker.post(name: .vc_meeting_callee_msgnotes_click, params: params)
    }

    func trackForClose() {
        let params: TrackParams = [
            "conference_id": body.meetingId,
            "caller_user_id": body.inviterUserId,
            .click: "close"
        ]
        VCTracker.post(name: .vc_meeting_callee_msgnotes_click, params: params)
    }
}

extension RingingRefuseViewController {
    func layoutViews() {
        let isRegular = VCScene.rootTraitCollection?.isRegular ?? false
        if isRegular {
            refuseNoticeView.snp.remakeConstraints { make in
                make.top.equalTo(self.view).offset(Layout.RegularTopMargin)
                make.right.equalToSuperview().inset(Layout.defaultMargin)
                make.width.equalTo(Layout.defaultWidth)
                make.height.equalTo(54)
            }

            refuseReasonView.snp.remakeConstraints { make in
                make.top.equalTo(self.view).offset(Layout.RegularTopMargin)
                make.right.equalToSuperview().inset(Layout.defaultMargin)
                make.width.equalTo(Layout.defaultWidth)
            }

            refuseResView.snp.remakeConstraints { make in
                make.top.equalTo(self.view).offset(Layout.RegularTopMargin)
                make.right.equalToSuperview().inset(Layout.defaultMargin)
                make.width.equalTo(Layout.defaultWidth)
            }
        } else if currentLayoutContext.layoutType.isPhoneLandscape {
            refuseNoticeView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(8)
                make.centerX.equalToSuperview()
                make.width.equalTo(Layout.defaultWidth)
                make.height.equalTo(54)
            }

            refuseReasonView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(8)
                make.centerX.equalToSuperview()
                make.width.equalTo(Layout.defaultWidth)
            }

            refuseResView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(8)
                make.centerX.equalToSuperview()
                make.width.equalTo(Layout.defaultWidth)
            }
        } else {
            refuseNoticeView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(8)
                make.left.right.equalToSuperview().inset(Layout.defaultMargin)
                make.height.equalTo(54)
            }

            refuseReasonView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(8)
                make.left.right.equalToSuperview().inset(Layout.defaultMargin)
            }

            refuseResView.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(8)
                make.left.right.equalToSuperview().inset(Layout.defaultMargin)
            }
        }

        refuseInputView.layoutView(isRegular: isRegular)
    }
}

/// delegate
extension RingingRefuseViewController: RefuseShadowViewDelegate {
    func refuseShadowPanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        switch sender.state {
        case .changed:
            let point = sender.translation(in: view)
            guard point.y < 0, point.y < panY  else { return }
            panY = point.y
            view.transform = CGAffineTransform(translationX: 0, y: point.y)
            sender.translation(in: view)
        case .ended:
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.6, delay: 0, options: []) {
                view.transform = CGAffineTransform(translationX: 0, y: -1000)
                sender.translation(in: view)
            } completion: { [weak self] done in
                if done {
                    view.isHidden = true
                    self?.panY = 0.0
                    self?.hide()
                }
            }
        default: return
        }
    }
}
