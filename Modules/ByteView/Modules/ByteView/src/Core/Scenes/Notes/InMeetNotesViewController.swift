//
//  InMeetNotesViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation
import ByteViewUI
import ByteViewNetwork

class InMeetNotesViewController: VMViewController<InMeetNotesViewModel>, InMeetNotesChangeDelegate {

    lazy var navigationWrapperViewController: UINavigationController = {
        return viewModel.meeting.service.ccm.createLkNavigationController()
    }()

    let navigationWrapperView: UIView = {
        let view = UIView()
        return view
    }()

    override func bindViewModel() {
        viewModel.notesChangeDelegate = self
        viewModel.startDataObservation()
    }

    override func setupViews() {
        isNavigationBarHidden = true
        view.addSubview(navigationWrapperView)
        navigationWrapperView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }

        addChild(navigationWrapperViewController)
        navigationWrapperView.addSubview(navigationWrapperViewController.view)
        navigationWrapperViewController.didMove(toParent: self)

        navigationWrapperViewController.view.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }

        viewModel.meeting.notesData.hasTriggeredAutoOpen = true
    }

    override var shouldAutorotate: Bool {
        navigationWrapperViewController.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        navigationWrapperViewController.supportedInterfaceOrientations
    }

    // MARK: - InMeetNotesChangeDelegate

    func didChangeNotes(to runtime: NotesRuntime?) {
        Logger.notes.info("in notesVC, did change notes to: \(runtime)")
        if VCScene.supportsMultipleScenes, isNotesSceneInavtive { return }
        if let notesRuntime = runtime {
            Logger.notes.info("notesVC received notes: \(notesRuntime)")
            Util.runInMainThread { [weak self] in
                guard let meeting = self?.viewModel.meeting, let self = self else {
                    Logger.notes.info("replace notes failed due to invalid self")
                    return
                }
                let wrapperVC = NotesWrapperViewController(notesRuntime: notesRuntime, meeting: meeting)
                self.navigationWrapperViewController.setViewControllers([wrapperVC], animated: false)
            }
        } else {
            Logger.notes.warn("notesVC received invlaid notes info")
        }
    }

    func didTapQuickShareButton() {
        guard viewModel.canQuickShare else {
            Toast.showOnVCScene(I18n.View_G_CantShareNoPermission_Tooltip, in: self.view)
            return
        }
        let isSharingContent: Bool = viewModel.meeting.shareData.isSharingContent
        ByteViewDialog.Builder()
            .id(.notesQuickShare)
            .needAutoDismiss(true)
            .colorTheme(.followSystem)
            .title(isSharingContent ? I18n.View_G_ConfirmStopandShareMeetingNotes_Desc : I18n.View_G_ConfirmShareMeetingNotes_Desc)
            .leftTitle(I18n.View_G_CancelNoShare_Button)
            .leftHandler({ _ in
                Logger.notes.debug("notesQuickShare alert, tapped cancel")
            })
            .rightTitle(isSharingContent ? I18n.View_G_ContinuetoShare_Button : I18n.View_G_ShareNotes_Button)
            .rightHandler({ [weak self] _ in
                Logger.notes.debug("notesQuickShare alert, tapped confirm, isSharingContent: \(isSharingContent)")
                guard let self = self, let notesUrl = self.viewModel.meeting.notesData.notesInfo?.notesURL else { return }
                NotesTracks.trackClickNotesQuickShareAlert(isSharingContent, fileUrl: self.viewModel.meeting.notesData.notesInfo?.notesURL ?? "")
                self.viewModel.meeting.httpClient.follow.startShareDocument(notesUrl,
                                                                            meetingId: self.viewModel.meeting.meetingId,
                                                                            lifeTime: .ephemeral,
                                                                            initSource: .initDirectly,
                                                                            authorityMask: nil,
                                                                            breakoutRoomId: nil) { [weak self] rsp in
                    switch rsp {
                    case .success:
                        self?.viewModel.notesEventDelegate?.didTapCloseButtonNotesEvent()
                    case .failure(let error):
                        Logger.notes.error("quick share notes failed, error: \(error.toErrorCode())")
                    }
                }
            })
            .show(animated: true, in: self)
    }

    deinit {
        Logger.notes.info("InMeetNotesVC.deinit")
    }

    // 纪要Scene不可见
    // 如果支持分屏，进入下面判断；如果不支持分屏，直接显示（老版本iPad走iPhone逻辑）
    // 如果有纪要Scene，判断是否是前台活跃，不是则提示
    // 如果没有纪要Scene，一定没有展开纪要，则直接提示
    // 需要确保在主线程调用!!!
    private var isNotesSceneInavtive: Bool {
        if #available(iOS 13.0, *) {
            if let validNotesScene = VCScene.connectedScene(scene: InMeetNotesKeyDefines.generateNotesSceneInfo(with: viewModel.meeting.meetingId)),
               validNotesScene.activationState == .foregroundActive {
                if let ws = viewModel.meeting.router.window?.windowScene, ws.session == validNotesScene.session, !viewModel.meeting.router.isFloating { // 独占Scene，且会议全屏
                    return true
                }
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }

}
