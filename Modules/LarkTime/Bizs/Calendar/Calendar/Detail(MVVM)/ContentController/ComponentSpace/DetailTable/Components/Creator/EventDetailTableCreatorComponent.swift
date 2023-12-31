//
//  EventDetailTableCreatorComponent.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import UIKit
import LarkCombine
import LarkContainer
import CalendarFoundation

final class EventDetailTableCreatorComponent: UserContainerComponent {

    let viewModel: EventDetailTableCreatorViewModel
    var bag: Set<AnyCancellable> = []

    init(viewModel: EventDetailTableCreatorViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.snp.makeConstraints { (make) in
            make.height.equalTo(42)  // 内容高度 22， 上下 padding 20
        }

        view.addSubview(creatorView)
        creatorView.snp.edgesEqualToSuperView()

        bindViewModel()
    }

    private func bindViewModel() {
        if let viewData = viewModel.viewData.value {
            creatorView.viewData = viewData
        }

        viewModel.viewData
            .assignUI(to: \.viewData, on: creatorView)
            .store(in: &bag)
    }

    private lazy var creatorView: EventDetailTableCreatorView = {
        let creatorView = EventDetailTableCreatorView()
        return creatorView
    }()
}
