//
//  MeetingRoomDetailViewModel.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/1/14.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer

enum MeetingRoomDetailInput {
    case detailOnly(DetailOnlyContext)
    case detailWithStatus(DetailWithStatusContext)
}

struct DetailOnlyContext {
    var calendarID: String = ""
    // 日程三元组信息，跨租户鉴权需要
    var eventUniqueFields: CalendarEventUniqueField?
}

struct DetailWithStatusContext {
    var calendarID: String = ""
    var rrule: String = ""
    var startTime: Date?
    var endTime: Date?
    var timeZone: String = ""
    // 日程三元组信息，跨租户鉴权需要
    var eventUniqueFields: CalendarEventUniqueField?
}

/// Detail - ViewModel

final class MeetingRoomDetailViewModel: UserResolverWrapper {

    let disposeBag = DisposeBag()

    // entity
    var rxMeetingRoomDetailEntity = BehaviorRelay<MeetingRoomDetailEntity>(value: MeetingRoomDetailEntity(fromInfo: MeetingRoomInfo()))

    // viewData
    var rxTitleViewData = BehaviorRelay<MeetingRoomDetailTitleViewDataType>(value: TitleViewData(title: "",
                                                                                                 subTitle: "",
                                                                                                 roomState: nil))
    var rxStatusContentViewData = BehaviorRelay<BasicInfoViewDataType>(value: BasicInfoViewData(cellsData: []))
    var rxBasicInfoViewData = BehaviorRelay<BasicInfoViewDataType>(value: BasicInfoViewData(cellsData: []))

    // viewState
    var rxViewState = BehaviorRelay<MeetingRoomDetailViewState>(value: .idle)

    // 两种类型：有状态、无状态
    let input: MeetingRoomDetailInput
    @ScopedInjectedLazy private var calendarApi: CalendarRustAPI?

    let userResolver: UserResolver

    init(input: MeetingRoomDetailInput, userResolver: UserResolver) {
        self.input = input
        self.userResolver = userResolver
    }

    func setupDetailContent(onFinish: @escaping (() -> Void)) {
        guard let api = self.calendarApi else {
            assertionFailure("setupDetailContent failed, can not get rust api from larkcontainer")
            return
        }
        rxViewState.accept(.loading)
        switch input {
        case .detailOnly(let context):
            api.getMeetingRoomDetailInfo(by: [context.calendarID],
                                         eventUniqueFields: context.eventUniqueFields)
                .take(1).asSingle()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(
                    onSuccess: { [weak self] detailInfos in
                        guard let info = detailInfos.first else { return }
                        // setup entity
                        self?.rxMeetingRoomDetailEntity = BehaviorRelay(value: MeetingRoomDetailEntity(fromInfo: info))
                        // bindViewData
                        self?.bindTitleViewData()
                        self?.bindBasicInfoViewData()
                        self?.rxViewState.accept(.data)
                        onFinish()
                    },
                    onError: { [weak self] _ in
                        self?.rxViewState.accept(.failed)
                    }
                ).disposed(by: disposeBag)
        case .detailWithStatus(let context):
            guard let startTime = context.startTime, let endTime = context.endTime else {
                assertionFailure("日程起止时间为空")
                return
            }
            api.getMeetingRoomDetailInfoWithStatus(
                by: [context.calendarID],
                startTimeZone: context.timeZone,
                startTime: startTime,
                endTime: endTime,
                rrule: context.rrule,
                eventUniqueFields: context.eventUniqueFields).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] statusInfos in
                    guard let info = statusInfos.first else { return }
                    // setup entity
                    self?.rxMeetingRoomDetailEntity = BehaviorRelay(value: MeetingRoomDetailEntity(fromStatusInfo: info, with: context))
                    // bindViewData
                    self?.bindTitleViewData()
                    self?.bindStatusContentViewData()
                    self?.bindBasicInfoViewData()
                    self?.rxViewState.accept(.data)
                    onFinish()
                },
                onError: { [weak self] err in
                    self?.rxViewState.accept(.failed)
                    assertionFailure(err.info())
                }
            ).disposed(by: disposeBag)
        }
    }

    // MARK: titleVeiwData

    struct TitleViewData: MeetingRoomDetailTitleViewDataType {
        var title: String
        var subTitle: String
        var roomState: MeetingRoomStatus?
    }

    private func bindTitleViewData() {
        let transform = { (entity: MeetingRoomDetailEntity) -> TitleViewData in
            return TitleViewData(title: entity.roomName,
                                 subTitle: entity.buildingName,
                                 roomState: entity.state)
        }
        let viewData = transform(rxMeetingRoomDetailEntity.value)
        rxTitleViewData = BehaviorRelay(value: viewData)
        rxMeetingRoomDetailEntity.subscribeOn(MainScheduler.asyncInstance)
            .map { transform($0) }
            .bind(to: rxTitleViewData)
            .disposed(by: disposeBag)
    }

    // MARK: StatusContentViewData

    struct BasicInfoViewData: BasicInfoViewDataType {
        var cellsData: [CellData]
    }

    private func bindStatusContentViewData() {
        guard let status = rxMeetingRoomDetailEntity.value.state else {
            assertionFailure("会议室状态为空")
            return
        }
        var transform: (_ entity: MeetingRoomDetailEntity) -> BasicInfoViewData
        switch status {
        case .canNotReserve:
            transform = { (entity: MeetingRoomDetailEntity) -> BasicInfoViewData in
                let cantUse = CellData(type: .cantUse, content: entity.cantReserveReasons)
                return BasicInfoViewData(cellsData: [cantUse])
            }
        case .inUse:
            transform = { (entity: MeetingRoomDetailEntity) -> BasicInfoViewData in
                let reserveTime = CellData(type: .scheduledTime, content: [entity.scheduledTime])
                let subscriber = CellData(type: .booker, content: entity.bookerInfo)
                return BasicInfoViewData(cellsData: [reserveTime, subscriber])
            }
        case .canReserve:
            transform = { (_: MeetingRoomDetailEntity) -> BasicInfoViewData in
                return BasicInfoViewData(cellsData: [])
            }
        @unknown default:
            transform = { (_: MeetingRoomDetailEntity) -> BasicInfoViewData in
                return BasicInfoViewData(cellsData: [])
            }
        }

        let viewData = transform(rxMeetingRoomDetailEntity.value)
        rxStatusContentViewData = BehaviorRelay(value: viewData)
        rxMeetingRoomDetailEntity.subscribeOn(MainScheduler.asyncInstance)
            .map { transform($0) }
            .bind(to: rxStatusContentViewData)
            .disposed(by: disposeBag)
    }

    // MARK: BasicInfoViewData

    private func bindBasicInfoViewData() {
        let transform = { (entity: MeetingRoomDetailEntity) -> BasicInfoViewData in
            var cellsData: [CellData] = []
            if let creator = entity.creator {
                cellsData.append(CellData(type: .creator, content: [creator]))
            }
            if let capcity = entity.capcity {
                cellsData.append(CellData(type: .capcity, content: [capcity]))
            }
            if let equipments = entity.equipments {
                cellsData.append(CellData(type: .equipments, content: [equipments]))
            }
            if let resourcesRules = entity.resourcesRules {
                cellsData.append(CellData(type: .resourceStrategy, content: resourcesRules))
            }
            if let remarks = entity.remark {
                cellsData.append(CellData(type: .remarks, content: [remarks]))
            }
            if let picture = entity.picture {
                cellsData.append(CellData(type: .picture, content: [picture]))
            }
            return BasicInfoViewData(cellsData: cellsData)
        }
        let viewData = transform(rxMeetingRoomDetailEntity.value)
        rxBasicInfoViewData = BehaviorRelay(value: viewData)
        rxMeetingRoomDetailEntity.subscribeOn(MainScheduler.asyncInstance)
            .map { transform($0) }
            .bind(to: rxBasicInfoViewData)
            .disposed(by: disposeBag)
    }
}
