//
//  CalendarDeletable.swift
//  Calendar
//
//  Created by harry zou on 2019/3/21.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import LarkUIKit
import UniverseDesignToast

protocol CalendarDeletable {
    var api: CalendarRustAPI { get }
    var disposeBag: DisposeBag { get }
    func deleteSuccess()
}

extension CalendarDeletable where Self: UIViewController {
    func deleteCalendar(with calendarId: String) {
        CalendarTracer.shareInstance.calDeleteCalendar()
        var getCallBack: Bool = false
        UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Toast_Deleting, on: view)
        self.api.deleteCalendar(with: calendarId)
            .subscribeForUI(onNext: { [weak self] () in
                getCallBack = true
                self?.deleteSuccess()
                if let window = self?.view.window {
                    UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Toast_Deleted, on: window)
                }
                self?.navigationController?.dismiss(animated: true)
            }, onError: { [weak self] (error) in
                getCallBack = true
                if let window = self?.view.window {
                    UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_FailToDelete, on: window)
                }
            }, onDisposed: { [weak self] in
                if !getCallBack, let view = self?.view {
                    UDToast.removeToast(on: view)
                }
            }).disposed(by: self.disposeBag)
    }
}
