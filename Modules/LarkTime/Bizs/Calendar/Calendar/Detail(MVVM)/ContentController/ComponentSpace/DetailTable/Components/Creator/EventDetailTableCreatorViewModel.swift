//
//  EventDetailTableCreatorViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import Foundation
import LarkContainer
import LarkCombine
import RxSwift
import RxRelay

final class EventDetailTableCreatorViewModel: EventDetailComponentViewModel {

    @ContextObject(\.rxModel) var rxModel

    let viewData = CurrentValueSubject<EventDetailTableCreatorViewDataType?, Never>(nil)
    let disposeBag = DisposeBag()

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {

        rxModel
            .compactMap { $0.event }
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                self.buildViewData(with: event)
            }).disposed(by: disposeBag)
    }
}

extension EventDetailTableCreatorViewModel {
    struct ViewData: EventDetailTableCreatorViewDataType {
        let creatorInfo: String
    }

    private func buildViewData(with event: EventDetail.Event) {
        let data = ViewData(creatorInfo: getCreatorString(with: event))
        viewData.send(data)
    }
}

extension EventDetailTableCreatorViewModel {
    func getCreatorString(with event: EventDetail.Event) -> String {
        let creatorInfo = BundleI18n.Calendar.Calendar_Detail_CreatedBy(creator: event.creator.displayName)
        return creatorInfo
    }
}
