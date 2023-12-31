//
//  InMeetReactionComponent.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/11.
//

import UIKit
import ByteViewCommon

final class InMeetReactionComponent: InMeetViewComponent {
    let componentIdentifier: InMeetViewComponentIdentifier = .reaction
    private let meeting: InMeetMeeting
    private let reactionContainerView: ReactionContainerView
    private let containerView: UIView
    private weak var container: InMeetViewContainer?
    private let interactionViewModel: FloatingInteractionViewModel
    private var reactionGuideToken: MeetingLayoutGuideToken?
    private let subtitle: InMeetSubtitleViewModel
    private weak var subtitleComponent: InMeetSubtitleComponent?

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.container = container
        self.meeting = viewModel.meeting
        self.interactionViewModel = viewModel.resolver.resolve()!
        self.subtitle = viewModel.resolver.resolve()!
        self.reactionContainerView = ReactionContainerView(emotion: viewModel.service.emotion,
                                                           animator: self.interactionViewModel.floatConfig.animator)
        self.containerView = container.loadContentViewIfNeeded(for: .reaction)

        self.reactionContainerView.dataSource = self
        self.interactionViewModel.addListener(self)
        viewModel.viewContext.addListener(self, for: [.hideReactionBubble])
    }

    func containerDidLoadComponent(container: InMeetViewContainer) {
        subtitleComponent = container.component(by: .subtitle) as? InMeetSubtitleComponent
    }

    func setupConstraints(container: InMeetViewContainer) {
        let reactionGuideToken = container.layoutContainer.requestLayoutGuide { anchor, ctx in
            if anchor == .bottomShareBar {
                return .none
            }
            return InMeetOrderedLayoutGuideQuery(topAnchor: .topSafeArea, bottomAnchor: .bottomSketchBar).verticalRelationWithAnchor(anchor, context: ctx)
        }
        self.reactionGuideToken = reactionGuideToken
        let reactionGuide = reactionGuideToken.layoutGuide

        containerView.addSubview(reactionContainerView)
        reactionContainerView.snp.makeConstraints { make in
            make.top.left.right.equalTo(reactionGuide)
            make.bottom.equalTo(reactionGuide).offset(-4)
        }
    }

    func viewLayoutContextWillChange(to layoutContext: VCLayoutContext) {
        reactionContainerView.viewLayoutContextWillChange(to: layoutContext)
    }

    func viewLayoutContextDidChanged() {
        reactionContainerView.viewLayoutContextDidChange()
    }
}

extension InMeetReactionComponent: FloatingInteractionViewModelDelegate {
    func didReceiveNewReaction(reactionMessage: ReactionMessage) {
        let isFromInterview = meeting.isInterviewMeeting
        let isInterviewer = isFromInterview && (meeting.myself.role == .interviewer || meeting.myself.role == .unknown)

        let sender: String
        let avatar: AvatarInfo
        if isFromInterview && !isInterviewer && (reactionMessage.userRole == .interviewer || reactionMessage.userRole == .unknown) {
            avatar = .asset(AvatarResources.interviewer)
            sender = I18n.View_M_Interviewer
        } else if reactionMessage.avatarInfo.isEmpty && reactionMessage.userType == .neoGuestUser {
            // 正常情况下后端应该填充 avatar_key, 此处增加兼容逻辑，避免争议
            avatar = .asset(AvatarResources.guest)
            sender = reactionMessage.userName
        } else {
            avatar = reactionMessage.avatarInfo
            sender = reactionMessage.userName
        }

        switch meeting.setting.reactionDisplayMode {
        case .floating:
            let delay = Int.random(in: 0..<5) * 100
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) { [weak self] in
                self?.reactionContainerView.addReaction(userID: reactionMessage.userId,
                                                        sender: sender,
                                                        reactionKey: reactionMessage.reactionKey,
                                                        count: reactionMessage.count,
                                                        duration: reactionMessage.duration)
            }
        case .bubble:
            guard let component = container?.component(by: .messageBubble) as? InMeetMessageBubbleComponent else { return }
            component.bubbleContainerView.addReaction(userID: reactionMessage.userId,
                                                      sender: sender,
                                                      avatar: avatar,
                                                      reactionKey: reactionMessage.reactionKey,
                                                      count: reactionMessage.count,
                                                      duration: reactionMessage.duration)
        }
    }
}

extension InMeetReactionComponent: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .hideReactionBubble:
            reactionContainerView.hideOtherUserReaction(currentUserId: meeting.userId)
        default:
            break
        }
    }
}

extension InMeetReactionComponent: ReactionContainerViewDataSource {
    var subtitleFrame: CGRect? {
        guard let view = subtitleComponent?.floatingSubtitleController?.floatingContainerView,
              let superview = view.superview, !view.isHidden else { return nil }
        return superview.convert(view.frame, to: reactionContainerView)
    }
}
