//
//  EventDetailTableFreeBusyComponent.swift
//  Calendar
//
//  Created by Rico on 2021/10/8.
//

import UIKit
import LarkCombine
import LarkContainer
import CalendarFoundation

final class EventDetailTableFreeBusyComponent: UserContainerComponent {

    let viewModel: EventDetailTableFreeBusyViewModel
    var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailTableFreeBusyViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.snp.makeConstraints { (make) in
            make.height.equalTo(42)
        }

        view.addSubview(freeBusyView)
        freeBusyView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            freeBusyView.viewData = viewData
        }

        viewModel.viewData
            .assignUI(to: \.viewData, on: freeBusyView)
            .store(in: &bag)
    }

    private lazy var freeBusyView: EventDetailTableFreeBusyView = {
        let freeBusyView = EventDetailTableFreeBusyView()
        return freeBusyView
    }()
}
