//
//  EventEditViewModel+Expend.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import RxCocoa
import RxSwift

// MARK: Setup Expand

extension EventEditViewModel {

    // 控制「颜色、忙闲、可见性」模块的展开与否
    var expandModel: EventEditModelManager<Bool>? {
        self.models[EventEditModelType.expand] as? EventEditModelManager<Bool>
    }

    func makeExpandModel() -> EventEditModelManager<Bool> {
        let expend_model = EventEditModelManager<Bool>(userResolver: self.userResolver,
                                                       identifier: EventEditModelType.expand.rawValue,
                                                       rxModel: BehaviorRelay<Bool>(value: false))
        expend_model.relyModel = [EventEditModelType.permission.rawValue]
        expend_model.initMethod = { [weak self, weak expend_model] observer in
            guard let permissions = self?.permissionModel?.rxModel?.value, let expend_model = expend_model else { return }
            let shouldHide = permissions.calendar.isVisible
            && permissions.color.isVisible
            && permissions.freeBusy.isVisible
            && permissions.visibility.isVisible
            expend_model.rxModel?.accept(!shouldHide)
            observer.onCompleted()
        }
        return expend_model
    }

}
