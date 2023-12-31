//
//  EventDetailNavigationBarViewModel+Copy.swift
//  Calendar
//
//  Created by huoyunjie on 2021/11/27.
//

import Foundation

extension EventDetailNavigationBarViewModel {
    func copy() {
        guard case .pb(let event, let instance) = model else { return }
        CalendarTracerV2.EventMore.traceClick {
            $0.click("copy").target("cal_event_full_create_view")
            $0.mergeEventCommonParams(commonParam: CommonParamData(instance: self.model.instance, event: self.model.event))
        }

        let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false

        if event.disableEncrypt || disableEncrypt {
            rxToast.accept(.tips(I18n.Calendar_NoKeyNoOperate_Toast))
            return
        }
        /// 复制日程后送入编辑页的event会通过input来构造EventEditModel，EventEditAttachmentManager也会通过input构造attachmentModel
        /// 若在编辑页构造Model时有处理Model字段，需要注意两个通过input构造的model数据的一致性。
        let eventCoordinator = EventEditCoordinator(
            userResolver: self.userResolver, editInput: .copyWithEvent(pbEvent: event, pbInstance: instance),
            dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver)
        )
        eventCoordinator.delegate = self
        eventCoordinator.actionSource = .detail
        rxRoute.accept(.edit(coordinator: eventCoordinator))
    }
}
