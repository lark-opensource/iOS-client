//
//  EventDetailTableWebinarAudienceComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2022/10/24.
//

import UIKit
import SnapKit
import RxSwift
import LarkCombine
import LarkContainer
import CalendarFoundation
import UniverseDesignIcon

final class EventDetailTableWebinarAudienceComponent: UserContainerComponent {

    let viewModel: EventDetailTableWebinarAudienceViewModel
    var bag: Set<AnyCancellable> = []
    var currentShowingView: UIView?

    init(viewModel: EventDetailTableWebinarAudienceViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
                self?.jumpToAttendees(route)
            }.store(in: &bag)
    }

    private lazy var audienceView: EventDetailTableWebinarAudienceView = {
        let view = EventDetailTableWebinarAudienceView()
        view.onClick = { [weak self] in
            guard let self = self else { return }
            self.viewModel.tap()
        }
        return view
    }()

    private lazy var loadingView: UIView = {
        let view = DetailSingleLineCell()
        view.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.communityTabOutlined).renderColor(with: .n3))
        view.setText(BundleI18n.Calendar.Calendar_Common_LoadingCommon)
        return view
    }()

    private lazy var hiddenView: UIView = {
        let view = DetailSingleLineCell()
        view.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.communityTabOutlined).renderColor(with: .n3))
        view.setText(BundleI18n.Calendar.Calendar_Detail_HiddenGuestList)
        return view
    }()
}

extension EventDetailTableWebinarAudienceComponent {
    private func buildUI(with data: EventDetailTableWebinarViewModel.ViewData) {
        let targetView: UIView
        switch data {
        case .loading:
            targetView = loadingView
        case .hidden:
            targetView = hiddenView
        case let .attendee(viewData):
            audienceView.viewData = viewData
            targetView = audienceView
        }
        if currentShowingView != targetView && !view.subviews.contains(targetView) {
            currentShowingView?.removeFromSuperview()
            view.addSubview(targetView)
            targetView.snp.edgesEqualToSuperView()
        }
        currentShowingView = targetView
    }

    private func jumpToAttendees(_ route: EventDetailTableWebinarAudienceViewModel.Route) {
         guard let viewController = self.viewController else { return }
         if case let .attendees(viewModel) = route {
             let vc = EventAttendeeListViewController(viewModel: viewModel, userResolver: self.userResolver)
             vc.isFromDetail = true
             viewController.navigationController?.pushViewController(vc, animated: true)
         }
     }
}
