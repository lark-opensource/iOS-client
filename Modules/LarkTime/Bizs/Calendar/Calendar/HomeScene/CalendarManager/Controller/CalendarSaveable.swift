//
//  CalendarSaveable.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/26.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RustPB
import LarkUIKit
import UniverseDesignToast

protocol CalendarSaveable {
    var disposeBag: DisposeBag { get }
    var api: CalendarRustAPI { get }
}

extension CalendarSaveable where Self: UIViewController {
    func saveCal(withModel model: CalendarManagerDataProtocol, saveSucess: (() -> Void)? = nil) {
        UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Toast_Saving, on: self.view.window ?? UIView())
        api.newCalendar(with: model.calendar, members: model.calendarMembers, rejectedUsers: model.rejectedUserIDs)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                if let window = self?.view.window {
                    UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Toast_Saved, on: window)
                }
                if (model as? AddNewCalendarViewData) != nil {
                    saveSucess?()
                }

                self?.navigationController?.dismiss(animated: true, completion: nil)
            }, onError: { [weak self] (error) in
                if let window = self?.view.window {
                    if error.errorType() == .calendarWriterReachLimitErr {
                        UDToast.showFailure(with: error.getServerDisplayMessage() ?? BundleI18n.Calendar.Calendar_Toast_FailedToSave, on: window)
                    } else {
                        UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_FailedToSave, on: window)
                    }
                }
            })
            .disposed(by: disposeBag)

    }
}
