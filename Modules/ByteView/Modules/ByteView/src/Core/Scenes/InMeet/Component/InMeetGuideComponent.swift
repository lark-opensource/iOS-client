//
//  InMeetGuideComponent.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/8/10.
//

import Foundation

final class InMeetGuideComponent: InMeetViewComponent {

    /// 横竖屏/RC切换时，referenceView布局会延后于屏幕变化的系统通知，延后0.5秒再更新显示GuideView
    static let rotationDuration: CGFloat = 0.5
    /// 会议纪要的Onboarding、新建纪要提示以及议程开始提示的distance参数
    static let distanceForNotesHints: CGFloat = -4

    var componentIdentifier: InMeetViewComponentIdentifier = .guide

    private weak var guideView: GuideView?
    private weak var container: InMeetViewContainer?
    private let view: UIView
    private let toolBarViewModel: ToolBarViewModel
    private let topBarViewModel: InMeetTopBarViewModel

    private var blockFullScreenToken: BlockFullScreenToken? {
        didSet {
            guard oldValue !== blockFullScreenToken else {
                return
            }
            oldValue?.invalidate()
        }
    }

    private var currentLayoutType: LayoutType

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.view = container.loadContentViewIfNeeded(for: .guide)
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        self.toolBarViewModel = viewModel.resolver.resolve()!
        self.topBarViewModel = viewModel.resolver.resolve()!
        GuideManager.shared.addListener(self)
        toolBarViewModel.addListener(self)

        NotificationCenter.default.addObserver(self, selector: #selector(handlePadToolbarLayoutFinish), name: .padToolBarFinishedLayout, object: nil)
    }

    // MARK: - Private

    private func setupGuideView() {
        guard self.guideView == nil else { return }
        let guideView = GuideView(frame: view.bounds)
        view.addSubview(guideView)
        guideView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.guideView = guideView
    }

    private func removeGuideView() {
        guideView?.removeFromSuperview()
        blockFullScreenToken = nil
        guideView = nil
    }

    private func hideGuideView() {
        guard let guideView = guideView else {
            return
        }
        guideView.isHidden = true
    }

    // 横竖屏/RC切换时，referenceView布局会延后于屏幕变化的系统通知，referenceView为空时，guideView位置会显示在左上角
    // 目前规避方式是，先隐藏guideView，待0.5秒后再显示guideView，此时referenceView已经布局完成（能拿到正确的frame）
    private func updateGuideOnScreenChange() {
        hideGuideView()
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.rotationDuration) { [weak self] in
            self?.guideView?.isHidden = false
            self?.updateCurrentGuide()
        }
    }

    private func updateCurrentGuide() {
        guard let current = GuideManager.shared.currentShowingGuide,
              let guideView = guideView,
              let referenceView = referenceView(for: current.type) else {
            GuideManager.shared.checkGuide()
            return
        }
        guideView.updateLayout(referenceView: referenceView, distance: distance(for: current.type), arrowDirection: arrowDirection(for: current.type))
    }

    private func referenceView(for guideType: GuideType) -> UIView? {
        switch guideType {
        case .askHostForHelp: return toolBarItemView(for: .askHostForHelp)
        case .rejoinBreakoutRoom: return toolBarItemView(for: .rejoinBreakoutRoom)
        case .breakoutRoomHostControl: return toolBarItemView(for: .breakoutRoomHostControl)
        case .vote: return toolBarItemView(for: .vote)
        case .countDown: return toolBarItemView(for: .countDown)
        case .countDownFold:
            guard let component = container?.component(by: .topBar) as? InMeetTopBarComponent else { return nil }
            return component.topBar.countDownFoldGuideReferenceView
        case .more: return toolBarItemView(for: .more)
        case .liveReachMaxParticipant: return toolBarItemView(for: .live)
        case .interpretation: return toolBarItemView(for: .interpretation)
        case .hostControl: return toolBarItemView(for: .security)
        case .padChangeSceneMode, .resetOrder:
            return referenceViewForPadSwitchSceneButton()
        case .customOrder:
            return UIView()
        case .interviewPromotion: return toolBarItemView(for: .interviewPromotion)
        case .interviewSpace: return toolBarItemView(for: .interviewSpace)
        case .webinarAttendee: return toolBarItemView(for: .handsup)
        case .notesOnboarding, .newNotesHint, .newAgendaHint: return toolBarItemView(for: .notes)
        case .transcribe: return toolBarItemView(for: .transcribe)
        case .micLocation: return toolBarItemView(for: .microphone)
        case .myai:
            if Display.pad, let component = container?.component(by: .topBar) as? InMeetTopBarComponent {
                return component.topBar.myAIButton
            } else {
                return toolBarItemView(for: .myai)
            }
        case .security: return toolBarItemView(for: .security)
        default: return nil
        }
    }

    private func referenceViewForPadSwitchSceneButton() -> UIView? {
        guard let component = container?.component(by: .topBar) as? InMeetTopBarComponent else {
           return nil
        }
        let btn = component.topBar.padSwitchSceneButton
        if btn.superview != nil {
            return btn
        }
        return nil
    }

    private func distance(for guideType: GuideType) -> CGFloat? {
        switch guideType {
        case .countDownFold, .micLocation: return 4
        case .newNotesHint, .notesOnboarding, .newAgendaHint: return Display.pad ? 4 : Self.distanceForNotesHints
        default: return nil
        }
    }

    private func arrowDirection(for guideType: GuideType) -> TriangleView.Direction {
        switch guideType {
        case .countDownFold: return .bottom
        case .padChangeSceneMode, .resetOrder: return .bottom
        case .notesOnboarding, .newNotesHint, .newAgendaHint: return Display.pad ? .top : .bottom
        case .myai: return Display.pad ? .bottom : .top
        default: return currentLayoutType.isPhoneLandscape ? .bottom : .top
        }
    }

    private func toolBarItemView(for type: ToolBarItemType) -> UIView? {
        toolBarViewModel.itemOrContainerView(with: type)
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
        if oldContext.layoutType != newContext.layoutType || newContext.layoutChangeReason.isOrientationChanged {
            updateGuideOnScreenChange()
        }
    }

    @objc
    private func handlePadToolbarLayoutFinish() {
        updateCurrentGuide()
    }
}


extension InMeetGuideComponent: GuideManagerDelegate {
    func guideCanShow(_ guide: GuideDescriptor) -> Bool {
        guard checkShouldShowGuide(guide), let view = referenceView(for: guide.type) else { return false }

        setupGuideView()
        self.blockFullScreenToken = self.container?.fullScreenDetector.requestBlockAutoFullScreen()

        let style: GuideStyle
        switch guide.style {
        case .darkPlain: style = .darkPlain(content: guide.desc ?? "")
        case .plain: style = .plain(content: guide.desc ?? "", title: guide.title)
        case .lightOnboarding: style = .lightOnboarding(content: guide.desc ?? "", title: guide.title)
        case .alert: style = .alert(content: guide.desc ?? "", title: guide.title, config: nil)
        case .focusPlain: style = .focusPlain(content: guide.desc ?? "")
        case .alertWithAnimation: style = .alertWithAnimation(content: guide.desc ?? "", title: guide.title ?? "", animationName: guide.animationName ?? "")
        case .stressedPlain: style = .stressedPlain(content: guide.desc ?? "", title: guide.title ?? "")
        }
        guideView?.sureAction = { [weak self] _ in
            self?.removeGuideView()
            guide.sureAction?()
        }
        let guideType = guide.type
        guideView?.setStyle(style,
                            on: arrowDirection(for: guideType),
                            of: view,
                            distance: distance(for: guideType))
        return true
    }

    func guideShouldRemove(_ guide: GuideDescriptor) {
        guideView?.sure()
    }

    func checkShouldShowGuide(_ guide: GuideDescriptor) -> Bool {
        switch guide.type {
        case .newNotesHint, .newAgendaHint: // 是纪要相关提示则放行，否则走老逻辑
            return true
        default:
            return !toolBarViewModel.isExpanded
        }
    }
}

extension InMeetGuideComponent: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        updateCurrentGuide()
    }
}
