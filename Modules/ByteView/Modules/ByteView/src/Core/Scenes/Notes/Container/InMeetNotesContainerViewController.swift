//
//  InMeetNotesContainerViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/5/29.
//

import Foundation
import ByteViewUI
import ByteViewNetwork
import ByteViewCommon

protocol InMeetNotesContainerChangeDelegate: AnyObject {

    func didChangeNotesInfo(to notesInfo: NotesInfo?, from oldValue: NotesInfo?)

    func didTapCloseButton()

    /// 创建中展示Toast提示
    func showLoadingState(_ isOn: Bool)

    /// 创建失败展示Toast提示
    func showCreateFailedToast()

}

extension InMeetNotesContainerChangeDelegate {
    func didChangeNotesInfo(to notesInfo: NotesInfo?, from oldValue: NotesInfo?) {}
    func didTapCloseButton() {}
}

class InMeetNotesContainerViewController: VMViewController<InMeetNotesContainerViewModel>, InMeetNotesContainerChangeDelegate, RouterListener, InMeetNotesEventDelegate, InMeetMeetingListener {

    var toast: Toast.ToastOperator?
    var isSceneReady = !VCScene.supportsMultipleScenes {
        didSet {
            guard isSceneReady != oldValue else { return }
            if isSceneReady {
                Logger.notes.info("will request latest data")
                requestDataIfNeeded()
            } else {
                Logger.notes.info("will pause data update")
                pauseDataIfNeeded()
            }
        }
    }

    /// 文档嵌套容器的导航容器
    let navigationWrapperViewController: NavigationController = {
        let nav = NavigationController()
        nav.interactivePopDisabled = true
        nav.navigationBar.isHidden = true
        return nav
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        navigationWrapperViewController.supportedInterfaceOrientations
    }

    @objc
    private func closeSelf(_ animated: Bool = true) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
                VCScene.closeScene(InMeetNotesKeyDefines.generateNotesSceneInfo(with: self.viewModel.meeting.meetingId))
            } else {
                self.navigationController?.popToRootViewController(animated: false)
                self.popOrDismiss(animated)
                self.viewModel.meeting.router.setWindowFloating(false, animated: animated)
                self.viewModel.meeting.notesData.setNotesOn(false)
            }
        }
    }

    func setRootVC(_ rootVC: UIViewController, animated: Bool = true) {
        navigationWrapperViewController.setViewControllers([rootVC], animated: false)
    }

    override func setupViews() {
        viewModel.meeting.router.addListener(self)

        isNavigationBarHidden = true
        addChild(navigationWrapperViewController)
        view.addSubview(navigationWrapperViewController.view)
        navigationWrapperViewController.view.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        navigationWrapperViewController.didMove(toParent: self)

        viewModel.meeting.addListener(self)
    }

    override func bindViewModel() {
        viewModel.notesContainerChangeDelegate = self
        requestDataIfNeeded()
    }

    func requestDataIfNeeded() {
        if isViewLoaded, isSceneReady {
            viewModel.requestLatestNotes()
        }
    }

    func pauseDataIfNeeded() {
        viewModel.pauseDataIfNeeded()
    }

    // MARK: - InMeetNotesContainerChangeDelegate

    func didChangeNotesInfo(to notesInfo: NotesInfo?, from oldValue: NotesInfo?) {
        Logger.notes.info("notesContainerVC didChangeNotesInfo: \(notesInfo) from: \(oldValue)")
        Util.runInMainThread { [weak self] in
            self?.updateNotesInfo(notesInfo, oldValue: oldValue)
        }
    }

    private func updateNotesInfo(_ notesInfo: NotesInfo?, oldValue: NotesInfo?) {
        Logger.notes.info("updateNotesInfo: \(notesInfo) from: \(oldValue)")
        if let newNotes = notesInfo, URL(string: newNotes.notesURL) != nil {
            // 生成会议纪要页面并切换为root
            Logger.notes.info("will set new rootVC")
            if let oldNotes = oldValue, URL(string: oldNotes.notesURL) != nil, newNotes.notesURL == oldNotes.notesURL {
                Logger.notes.info("will update notes") // update 为NotesVM内部逻辑，容器不处理
            } else {
                let notesVM = InMeetNotesViewModel(meeting: viewModel.meeting, resolver: viewModel.resolver)
                let notesVC = InMeetNotesViewController(viewModel: notesVM)
                notesVM.notesEventDelegate = self
                setRootVC(notesVC, animated: false)
            }
        }
    }

    func didTapCloseButton() {
        Logger.notes.info("did tap notes close button")
        closeSelf()
    }

    func showLoadingState(_ isOn: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if isOn {
                self.toast = Toast.showLoading(I18n.View_VM_Loading, in: self.view)
            } else {
                self.toast?.hideLoading()
            }
        }
    }

    func showCreateFailedToast() {
        Util.runInMainThread {
            Toast.show(I18n.View_G_Notes_FailToast)
        }
    }

    // MARK: - RouterListener

    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if !isFloating, !VCScene.supportsMultipleScenes {
                self.closeSelf()
            }
        }
    }

    // MARK: - InMeetNotesEventDelegate

    func didTapCloseButtonNotesEvent() {
        closeSelf()
    }

    // MARK: - InMeetMeetingListener

    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        closeSelf(false)
    }
}
