//
//  EventDetailTableCalendarComponent.swift
//  Calendar
//
//  Created by Rico on 2021/3/27.
//

import UIKit
import LarkCombine
import LarkContainer
import CalendarFoundation

final class EventDetailTableCalendarComponent: UserContainerComponent {
    let viewModel: EventDetailTableCalendarViewModel
    var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailTableCalendarViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(calendarView)
        calendarView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {

        if let viewData = viewModel.viewData.value {
            calendarView.viewData = viewData
        }

        viewModel.viewData
            .assignUI(to: \.viewData, on: calendarView)
            .store(in: &bag)

    }

    private lazy var calendarView: EventDetailTableCalendarView = {
        return EventDetailTableCalendarView()
    }()
}
