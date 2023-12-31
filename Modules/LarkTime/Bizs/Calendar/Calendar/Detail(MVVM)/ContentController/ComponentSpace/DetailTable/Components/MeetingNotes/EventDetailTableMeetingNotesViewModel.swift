//
//  EventDetailTableMeetingNotesViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2023/5/31.
//

import Foundation
import LarkContainer
import LarkRustClient
import RxSwift
import RxCocoa
import ServerPB
import Swinject
import LarkTimeFormatUtils
import LarkLocalizations
import CalendarFoundation
import UniverseDesignToast

final class EventDetailTableMeetingNotesViewModel: EventDetailComponentViewModel {

    @ContextObject(\.rxModel) var rxModel
    @ContextObject(\.state) var state

    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var serverPush: ServerPushService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    let viewData: BehaviorRelay<EventDetailTableMeetingNotesViewDataType> = .init(value: ViewData())
    private let disposeBag = DisposeBag()

    private(set) var currentNotes: MeetingNotesModel?
    private(set) var originalNotes: MeetingNotesModel?
    private(set) lazy var loader: MeetingNotesLoader = {
        MeetingNotesLoader(userResolver: self.userResolver)
    }()

    override init(context: EventDetailContext, userResolver: UserResolver) {

        super.init(context: context, userResolver: userResolver)

        bindRx()
        bindServerPush()
    }

    private func bindRx() {
        rxModel
            .subscribe(onNext: { [weak self] _ in
                self?.fetchMeetingNotes()
            }).disposed(by: disposeBag)
    }

    private func bindServerPush() {
        serverPush?.rxMeetingNotesUpdate
            .subscribe(onNext: { [weak self] (updateInfo: Server.MeetingNotesUpdateInfo) in
                guard let self = self, updateInfo.hasInstance else { return }
                let instanceInfo = updateInfo.instance
                if instanceInfo.eventUid == self.model.key,
                   instanceInfo.originalTime == self.model.originalTime,
                   instanceInfo.instanceStartTime == self.model.startTime {
                    self.fetchMeetingNotes()
                }
            }).disposed(by: disposeBag)
    }
}

extension EventDetailTableMeetingNotesViewModel {

    struct ViewData: EventDetailTableMeetingNotesViewDataType {
        var viewStatus: MeetingNotesViewStatus = .hidden
        var showDeleteIcon: Bool = false
        var shouldShowAIStyle: Bool = false
    }

    var model: EventDetailModel {
        rxModel.value
    }
}

// Request
extension EventDetailTableMeetingNotesViewModel {

    var fourTuple: CalendarRustAPI.InstanceFourTupleRequest {
        let fourTuple = CalendarRustAPI.InstanceFourTupleRequest(calendarID: model.calendarId,
                                                                 key: model.key,
                                                                 originalTime: model.originalTime,
                                                                 instanceStartTime: model.startTime)
        return fourTuple
    }

    /// 请求 instance 绑定的 meetingNotes
    func fetchMeetingNotes() {
        loader.getInstanceRelatedInfo(calendarID: model.calendarId,
                                      key: model.key,
                                      originalTime: model.originalTime,
                                      instanceStartTime: model.startTime)
        .observeOn(loader.accessDataScheduler)
        .map { [weak self] (notesInfo, inNotesFG) -> MeetingNotesViewStatus in
            guard inNotesFG else { return .hidden }
            guard let notes = notesInfo else {
                // 没有绑定 notesInfo
                self?.originalNotes = nil
                self?.currentNotes = nil
                return .createMeetingNotes
            }
            self?.originalNotes = notes
            self?.currentNotes = notes
            let meetingNotesViewData = notes.transformToViewData()
            return .viewData(meetingNotesViewData)
        }
        .map { ViewData(viewStatus: $0) }
        .subscribe(onNext: { [weak self] viewData in
            self?.sendToViewData(viewData)
        }, onError: { [weak self] error in
            guard let self = self else { return }
            var viewData = ViewData()
            if error.errorType() == .instanceInfoErrorInMeetingNotesFG {
                viewData = ViewData(viewStatus: .failed(retryAction: self.fetchMeetingNotes))
            } else if error.errorType() == .getNotesInstanceNotFound {
                viewData = ViewData()
                EventDetail.logWarn("instance not found, hidden meeting notes")
            }
            self.sendToViewData(viewData)
        }).disposed(by: disposeBag)
    }

    /// 创建 MeetingNotes
    func createMeetingNotes() -> Observable<(MeetingNotesModel?, Bool)> {
        EventDetail.logInfo("create meeting notes")
        let docTitle = MeetingNotesLoader.makeDocTitle(
            templateTitle: "",
            eventSummary: model.event?.summary ?? "",
            date: Date(timeIntervalSince1970: TimeInterval(self.model.startTime)),
            timeZone: TimeZone(identifier: model.event?.startTimezone ?? "") ?? .current
        )

        let observable = loader.createNotes(by: nil,
                           title: docTitle,
                           fourTuple: self.fourTuple,
                           originalToken: self.originalNotes?.token)
        .flatMap({ [weak self] (notes, isNewCreate) -> Observable<(MeetingNotesModel?, Bool)> in
            guard let self = self else { return .empty() }
            if let notes = notes, isNewCreate {
                return self.bindMeetingNotesToInstance(notes: notes).map { _ in
                    return (notes, isNewCreate)
                }
            }
            return .just((notes, isNewCreate))
        })
        .share()

        observable
            .observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] (notes, isNewCreate) in
                let viewStatus: MeetingNotesViewStatus
                if let notes = notes {
                    self?.currentNotes = notes
                    viewStatus = .viewData(notes.transformToViewData())
                    if !isNewCreate {
                        self?.originalNotes = notes
                    }
                } else {
                    self?.currentNotes = nil
                    viewStatus = .createMeetingNotes
                }
                self?.sendToViewData(ViewData(viewStatus: viewStatus))
            }).disposed(by: disposeBag)
        return observable
    }

    /// 关联已有文档
    func associateNotesInfo(docToken: String, docType: Int) -> Observable<MeetingNotesModel?> {
        let observable = self.loader.getAssociateNotesInfo(docToken: docToken, docType: docType)
            .flatMap({ [weak self] notes -> Observable<MeetingNotesModel?> in
                guard let self = self else { return .empty() }
                if let notes = notes {
                    return self.bindMeetingNotesToInstance(notes: notes).map { _ in
                        return notes
                    }
                }
                return .just(notes)
            })
            .share()

        observable
            .observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] notes in
                let viewStatus: MeetingNotesViewStatus
                if let notes = notes {
                    self?.currentNotes = notes
                    viewStatus = .viewData(notes.transformToViewData())
                } else {
                    self?.currentNotes = nil
                    viewStatus = .createMeetingNotes
                }
                self?.sendToViewData(ViewData(viewStatus: viewStatus))
            }).disposed(by: disposeBag)
        return observable
    }

    /// 将 meetingNotes 与 instance 进行绑定
    @discardableResult
    func bindMeetingNotesToInstance(notes: MeetingNotesModel) -> Observable<Void> {
        let observable = loader.bindMeetingNotesToInstance(
            fourTuple: fourTuple,
            model: notes,
            originalDocToken: originalNotes?.token
        ).share().map { _ in Void() }
        observable
            .observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] _ in
                EventDetail.logInfo("bind meetingNotes to instance success")
                /// 绑定成功，异步刷新 MeetingNotes
                self?.fetchMeetingNotes()
            }, onError: { err in
                EventDetail.logError("bind meetingNotes to instance error! \(err)")
            }).disposed(by: disposeBag)
        return observable
    }

    /// 刷新 meetingNotes
    func refreshMeetingNotes() {
        guard let notes = currentNotes else { return }
        let docOwnerId = notes.docOwnerId
        let docBotId = notes.docBotId
        let eventPermission = notes.eventPermission
        let showEventPermission = notes.showEventPermission
        loader.getNotesInfo(with: notes.token, docType: notes.type)
            .observeOn(loader.accessDataScheduler)
            .subscribe(onNext: { [weak self] notesInfo in
                guard let self = self, var notesInfo = notesInfo else {
                    /// 文档被删除
                    self?.currentNotes = nil
                    self?.sendToViewData(ViewData(viewStatus: .createMeetingNotes))
                    return
                }
                notesInfo.docOwnerId = docOwnerId
                notesInfo.docBotId = docBotId
                notesInfo.eventPermission = eventPermission
                notesInfo.showEventPermission = showEventPermission
                
                let viewStatus = notesInfo.transformToViewData()
                self.currentNotes = notesInfo
                self.sendToViewData(ViewData(viewStatus: .viewData(viewStatus)))
                self.syncThumbnailImage()
            }).disposed(by: disposeBag)
    }

    /// 更改日程协作人对文档的编辑权
    func changeNotesEventPermission(_ permission: CalendarNotesEventPermission) -> Observable<Void> {
        guard var model = currentNotes else { return .empty() }
        model.eventPermission = permission
        return bindMeetingNotesToInstance(notes: model)
    }

    /// 同步缩略图最新变更
    private func syncThumbnailImage() {
        guard var notes = currentNotes else { return }
        loader.syncThumbnailImage(notes: notes) { [weak self] rxThumbnail in
            guard let self = self else { return }
            self.loader.accessDataQueue.async {
                if self.currentNotes == notes {
                    notes.thumbnail?.rxImage = rxThumbnail
                    self.currentNotes = notes
                    let viewData = notes.transformToViewData()
                    self.sendToViewData(ViewData(viewStatus: .viewData(viewData)))
                }
            }
        }
    }

    /// 统一处理 viewData 的刷新
    private func sendToViewData(_ viewData: EventDetailTableMeetingNotesViewDataType) {
        switch viewData.viewStatus {
        case .viewData(var data):
            fixShowPermissionTip(viewData: &data)
            fixEventPermission(viewData: &data)
            self.viewData.accept(ViewData(viewStatus: .viewData(data)))
        default:
            self.viewData.accept(viewData)
        }
    }

    /// 校验是否展示外部权限调整提示
    private func fixShowPermissionTip(viewData data: inout MeetingNotesViewData) {
        EventDetail.logInfo("fixShowPermissionTip before value: \(data.showPermissionTip)")
        /// 日程是否跨租户
        let eventIsCrossTenant = model.event?.isCrossTenant ?? false
        /// 参与者是否有外部
        let hasExternalAttendee: () -> Bool = { [weak self] in
            guard let self = self,
                  let tenantId = self.calendarDependency?.currentUser.tenantId,
                  let attendees = self.model.event?.attendees else { return false }
            return EventEditAttendee
                .makeAttendees(from: attendees)
                .hasExternalAttendee(tenantId: tenantId)
        }

        data.showPermissionTip = data.showPermissionTip && (eventIsCrossTenant || hasExternalAttendee())
        EventDetail.logInfo("fixShowPermissionTip before value: \(data.showPermissionTip), eventIsCrossTenant: \(eventIsCrossTenant), hasExternalAttendee: \(hasExternalAttendee)")
    }

    /// 日程协作人编辑权限展示校验，权限逻辑：仅 组织者 在 组织者日历上 有编辑权限
    private func fixEventPermission(viewData data: inout MeetingNotesViewData) {
        EventDetail.logInfo("fixEventPermission before value: \(data.eventPermission)")
        let canEditCalId = {
            if let calendar = model.getCalendar(calendarManager: calendarManager),
               calendar.type == .other {
                return model.event?.creatorCalendarID ?? ""
            } else {
                return model.event?.organizerCalendarID ?? ""
            }
        }()
        let eventPermission: CalendarNotesEventPermission?
        if let event = model.event,
           event.calendarID == event.organizerCalendarID,
           calendarManager?.primaryCalendarID == canEditCalId
        {
            eventPermission = data.eventPermission
        } else {
            eventPermission = nil
        }
        data.eventPermission = eventPermission
        EventDetail.logInfo("fixEventPermission after value: \(data.eventPermission)")
    }
}
