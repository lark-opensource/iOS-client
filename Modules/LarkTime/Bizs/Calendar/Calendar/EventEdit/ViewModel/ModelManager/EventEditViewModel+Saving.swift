//
//  EventEditViewModel+Saving.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: Setup Saving Status

extension EventEditViewModel {

    var savingModel: EventEditModelManager<EventEditSaveStatus>? {
        self.models[EventEditModelType.saving] as? EventEditModelManager<EventEditSaveStatus>
    }

    func makeSavingModel() -> EventEditModelManager<EventEditSaveStatus> {
        let rxModel = BehaviorRelay<EventEditSaveStatus>(value: .disabled)
        let saving_model = EventEditModelManager<EventEditSaveStatus>(userResolver: self.userResolver,
                                                                      identifier: EventEditModelType.saving.rawValue,
                                                                      rxModel: rxModel)
        saving_model.initLater = { [weak self, weak saving_model] in
            guard let self = self,
                  let saving_model = saving_model,
                  let rxSaveStatus = saving_model.rxModel else { return }

            // rrule.endDate 是否合法（是否和会议室有效时长冲突）
            let rxIsRruleEndDateValid = self.eventModel?.rxModel?.map { [weak self] (eventModel: EventEditModel) -> Bool in
                guard let self = self else { return true }
                guard let rrule = eventModel.rrule else { return true }
                return self.isRruleEndDateValid(
                    of: rrule,
                    by: eventModel.startDate,
                    model: eventModel
                )
            }.distinctUntilChanged() ?? .just(true)

            // 编辑/保存权限
            let rxSavePermission = self.permissionModel?.rxModel?.map({ $0.saving }).distinctUntilChanged() ?? .just(.writable)

            // 拉取所有参与人
            let transfrom = { (status: PullAllAttendeeStatus) -> Bool in
                switch status {
                case .success, .failed:
                    return true
                default:
                    return false
                }
            }
            let rxAttendeeStatus = self.attendeeModel?.rxPullAllAttendeeStatus.map(transfrom) ?? .just(true)
            let rxSpeakerStatus = self.webinarAttendeeModel?.speakerContext.rxPullAllAttendeeStatus.map(transfrom) ?? .just(true)
            let rxAudienceStatus = self.webinarAttendeeModel?.audienceContext.rxPullAllAttendeeStatus.map(transfrom) ?? .just(true)
            let rxPullAllAttendeeStatus = Observable.combineLatest(rxAttendeeStatus, rxSpeakerStatus, rxAudienceStatus).map({ $0 && $1 && $2 }).distinctUntilChanged()

            // 签到配置是否有效
            let rxCheckInValid = self.rxCheckInViewData.map { data -> Bool in
                !(data.isVisible && !data.isValid)
            }

            Observable.combineLatest(
                rxIsRruleEndDateValid,
                rxSavePermission,
                rxPullAllAttendeeStatus,
                self.rxEventDateOrRruleChanged,
                rxCheckInValid
            ).bind { [weak self] (isRruleEndDateValid, savePermission, pullAllAttendeeStatus, hasChanged, isCheckInValid) in
                guard let self = self else { return }

                guard savePermission.isEditable else {
                    // 没有编辑权限
                    let alert = self.permissionModel?.alertMessageForSavingForbidden()
                    assert(alert != nil)
                    rxSaveStatus.accept(.alert(message: alert ?? ""))
                    return
                }

                guard pullAllAttendeeStatus else {
                    // 编辑 复制场景 尚未拉取到所有参与者
                    rxSaveStatus.accept(.disabled)
                    return
                }

                guard isCheckInValid else {
                    // 签到配置不合法
                    rxSaveStatus.accept(.disabled)
                    return
                }

                let rruleEditPermission = self.permissionModel?.rxPermissions.value.rrule.isEditable ?? false

                // 有 rrule 编辑权限的用户需要考虑会议室可预定最长范围是否与重复性规则冲突
                // Feature: 无 rrule 编辑权限但可以添加参与人和会议室的用户，允许其添加的会议室被保存，不管会议室可预定最长范围是否与重复性规则冲突
                guard isRruleEndDateValid || !hasChanged || !rruleEditPermission else {
                    // rrule.endDate 不合法（和会议室冲突）
                    rxSaveStatus.accept(.disabled)
                    return
                }

                rxSaveStatus.accept(.enabled)
            }.disposed(by: self.disposeBag)
        }
        return saving_model
    }

}
