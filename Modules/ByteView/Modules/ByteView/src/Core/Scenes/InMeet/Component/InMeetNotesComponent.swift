//
//  InMeetNotesComponent.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/6/15.
//

import Foundation
import RxSwift
import ByteViewTracker
import ByteViewNetwork
import ByteViewCommon
import ByteViewUI

/// 会议纪要的会中容器，负责控制显示Onboarding、创建纪要提示以及议程开始提示等
final class InMeetNotesComponent: InMeetViewComponent, InMeetNotesDataListener {

    private weak var container: InMeetViewContainer?
    let disposeBag = DisposeBag()
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver

    weak var notesOnboarding: GuideDescriptor?

    weak var newNotesHint: GuideDescriptor?
    weak var dismissNewNotesHintWorkItem: DispatchWorkItem?

    weak var newAgendaHint: GuideDescriptor?
    weak var dismissNewAgendaHintWorkItem: DispatchWorkItem?

    var latestNotesInfo: NotesInfo?
    var shouldShowNewNotesHint: Bool = false

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.resolver = viewModel.resolver
        self.container = container
        self.meeting.notesData.addListener(self)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .notes
    }

    func containerWillAppear(container: InMeetViewContainer) {
        resolver.viewContext.post(.containerWillAppear)
    }

    func containerDidDisappear(container: InMeetViewContainer) {
        resolver.viewContext.post(.containerDidDisappear)
    }

    deinit {
        Toast.update(customInsets: .zero)
    }

    // MARK: - InMeetNotesDataListener

    func didChangeNotesInfo(_ notes: NotesInfo?, oldValue: NotesInfo?) {
        Util.runInMainThread { [weak self] in
            self?.handleNotesInfoChangeOnMainThread(notes, oldNotes: oldValue)
        }
    }

    // MARK: - Onboarding

    private var shouldShowNotesOnboarding: Bool {
        return isNotesEnabled && meeting.service.shouldShowGuide(.notesOnboarding)
    }

    private func showNotesOnboarding() {
        DispatchQueue.main.async { [weak self] in
            self?.showNotesOnboardingOnMainThread()
        }
    }

    private func showNotesOnboardingOnMainThread() {
        assert(Thread.isMainThread, "show notes onboarding called on non-main thread")
        guard isNotesEnabled, meeting.service.shouldShowGuide(.notesOnboarding) else { return }
        let guide = GuideDescriptor(type: .notesOnboarding,
                                    title: I18n.View_G_Notes_Onboarding,
                                    desc: I18n.View_G_Notes_OnboardingExplain)
        guide.style = .lightOnboarding
        guide.sureAction = { [weak self] in
            self?.meeting.service.didShowGuide(.notesOnboarding)
        }
        guide.afterSureAction = { [weak self] in
            guard let self = self else { return }
            // 如果需要展示newAgenda，当作显示过newNotes；如果不需要显示newAgenda，判断是否需要显示newNotes
            if self.meeting.shouldShowNewAgendaHint {
                self.showNewAgendaHint(self.latestNotesInfo)
                self.meeting.notesData.hasTriggeredAutoOpen = true
                self.shouldShowNewNotesHint = false
            } else if self.shouldShowNewNotesHint {
                self.showNewNotesHint()
                self.shouldShowNewNotesHint = false
            }
        }
        notesOnboarding = guide
        GuideManager.shared.request(guide: guide)
    }

    private func dismissNotesOnboarding() {
        GuideManager.shared.dismissGuide(with: .notesOnboarding)
        self.notesOnboarding?.sureAction?()
        self.notesOnboarding = nil
    }

    // MARK: - New Notes Hint

    /// 由于入会时推送不保证顺序，无法判断会前是否有纪要；
    /// 三端统一采用这种方法判断是否需要显示新纪要提示：“创建纪要”的Tips仅在入会后 1 秒内可以提示
    var canShowNewNotesHint: Bool {
        if let date = notesProviderVM?.enterMeetingDate {
            let now = Date().timeIntervalSince1970
            return (now - date) < 1.0
        } else {
            return false
        }
    }

    private func showNewNotesHint() {
        guard canShowNewNotesHint else { return }
        self.shouldShowNewNotesHint = false
        meeting.notesData.hasTriggeredAutoOpen = true
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            let isHostOrCoHost = self.meeting.myself.isHost || self.meeting.myself.isCoHost || self.meeting.type == .call
            self.showNewNotesHintOnMainThread(isHostOrCoHost: isHostOrCoHost)
        }
    }

    private func showNewNotesHintOnMainThread(isHostOrCoHost: Bool) {
        assert(Thread.isMainThread, "show new notes hint for host or cohost called on non-main thread")
        guard isNotesEnabled else { return }
        // 如果是单流放大则先关闭
        if let isSingleVideoVisible = self.container?.context.isSingleVideoVisible,
           isSingleVideoVisible,
           !VCScene.supportsMultipleScenes {
            self.hideSingleVideo()
        }
        // 移除当前的提示的Guide
        dismissNewNotesHint()
        // 创建新Guide
        let guide = GuideDescriptor(type: .newNotesHint, title: nil, desc: isHostOrCoHost ? I18n.View_M_ViewAgendaKnowDiscussion_Tooltip : I18n.View_M_ViewAgenda_Tooltip)
        guide.style = .darkPlain
        guide.sureAction = { [weak self] in
            self?.meeting.notesData.hasTriggeredAutoOpen = true
            self?.newNotesHint = nil
        }
        // 设定6秒后移除
        // 无法使用duration，需要自定义关闭，否则第二个相同类型的guide显示时，会跟着第一个guide一起dismiss
        // guide.duration = 5
        let dismissNewNotesHintWorkItem = DispatchWorkItem { [weak self, weak guide] in
            guard let self = self, let type = guide?.type else { return }
            GuideManager.shared.dismissGuide(with: type)
            guide?.sureAction?()
            self.newNotesHint = nil
            self.dismissNewNotesHintWorkItem = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: dismissNewNotesHintWorkItem)
        // 显示新Guide，存储指针
        GuideManager.shared.request(guide: guide)
        self.newNotesHint = guide
        self.dismissNewNotesHintWorkItem = dismissNewNotesHintWorkItem
    }

    private func dismissNewNotesHint() {
        self.dismissNewNotesHintWorkItem?.cancel()
        GuideManager.shared.dismissGuide(with: .newNotesHint)
        self.newNotesHint?.sureAction?()
        self.newNotesHint = nil
        self.dismissNewNotesHintWorkItem = nil
    }

    // MARK: - New Agenda Hint

    private func showNewAgendaHint(_ notesInfo: NotesInfo?) {
        Util.runInMainThread { [weak self] in
            self?.showNewAgendaHintOnMainThread(notesInfo)
        }
    }

    private func showNewAgendaHintOnMainThread(_ notesInfo: NotesInfo?) {
        assert(Thread.isMainThread, "show new agenda hint called on non-main thread")
        if let isSingleVideoVisible = self.container?.context.isSingleVideoVisible,
           isSingleVideoVisible,
           !VCScene.supportsMultipleScenes {
            self.hideSingleVideo()
        }
        guard let notes = notesInfo else { return }
        self.showNewAgendaHintOnMainThread(notes.activatingAgenda.title)
    }

    private func showNewAgendaHintOnMainThread(_ agendaTitle: String) {
        assert(Thread.isMainThread, "show new agenda hint called on non-main thread")
        guard isNotesEnabled else { return }
        meeting.shouldShowNewAgendaHint = false
        if Display.pad, !isNotesSceneInavtive { return }
        // 移除当前的提示的Guide
        dismissNewNotesHint()
        dismissNewAgendaHint()
        // 创建新Guide
        let guide = GuideDescriptor(type: .newAgendaHint,
                                    title: I18n.View_G_Notes_CurrentAgenda,
                                    desc: agendaTitle)
        guide.style = .stressedPlain
        // 设定5秒后移除
        // 无法使用duration，需要自定义关闭，否则第二个相同类型的guide显示时，会跟着第一个guide一起dismiss
        // guide.duration = 5
        let dismissNewAgendaHintWorkItem = DispatchWorkItem { [weak self, weak guide] in
            guard let self = self, let type = guide?.type else { return }
            GuideManager.shared.dismissGuide(with: type)
            guide?.sureAction?()
            self.newAgendaHint = nil
            self.dismissNewAgendaHintWorkItem = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: dismissNewAgendaHintWorkItem)
        // 显示新Guide，存储指针
        GuideManager.shared.request(guide: guide)
        self.newAgendaHint = guide
        self.dismissNewAgendaHintWorkItem = dismissNewAgendaHintWorkItem
    }

    private func dismissNewAgendaHint() {
        self.dismissNewAgendaHintWorkItem?.cancel()
        GuideManager.shared.dismissGuide(with: .newAgendaHint)
        self.newAgendaHint?.sureAction?()
        self.newAgendaHint = nil
        self.dismissNewAgendaHintWorkItem = nil
    }

    private func hideSingleVideo() {
        // 单流放大场景下展示提示时，恢复到会中视图
        if let component = container?.component(by: .singleVideo) as? InMeetSingleVideoComponent {
            component.hideSingleVideo(animated: true)
        }
    }

    /// 支持会议纪要，如果是私有化互通、FG关闭、webinar会议、面试会议或者加密会议则隐藏入口
    private var isNotesEnabled: Bool {
        return meeting.setting.isMeetingNotesEnabled && !meeting.setting.isCrossWithKa && meeting.subType != .webinar && !meeting.isInterviewMeeting && !meeting.isE2EeMeeing
    }

    // 纪要Scene不可见
    // 如果支持分屏，进入下面判断；如果不支持分屏，直接显示（老版本iPad走iPhone逻辑）
    // 如果有纪要Scene，判断是否是前台活跃，不是则提示
    // 如果没有纪要Scene，一定没有展开纪要，则直接提示
    // 需要确保在主线程调用!!!
    private var isNotesSceneInavtive: Bool {
        if #available(iOS 13.0, *) {
            if let validNotesScene = VCScene.connectedScene(scene: InMeetNotesKeyDefines.generateNotesSceneInfo(with: meeting.meetingId)),
               validNotesScene.activationState == .foregroundActive {
                if let ws = meeting.router.window?.windowScene, ws.session == validNotesScene.session, !meeting.router.isFloating { // 独占Scene，且会议全屏
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

    private func handleNotesInfoChangeOnMainThread(_ newNotes: NotesInfo?, oldNotes: NotesInfo?) {
        // 保证主线程执行
        assert(Thread.isMainThread, "handle notes info change called on non-main thread")
        // 保证有纪要权限
        guard isNotesEnabled else { return }
        self.latestNotesInfo = newNotes
        self.shouldShowNewNotesHint = checkShouldShowNewNotesHint(newNotes, oldNotes: oldNotes)
        // 显示彩色Notes按钮
        if checkShouldShowColorfulNotesButton {
            notesButtonTurnToColorful()
        }
        // 如果没有notes信息，检查是否需要显示或正在显示Onboarding
        if newNotes == nil {
            if shouldShowNotesOnboarding {
                showNotesOnboarding()
                return
            } else if notesOnboarding != nil {
                return
            }
        }
        let showHintsClosure: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            if self.shouldShowNotesOnboarding { // 如果要显示Onboarding：显示Onboarding
                self.showNotesOnboarding()
            } else if self.notesOnboarding != nil { // 如果正在显示Onboarding：什么都不做
                // do nothing
            } else { // 如果不要显示Onboarding，判断是否要显示newAgenda
                if self.meeting.shouldShowNewAgendaHint { // 要显示newAgenda：显示newAgenda，当作显示了newNotes
                    // 显示newAgenda
                    self.showNewAgendaHint(newNotes)
                    // 当作显示了newNotes
                    self.meeting.notesData.hasTriggeredAutoOpen = true
                    self.shouldShowNewNotesHint = false
                } else if self.shouldShowNewNotesHint { // 要显示newNotes
                    // 显示newNotes
                    self.showNewNotesHint()
                    self.shouldShowNewNotesHint = false
                }
            }
        }
        if VCScene.supportsMultipleScenes { // 支持分屏
            if !meeting.notesData.hasTriggeredAutoOpen { // 需要自动分屏
                if isNotesSceneInavtive { // 没有在显示的Notes的分屏：隐藏Onboarding，newNotes，newAgenda，当作显示过Onboarding，newNotes，newAgenda，分屏
                    showHintsClosure()
                }
            } else { // 不需要自动分屏
                if shouldShowNotesOnboarding { // 如果要显示Onboarding：显示Onboarding
                    showNotesOnboarding()
                } else if notesOnboarding != nil { // 如果正在显示Onboarding：什么都不做
                    // do nothing
                } else { // 如果不要显示Onboarding，判断是否要显示newAgenda
                    if meeting.shouldShowNewAgendaHint, isNotesSceneInavtive { // 要显示newAgenda：显示newAgenda，当作显示了newNotes
                        // 显示newAgenda
                        showNewAgendaHint(newNotes)
                        // 当作显示了newNotes
                        meeting.notesData.hasTriggeredAutoOpen = true
                        shouldShowNewNotesHint = false
                    }
                }
            }
        } else { // 不支持分屏
            showHintsClosure()
        }
    }

    private func checkShouldShowNewNotesHint(_ newNotes: NotesInfo?, oldNotes: NotesInfo?) -> Bool {
        // 如果是新纪要，展示提示
        if let validNewNotes = newNotes,
           URL(string: validNewNotes.notesURL) != nil,
           oldNotes == nil,
           !meeting.notesData.hasTriggeredAutoOpen {
            return true
        }
        // 如果是重新创建了纪要，相当于更新了数据，重置自动打开标记，并展示提示
        if let newNotesUrl = newNotes?.notesURL,
           let oldNotesUrl = oldNotes?.notesURL,
           !newNotesUrl.isEmpty,
           !oldNotesUrl.isEmpty,
           newNotesUrl != oldNotesUrl {
            meeting.notesData.hasTriggeredAutoOpen = false
            return true
        }
        return false
    }

    var checkShouldShowColorfulNotesButton: Bool {
        guard isMyAINotesGuideOn else { return false }
        return meeting.shouldShowColorfulNotesButton
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

    /// 纪要按钮变彩色
    /// 若会议侧边栏未展开，用户首次入会会给予提示
    private func notesButtonTurnToColorful() {
        Logger.notes.info("notesButtonTurnToColorful")
        container?.context.isNotesButtonColorful = true
    }

}
