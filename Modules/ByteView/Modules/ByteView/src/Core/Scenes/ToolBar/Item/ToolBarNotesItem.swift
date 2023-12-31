//
//  ToolBarNotesItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/13.
//

import Foundation
import ByteViewCommon
import ByteViewSetting
import ByteViewUI

final class ToolBarNotesItem: ToolBarItem, InMeetViewChangeListener, NotesCollaboratorAvatarListener {
    override func initialize() {
        resolver.viewContext.addListener(self, for: [.notesButtonChangeColor])
        notesProviderVM?.addListener(self)
    }

    override var itemType: ToolBarItemType {
        .notes
    }

    override var title: String {
        I18n.View_G_Notes_Button
    }

    override var titleColor: ToolBarColorType {
        let titleColors = [UIColor(red: 0.278, green: 0.322, blue: 0.902, alpha: 1.0),
                           UIColor(red: 0.812, green: 0.369, blue: 0.812, alpha: 1.0)]
        let isInMore = actualPadLocation == .more || phoneLocation == .more
        return isAnimationOn ? isInMore ? .none : .pureColor(color: .ud.textDisabled)
        : isColorful ? .obliqueGradientColor(colors: titleColors) : .none
    }

    override var filledIcon: ToolBarIconType {
        return isColorful ? .image(BundleResources.ByteView.notes) : .icon(key: .fileLinkDocxFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        return isColorful ? .image(BundleResources.ByteView.notes_w) : .icon(key: .fileLinkWordOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        guard isNotesEnabled else {
            return .none
        }
        return .navbar
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        guard isNotesEnabled else {
            return .none
        }
        return .right
    }

    override func clickAction() {
        Logger.notes.info("topBarComponent did click notes button")
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if !self.meeting.notesData.hasCreatedNotes, !self.meeting.setting.canCreateNotes {
                Toast.show(I18n.View_G_HostForbidThis_Tooltip)
                return
            }
            self.setColorfulNotesButtonTapped()
            if !self.meeting.notesData.hasCreatedNotes {
                if self.isMyAINotesGuideOn {
                    self.createAndOpenEmptyNotes()
                } else {
                    self.createAndOpenEmptyNotes()
                }
            } else {
                if VCScene.supportsMultipleScenes {
                    self.openNotesOnPad()
                } else {
                    self.openNotesOnPhone()
                }
            }
        }
    }

    private func setColorfulNotesButtonTapped() {
        meeting.shouldShowColorfulNotesButton = false
        isColorful = false
        notifyListeners()
    }

    // MARK: - Private Functions

    /// 创建并打开空白纪要
    private func createAndOpenEmptyNotes() {
        meeting.shouldShowColorfulNotesButton = false
        meeting.notesData.hasTriggeredAutoOpen = true
        changeAnimationStateTo(true)
        meeting.httpClient.notes.createNotes(meeting.meetingId,
                                             templateToken: "",
                                             templateId: "",
                                             locale: BundleI18n.currentLanguage.identifier.lowercased(),
                                             timeZone: TimeZone.current.identifier, completion: { [weak self] result in
            self?.changeAnimationStateTo(false)
            switch result {
            case .success(let rsp):
                Logger.notes.info("createNotes succeeded, response: \(rsp)")
                Util.runInMainThread { [weak self] in
                    if VCScene.supportsMultipleScenes {
                        self?.openNotesOnPad()
                    } else {
                        self?.openNotesOnPhone()
                    }
                }
            case .failure(let error):
                Logger.notes.info("createNotes failed, error: \(error)")
            }
        })
    }

    /// iPhone打开纪要
    private func openNotesOnPhone() {
        Logger.notes.info("will openNotesOnPhone")
        NotesTracks.trackClickNotesNavigationBar(on: .notes, isOpen: true)
        NotesTracks.trackShowNotes(with: meeting.notesData.notesInfo?.notesURL, fromSource: .notesButton)
        meeting.router.setWindowFloating(true)
        let notesContainerVM = InMeetNotesContainerViewModel(meeting: self.meeting, resolver: resolver)
        let notesContainerVC = InMeetNotesContainerViewController(viewModel: notesContainerVM)
        notesContainerVC.modalPresentationStyle = .fullScreen
        self.meeting.larkRouter.present(notesContainerVC, animated: false)
        self.meeting.notesData.setNotesOn(true)
    }

    /// iPad打开纪要
    private func openNotesOnPad() {
        Logger.notes.info("will openNotesOnPad")
        NotesTracks.trackShowNotes(with: meeting.notesData.notesInfo?.notesURL, fromSource: .notesButton)
        if #available(iOS 13, *) {
            let provider = resolver.resolve(InMeetNotesProviderViewModel.self)
            self.meeting.router.openByteViewScene(sceneInfo: InMeetNotesKeyDefines.generateNotesSceneInfo(with: meeting.meetingId),
                                                  actionCallback: { action in
                                                      switch action {
                                                      case .close:
                                                          NotesTracks.trackClickNotesNavigationBar(on: .notes, isOpen: false)
                                                      case .floatingVC, .open, .reopen:
                                                          NotesTracks.trackClickNotesNavigationBar(on: .notes, isOpen: true)
                                                      default:
                                                          break
                                                      }
                                                  }, completion: { [weak provider] window, error in
                                                      Logger.notes.info("openScene completed, window: \(window), error: \(error)")
                                                      provider?.notesContainerVC?.isSceneReady = true
                                                  })
        } else {
            Logger.notes.warn("operation skipped, iOS version < 13, cant open scene")
        }
    }

    /// 控制纪要loading动画开关
    private func changeAnimationStateTo(_ isAnimationOn: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.isAnimationOn = isAnimationOn
            if let toolBarNotesView = self.provider?.itemView(with: .notes) as? ToolBarItemView {
                if isAnimationOn {
                    toolBarNotesView.startAnimation()
                } else {
                    toolBarNotesView.stopAnimation()
                }
            } else {
                Logger.notes.error("change notesItem animation state failed")
            }
        }
    }

    /// 支持会议纪要，如果是私有化互通、FG关闭、webinar会议、面试会议或者加密会议则隐藏纪要入口
    private var isNotesEnabled: Bool {
        meeting.setting.isMeetingNotesEnabled
        && !meeting.setting.isCrossWithKa
        && meeting.subType != .webinar
        && !meeting.isInterviewMeeting
        && !meeting.isE2EeMeeing
    }

    private lazy var notesProviderVM: InMeetNotesProviderViewModel? = {
        return resolver.resolve(InMeetNotesProviderViewModel.self)
    }()

    /// 是否允许显示 MyAI 在 Notes 的引导
    private var isMyAINotesGuideOn: Bool {
        meeting.setting.isMyAIAllEnabled
        && meeting.setting.isNotesMyAIGuideEnabled
        && !meeting.service.shouldShowGuide(.myAIOnboarding)
        && meeting.setting.isRecordEnabled
        && (notesProviderVM?.inMeetGenerateMeetingSummaryInDocs ?? false)
    }

    /// 纪要按钮icon和标题是否显示彩色
    var isColorful: Bool = false {
        didSet {
            if isColorful != oldValue {
                notifyListeners()
            }
        }
    }

    /// 纪要按钮是否显示loading
    var isAnimationOn: Bool = false {
        didSet {
            if isAnimationOn != oldValue {
                notifyListeners()
            }
        }
    }

    // MARK: - InMeetViewChangeListener

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .notesButtonChangeColor, let isColorful = userInfo as? Bool {
            if isColorful != self.isColorful {
                self.isColorful = isColorful
            }
        }
    }

    // MARK: - NotesCollaboratorAvatarListener

    var notesCollaboratorsInfo: NotesCollaboratorInfo? {
        notesProviderVM?.currentNotesCollaboratorInfo
    }

    func didChangeNotesCollaborators(_ info: NotesCollaboratorInfo?) {
        Logger.notes.info("did change notes collaborator info to: \(info)")
        guard Display.pad else { return }
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if let toolBarNotesView = self.provider?.itemView(with: .notes) as? PadToolBarNotesView {
                toolBarNotesView.collaboratorsInfo = info ?? .default
            } else {
                Logger.notes.error("found NO toolBarNotesView")
            }
            self.notifyListeners()
        }
    }
}
