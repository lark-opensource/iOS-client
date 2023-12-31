//
//  EventDetailTableAttendeeComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/6.
//

import UIKit
import LarkCombine
import SnapKit
import LarkContainer
import RxSwift
import CalendarFoundation

final class EventDetailTableAttendeeComponent: UserContainerComponent {

    let viewModel: EventDetailTableAttendeeViewModel
    var bag: Set<AnyCancellable> = []
    let rxBag = DisposeBag()
    var currentShownView: UIView?

    init(viewModel: EventDetailTableAttendeeViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bindViewModel()

        CalendarTracer.shareInstance.calShowAttendeeList(actionSource: .eventDetail)
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
                self?.jumpToAttendees(route)
            }.store(in: &bag)
    }

    private lazy var hiddenView: DetailHiddenAttendeeCell = {
        let view = DetailHiddenAttendeeCell()
        return view
    }()

    private lazy var attendeeView: DetailAttendeeCell = {
        let attendeeView = DetailAttendeeCell()
        attendeeView.onClick = { [weak self] in
            guard let self = self else { return }
            self.viewModel.tap()
        }
        return attendeeView
    }()
}

extension EventDetailTableAttendeeComponent {
    private func buildUI(with data: EventDetailTableAttendeeViewModel.ViewData) {
        let targetView: UIView
        switch data {
        case .hidden:
            targetView = hiddenView
        case let .attendee(data):
            targetView = attendeeView
            attendeeView.viewData = data
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

    private func jumpToAttendees(_ route: EventDetailTableAttendeeViewModel.Route) {
        guard let viewController = self.viewController else { return }
        if case let .attendees(viewModel) = route {
            CalendarTracer.shareInstance.calShowAttendeeList(actionSource: .eventDetail)
            ReciableTracer.shared.recStartCheckAttendee()

            let vc = EventAttendeeListViewController(viewModel: viewModel, userResolver: self.userResolver)
            vc.isFromDetail = true
            viewController.navigationController?.pushViewController(vc, animated: true)

            ReciableTracer.shared.recEndCheckAttendee()
        }
    }
}
