//
//  EventDetailTableVisibilityComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import UIKit
import LarkCombine
import LarkContainer
import CalendarFoundation

final class EventDetailTableVisibilityComponent: UserContainerComponent {

    let viewModel: EventDetailTableVisibilityViewModel
    var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailTableVisibilityViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.snp.makeConstraints { (make) in
            make.height.equalTo(42)
        }

        view.addSubview(visibilityView)
        visibilityView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            visibilityView.viewData = viewData
        }

        viewModel.viewData
            .assignUI(to: \.viewData, on: visibilityView)
            .store(in: &bag)
    }

    private lazy var visibilityView: EventDetailTableVisibilityView = {
        let remindView = EventDetailTableVisibilityView()
        return remindView
    }()
}
