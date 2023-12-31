//
//  CalendarUnsubsrible.swift
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
import UniverseDesignDialog

protocol CalendarUnsubscribeable {
    var disposeBag: DisposeBag { get }
    var api: CalendarRustAPI { get }
}

extension CalendarUnsubscribeable where Self: UIViewController {
    func unsubscribeCal(calendarId: String) {
        var getCallBack: Bool = false
        UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Toast_RescindingSubscription, on: view)
        api.unsubscribeCalendar(with: calendarId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                if response.code != 0 {
                    let dialog = UDDialog(config: UDDialogUIConfig())
                    dialog.setTitle(text: response.alertTitle)
                    dialog.setContent(text: response.alertContent)
                    dialog.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                    self?.present(dialog, animated: true)
                    CalendarTracerV2.CalendarNoUnsubscribe.traceView {
                        $0.calendar_id = calendarId
                    }
                    return
                }
                getCallBack = true
                if let window = self?.view.window {
                    UDToast.showSuccess(with: BundleI18n.Calendar.Calendar_Toast_Removed, on: window)
                }
                self?.navigationController?.dismiss(animated: true, completion: nil)
                }, onError: { [weak self] (error) in
                    getCallBack = true
                    if let window = self?.view.window {
                        UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_FailedToRemoveCalendar, on: window)
                    }
            }, onDisposed: { [weak self] in
                if !getCallBack, let view = self?.view {
                    UDToast.removeToast(on: view)
                }
            }).disposed(by: disposeBag)
    }
}
