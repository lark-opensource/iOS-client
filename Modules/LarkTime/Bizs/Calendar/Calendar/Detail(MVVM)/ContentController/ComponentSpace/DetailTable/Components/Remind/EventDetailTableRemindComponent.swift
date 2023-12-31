//
//  EventDetailTableRemindComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import UIKit
import LarkCombine
import LarkContainer
import CalendarFoundation

final class EventDetailTableRemindComponent: UserContainerComponent {

    let viewModel: EventDetailTableRemindViewModel
    var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailTableRemindViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(remindView)
        remindView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            remindView.viewData = viewData
        }

        viewModel.viewData
            .assignUI(to: \.viewData, on: remindView)
            .store(in: &bag)
    }

    private lazy var remindView: EventDetailTableRemindView = {
        let remindView = EventDetailTableRemindView()
        return remindView
    }()
}
