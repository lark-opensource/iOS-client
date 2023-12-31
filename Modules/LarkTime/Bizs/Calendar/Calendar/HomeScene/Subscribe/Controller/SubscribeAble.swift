//
//  SubscribeAble.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/25.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import RxSwift
import UIKit
import LarkUIKit
import RoundedHUD
import UniverseDesignDialog

protocol SubscribeAble: UnsubscribeAlert, NSObjectProtocol {
    func subscribeFailed(controller: UIViewController)
    func subscribeFailed(reason: ErrorType, controller: UIViewController)
    func getReloadRow(content: SubscribeAbleModel, contents: [SubscribeAbleModel]) -> IndexPath
}

protocol SubscribeAbleModel {
    var calendarID: String { get }
    var subscribeStatus: SubscribeStatus { get set }
    var isOwner: Bool { get set }
}

extension SubscribeAble {

    func subscribeFailed(controller: UIViewController) {
        subscribeFailed(reason: .unknown, controller: controller)
    }

    func subscribeFailed(reason: ErrorType, controller: UIViewController) {
        let hud = RoundedHUD()
        switch reason {
        case .subscribeCalendarExceedTheUpperLimitErr:
            hud.showTips(with: BundleI18n.Calendar.Calendar_SubscribeCalendar_NumLimit, on: controller.view)
        case .exceedMaxVisibleCalNum:
            hud.showTips(with: I18n.Calendar_Detail_TooMuchViewReduce, on: controller.view)
        default:
            hud.showTips(with: BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationFailed, on: controller.view)
        }
    }

    func getReloadRow(content: SubscribeAbleModel, contents: [SubscribeAbleModel]) -> IndexPath {
        var row = 0
        for i in 0..<contents.count {
            let cellContent = contents[i]
            if content.calendarID == cellContent.calendarID {
                row = i
                return IndexPath(row: row, section: 0)
            }
        }
        return IndexPath(row: row, section: 0)
    }

    /// 订阅和退订逻辑封装
    func changeSubscribeStatus(content: SubscribeAbleModel,
                               calendarApi: CalendarRustAPI?,
                               disposeBag: DisposeBag,
                               searchType: CalendarTracer.SearchType,
                               pageType: CalendarTracer.PageType,
                               controller: UIViewController,
                               refresh: @escaping (_ content: SubscribeAbleModel) -> Void ) {

        let doAction = {
            var data = content
            let nextStatues = data.subscribeStatus.nextStatus()
            if nextStatues == .subscribing {
                data.subscribeStatus = nextStatues
                refresh(data)
                calendarApi?
                    .subscribeCalendar(with: data.calendarID)
                    .delay(.milliseconds(330), scheduler: MainScheduler.instance)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (isOwner) in
                        data.isOwner = isOwner
                        data.subscribeStatus = nextStatues.nextStatus()
                        refresh(data)
                        RoundedHUD().showSuccess(with: BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded, on: controller.view)
                        CalendarMonitorUtil.endTrackSubscribeCalendarTime()
                    }, onError: { [weak self] (error) in
                        guard let self = self else { return }
                        data.subscribeStatus = nextStatues.preStatus()
                        refresh(data)
                        switch error.errorType() {
                        case .subscribeCalendarExceedTheUpperLimitErr:
                            self.subscribeFailed(reason: .subscribeCalendarExceedTheUpperLimitErr, controller: controller)
                        case .exceedMaxVisibleCalNum:
                            self.subscribeFailed(reason: .exceedMaxVisibleCalNum, controller: controller)
                        default:
                            self.subscribeFailed(controller: controller)
                        }
                    }).disposed(by: disposeBag)
            } else if nextStatues == .unSubscribing {
                data.subscribeStatus = nextStatues
                refresh(data)
                calendarApi?.unsubscribeCalendar(with: data.calendarID)
                    .delay(.milliseconds(330), scheduler: MainScheduler.instance)
                    .observeOn(MainScheduler.instance).subscribe(onNext: { response in
                        if response.code != 0 {
                            let dialog = UDDialog(config: UDDialogUIConfig())
                            dialog.setTitle(text: response.alertTitle)
                            dialog.setContent(text: response.alertContent)
                            dialog.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                            controller.present(dialog, animated: true)
                            CalendarTracerV2.CalendarNoUnsubscribe.traceView {
                                $0.calendar_id = data.calendarID
                            }
                            data.subscribeStatus = nextStatues.preStatus()
                            refresh(data)
                            return
                        }
                        data.subscribeStatus = nextStatues.nextStatus()
                        refresh(data)
                        RoundedHUD().showSuccess(with: BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded, on: controller.view)
                    }, onError: { [weak self] (_) in
                        guard let self = self else { return }
                        data.subscribeStatus = nextStatues.preStatus()
                        refresh(data)
                        self.subscribeFailed(controller: controller)
                    }).disposed(by: disposeBag)
            }
        }

        if content.isOwner, content.subscribeStatus == .subscribed {
            self.showAlert(in: controller) {
                doAction()
            }
        } else {
            doAction()
        }
    }
}
