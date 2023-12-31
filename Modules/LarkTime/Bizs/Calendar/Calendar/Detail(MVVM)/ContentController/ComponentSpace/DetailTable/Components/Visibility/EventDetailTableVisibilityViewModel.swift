//
//  EventDetailTableVisibilityViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import Foundation
import LarkCombine
import LarkContainer
import RxSwift

final class EventDetailTableVisibilityViewModel: EventDetailComponentViewModel {

    let viewData = CurrentValueSubject<EventDetailTableVisibilityViewDataType?, Never>(nil)

    let disposeBag = DisposeBag()
    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel.subscribe(onNext: { [weak self] model in
            guard let self = self,
                  let event = model.event else { return }
            self.buildViewData(with: event)
        })
        .disposed(by: disposeBag)
    }
}

extension EventDetailTableVisibilityViewModel {
    struct ViewData: EventDetailTableVisibilityViewDataType {
        let visibility: String
    }

    private func buildViewData(with event: EventDetail.Event) {
        let data = ViewData(visibility: getVisibilityString(with: event))
        viewData.send(data)
    }
}

extension EventDetailTableVisibilityViewModel {
    func getVisibilityString(with event: EventDetail.Event) -> String {
        switch event.visibility {
        case .default:
            return BundleI18n.Calendar.Calendar_Edit_DefalutVisibility
        case .public:
            return BundleI18n.Calendar.Calendar_Edit_Public
        case .private:
            return BundleI18n.Calendar.Calendar_Edit_Private
        }
    }
}
