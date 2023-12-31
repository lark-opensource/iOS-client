//
//  NotificationReplyViewController.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/11.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignDialog
import UniverseDesignToast
import SnapKit
import ByteWebImage
import LarkNotificationContentExtensionSDK
import RxSwift
import LarkContainer
import LKCommonsLogging

typealias SwitchEventHandler = () -> Void
typealias DismissHandler = () -> Void

final class NotificationReplyViewController: UIViewController {
    
    let logger = Logger.log(NotificationReplyViewController.self, category: "LarkNotificationAssembly")

    let vm: NotificationViewModel
    let userResolver: UserResolver

    init(vm: NotificationViewModel, userResolver: UserResolver) {
        self.vm = vm
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    public var switchHandler: SwitchEventHandler?
    public var dismissHandler: DismissHandler?
    
    var hasShowAnimation: Bool = false

    private lazy var maskView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        view.alpha = 0
        return view
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = Layout.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private lazy var naviBar: NaviBarView = {
        let view = NaviBarView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var chatItemView: ChatItemView = {
        let view = ChatItemView()
        return view
    }()

    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: Layout.noteLabelFont)
        return label
    }()

    private lazy var replyInput: LarkNCExtensionKeyboard = {
        LarkNCExtensionKeyboard()
    }()
    
    private lazy var fakeInputBackView: UIView = {
        let view = UIView()
        view.backgroundColor = self.replyInput.backgroundColor
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let disposeBag = DisposeBag()

    @objc
    private func didTapSwitchButton() {
        self.onDimiss()
        self.switchHandler?()
        guard let extra = self.vm.userInfo.nseExtra, let msgID = extra.messageID else {
            return
        }
        ReplyTracker.clickSwitch(msgId: String(msgID),
                                 userId: extra.userId,
                                 ifCrossTenant: extra.userId == self.vm.currentUserId,
                                 isRemote: extra.isRemote)
    }

    @objc
    private func didTapCloseButton() {
        if self.replyInput.textView.text.isEmpty {
            self.onDimiss()
            return
        }
        let dialog = UDDialog()
        dialog.setTitle(text: self.vm.closeDialogTitle)
        dialog.addSecondaryButton(text: self.vm.closeButtonTitle, dismissCompletion: { [weak self] in
            self?.onDimiss()
        })
        dialog.addPrimaryButton(text: self.vm.editButtonTitle)
        self.userResolver.navigator.present(dialog, from: self)
    }
    
    private func onDimiss() {
        self.dismissHandler?()
        self.replyInput.textView.resignFirstResponder()
        if Self.isAlert(window: self.view.window) {
            /// iPad/R 使用系统的dismiss动画效果
            self.dismiss(animated: true)
        } else {
            let bounds = self.view.bounds
            let size = CGSize(width: bounds.size.width, height: bounds.size.height - Layout.naviBarTop)
            /// 浮层为了mask view有更好的消失过程，先走一个自己的动画，再调系统的
            UIView.animate(withDuration: 0.5) {
                self.maskView.alpha = 0
                self.containerView.frame = CGRect(origin: CGPoint(x: 0, y: bounds.size.height), size: size)
            } completion: { _ in
                self.dismiss(animated: false)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.hasShowAnimation { return }
        self.hasShowAnimation = true
        UIView.animate(withDuration: 0.5, delay: 0.25) {
            self.maskView.alpha = Layout.maskAlpha
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        /// iPad 上可以调整视图宽度，要实时响应
        setUpLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.modalPresentationStyle == .overFullScreen {
            /// 非弹窗模式需要自己加上mask view
            self.view.addSubview(self.maskView)
            self.maskView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .bind { [weak self] (noti) in
                guard let self = self else { return }
                self.onKeyboardShowOrHide(noti)
            }.disposed(by: self.disposeBag)

        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .bind { [weak self] (noti) in
                guard let self = self else { return }
                self.onKeyboardShowOrHide(noti)
            }.disposed(by: self.disposeBag)

        self.view.addSubview(self.containerView)
        self.setNaviBar()
        self.setChatView()
        self.setNoteLabel()
        self.setInputView()
        self.setConstraints()

        replyInput.textView.becomeFirstResponder()

        /// view 事件埋点
        guard let extra = self.vm.userInfo.nseExtra, let msgID = extra.messageID else {
            return
        }
        ReplyTracker.view(msgId: String(msgID),
                          userId: extra.userId,
                          ifCrossTenant: extra.userId == self.vm.currentUserId,
                          isRemote: extra.isRemote)
    }

    @objc
    private func onKeyboardShowOrHide(_ notify: Notification) {
        guard let userinfo = notify.userInfo else { return }
        if notify.name == UIResponder.keyboardWillShowNotification ||
            notify.name == UIResponder.keyboardWillHideNotification {
            self.onKeyboardShow(userinfo)
        }
    }

    /// 键盘弹出时，对判断是否需要对Dialog进行上移操作
    private func onKeyboardShow(_ userinfo: [AnyHashable : Any]) {
        if let keyboardRect = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            self.remakeInputToKeyBoard(keyboardRect: keyboardRect)
        }
    }

    private func remakeInputToKeyBoard(keyboardRect: CGRect) {
        let offset = self.systemKeyboardHeight(forView: self.view, toFrame: keyboardRect)
        self.replyInput.snp.remakeConstraints { (make) in
            make.bottom.equalTo(self.view.snp.bottom).offset(-offset)
            make.left.right.width.equalToSuperview()
            make.height.equalTo(Layout.inputViewHeight)
        }
        self.view.layoutIfNeeded()
    }

    /// 计算键盘遮挡了view的部分的高度
    /// 因为输入框可能不贴紧底部，所以需要计算相对键盘高度
    /// 如果此时 view不在视图层级上则返回完整键盘高度
    func systemKeyboardHeight(forView: UIView, toFrame: CGRect) -> CGFloat {
        if let window = forView.window {
            let convertRect = forView.convert(forView.bounds, to: window)
            var windowOffSetY: CGFloat = 0
            /// 如果高都小于屏幕高度，这个时候键盘的计算的高度会有问题 需要调整一下
            /// 补充的高度 = 键盘window相对整个屏幕的高度偏移
            if window.frame.height < UIScreen.main.bounds.height,
               Display.pad {
                let point = window.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
                windowOffSetY = point.y
            }

            let bottomY = windowOffSetY + window.frame.minY + convertRect.minY + convertRect.height
            /// 兼容视图最大 Y 超出键盘底部的场景
            return max(0, min(toFrame.maxY, bottomY) - toFrame.minY)
        } else {
            return toFrame.height
        }
    }

    func setNaviBar() {
        self.containerView.addSubview(self.naviBar)
        self.naviBar.titleLabel.text = self.vm.title
        self.naviBar.subTitleLabel.text = self.vm.subTitle
        self.naviBar.subTitleLabel.isHidden = self.vm.subTitle.isEmpty
        self.naviBar.closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        self.naviBar.switchTenantButton.addTarget(self, action: #selector(didTapSwitchButton), for: .touchUpInside)
        self.naviBar.switchTenantButton.setTitle(self.vm.switchTenantTitle, for: .normal)
    }

    func setChatView() {
        self.containerView.addSubview(self.chatItemView)
        if self.vm.isShowDetail {
            self.chatItemView.avatarView.bt.setImage(self.vm.imageURL, placeholder: self.vm.placeHolderImage)
        } else {
            /// 不展示详情时候，展示默认头像
            self.chatItemView.avatarView.image = self.vm.placeHolderImage
        }
        self.chatItemView.nameLabel.isHidden = self.vm.nameLabelIsHidden
        self.chatItemView.nameLabel.text = self.vm.senderName
        self.chatItemView.contentLabel.text = self.vm.content
        self.chatItemView.contentLabel.textColor = self.vm.contentLabelColor
        self.chatItemView.urgentView.isHidden = self.vm.urgentIconIsHidden
    }

    func setNoteLabel() {
        self.containerView.addSubview(self.noteLabel)
        self.noteLabel.text = self.vm.noteText
        self.noteLabel.isHidden = self.vm.isNoteTextHidden
    }

    func setInputView() {
        self.containerView.addSubview(self.fakeInputBackView)
        self.containerView.addSubview(self.replyInput)
        replyInput.sendCallBack = { [weak self] (text) in
            guard let `self` = self else { return }
            self.vm.sendReadMessage()
            self.vm.sendReplyMessage(text: text) { [weak self] success in
                guard let `self` = self else { return }
                guard let mainWindow = self.userResolver.navigator.mainSceneWindow else {
                    self.onDimiss()
                    return
                }
                if success {
                    UDToast.showSuccess(with: self.vm.replySuccessToast, on: mainWindow)
                    self.onDimiss()
                } else {
                    UDToast.showFailure(with: self.vm.replyFailToast, on: mainWindow)
                }
            }
        }

        replyInput.sendEmotionCallBack = { [weak self] (key) in
            guard let `self` = self else { return }
            self.vm.sendReadMessage()
            self.vm.sendReaction(key) { [weak self] success in
                guard let `self` = self else { return }
                guard let mainWindow = self.userResolver.navigator.mainSceneWindow else {
                    self.onDimiss()
                    return
                }
                if success {
                    UDToast.showSuccess(with: self.vm.replySuccessToast, on: mainWindow)
                    self.onDimiss()
                } else {
                    UDToast.showFailure(with: self.vm.replyFailToast, on: mainWindow)
                }
            }
        }
    }

    func setConstraints() {
        self.naviBar.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(Layout.naviBarHeight)
            make.left.right.top.equalToSuperview()
        }

        self.chatItemView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.naviBar.snp.bottom)
        }

        self.replyInput.snp.makeConstraints { make in
            make.width.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaInsets.top)
            make.height.equalTo(Layout.inputViewHeight)
        }

        self.fakeInputBackView.snp.makeConstraints { make in
            make.width.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaInsets.top)
            make.top.equalTo(self.replyInput.snp.bottom)
        }

        self.noteLabel.snp.makeConstraints { make in
            make.left.right.width.equalToSuperview()
            make.top.equalTo(self.chatItemView.snp.bottom).offset(Layout.noteLabelTop)
        }
    }

    func setUpLayout() {
        self.containerView.snp.remakeConstraints { make in
            if Self.isAlert(window: self.view.window) {
                /// iPad R 视图alert弹出
                make.edges.equalToSuperview()
            } else {
                make.top.equalTo(Layout.naviBarTop)
                make.left.bottom.right.equalToSuperview()
            }
        }
    }

    static func isAlert(window: UIWindow? = nil) -> Bool {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return false
        }
        if let window = window {
            return window.traitCollection.horizontalSizeClass == .regular
        }
        return false
    }

    enum Layout {
        static let naviBarHeight: CGFloat = 56
        static let naviBarTop: CGFloat = 165
        static let cornerRadius: CGFloat = 10
        static let padding: CGFloat = 14
        static let inputViewHeight: CGFloat = 62
        static let noteLabelTop: CGFloat = 17
        static let noteLabelFont: CGFloat = 14
        static let maskAlpha: CGFloat = 0.55
    }
}
