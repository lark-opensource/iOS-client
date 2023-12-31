//
//  EventDetailBottomActionComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/25.
//

import UIKit
import RxSwift
import LarkUIKit
import Foundation
import LarkCombine
import EENavigator
import LarkContainer
import UniverseDesignToast
import UniverseDesignActionPanel
import UniverseDesignDialog
import CalendarFoundation

final class EventDetailBottomActionComponent: UserContainerComponent {

    typealias ViewModel = EventDetailBottomActionViewModel

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private var bag = Set<AnyCancellable>()
    private let rxBag = DisposeBag()
    private let viewModel: ViewModel
    private var replyContainerVC: SwipeContainerViewController?

    init(viewModel: ViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(bottomBar)
        bottomBar.snp.edgesEqualToSuperView()

        bindViewModel()
        bindView()
    }

    private lazy var bottomBar: EventDetailBottomBar = {
        let view = EventDetailBottomBar()
        return view
    }()
}

extension EventDetailBottomActionComponent: BottomViewSharable {
    func provideView(for key: BottomViewSharableKey) -> UIView? {
        let map = [BottomViewSharableKey.bottomActionBar: bottomBar]
        return map[key]
    }
}

extension EventDetailBottomActionComponent {

    private func bindViewModel() {

        guard let viewController = viewController else { return }

        viewModel.route
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] route in
                guard let self = self, let viewController = self.viewController else { return }
                switch route {
                case let .url(url): self.userResolver.navigator.open(url, from: viewController)
                case let .replyVC(param): self.jumpToReply(param: param)
                case let .reTap(options): self.presentReTap(with: options)
                case let .replyEventSheet(status, spanConfirm): self.presentReplySheet(with: status, confirm: spanConfirm)
                case let .unableToJoin(title, message, clickTracer): self.presentUnableToJoin(title: title, message: message, clickTracer: clickTracer)
                }
            }.store(in: &bag)

        viewModel.viewData
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] viewData in
                guard let self = self,
                      let viewData = viewData else { return }
                var buttonDisplay: [ActionBarButtonForIG.ButtonType] = []
                if let rsvpTips = viewData.rsvpStatusString {
                    self.bottomBar.showRSVPStatusString(tips: rsvpTips)
                } else if viewData.showJoinButton {
                    if viewData.canJoinEvent {
                        buttonDisplay.append(.join)
                    } else {
                        self.bottomBar.showCantJoinLabel()
                    }
                } else {
                    switch viewData.status {
                    case .accept:
                        buttonDisplay.append(.hasAccepted)
                    case .decline:
                        buttonDisplay.append(.hasRejected)
                    case .tentative:
                        buttonDisplay.append(.hasBeenTentative)
                    case .needsAction:
                        buttonDisplay.append(.accept)
                        buttonDisplay.append(.reject)
                        buttonDisplay.append(.tentative)
                    @unknown default:
                        self.bottomBar.isHidden = true
                    }
                    let shouldDeleteReply = FeatureGating.shouldDeleteReply(userID: self.userResolver.userID)
                    if !shouldDeleteReply, viewData.showReplyEntrance {
                        self.bottomBar.appendReplyBtn()
                    }
                }
                self.bottomBar.setupButtons(with: buttonDisplay)
            }.store(in: &bag)

        viewModel.rxToast
            .bind(to: viewController.rx.toast)
            .disposed(by: rxBag)
    }

    private func bindView() {
        bottomBar.delegate = self
    }
}

extension EventDetailBottomActionComponent {
    private func jumpToReply(param: ViewModel.Route.ReplyVCParam) {

        guard let viewController = self.viewController else { return }

        let controller = EventReplyViewController(
            userResolver: self.userResolver,
            status: param.status,
            inviterCalendarId: param.inviterCalendarId,
            inviterlocalizedName: param.inviterlocalizedName,
            calendarId: param.calendarId,
            key: param.key,
            originalTime: param.originalTime,
            messageId: nil,
            traceContext: .init(eventID: self.viewModel.model.event?.serverID ?? "none",
                                startTime: self.viewModel.model.startTime ?? 0,
                                isRecurrence: self.viewModel.model.isRecurrence,
                                originalTime: Int(self.viewModel.model.originalTime),
                                uid: self.viewModel.model.key),
            isWebinar: viewModel.model.isWebinar,
            commpentSucess: { [weak self] (chatId) in
                guard let self = self else { return }
                CalendarTracer.shareInstance.rsvpReplyFromEventDetail()
                self.dismissReplyContainerVC(completion: {
                    self.calendarDependency?
                        .jumpToChatController(from: viewController,
                                              chatID: chatId,
                                              onError: {
                                                UDToast().showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: viewController.view)
                                              },
                                              onLeaveMeeting: {
                                                viewController.navigationController?.popToRootViewController(animated: true)
                                              })
                })
            })

        let containerVC = SwipeContainerViewController(subViewController: controller)
        self.replyContainerVC = containerVC
        containerVC.originY = 64 + UIApplication.shared.statusBarFrame.size.height / 2
        controller.dismiss = { [weak self] (_) in
            self?.dismissReplyContainerVC()
//            self?.replyMessage = replyComment
        }
        controller.changeEvent = { [weak self] event in
            self?.viewModel.refreshHandle.refresh(newEvent: event)
        }
        viewController.present(containerVC,
                               animated: true,
                               completion: { containerVC.setTapSwitch(isEnable: true) })
    }

    private func dismissReplyContainerVC(completion: (() -> Void)? = nil) {
        self.replyContainerVC?.dismiss(completion: completion)
    }

    private func presentReTap(with options: [ViewModel.Route.Option]) {
        guard let viewController = viewController as? CalendarController else { return }
        if Display.pad {
            let notificationOption = PopOverNotificationOption(sourceView: bottomBar,
                                                               sourceRect: bottomBar.bounds,
                                                               arrowDirection: .down,
                                                               delegate: viewController)
            options.forEach {
                notificationOption.addItem(title: $0.title, tapAction: $0.action)
            }
            viewController.present(notificationOption, animated: true, completion: nil)
        } else {
            let actionSheet = UDActionSheet(config: .init())
            options.forEach {
                actionSheet.addDefaultItem(text: $0.title, action: $0.action)
            }
            actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel)
            viewController.present(actionSheet, animated: true, completion: nil)
        }
    }

    private func presentUnableToJoin(title: String?, message: String?, clickTracer: (() -> Void)?) {
        let alertVC = UDDialog(config: UDDialogUIConfig())
        if let title = title {
            alertVC.setTitle(text: title)
        }
        if let message = message {
            alertVC.setContent(text: message)
        }
        alertVC.addPrimaryButton(text: I18n.Calendar_Common_GotIt, dismissCompletion: {
            clickTracer?()
        })
        viewController.present(alertVC, animated: true, completion: nil)
    }

    private func presentReplySheet(with status: CalendarEventAttendee.Status, confirm: @escaping (CalendarEvent.Span) -> Void) {

        guard let viewController = viewController as? CalendarController else {
            return
        }

        var onetime = ""
        var alltime = ""

        var thisType = CalendarOperationType.acceptThis
        var allType = CalendarOperationType.acceptAll
        switch status {
        case .accept:
            onetime = I18n.Calendar_Detail_AccpetThisEventOnly
            alltime = I18n.Calendar_Detail_AcceptAllEvents
            thisType = .acceptThis
            allType = .acceptAll
        case .decline:
            onetime = I18n.Calendar_Detail_DeclineThisEventOnly
            alltime = I18n.Calendar_Detail_DeclineAllEvents
            thisType = .refuseThis
            allType = .refuseAll
        case .tentative:
            onetime = I18n.Calendar_Detail_TentativeAcceptThisEventOnly
            alltime = I18n.Calendar_Detail_TentativeAcceptAllEvent
            thisType = .udmThis
            allType = .udmAll
        @unknown default:
            onetime = I18n.Calendar_Edit_UpdateThisEventOnly
            alltime = I18n.Calendar_Detail_UpdateAllEvent
        }

        let rsvpType: [CalendarEventAttendee.Status: String] = [.accept: "accept",
                                                                .decline: "reject",
                                                                .tentative: "not_determined"]

        let clickTrace = { (span: CalendarEvent.Span?) in
            CalendarTracerV2.RsvpConfirmForRepeatedEvent.traceClick {
                $0.type = rsvpType[status] ?? ""
                if let span = span {
                    $0.click("confirm")
                    $0.accept_type = span == .thisEvent ? "only_this" : "all"
                } else {
                    $0.click("cancel")
                }
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.viewModel.model.instance, event: self.viewModel.model.event))
            }
        }

        if Display.pad {

            var sourceView: UIView = bottomBar
            switch status {
            case .accept:
                sourceView = bottomBar.acceptBtn
            case .decline:
                sourceView = bottomBar.declineBtn
            case .tentative:
                sourceView = bottomBar.tentativeBtn
            @unknown default:
                sourceView = bottomBar
            }

            if sourceView.superview == nil {
                sourceView = bottomBar
            }

            let notificationOption = PopOverNotificationOption(sourceView: sourceView,
                                                               sourceRect: sourceView.bounds,
                                                               arrowDirection: .down,
                                                               delegate: viewController)
            notificationOption.addItem(title: onetime) {
                clickTrace(.thisEvent)
                confirm(.thisEvent)
            }
            notificationOption.addItem(title: alltime) {
                clickTrace(.allEvents)
                confirm(.allEvents)
            }
            viewController.present(notificationOption, animated: true, completion: nil)
        } else {
            let actionSheet = UDActionSheet(config: .init())
            actionSheet.setCancelItem(text: BundleI18n.Calendar.Calendar_Common_Cancel) {
                clickTrace(nil)
            }
            actionSheet.addDefaultItem(text: onetime) {
                clickTrace(.thisEvent)
                confirm(.thisEvent)
            }
            actionSheet.addDefaultItem(text: alltime) {
                clickTrace(.thisEvent)
                confirm(.allEvents)
            }
            viewController.present(actionSheet, animated: true, completion: nil)
        }

        CalendarTracerV2.RsvpConfirmForRepeatedEvent.traceView {
            $0.type = rsvpType[status] ?? ""
        }
    }
}

// MARK: - ReplyViewDelegate

extension EventDetailBottomActionComponent: EventDetailBottomBarDelegate {
    func actionBarDidTapAccept(_ bottomBar: EventDetailBottomBar) {
        viewModel.action(.changeStatus(status: .accept))
    }

    func actionBarDidTapDecline(_ bottomBar: EventDetailBottomBar) {
        viewModel.action(.changeStatus(status: .decline))
    }

    func actionBarDidTapTentative(_ bottomBar: EventDetailBottomBar) {
        viewModel.action(.changeStatus(status: .tentative))
    }

    func actionBarDidReTap(_ bottomBar: EventDetailBottomBar) {
        viewModel.action(.reTap)
    }

    func actionBarDidTapJoin(_ bottomBar: EventDetailBottomBar) {
        viewModel.action(.join)
    }

    func actionBarDidTapReply(_ bottomBar: EventDetailBottomBar, handle: (() -> Void)? = nil) {
        viewModel.action(.reply, handle: handle)
    }
}
