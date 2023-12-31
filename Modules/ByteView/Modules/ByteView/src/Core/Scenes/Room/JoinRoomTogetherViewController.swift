//
//  JoinRoomTogetherViewController.swift
//  ByteView
//
//  Created by kiri on 2022/4/13.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewUI
import ByteViewCommon
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewTracker

protocol JoinRoomTogetherViewControllerDelegate: AnyObject {
    func didConnectRoom(_ controller: UIViewController, room: ByteviewUser)
    func didDisconnectRoom(_ controller: UIViewController?, room: ByteviewUser)
    func joinRoomViewControllerDidAppear(_ controller: JoinRoomTogetherViewController)
    func joinRoomViewControllerWillDisappear(_ controller: JoinRoomTogetherViewController)
    func joinRoomViewControllerDidChangeStyle(_ controller: JoinRoomTogetherViewController, style: JoinRoomViewStyle)
}

extension JoinRoomTogetherViewControllerDelegate {
    func joinRoomViewControllerDidAppear(_ controller: JoinRoomTogetherViewController) {}
    func joinRoomViewControllerWillDisappear(_ controller: JoinRoomTogetherViewController) {}
    func joinRoomViewControllerDidChangeStyle(_ controller: JoinRoomTogetherViewController, style: JoinRoomViewStyle) {}
}

final class JoinRoomTogetherViewController: VMViewController<JoinRoomTogetherViewModel> {
    weak var delegate: JoinRoomTogetherViewControllerDelegate?
    private lazy var contentView: JoinRoomContentView = {
        let view = JoinRoomContentView(style: style)
        view.delegate = self
        return view
    }()

    @RwAtomic
    private(set) var style: JoinRoomViewStyle = .phone

    private let containerView = UIView()
    private let keyboardAssistView = UIView()

    override func setupViews() {
        containerView.backgroundColor = .clear
        view.addSubview(keyboardAssistView)
        view.addSubview(containerView)

        keyboardAssistView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        containerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        containerView.addSubview(contentView)
    }

    override func bindViewModel() {
        if !viewModel.fromAutoScan, viewModel.state != .connected {
            viewModel.scan()
        }
        updateStyle()
        // 监听
        self.viewModel.delegate = self
        self.viewModel.trackShowPopover()

        NotificationCenter.default.addObserver(self, selector: #selector(willChangeKeyboardFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.joinRoomViewControllerDidAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.joinRoomViewControllerWillDisappear(self)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let hasBottomSafeArea = self.view.safeAreaInsets.bottom > 0
        if self.contentView.hasBottomSafeArea != hasBottomSafeArea {
            self.contentView.hasBottomSafeArea = hasBottomSafeArea
            if self.style == .phone {
                self.updateContentSize()
            }
        }
    }

    private var lastLayoutSubviewsSize: CGSize = .zero
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.lastLayoutSubviewsSize != self.view.frame.size {
            self.lastLayoutSubviewsSize = self.view.frame.size
            updateContentSize()
        }
    }

    private var popoverHeight: CGFloat = 100
    private var ggHeight: CGFloat = 100
    private func updateContentSize(animationCoordinator: AnimationCoordinator? = nil, from: String = #function) {
        guard isAvailable else { return }
        if style == .popover {
            var height = self.contentView.fitContentHeight(maxWidth: 320)
            if let w = self.view.window {
                height = min(height, w.bounds.height - 89)
            }
            if height != self.popoverHeight {
                logger.info("preferredContentHeight is \(height)")
                self.popoverHeight = height
                self.updateDynamicModalSize(CGSize(width: 320, height: height))
            }
        } else {
            let keyboardHeight = self.keyboardHeightInContentView
            let contentHeight = self.contentView.fitContentHeight(maxWidth: self.view.frame.width)
            let height = contentHeight + keyboardHeight
            if height > 0, self.ggHeight != height {
                self.ggHeight = height
                if let animationCoordinator = animationCoordinator {
                    animationCoordinator.animate { [weak self] in
                        self?.panViewController?.updateBelowLayout()
                        self?.panViewController?.view.layoutIfNeeded()
                    }
                } else {
                    self.panViewController?.updateBelowLayout()
                }
                logger.info("ggHeight changed to \(height), keyboard = \(keyboardHeight)")
            }
        }
    }

    private var keyboardHeightInContentView: CGFloat = 0
    private var keyboardHeightInWindow: CGFloat = 0
    @objc private func willChangeKeyboardFrame(_ notification: Notification) {
        guard let w = self.view.window, let userInfo = notification.userInfo,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let from = w.screen.coordinateSpace
        self.keyboardHeightInWindow = max(0, w.bounds.height - w.convert(endFrame, from: from).minY)
        self.keyboardHeightInContentView = max(0, self.keyboardAssistView.bounds.height - self.keyboardAssistView.convert(endFrame, from: from).minY)
        if self.style == .popover {
            self.updateContentSize()
        } else {
            let animationCoordinator = AnimationCoordinator()
            animationCoordinator.animate { [weak self] in
                guard let self = self else { return }
                self.keyboardAssistView.snp.updateConstraints { make in
                    make.height.equalTo(self.keyboardHeightInContentView)
                }
            }
            self.updateContentSize(animationCoordinator: animationCoordinator)
            let options = UIView.AnimationOptions(rawValue: curveValue << 16)
            animationCoordinator.run(withDuration: duration, delay: 0, options: options)
        }
    }

    private func updateStyle() {
        guard isViewLoaded, isAvailable else { return }
        logger.info("updateStyle: \(style)")
        self.resetContentViewLayout()
        self.contentView.style = style
        self.contentView.updateRoomInfo(viewModel)
        self.view.backgroundColor = style == .popover ? .ud.bgFloat : .ud.bgBody
    }

    private func resetContentViewLayout() {
        if style == .popover {
            let topInset: CGFloat = popoverPresentationController?.permittedArrowDirections == .up ? 13 : 0
            let bottomInset: CGFloat = popoverPresentationController?.permittedArrowDirections == .down ? 13 : 0
            contentView.snp.remakeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0))
            }
        } else {
            contentView.snp.remakeConstraints { make in
                make.left.right.top.equalToSuperview()
                if viewModel.state == .roomFound(.roomNeedVerify) {
                    make.bottom.equalTo(keyboardAssistView.snp.top)
                }
                make.bottom.equalToSuperview().priority(.high)
            }
        }
    }

    @objc private func didClickClose(_ sender: UIButton) {
        Logger.ui.info("didClickClose")
        handleWillDismissSelf()
        self.viewModel.cancelScanning()
        self.dismissSelf()
    }

    @objc private func didClickJoin(_ sender: UIButton) {
        self.viewModel.trackConnectWhenPreview()
        if self.viewModel.state == .roomFound(.roomNeedVerify) {
            self.viewModel.gotoVerifyCode()
            return
        }
        self.viewModel.trackConnect()
        guard let room = self.viewModel.room else {
            Logger.ui.warn("didClickJoin ignored, room is nil")
            self.dismissSelf()
            return
        }
        Logger.ui.info("didClickJoin")
        self.viewModel.connectRoom()
        self.delegate?.didConnectRoom(self, room: room)
    }

    @objc private func didClickScanAgain(_ sender: UIButton) {
        Logger.ui.info("didClickScanAgain")
        self.viewModel.trackRescan()
        self.viewModel.scan()
    }

    private func didClickDisconnect() {
        handleWillDismissSelf()
        self.viewModel.trackDisconnect()
        guard let room = self.viewModel.room else {
            Logger.ui.warn("didClickDisconnect ignored, room is nil")
            self.dismissSelf()
            return
        }
        Logger.ui.info("didClickDisconnect")
        let delegate = self.delegate
        if viewModel.shouldDoubleCheckDisconnection {
            ByteViewDialog.Builder()
                .colorTheme(.redLight)
                .title(I18n.View_G_ConfirmRoomDisconnect_Title)
                .message(I18n.View_G_ConfirmRoomDisconnect_Desc)
                .leftTitle(I18n.View_MV_CancelButtonTwo)
                .leftHandler({
                    $0.dismiss()
                })
                .rightTitle(I18n.View_MV_Disconnect_Button)
                .rightHandler({ [weak self, weak delegate] alert in
                    self?.viewModel.trackDisconnectConfirm()
                    self?.viewModel.disconnectRoom()
                    delegate?.didDisconnectRoom(self, room: room)
                    self?.dismissSelf()
                    alert.dismiss()
                })
                .id(.disconnectRoom)
                .needAutoDismiss(true)
                .show()
        } else {
            viewModel.disconnectRoom()
            delegate?.didDisconnectRoom(self, room: room)
            self.dismissSelf()
        }
    }

    @RwAtomic private var isAvailable = true
    private func handleWillDismissSelf() {
        isAvailable = false
        viewModel.delegate = nil
    }

    /// for example: auto connected after verify code success
    private func didJoinAutomatically() {
        logger.info("didJoinAutomatically")
        if let room = viewModel.room {
            delegate?.didConnectRoom(self, room: room)
        }
    }

    private func dismissSelf() {
        self.presentingViewController?.dismiss(animated: true)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        viewModel.supportedInterfaceOrientations
    }
}

extension JoinRoomTogetherViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        let style: JoinRoomViewStyle = isRegular ? .popover : .phone
        if style != self.style {
            self.style = style
            self.updateStyle()
            self.delegate?.joinRoomViewControllerDidChangeStyle(self, style: style)
        }
    }
}

extension JoinRoomTogetherViewController: PanChildViewControllerProtocol {
    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        let bottomOffset: CGFloat = VCScene.safeAreaInsets.bottom > 0 ? 0 : 12
        // + barView 12pt
        return .contentHeight(ggHeight + bottomOffset + 12)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }
}

extension JoinRoomTogetherViewController: JoinRoomTogetherViewModelDelegate {
    func roomStateDidChange() {
        reloadRoomInfo()
    }

    func roomInfoDidUpdate() {
        reloadRoomInfo()
    }

    func roomVerifyCodeStateDidChange() {
        reloadRoomInfo()
    }

    private func reloadRoomInfo(from: String = #function) {
        Util.runInMainThread { [weak self] in
            guard let self = self, self.isAvailable else { return }
            self.logger.info("reloadData for \(from)")
            if self.viewModel.state == .connected {
                self.didJoinAutomatically()
            }
            self.resetContentViewLayout()
            self.contentView.updateRoomInfo(self.viewModel)
            self.updateContentSize()
        }
    }
}

extension JoinRoomTogetherViewController: JoinRoomContentViewDelegate {
    func roomContentViewDidClickScanAgain(_ view: UIView, sender: UIButton) {
        viewModel.scan()
    }

    func roomContentViewDidClickJoin(_ view: UIView, sender: UIButton) {
        didClickJoin(sender)
    }

    func roomContentViewDidClickDisconnect(_ view: UIView) {
        didClickDisconnect()
    }

    func roomContentViewDidClickClose(_ view: UIView, sender: UIButton) {
        didClickClose(sender)
    }

    func roomContentViewDidChangeVerifyCode(_ view: UIView, verifyCode: String) {
        viewModel.onVerifyCodeChanged(verifyCode)
    }
}
