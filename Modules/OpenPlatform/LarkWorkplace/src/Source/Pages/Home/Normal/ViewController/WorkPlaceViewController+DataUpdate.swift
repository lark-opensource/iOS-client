//
//  WorkPlaceViewController+DataUpdate.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/7/15.
//

import Foundation
/// 工作台通知相关
extension WorkPlaceViewController {
    func registerDataUpdateNoti() {
        let notiName = WorkplaceNotificationEvent.workplaceCommonAppDataChange.notificationName()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataProduce),
            name: notiName,
            object: nil
        )
    }
    /// 移除数据更新通知
    func removeDataUpdateNoti() {
        let notiName = WorkplaceNotificationEvent.workplaceCommonAppDataChange.notificationName()
        NotificationCenter.default.removeObserver(self, name: notiName, object: nil)
        deObserveAuxiliarySceneActive()
    }
}
