//
//  EventDetailTableFreeBusyViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/10/8.
//

import Foundation
import LarkCombine
import LarkContainer
import RxSwift

final class EventDetailTableFreeBusyViewModel: EventDetailComponentViewModel {

    var model: EventDetailModel { rxModel.value }
    let viewData = CurrentValueSubject<EventDetailTableFreeBusyViewDataType?, Never>(nil)
    private let disposeBag = DisposeBag()

    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {
        rxModel.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.buildViewData()
        })
        .disposed(by: disposeBag)
    }
}

extension EventDetailTableFreeBusyViewModel {
    struct ViewData: EventDetailTableFreeBusyViewDataType {
        let freeBusyString: String
    }

    private func buildViewData() {
        let data = ViewData(freeBusyString: getFreeBusyString())
        viewData.send(data)
    }
}

extension EventDetailTableFreeBusyViewModel {
    func getFreeBusyString() -> String {

        let isFree: Bool
        switch model {
        case let .local(localEvent): isFree = localEvent.availability == .free
        case .meetingRoomLimit: isFree = false
        case let .pb(event, _): isFree = event.isFree
        }

        return isFree ? I18n.Calendar_Detail_Free : I18n.Calendar_Detail_Busy
    }
}
