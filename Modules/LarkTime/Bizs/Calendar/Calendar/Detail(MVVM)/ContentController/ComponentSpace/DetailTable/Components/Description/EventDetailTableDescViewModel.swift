//
//  EventDetailTableDescViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import Foundation
import LarkContainer
import RxSwift
import RxRelay

final class EventDetailTableDescViewModel: EventDetailComponentViewModel {

    let rxViewData = BehaviorRelay<DetailDescCellContent?>(value: nil)

    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ContextObject(\.rxModel) var rxModel

    override init(context: EventDetailContext, userResolver: UserResolver) {
        super.init(context: context, userResolver: userResolver)

        bindRx()
    }

    private func bindRx() {

        rxModel
            .compactMap { [weak self] model -> DetailDescCellContent? in
                guard let self = self else { return nil }
                return self.getDesc(with: model)
            }.distinctUntilChanged({ lhs, rhs in
                lhs.desc == rhs.desc
            }).bind(to: rxViewData)
            .disposed(by: disposeBag)
    }
}

extension EventDetailTableDescViewModel {
    func getDesc(with model: EventDetailModel) -> DetailDescCellContent {

        var contentType: DetailDescCell.ContentType = .docsData
        if model.isThirdParty || model.docsDescription.isEmpty {
            contentType = .docsHtml
        }

        return DetailDescCellModel(desc: model.eventDescription,
                                   docsData: model.docsDescription,
                                   contentType: contentType)
    }
}

struct DetailDescCellModel: DetailDescCellContent {
    var desc: String
    var docsData: String
    var contentType: DetailDescCell.ContentType
}
