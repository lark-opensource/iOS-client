//
//  EventDetailTableOrganizerComponent.swift
//  Calendar
//
//  Created by Rico on 2021/3/30.
//

import UIKit
import LarkCombine
import LarkContainer
import RxSwift
import CalendarFoundation

final class EventDetailTableOrganizerComponent: UserContainerComponent {

    @ScopedInjectedLazy
    var calendarDependency: CalendarDependency?

    @ScopedInjectedLazy
    var calendarApi: CalendarRustAPI?

    let viewModel: EventDetailTableOrganizerViewModel
    var bag: Set<AnyCancellable> = []
    let rxBag = DisposeBag()
    var currentShownView: UIView?

    // 实际内容高度 32，上下 padding/margin 20
    let viewHeight = 32 + 20

    init(viewModel: EventDetailTableOrganizerViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(viewHeight)
        }

        bindViewModel()
    }

    private func bindViewModel() {
        self.buildUI(with: viewModel.viewData.value)

        viewModel.viewData
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] (viewData) in
                self?.buildUI(with: viewData)
            }.store(in: &bag)

        viewModel.route
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] route in
                self?.jumpToProfile(route)
            }.store(in: &bag)
    }

    private lazy var contactView: EventDetailTableOrganizerView = {
        let creatorView = EventDetailTableOrganizerView()
        creatorView.tapAction = { [weak self] in
            self?.viewModel.tap()
        }
        return creatorView
    }()

    private lazy var emailView: EventDetailTableOrganizerEmailView = {
        let emailView = EventDetailTableOrganizerEmailView()
        return emailView
    }()

    private lazy var cannotGetInfoView: DetailCannotGetBookerInfoMeetingRoomCell = {
        let cannotGetInfoView = DetailCannotGetBookerInfoMeetingRoomCell()
        return cannotGetInfoView
    }()
}

extension EventDetailTableOrganizerComponent {
    private func buildUI(with data: EventDetailTableOrganizerViewModel.ViewData) {
        let targetView: UIView
        switch data {
        case .cannotGetInfo:
            targetView = cannotGetInfoView
        case let .email(data):
            targetView = emailView
            emailView.viewData = data
        case let .contact(data):
            targetView = contactView
            contactView.viewData = data
        case .notDecision:
            return
        }
        if currentShownView != targetView && !view.subviews.contains(targetView) {
            currentShownView?.removeFromSuperview()
            view.addSubview(targetView)
            targetView.snp.edgesEqualToSuperView()
        }
        currentShownView = targetView
    }

    private func jumpToProfile(_ route: EventDetailTableOrganizerViewModel.Route) {
        guard let viewController = self.viewController else { return }
        if case let .profile(calendarId, eventTitle) = route {
            CalendarTracer.shareInstance.calShowUserCard(actionSource: .eventDetail)
            guard let api = self.calendarApi else { return }
            self.calendarDependency?.jumpToAttendeeProfile(calendarApi: api, attendeeCalendarID: calendarId, eventTitle: eventTitle, from: viewController, bag: rxBag)
        }
        if case let .profileWithChatterID(chatterID, eventTitle) = route {
            self.calendarDependency?.jumpToProfile(chatterId: chatterID, eventTitle: eventTitle, from: viewController)
        }
    }
}
