//
//  SelectTimeZone.swift
//  Calendar
//
//  Created by 张威 on 2020/1/16.
//

import RxSwift
import RxCocoa

/// 时区选择弹窗
///
/// - Parameters:
///   - service: 依赖；用于为弹窗提供数据服务：获取/新增/删除 最近使用的时区；搜索时区
///   - selectedTimeZone: 输入；被选中的时区
///   - onTimeZoneSelect: 输出；当某个时区被选中时触发回调；默认行为 `selectedTimeZone.accept(timeZone)`
func getPopupTimeZoneSelectViewController(
    with service: TimeZoneSelectService,
    selectedTimeZone: BehaviorRelay<TimeZoneModel>,
    onTimeZoneSelect: ((TimeZoneModel) -> Void)? = nil
) -> PopupViewController {

    let onTimeZoneSelect = onTimeZoneSelect ?? { [weak selectedTimeZone] timeZone in
        selectedTimeZone?.accept(timeZone)
    }

    // search time zone
    let searchVCFactory: TimeZoneQuickSelectViewController.SearchViewControllerMaker = {
        let searchVC = TimeZoneSearchSelectViewController(service: service)
        searchVC.onTimeZoneSelect = { [weak searchVC] timeZone in
            _ = service.upsertRecentTimeZones(with: [timeZone.identifier]).subscribe {}
            onTimeZoneSelect(timeZone)
            searchVC?.popupViewController?.dismiss(animated: true, completion: nil)

//            CalendarTracer.shareInstance.calSelectTimeZoneSearchingResult()
        }
        return searchVC
    }

    // quick select time zone
    let quickSelectVC = TimeZoneQuickSelectViewController(
        service: service,
        selectedTimeZone: selectedTimeZone,
        searchViewControllerMaker: searchVCFactory
    )
    quickSelectVC.onTimeZoneSelect = { [weak quickSelectVC] (timeZone, reason) in
        onTimeZoneSelect(timeZone)
        if reason == .userClicked {
            _ = service.upsertRecentTimeZones(with: [timeZone.identifier]).subscribe {}
            quickSelectVC?.popupViewController?.dismiss(animated: true, completion: nil)

//            CalendarTracer.shareInstance.calQuickSelectTimeZone(
//                timeZone.identifier == TimeZone.current.identifier ? .device : .recent
//            )
        }
    }

    // popup container
    let popupVC = PopupViewController(rootViewController: quickSelectVC)

    return popupVC
}
