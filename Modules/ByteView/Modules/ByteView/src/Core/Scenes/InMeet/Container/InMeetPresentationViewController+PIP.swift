//
//  InMeetPresentationViewController+PIP.swift
//  ByteView
//
//  Created by eesh-macmini-automation on 2022/9/29.
//

import Foundation
import ByteViewRtcBridge
import ByteViewUI

extension InMeetPresentationViewController {

    private var pip: PIPManager {
        viewModel.meeting.pip
    }

    private var defaultAcitveFrame: CGRect {
        CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
    }

    func registerPIP() {
        guard pip.isEnabled else { return }
        pip.addObserver(self)
        // 不能隐藏或者 frame zero，否则无法唤起 PIP
        let activeView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        activeView.isUserInteractionEnabled = false
        view.addSubview(activeView)
        pip.setup(with: viewModel.meeting.router.pipActiveView)
    }

    func unregisterPIP() {
        pip.removeObserver(self)
        pip.reset()
    }

    private var window: UIWindow? {
        if #available(iOS 13, *) {
            return VCScene.windowScene?.windows.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    func movePiPActiveViewToWindow() {
        guard let activeView = pip.activeView else {
            return
        }
        window?.addSubview(activeView)
    }

    func movePiPActiveViewBack() {
        guard let activeView = pip.activeView else {
            return
        }
        view.addSubview(activeView)
    }

    /// 控制画中画退出时过场动画
    /// 全屏时居中收束
    /// 窗口化时指向窗口
    private func updateRestoreTargetFrame() {
        if viewModel.viewContext.scope == .fullScreen {
            pip.activeView?.frame = defaultAcitveFrame
            pip.activeView?.center = view.center
        } else {
            pip.activeView?.frame = view.bounds
        }
    }
}

extension InMeetPresentationViewController: PIPObserver {
    func pictureInPictureWillStart() {
        let vc = PIPContainerViewController(viewModel: viewModel)
        pip.attach(vc: vc)
        updateRestoreTargetFrame()
        viewModel.viewContext.floatingWindowSize = vc.view.frame.size
    }

    func pictureInPictureDidStop() {
        pip.detach()
        pip.activeView?.frame = defaultAcitveFrame
    }

    func pictureInPictureRestoreUserInterface(completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}

class PIPContainerViewController: FloatingContainerViewController {
    override func createInMeetingVC() -> FloatingInMeetingViewController {
        let floatingViewController = FloatingInMeetingViewController(viewModel: InMeetFloatingViewModel(resolver: viewModel.resolver), isPIPFloatingVC: true)
        return floatingViewController
    }
}
