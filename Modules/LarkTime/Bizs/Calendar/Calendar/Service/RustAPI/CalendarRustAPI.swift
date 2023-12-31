//
//  CalendarApiImplement.swift
//  Calendar
//
//  Created by linlin on 2017/12/14.
//  Copyright © 2017年 linlin. All rights reserved.
//
// swiftlint:disable file_length

import Foundation
import CalendarFoundation
import RxSwift
import LarkRustClient
import RustPB
import LarkLocalizations
import ServerPB
import LarkContainer
import LarkAccountInterface
import UniverseDesignToast
import EENavigator
import SwiftProtobuf

#if !DEBUG && !ALPHA
extension ServerPB_Calendarevents_GetMeetingRoomsReserveStatusResponse.StatusInformation: SwiftProtobuf.MessageDebugDescriptionLarkExt {}
extension ServerPB_Entities_CalendarEventUniqueField: SwiftProtobuf.MessageDebugDescriptionLarkExt {}
#endif

final class FieldComparator {
    private var changeFields = [String]()

    func addField<T: Equatable>(oldValue: T?, newValue: T?, name: String) {
        if oldValue != newValue {
            changeFields.append(name)
        }
    }

    func getChangeFields() -> [String: String] {
        return ["changeFields": changeFields.description]
    }

}

final class CalendarRustAPI: UserResolverWrapper {
    typealias MeetingEventSpecialRule = JudgeNotificationBoxTypeResponse.MeetingEventSpecialRule
    typealias MailAttendeeSpecialRule = JudgeNotificationBoxTypeResponse.MailAttendeeSpecialRule
    typealias MeetingChatSpecialRule = JudgeNotificationBoxTypeResponse.MeetingChatSpecialRule
    typealias TimeZoneCityPair = (timeZone: TimeZoneModel, cityNames: [String])
    typealias MeetingRoomSearchItem = (meetingRoom: Rust.MeetingRoom, building: Rust.Building)
    typealias ArangementInstanceResponse = (instances: [CalendarEventInstanceEntity], timezoneMap: [String: String], workHourMap: [String: WorkHourSetting], privateCalMap: [String: Bool])
    let calendarDependency: CalendarDependency
    @ScopedInjectedLazy var calendarSubscribeTracer: CalendarSubscribeTracer?

    func loadAttendees(by seeds: [EventAttendeeSeed], primaryCalendarID: String) -> Observable<[PBAttendee]> {
        var result = Observable<[PBAttendee]>.just([])
        guard !seeds.isEmpty else {
            return result
        }
        var chatterIds = [String]()
        var groupIds = [String]()
        var meetingGroupIds = [String]()
        var mailAttendees = [PBAttendee]()

        for seed in seeds {
            switch seed {
            case .user(let chatterId): chatterIds.append(chatterId)
            case .group(let chatId): groupIds.append(chatId)
            case .meetingGroup(let chatId): meetingGroupIds.append(chatId)
            case .email(let address): mailAttendees.append(PBAttendee(email: address))
            case let .emailContact(address, name, avatarKey, entityId, type): mailAttendees.append(PBAttendee(emailContact: address,
                                                                                                              type: type,
                                                                                                              avatarKey: avatarKey,
                                                                                                              displayName: name))
            }
        }

        let getGroupObserverable = self.getGroupFakeAttendees(groupIds: groupIds, primaryCalendarID: primaryCalendarID)
        if groupIds.isEmpty {
            result = self.getAttendees(uids: chatterIds)
        } else if chatterIds.isEmpty {
            result = getGroupObserverable
        } else {
            result = Observable.zip(self.getAttendees(uids: chatterIds), getGroupObserverable) {
                return $0 + $1
            }
        }
        if !meetingGroupIds.isEmpty {
            let getMeetingGroupObservable = self.getGroupFakeAttendees(groupIds: meetingGroupIds, primaryCalendarID: primaryCalendarID).map { pbAttendees -> [PBAttendee] in
                return pbAttendees.map { pbAttendee -> PBAttendee in
                    var pbAttendee = pbAttendee
                    pbAttendee.isMeetingGroup = true
                    return pbAttendee
                }
            }
            result = Observable.zip(result, getMeetingGroupObservable) {
                return $0 + $1
            }
        }
        let rxMailAttendees = Observable.just(mailAttendees)
        result = Observable.zip(result, rxMailAttendees) { $0 + $1 }
        return result.observeOn(MainScheduler.instance)
    }

    private let calendarWorkQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "calendar.work.queue", qos: .userInteractive)
        return queue
    }()

    let disposeBag = DisposeBag()
    lazy var requestScheduler: SerialDispatchQueueScheduler = {
        SerialDispatchQueueScheduler(
           queue: calendarWorkQueue,
           internalSerialQueueName: calendarWorkQueue.label
       )
    }()

    let userResolver: UserResolver
    let rustService: CalendarRustService

    init(rustClient: RustService, userResolver: UserResolver) throws {
        self.rustService = CalendarRustService(rustService: rustClient)
        self.userResolver = userResolver
        calendarDependency = try self.userResolver.resolve(assert: CalendarDependency.self)
    }

    func updateUpdateCalendarVisibility(calendarId: String, visibility: Bool) -> Observable<Bool> {
        var request = UpdateCalendarVisibilityRequest()
        request.id = calendarId
        request.visibility = visibility
        return rustService.async(
            message: request,
            debugParams: ["id": request.id, "visibility": request.visibility.description],
            debugResponse: { ["success": $0.success.description] }
        ).map { (response: UpdateCalendarVisibilityResponse) -> Bool in response.success }
    }

    func startSyncCalendarsAndEvents() {
        let request = SyncCalendarsAndEventsRequest()
        rustService.async(message: request, debugParams: nil)
            .subscribeOn(requestScheduler)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func getPrimaryCalendarID() -> Observable<String> {
        return getPrimaryCalendar().map({ (response) -> String in
            return response.serverId
        })
    }

    func getPrimaryCalendar() -> Observable<CalendarModel> {
        let request = GetRemoteUserPrimaryCalendarRequest()
        return rustService.async(message: request,
                                 debugParams: nil,
                                 debugResponse: { response in
            return ["cal_id": response.calendar.serverID]
        }).map({ (response: GetRemoteUserPrimaryCalendarResponse) -> CalendarModel in
            return CalendarModelFromPb(pb: response.calendar)
        })
    }

    func getUserCalendars() -> Observable<[CalendarModel]> {
        let request = GetAllCalendarsRequest()
        return rustService.async(message: request,
                                 debugParams: nil,
                                    debugResponse: { response in
            return ["cal_ids_with_visiblity": response.calendars.map { "\($0.value.serverID) \($0.value.isVisible) \($0.value.calendarSyncInfo.isSyncing) \($0.value.calendarSyncInfo.minInstanceCacheTime)-\($0.value.calendarSyncInfo.maxInstanceCacheTime)" }.description]
        }).map({ (response: GetAllCalendarsResponse) -> [CalendarModel] in
            response.calendars.values.map({ CalendarModelFromPb(pb: $0) })
        })
    }

    func getAllCalendars() -> Observable<RustPB.Calendar_V1_GetAllCalendarsResponse> {
        let request = GetAllCalendarsRequest()
        return rustService.async(message: request, debugParams: nil,
                                 debugResponse: { response in
            return ["cal_ids_with_infos": response.calendars.map {
                "\($0.value.serverID) \($0.value.isVisible) \($0.value.calendarSyncInfo.isSyncing) \($0.value.selfAccessRole == .owner)"
            }.description]
        })
    }

    func getMeetingRoomBuildings() -> Observable<[Rust.Building]> {
        let request = Rust.GetBuildingsRequest()
        return rustService.async(
            message: request, debugParams: nil,
            debugResponse: { ["buildings": $0.buildings.values.map(\.id).description] }
        ).map { (response: Rust.GetBuildingsResponse) -> [Rust.Building] in
            return Array(response.buildings.values)
        }
    }

    func getResourceEquipments() -> Observable<[Rust.EquipmentExpand]> {
        let request = Rust.GetResourceEquipmentsRequest()
        return rustService.async(
            message: request, debugParams: nil,
            debugResponse: { ["equipmentIds": $0.equipmentIds.description] }
        ).map { (response: Rust.GetResourceEquipmentsResponse) -> [Rust.EquipmentExpand] in
            return response.equipmentIds.map {
                Rust.EquipmentExpand(equipment: response.equipmentLists[$0] ?? Rust.Equipment(), id: $0)
            }
        }
    }

    func getBuildings() -> Observable<[MeetingRoomBuilding]> {
        let request = GetBuildingsRequest()
        return rustService.async(
            message: request, debugParams: nil,
            debugResponse: { ["buildings": $0.buildings.values.map(\.id).description] }
        ).map({ (response: GetBuildingsResponse) -> [MeetingRoomBuilding] in
            var buildings = response.buildings.values.map({ (pbBuilding) -> MeetingRoomBuilding in
                let building = MeetingRoomBuilding(id: pbBuilding.id,
                                                   name: pbBuilding.name,
                                                   description: pbBuilding.debugDescription,
                                                   hasAvailableMeetingRoom: true,
                                                   weight: pbBuilding.weight)
                return building
            })
            let locale = Locale(identifier: "zh")
            buildings = buildings.sorted {
                if $0.weight != $1.weight {
                    return $0.weight > $1.weight
                }
                return $0.name.compare($1.name, locale: locale) == .orderedAscending
            }
            return buildings
        })
    }

    /// 根据指定的 id 获取层级和会议室信息
    func getMeetingRoomsAndLevels(levelIDs: [String] = [],
                                  pullAll: Bool = true,
                                  startTime: Date? = nil,
                                  endTime: Date? = nil,
                                  rrule: String? = nil,
                                  needDisabledResource: Bool = true,
                                  needToplevelInfo: Bool = false,
                                  needAutoJump: Bool = false,
                                  timezone: TimeZone = .current) -> Observable<Calendar_V1_MGetMeetingRoomsAndLevelsResponse> {
        if pullAll {
            var request = Calendar_V1_GetAllMeetingRoomsAndLevelsRequest()
            request.levelID = levelIDs[safeIndex: 0] ?? "0"
            if let startTime = startTime {
                request.startTime = Int64(startTime.timeIntervalSince1970)
            }
            if let endTime = endTime {
                request.endTime = Int64(endTime.timeIntervalSince1970)
            }
            request.needDisabledResource = needDisabledResource
            request.startTimezone = timezone.identifier
            request.needTopLevelInfo = needToplevelInfo

            let reqParams = ["levelID": request.levelID,
                             "startTime": request.startTime.description,
                             "endTime": request.endTime.description,
                             "needDisabledResource": request.needDisabledResource.description,
                             "startTimezone": request.startTimezone]
            return rustService.async(
                message: request, debugParams: reqParams,
                debugResponse: { ["levels": $0.levelInfo.keys.description,
                                  "autoDisplayPathMap": $0.autoDisplayPathMap.description,
                                  "recentlyUsedNodeList": $0.recentlyUsedNodeList.description] }
            )
        } else {
            var request = Calendar_V1_MGetMeetingRoomsAndLevelsRequest()
            request.levelIds = levelIDs
            if let startTime = startTime {
                request.startTime = Int64(startTime.timeIntervalSince1970)
            }
            if let endTime = endTime {
                request.endTime = Int64(endTime.timeIntervalSince1970)
            }
            if let rrule = rrule {
                request.rrule = rrule
            }

            request.needTopLevelInfo = needToplevelInfo
            request.jumpType = needAutoJump ? .redirect : .direct
            request.needDisabledResource = needDisabledResource
            request.startTimezone = timezone.identifier

            let reqParams = ["levelIds": request.levelIds.description,
                             "startTime": request.startTime.description,
                             "endTime": request.endTime.description,
                             "needDisabledResource": request.needDisabledResource.description,
                             "startTimezone": request.startTimezone]
            return rustService.async(
                message: request, debugParams: reqParams,
                debugResponse: { ["levels": $0.levelInfo.keys.description,
                                  "autoDisplayPathMap": $0.autoDisplayPathMap.description,
                                  "recentlyUsedNodeList": $0.recentlyUsedNodeList.description] }
            )
        }
    }

    func getMeetingRoomInstances(meetingRooms: [Rust.MeetingRoom], startTime: Date, endTime: Date) -> Observable<[Rust.MeetingRoom: [RoomViewInstance]]> {
        var request = Calendar_V1_GetRoomViewInstancesRequest()
        request.startTime = Int64(startTime.timeIntervalSince1970)
        request.endTime = Int64(endTime.timeIntervalSince1970)
        request.resourceCalendarIds = meetingRooms.map(\.calendarID)

        let reqParams = ["startTime": request.startTime.description,
                         "endTime": request.endTime.description,
                         "resourceCalendarIds": request.resourceCalendarIds.description]

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { ["instances": $0.roomViewInstances.map(\.eventKey).description] }
        ).map { (response: Calendar_V1_GetRoomViewInstancesResponse) -> [Rust.MeetingRoom: [RoomViewInstance]] in
            let instances = response.roomViewInstances
            let kv = meetingRooms.map { meetingRoom -> (Rust.MeetingRoom, [RoomViewInstance]) in
                return (meetingRoom, instances
                            .filter { $0.resourceCalendarID == meetingRoom.calendarID }
                            .map {
                    var instance = RoomViewInstance(pb: $0)
                    instance.meetingRoom = meetingRoom
                    return instance
                            })
            }
            return Dictionary(uniqueKeysWithValues: kv)
        }
    }
    
    func getMeetingRoomDetailInfo(by calendarIDs: [String],
                                  // 日程三元组信息，跨租户鉴权需要
                                  eventUniqueFields: CalendarEventUniqueField? = nil) -> Observable<[RustPB.Calendar_V1_MeetingRoomInformation]> {
        var request = GetMeetingRoomsStatusInformationRequest()
        request.calendarIds = calendarIDs
        if let eventUniqueFields = eventUniqueFields {
            request.resourceEventInfo = eventUniqueFields
        }

        return rustService.async(message: request, debugParams: ["calendarIDs": calendarIDs.description], debugResponse: nil).map({ (response: GetMeetingRoomsStatusInformationResponse) -> [RustPB.Calendar_V1_MeetingRoomInformation] in
            return calendarIDs.compactMap({
                if let info = response.statusInformation[$0]?.information {
                    return info
                }
                return nil
            })
        }
        )
    }

    func getMeetingRoomDetailInfoWithStatus(by calendarIDs: [String],
                                            startTimeZone: String,
                                            startTime: Date,
                                            endTime: Date,
                                            rrule: String,
                                            // 日程三元组信息，跨租户鉴权需要
                                            eventUniqueFields: CalendarEventUniqueField? = nil) -> Observable<[StatusInformation]> {
        var request = GetMeetingRoomsStatusInformationRequest()
        request.calendarIds = calendarIDs
        request.startTime = Int64(startTime.timeIntervalSince1970)
        request.endTime = Int64(endTime.timeIntervalSince1970)
        request.startTimezone = startTimeZone
        request.eventRrule = rrule
        if let eventUniqueFields = eventUniqueFields {
            request.resourceEventInfo = eventUniqueFields
        }

        let reqParams = ["calendarIds": request.calendarIds.description,
                         "startTime": request.startTime.description,
                         "endTime": request.endTime.description,
                         "eventRrule": request.eventRrule,
                         "needSubscriberInfo": false.description]

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { $0.statusInformation
                    .mapValues { "status: \($0.status.rawValue.description)" + "unusableReasons: \($0.unusableReasons.debugDescription)" }
            }).map({ (response: GetMeetingRoomsStatusInformationResponse) -> [StatusInformation] in
                return calendarIDs.compactMap({
                    if let statusInfo = response.statusInformation[$0] {
                        return statusInfo
                    }
                    return nil
                })
            })
    }

    func pullEventIndividualSimpleAttendeeList(
        calendarID: String,
        key: String,
        originalTime: Int64
    ) -> Observable<PullEventIndividualSimpleAttendeeListResponse> {
        var request = PullEventIndividualSimpleAttendeeListRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
    }

    func pullAttendeeDisplayInfoList(chatterIds: [String],
                                     chatIds: [String]) -> Observable<[Rust.AttendeeDisplayInfo]> {
        var request = PullAttendeeDisplayInfoListRequest()
        request.chatterIds = chatterIds
        request.chatIds = chatIds

        return rustService.async(message: request,
                                 debugParams: ["chatterIds": chatterIds.description,
                                               "chatIds": chatIds.description], debugResponse: nil)
        .map({ (response: PullAttendeeDisplayInfoListResponse) -> [Rust.AttendeeDisplayInfo] in
            return response.attendeeDisplayInfos
        })
    }

    func pullEventGroupsSimpleAttendeeList(
        calendarID: String,
        key: String,
        originalTime: Int64
    ) -> Observable<PullEventGroupsSimpleAttendeeListResponse> {
        var request = PullEventGroupsSimpleAttendeeListRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
    }

    func pullDepartmentChatterIDs(_ departmentIds: [String]) -> Observable<Rust.PullDepartmentChatterIDsResponse> {
        var request = Rust.PullDepartmentChatterIDsRequest()
        request.departmentIds = departmentIds
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
    }

    func getAttendees(uids: [String]) -> Observable<[PBAttendee]> {

        var request = GetAttendeesByChatterIdsRequest()
        request.chatterIds = uids

        return rustService.async(message: request, debugParams: ["uids": uids.description], debugResponse: nil)
            .map({ (response: GetAttendeesByChatterIdsResponse) -> [PBAttendee] in
                let attendees = response.chatterIDAttendees
                return uids.compactMap({
                    if let pb = attendees[$0] {
                        return PBAttendee(pb: pb)
                    }
                    return nil
                })
            })
    }

    func pullGroupChatterCalendarIDs(chatIDs: [String], pageToken: String? = nil) -> Observable<Server.PullGroupChatterCalendarIDsResponse> {
        var request = Server.PullGroupChatterCalendarIDsRequest()
        request.chatID = chatIDs
        request.pageToken = pageToken ?? ""
        let reqParams: [String: String] = ["chatIDs": chatIDs.description, "pageToken": request.pageToken]

        return rustService.sendPassThroughAsyncRequest(
            request, serCommand: .pullGroupChatterCalendarIds, debugParams: reqParams, debugResponse: nil)
        .flatMap { [weak self] (prevResponse: Server.PullGroupChatterCalendarIDsResponse) -> Observable<Server.PullGroupChatterCalendarIDsResponse> in
            guard let self = self, prevResponse.hasMore_p else { return .just(prevResponse) }

            return self.pullGroupChatterCalendarIDs(chatIDs: chatIDs, pageToken: prevResponse.pageToken).map { (nextResponse: Server.PullGroupChatterCalendarIDsResponse) in
                var prevResponse = prevResponse
                nextResponse.chatChatterIdsMap.forEach { (key: String, value: Server.ChatChatterIds) in
                    let prevChatterIds = prevResponse.chatChatterIdsMap[key]?.chatterIds ?? []
                    let nextChatterIds = value.chatterIds
                    var chatterIds = Set(prevChatterIds)
                    chatterIds.union(Set(nextChatterIds))
                    var chatChatterIdsPack = Server.ChatChatterIds()
                    chatChatterIdsPack.chatterIds = chatterIds.map { $0 }

                    prevResponse.chatChatterIdsMap[key] = chatChatterIdsPack
                }

                return prevResponse
            }
        }
    }

    func checkCollaborationPermission(uids: [String]) -> Observable<[String]> {
        guard !uids.isEmpty else { return .just([]) }
        var request = ServerPB_Calendarevents_CheckUserCollaborationPermRequest()
        request.checkUserIds = uids
        return rustService.sendPassThroughAsyncRequest(
            request, serCommand: .checkUserCollaborationPerm, debugParams: ["uidsToCheck": request.checkUserIds.description],
            debugResponse: { ["forbiddenUIDs": $0.userCollaborationForbiddenList.description] }
        ).map { (response: ServerPB_Calendarevents_CheckUserCollaborationPermResponse) -> [String] in
            return response.userCollaborationForbiddenList
        }
    }

    func checkCollaborationPermissionIgnoreError(uids: [String]) -> Observable<[String]> {
        return checkCollaborationPermission(uids: uids).catchErrorJustReturn([])
    }

    func pullChatLimitInfo(chatIDs: [String],
                           parentResponse: [String: Rust.GetChatLimitInfoResponse]? = nil) -> Observable<[String: Rust.GetChatLimitInfoResponse]> {
        let parentResponse = parentResponse ?? [:]
        guard parentResponse.count != chatIDs.count else { return .just(parentResponse) }
        guard let chatID = chatIDs.first(where: { !parentResponse.keys.contains($0) }) else {
            return .just(parentResponse)
        }

        var request = Rust.GetChatLimitInfoRequest()
        request.chatID = chatID

        return rustService.async(message: request,
                                 debugParams: ["chatID": request.chatID],
                                 debugResponse: nil)
        .flatMap { [weak self] (response: Rust.GetChatLimitInfoResponse) -> Observable<[String: Rust.GetChatLimitInfoResponse]> in
            guard let self = self else { return .empty() }
            var parentResponse = parentResponse
            parentResponse[request.chatID] = response
            return self.pullChatLimitInfo(chatIDs: chatIDs, parentResponse: parentResponse)
        }

    }

    typealias GroupInfos = (groupDisplayInfos: [Rust.AttendeeDisplayInfo],
                            limitMap: [String: Rust.GetChatLimitInfoResponse],
                            groupChatterInfo: Server.PullGroupChatterCalendarIDsResponse)

    func getGroupFakeAttendees(groupIds: [String], primaryCalendarID: String) -> Observable<[PBAttendee]> {
        guard !groupIds.isEmpty else { return .just([]) }
        return self.pullAttendeeDisplayInfoList(chatterIds: [], chatIds: groupIds)
            .flatMap { [weak self] chatMap -> Observable<GroupInfos> in
                guard let self = self else { return .empty() }

                return self.pullChatLimitInfo(chatIDs: groupIds).map { limitMap in
                    (groupDisplayInfos: chatMap,
                     limitMap: limitMap)
                }.flatMap { [weak self] maps -> Observable<GroupInfos> in
                    guard let self = self else { return .empty() }

                    return self.pullGroupChatterCalendarIDs(chatIDs: groupIds, pageToken: "").map { chatterInfo in
                        (groupDisplayInfos: maps.0,
                         limitMap: maps.1,
                         groupChatterInfo: chatterInfo)
                    }
                }
            }
            .map { (groupInfos: GroupInfos) -> [PBAttendee] in
                return groupInfos.groupChatterInfo.chatChatterIdsMap.compactMap { (chatID: String, chatterIDs: ServerPB_Calendars_ChatChatterIds) in
                    guard let displayInfo = groupInfos.groupDisplayInfos.first(where: {
                        $0.group.chatID == chatID
                    }) else {
                        return nil
                    }

                    guard let showMemberLimit = groupInfos.limitMap[chatID]?.showMemberLimit else { return nil }
                    guard let openSecurity = groupInfos.limitMap[chatID]?.openSecurity else { return nil }
                    let isUserCountVisible = groupInfos.limitMap[chatID]?.isUserCountVisible ?? false
                    return PBAttendee(chatID: chatID,
                                      chatterIDs: chatterIDs.chatterIds.map { "\($0)" },
                                      forbidenChatterIDs: groupInfos.groupChatterInfo.chatUserCollaborationForbiddenMap[chatID]?.chatterIds ?? [],
                                      chatterCalendarIdMap: groupInfos.groupChatterInfo.chatterCalendarIDMap,
                                      displayInfo: displayInfo,
                                      primaryCalendarID: primaryCalendarID,
                                      showMemberLimit: showMemberLimit,
                                      openSecurity: openSecurity,
                                      isUserCountVisible: isUserCountVisible)
                }
            }
    }

    // 分页拉取独立参与人
    func pullEventIndividualAttendees(
        calendarID: String,
        originalTime: Int64,
        key: String,
        eventVersion: String,
        pageToken: String,
        pageSize: Int32
    ) -> Observable<PullEventIndividualAttendeesResponse> {
        var request = PullEventIndividualAttendeesRequest()
        request.calendarID = calendarID
        request.originalTime = originalTime
        request.key = key
        request.pageToken = pageToken
        request.eventVersion = eventVersion
        request.pageSize = pageSize
        request.needsAllAttendees = false

        let debugParams = [
            "calendarID": calendarID,
            "originalTime": String(originalTime),
            "key": key,
            "eventVersion": eventVersion,
            "pageToken": pageToken,
            "pageSize": String(pageSize),
            "needsAllAttendees": request.needsAllAttendees.description
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil)
    }

    // 一次性拉取全量参与人
    func pullEventAllIndividualAttendees(
        calendarID: String,
        originalTime: Int64,
        key: String,
        eventVersion: String,
        pageToken: String
    ) -> Observable<PullEventIndividualAttendeesResponse> {

        var request = PullEventIndividualAttendeesRequest()
        request.calendarID = calendarID
        request.originalTime = originalTime
        request.key = key
        request.pageToken = pageToken
        request.eventVersion = eventVersion
        request.needsAllAttendees = true

        let debugParams = [
            "calendarID": calendarID,
            "originalTime": String(originalTime),
            "key": key,
            "pageToken": pageToken,
            "eventVersion": eventVersion,
            "needsAllAttendees": request.needsAllAttendees.description
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil)

    }

    // 拉取复制日程有权限的参与人
    func getEventAttendeesForCopyV2(
        calendarID: String,
        key: String,
        originalTime: Int64
    ) -> Observable<Rust.GetEventAttendeesForCopyV2Response> {
        var request = Rust.GetEventAttendeesForCopyV2Request()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime

        let debugParams = [
            "calendarID": calendarID,
            "key": key,
            "originalTime": String(originalTime)
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil)
    }

    func searchMeetingRooms(
        byKeyword keyword: String,
        cursor: Int,
        tenantId: String,
        startDate: Date?,
        endDate: Date?,
        count: Int,
        rruleStr: String?,
        needDisabledResource: Bool,
        minCapacity: Int32 = 0,
        needEquipments: [String] = []
    ) -> Observable<(items: [MeetingRoomSearchItem], cursor: Int, hasMore: Bool)> {
        var request = Rust.SearchMeetingRoomsRequest()
        request.keywords = keyword
        if let startDate = startDate, let endDate = endDate {
            request.startTime = Int64(startDate.timeIntervalSince1970)
            request.endTime = Int64(endDate.timeIntervalSince1970)
        }
        if let rrule = rruleStr {
            request.rrule = rrule
        }
        var meetingRoomFilter = Rust.MeetingRoomFilter()
        meetingRoomFilter.minCapacity = minCapacity
        meetingRoomFilter.needEquipments = needEquipments
        request.meetingRoomFilter = meetingRoomFilter
        request.needDisabledResource = needDisabledResource
        request.count = Int32(count)
        request.cursor = Int32(cursor)
        request.type = .byPage

        let reqParams = [
            "count": request.count.description,
            "cursor": request.cursor.description,
            "startTime": request.startTime.description,
            "endTime": request.endTime.description,
            "rrule": request.rrule,
            "meetingRoomFilter": request.meetingRoomFilter.debugDescription,
            "needDisabledResource": request.needDisabledResource.description
        ]

        let buildingExpand = { (pbBuilding: Calendar_V1_CalendarBuilding) -> [MeetingRoomSearchItem] in
            return pbBuilding.meetingRooms.map { ($0, pbBuilding) }
        }

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { ["count": $0.buildings.flatMap(buildingExpand).count.description, "hasMore": $0.hasMore_p.description] }
        ).map { (response: Rust.SearchMeetingRoomsResponse) -> (items: [MeetingRoomSearchItem], cursor: Int, hasMore: Bool) in
            return (
                items: response.buildings.flatMap(buildingExpand),
                cursor: Int(response.cursor),
                hasMore: response.hasMore_p
            )
        }
    }

    // 分页拉取webinar参与人
    func getWebinarIndividualAttendees(
        calendarID: String,
        webinarType: WebinarAttendeeType,
        pageToken: String,
        pageSize: Int32
    ) -> Observable<GetWebinarIndividualAttendeesByPageResponse> {
        var request = GetWebinarIndividualAttendeesByPageRequest()
        request.eventServerID = calendarID
        request.webinarType = webinarType
        request.pageToken = pageToken
        request.pageSize = pageSize

        let debugParams = [
            "eventServerID": calendarID,
            "webinarType": String(describing: webinarType),
            "pageToken": pageToken,
            "pageSize": String(pageSize)
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: { ["count": $0.attendees.count.description, "hasMore": $0.hasMore_p.description] })
    }

    func searchMeetingRoomsWithMultiLevel(
        byKeyword keyword: String,
        cursor: Int,
        tenantId: String,
        startDate: Date?,
        endDate: Date?,
        count: Int,
        rruleStr: String?,
        needDisabledResource: Bool,
        minCapacity: Int32 = 0,
        needEquipments: [String] = []
    ) -> Observable<(items: [MeetingRoomSearchItem], cursor: Int, hasMore: Bool)> {
        var request = RustPB.Calendar_V1_SearchMeetingRoomsForHierarchicalLevelsRequest()

        request.keyword = keyword
        if let startDate = startDate, let endDate = endDate {
            request.startTime = Int64(startDate.timeIntervalSince1970)
            request.endTime = Int64(endDate.timeIntervalSince1970)
        }
        if let rrule = rruleStr {
            request.rrule = rrule
        }
        request.cursor = Int32(cursor)
        var meetingRoomFilter = Rust.MeetingRoomFilter()
        meetingRoomFilter.minCapacity = minCapacity
        meetingRoomFilter.needEquipments = needEquipments
        request.meetingRoomFilter = meetingRoomFilter
        request.needDisabledResource = true
        request.count = Int32(count)

        let reqParams = [
            "count": request.count.description,
            "startTime": request.startTime.description,
            "endTime": request.endTime.description,
            "rrule": request.rrule,
            "meetingRoomFilter": request.meetingRoomFilter.debugDescription,
            "needDisabledResource": request.needDisabledResource.description
        ]

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { ["count": $0.resources.count.description, "hasMore": $0.hasMore_p.description] }
        ).map { (response: RustPB.Calendar_V1_SearchMeetingRoomsForHierarchicalLevelsResponse) -> (items: [MeetingRoomSearchItem], cursor: Int, hasMore: Bool) in
            let items = response.resources.map { ($0, Rust.Building()) }
            return (
                items: items,
                cursor: Int(response.cursor),
                hasMore: response.hasMore_p
            )
        }
    }

    func getUnusableMeetingRooms(
        startDate: Date, endDate: Date, eventRRule: String, eventOriginTime: Int64,
        resourceStatusInfoArray: [Rust.ResourceStatusInfo]
    ) -> Observable<Rust.UnusableReasonMap> {
        let eventStartTime = String(Int64(startDate.timeIntervalSince1970))
        let eventEndTime = String(Int64(endDate.timeIntervalSince1970))

        var request = Rust.GetUnusableMeetingRoomsRequest()
        request.resourceInfo = resourceStatusInfoArray
        request.eventStartTime = eventStartTime
        request.eventEndTime = eventEndTime
        request.eventRrule = eventRRule
        request.eventOriginalTime = eventOriginTime
        return rustService.async(message: request, debugParams: [
            "startTime": eventStartTime,
            "endTime": eventEndTime,
            "rrule": eventRRule,
            "eventOriginalTime": String(eventOriginTime)
        ], debugResponse: { response in
            response.unusableReasons.mapValues { reasons in
                reasons.unusableReasons.map({ String($0.rawValue) }).description
            }
        })
        .map { (response: Rust.GetUnusableMeetingRoomsResponse) -> Rust.UnusableReasonMap in
            return response.unusableReasons
        }
    }

    func getMeetingRoomReserveStatusFromServer(
        startTime: Date, endTime: Date, eventRrule: String,
        startTimezone: String, roomCalendarIDs: [String],
        eventUniqueFields: Server.CalendarEventUniqueField? = nil
    ) -> Observable<[String: ServerPB_Calendarevents_GetMeetingRoomsReserveStatusResponse.StatusInformation]> {
        var request = ServerPB_Calendarevents_GetMeetingRoomsReserveStatusRequest()
        let eventStartTime = String(Int64(startTime.timeIntervalSince1970))
        let eventEndTime = String(Int64(endTime.timeIntervalSince1970))

        request.startTime = eventStartTime
        request.endTime = eventEndTime
        request.eventRrule = eventRrule
        request.startTimezone = startTimezone
        request.roomCalendarIds = roomCalendarIDs
        if let eventUniqueFields = eventUniqueFields {
            request.eventUniqueFields = eventUniqueFields
        }

        let reqParams = ["startTime": request.startTime,
                         "endTime": request.endTime,
                         "eventRrule": request.eventRrule,
                         "startTimezone": request.startTimezone,
                         "roomCalendarIds": request.roomCalendarIds.debugDescription,
                         "eventUniqueFields": request.eventUniqueFields.debugDescription]

        return rustService.sendPassThroughAsyncRequest(
            request, serCommand: .getMeetingRoomsReserveStatus, debugParams: reqParams,
            debugResponse: { $0.statusInformation.mapValues { $0.debugDescription } }
        ).map { (response: ServerPB_Calendarevents_GetMeetingRoomsReserveStatusResponse) -> [String: ServerPB_Calendarevents_GetMeetingRoomsReserveStatusResponse.StatusInformation] in
            return response.statusInformation
        }
    }

    func getResourceSubscribeUsage(startTime: Date,
                                    endTime: Date,
                                    rrule: String,
                                    key: String,
                                    originalTime: Int64) -> Observable<Bool> {
        var request = ServerPB_Calendarevents_PullResourceSubscribeUsageRequest()
        request.startTime = String(Int64(startTime.timeIntervalSince1970))
        request.endTime = String(Int64(endTime.timeIntervalSince1970))
        request.timezone = TimeZone.current.identifier
        request.rrule = rrule
        request.uid = key
        request.originalTime = "\(originalTime)"

        let reqParams = ["startTime": request.startTime,
                         "endTime": request.endTime,
                         "timezone": request.timezone]

        return rustService.sendPassThroughAsyncRequest(
            request, serCommand: .pullResourceSubscribeUsage, debugParams: reqParams,
            debugResponse: { ["maxUsage": $0.maxUsage.description] }
        ).map { (response: ServerPB_Calendarevents_PullResourceSubscribeUsageResponse) -> Bool in
            // 新版本只有 is_over_usage_limit 有意义
            return response.isOverUsageLimit
        }
    }

    func getMeetingRooms(
        inBuilding buildingId: String,
        tenantId: String,
        startDate: Date,
        endDate: Date,
        rruleStr: String?,
        needDisabledResource: Bool,
        minCapacity: Int32 = 0,
        needEquipments: [String] = []
    ) -> Observable<([Rust.MeetingRoom], [String: Rust.LevelAdjustTimeInfo])> {
        var request = Rust.GetMeetingRoomsInBuildingRequest()
        request.buildingIds = [buildingId]
        request.startTime = Int64(startDate.timeIntervalSince1970)
        request.endTime = Int64(endDate.timeIntervalSince1970)
        request.needDisabledResource = needDisabledResource
        var meetingRoomFilter = Rust.MeetingRoomFilter()
        meetingRoomFilter.minCapacity = minCapacity
        meetingRoomFilter.needEquipments = needEquipments
        request.meetingRoomFilter = meetingRoomFilter
        if let rruleStr = rruleStr {
            request.rrule = rruleStr
        }

        let debugParams = ["buildingIds": request.buildingIds.description,
                           "startTime": request.startTime.description,
                           "endTime": request.endTime.description,
                           "needDisabledResource": request.needDisabledResource.description]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: { $0.resources.mapValues { $0.calendarID } })
            .map { (response: Rust.GetMeetingRoomsInBuildingResponse) -> ([Rust.MeetingRoom], [String: Rust.LevelAdjustTimeInfo]) in
                return (Array(response.resources.values), response.buildingIDToAdjustTimeInfo)
            }
    }

    func getMeetingRooms(inBuilding building: MeetingRoomBuilding,
                         startTime: Date,
                         endTime: Date,
                         rrule: String?,
                         currentTenantId: String,
                         needDisabledResource: Bool) -> Observable<[CalendarMeetingRoom]> {
        var request = GetMeetingRoomsInBuildingRequest()
        request.buildingIds = [building.id]
        request.startTime = Int64(startTime.timeIntervalSince1970)
        request.endTime = Int64(endTime.timeIntervalSince1970)
        request.needDisabledResource = needDisabledResource
        if let rrule = rrule {
            request.rrule = rrule
        }
        let debugParams = ["buildingIds": request.buildingIds.description,
                           "startTime": request.startTime.description,
                           "endTime": request.endTime.description,
                           "needDisabledResource": request.needDisabledResource.description]
        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil)
            .map({ (response: GetMeetingRoomsInBuildingResponse) -> [CalendarMeetingRoom] in
                return response.resources.values.map({ (resource) -> CalendarMeetingRoom in
                    return CalendarMeetingRoom.makeMeetingRoom(fromResource: resource,
                                                               buildingName: building.name,
                                                               tenantId: currentTenantId)
                    })
            })
    }

    func getAllMeetingRooms(startTime: Date, endTime: Date) -> Observable<[Rust.MeetingRoom]> {
        var request = Rust.GetAllMeetingRoomRequest()
        request.startTime = Int64(startTime.timeIntervalSince1970)
        request.endTime = Int64(endTime.timeIntervalSince1970)

        return rustService.async(
            message: request, debugParams: ["startTime": request.startTime.description, "endTime": request.endTime.description],
            debugResponse: nil
        ).map({ (response: Rust.GetAllMeetingRoomResponse) -> [Rust.MeetingRoom] in
            return Array(response.resources.values)
        })
    }

    func closeEventReminderCard(calendarID: String,
                                key: String,
                                originalTime: Int64,
                                startTime: Int64,
                                minutes: Int32) -> Observable<Void> {
        var request = CloseEventReminderCardRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        request.startTime = startTime
        request.minutes = minutes

        return rustService.async(message: request,
                                 debugParams: ["calendarID": calendarID,
                                               "key": key,
                                               "originalTime": String(originalTime),
                                               "startTime": String(startTime),
                                               "minutes": String(minutes)])
    }

    func getChatters(userIds: [String]) -> Observable<[String: RustPB.Basic_V1_Chatter]> {
        var request = MGetChattersRequest()
        request.chatterIds = userIds
        return rustService.async(message: request, debugParams: ["userIds": request.chatterIds.description]) { (res: MGetChattersResponse) in
            res.entity.chatters.mapValues { $0.id }
        }.map({ (response) -> [String: Chatter] in
            return response.entity.chatters
        })
    }

    func getChatters(calendarIDs: [String]) -> Observable<[String: Chatter]> {

        var request = GetChattersByCalendarIdsRequest()
        request.calendarIds = calendarIDs

        return rustService.async(message: request, debugParams: ["calendarIDs": calendarIDs.description]) { (res: GetChattersByCalendarIdsResponse) in
            res.chatters.mapValues { $0.id }
        }.map({ (response) -> [String: Chatter] in
            return response.chatters
        })
    }

    // 外部感知 error 事件
    func getCalendarSettings() -> Observable<Setting> {
        var request = GetCalendarSettingsRequest()

        return rustService.async(message: request, debugParams: nil, debugResponse: {
            var respDesc: String = """
                [
                showRejectedSchedule: \($0.settings.showRejectedSchedule),
                bindGoogleCalendar: \($0.settings.bindGoogleCalendar),
                remindNoDecline: \($0.settings.remindNoDecline),
                notifyWhenGuestsDecline: \($0.settings.notifyWhenGuestsDecline),
                weekStartDay: \($0.settings.weekStartDay),
                timezone: \($0.settings.timezone)
                ]
            """
            #if DEBUG || ALPHA
            respDesc = (try? $0.jsonString()) ?? "error"
            #endif
            return ["response": respDesc]
        }).map { (response: GetCalendarSettingsResponse) -> Setting in
            return SettingModel(pb: response.settings)
        }
    }

    // 外部不感知 error 事件，如果 error，再请求一次
    func getCalendarSettingsTwiceIfError() -> Observable<Setting> {
        let request = GetCalendarSettingsRequest()

        return rustService.async(message: request, debugParams: nil, debugResponse: {
                var respDesc: String = """
                    [
                    showRejectedSchedule: \($0.settings.showRejectedSchedule),
                    bindGoogleCalendar: \($0.settings.bindGoogleCalendar),
                    remindNoDecline: \($0.settings.remindNoDecline),
                    notifyWhenGuestsDecline: \($0.settings.notifyWhenGuestsDecline),
                    weekStartDay: \($0.settings.weekStartDay),
                    timezone: \($0.settings.timezone)
                    ]
                """
                #if DEBUG || ALPHA
                respDesc = (try? $0.jsonString()) ?? "error"
                #endif
                return ["response": respDesc]
            })
            .retry(1)
            .map({ (response: GetCalendarSettingsResponse) -> Setting in
                return SettingModel(pb: response.settings)
            }).catchError({ [weak self] (_) -> Observable<Setting> in
                return .just(SettingModel())
            })
    }

    func getCalendarTenantSetting(
        with row: Calendar_V1_CalendarTenantSettingsRow,
        from source: GetCalendarTenantSettingsRequest.Source
    ) -> Observable<CalendarTenantSetting> {
        var request = GetCalendarTenantSettingsRequest()
        request.row = row
        request.source = source
        let reqParam = ["source": request.source.rawValue.description,
                        "row": request.row.debugDescription]
        return rustService.async(
            message: request, debugParams: reqParam,
            debugResponse: { ["tenantSetting": $0.tenantSettings.debugDescription] }
        ).map({ (response: GetCalendarTenantSettingsResponse) -> CalendarTenantSetting in
                return response.tenantSettings
        })
    }

    func saveCalendarSettings(setting: CalendarSetting, editOtherTimezones: Bool = false) -> Observable<Void> {
        var request = SetCalendarSettingsRequest()
        request.settings = setting
        request.editOtherTimezones = editOtherTimezones
        return rustService.async(message: request, debugParams: ["setting": setting.debugDescription])
    }

    func getSettingExtension() -> Observable<SettingExtension> {
        var request = GetSettingsRequest()
        request.fields = ["calendar_config", "notes_template_category_id_config"]

        return rustService.async(message: request, debugParams: nil, debugResponse: nil).map({ (resp: GetSettingsResponse) -> SettingExtension in
            var eventAttendeeLimit: Int = 2000
            var attendeeTimeZoneEnableLimit: Int = 300
            var exchangeHelperUrl: String = ""
            var outlookHelperUrl: String = ""
            var departmentMemberUpperLimit: Int = 1000
            var vcCalendarMeeting: Int?
            if let numData = resp.fieldGroups["calendar_config"]?.data(using: .utf8),
               let numJson = try? JSONSerialization.jsonObject(with: numData, options: []) as? [String: Any]
            {
                eventAttendeeLimit = numJson["event_attendee_limit"] as? Int ?? 2000
                attendeeTimeZoneEnableLimit = min(numJson["attendee_timezone_enable_limit"] as? Int ?? 300, 300)
                exchangeHelperUrl = numJson["exchange_helper"] as? String ?? ""
                outlookHelperUrl = numJson["outlook_helper"] as? String ?? ""
                departmentMemberUpperLimit = numJson["max_individual_attendee_num_from_department"] as? Int ?? 1000
            }
            if let templateData = resp.fieldGroups["notes_template_category_id_config"]?.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: templateData, options: []) as? [String: Any],
               let categoryId = json["calendar_create"] as? Int
            {
                vcCalendarMeeting = categoryId
            }
            return SettingExtension(eventAttendeeLimit: eventAttendeeLimit,
                                    attendeeTimeZoneEnableLimit: attendeeTimeZoneEnableLimit,
                                    exchangeHelperUrl: exchangeHelperUrl,
                                    departmentMemberUpperLimit: departmentMemberUpperLimit,
                                    outlookHelperUrl: outlookHelperUrl,
                                    vcCalendarMeeting: vcCalendarMeeting)
        })
    }

    func getColorIndexMap(originalColor: [Int32]) -> Observable<[Int32: ColorIndex]> {
        var request = RustPB.Calendar_V1_GetNearestColorIndexRequest()
        request.colors = originalColor

        return rustService.async(message: request, debugParams: ["originalColor": request.colors.description], debugResponse: nil)
            .map({ (response: RustPB.Calendar_V1_GetNearestColorIndexResponse) -> [Int32: ColorIndex] in
                return response.colors
            })
    }

    func getConfigSetting() -> Observable<GetConfigSettingsResponse> {
        let request = GetConfigSettingsRequest()
        return rustService.async(message: request, debugParams: nil) { (res: GetConfigSettingsResponse) in
            let key = "response"
            var resData = [key: ""]
            #if DEBUG || ALPHA
            if let str = try? res.jsonString() {
                resData[key] = str
            } else {
                resData[key] = "error"
            }
            #endif
            return resData
        }
    }

    func markRedDotDisappear(items: [RedDotUiItem]) -> Observable<MarkRedDotsDisappearResponse> {
        var request = MarkRedDotsDisappearRequest()
        request.redDotItems = items

        return rustService.async(message: request, debugParams: ["RedDotUiItemCount": String(items.count)], debugResponse: nil)
    }

    func subscribeCalendar(with calendarId: String) -> Observable<Bool> {
        var request = SubscribeCalendarRequest()
        request.calendarID = calendarId

        return rustService.async(message: request, debugParams: ["subscribeCalendar'sID": calendarId], debugResponse: nil)
            .do(onNext: { [weak self] _ in
                self?.calendarSubscribeTracer?.subscribeStart(calendarID: calendarId)
            }).map({ (response: SubscribeCalendarResponse) -> Bool in
                return response.calendar.selfAccessRole == .owner
            })
    }

    func unsubscribeCalendar(with calendarId: String) -> Observable<UnsubscribeCalendarResponse> {
        var request = UnsubscribeCalendarRequest()
        request.calendarID = calendarId
        return rustService.async(message: request, debugParams: ["unsubscribeCalendar'sID": calendarId]) { response in
            ["code": response.code.description]
        }
    }

    func mapToMultiCalendarSearchModel(_ response: MultiCalendarSearchResponse) -> [MultiCalendarSearchModel] {
        return response.contents.map({ (content) -> MultiCalendarSearchModel in
            func getStatus(with content: Calendar_V1_MultiCalendarSearchContent) -> SubscribeStatus {
                var status: SubscribeStatus = .noSubscribe
                if content.isPrivate && !content.isMember {
                    status = .privated
                } else {
                    status = .none
                }
                return status
            }

            let status = getStatus(with: content)
            let chatterID = response.calendarChatterMap[content.calendarID]
            let chatter = response.chatterMap[chatterID ?? ""]
            let isExternal = FG.optimizeCalendar && chatter?.tenantID != calendarDependency.currentUser.tenantId && !(chatter?.tenantID.isEmpty ?? true)
            let cellContent = MultiCalendarSearchModel(title: (FG.useChatterAnotherName ? chatter?.nameWithAnotherName : chatter?.localizedName) ?? content.title,
                                                       subNum: FG.showSubscribers ? Int(content.subscriberNum) : 0,
                                                       subTitle: content.subtitle,
                                                       avatarKey: chatter?.avatar.key ?? content.coverImageSet.key,
                                                       isDismissed: content.isDismissed,
                                                       subscribeStatus: status,
                                                       calendarID: content.calendarID,
                                                       chatterID: chatterID,
                                                       chatter: chatter,
                                                       isOwner: false,
                                                       isExternal: isExternal)
            return cellContent
        })
    }

    func multiSearchCalendars(query: String, offset: Int32, count: Int32, searchSharedCalendar: Bool, searchPrimaryCalendar: Bool) -> Observable<[MultiCalendarSearchModel]> {
        var request = MultiCalendarSearchRequest()
        request.query = query
        request.offset = offset
        request.count = count
        request.needSearchExternalPrimaryCalendar = FG.optimizeCalendar
        request.needSearchMeetingRoom = false
        request.needSearchSharedCalendar = searchSharedCalendar
        request.needSearchPrimaryCalendar = searchPrimaryCalendar

        let reqParams = ["query": request.query,
                         "offset": request.offset.description,
                         "count": request.count.description,
                         "searchMeetingRoom": false.description,
                         "searchSharedCalendar": request.needSearchSharedCalendar.description,
                         "searchPrimaryCalendar": request.needSearchPrimaryCalendar.description]

        return rustService.async(message: request, debugParams: reqParams, debugResponse: nil)
            .map({ [weak self] (response: MultiCalendarSearchResponse) -> [MultiCalendarSearchModel] in
            return self?.mapToMultiCalendarSearchModel(response) ?? [MultiCalendarSearchModel]()
        })
    }

    func snycGetReadableRrule(_ rrule: String, timezone: String) -> Observable<ReadableRRule> {
        let languageStr = LanguageManager.currentLanguage
        var languageType = LanguageType.enUs
        // 后续如果添加新的语言，这一块需要补充 cases
        switch languageStr {
        case .zh_CN:
            languageType = .zhCn
        case .ja_JP:
            languageType = .jaJp
        case .id_ID:
            languageType = .idID
        case .de_DE:
            languageType = .deDe
        case .es_ES:
            languageType = .esEs
        case .fr_FR:
            languageType = .frFr
        case .it_IT:
            languageType = .itIt
        case .pt_BR:
            languageType = .ptBr
        case .vi_VN:
            languageType = .viVn
        case .ru_RU:
            languageType = .ruRu
        case .hi_IN:
            languageType = .hiIn
        case .th_TH:
            languageType = .thTh
        case .ko_KR:
            languageType = .koKr
        case .zh_TW:
            languageType = .zhTw
        case .zh_HK:
            languageType = .zhHk
        case .ms_MY:
            languageType = .msMy
        default:
            languageType = .enUs
        }

        var request = GetParsedRruleTextRequest()
        request.rrule = rrule
        request.languageType = languageType
        request.timezone = timezone
        return rustService.sync(message: request, debugParams: ["rrule": rrule], debugResponse: nil, allowOnMainThread: true)
            .map { (res: GetParsedRruleTextResponse) -> ReadableRRule in
                return ReadableRRule(fullSentance: res.parsedRrule,
                                     repeatPart: res.freqPart,
                                     untilPart: res.untilPart)
            }
    }

    func getArangementInstance(calendarIds: [String],
                               startTime: Int64,
                               endTime: Int64,
                               timeZone: String
        ) -> Observable<ArangementInstanceResponse> {

        var request = MGetServerInstancesRequest()
        request.calendarIds = calendarIds
        request.startTime = startTime
        request.endTime = endTime
        request.timezone = timeZone
        request.workHourCalendarIds = calendarIds

        let reqParams = ["calendarIds": request.calendarIds.description,
                         "startTime": request.startTime.description,
                         "endTime": request.endTime.description,
                         "timezone": request.timezone, "workHourCalendarIds": request.workHourCalendarIds.description]

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { ["insNumBeforeFilter": $0.instances.count.description] }
        ).map({ (response: MGetServerInstancesResponse) -> ArangementInstanceResponse in
            let keysCounter = Dictionary(response.instances.map { ($0.quadrupleStr, 1) }, uniquingKeysWith: +)
            let instances = response.instances
                .filter { (instance ) -> Bool in
                    let isNotSyncFromEmail = FG.syncDeduplicationOpen && (instance.source == .exchange || instance.source == .google) && keysCounter[instance.quadrupleStr] ?? 0 > 1
                    // 忙闲 exchange 同步日程全部过滤 && 非邮件日程同步需要过滤
                    let isDuplicated = instance.isSyncFromLark || isNotSyncFromEmail
                    return !instance.isFree
                        && instance.selfAttendeeStatus != .removed
                        && instance.selfAttendeeStatus != .decline
                        && !isDuplicated
                }.map { CalendarEventInstanceEntityFromPB(withInstance: $0) }
            var calendarIDTimezoneMap = response.calendarIDTimezoneMap
            var workHourSettings = response.workHourSettings
            // filter private infos
            response.privateCalendarIds.keys.forEach {
                calendarIDTimezoneMap.removeValue(forKey: $0)
                workHourSettings.removeValue(forKey: $0)
            }

            workHourSettings.keys.forEach {
                if calendarIDTimezoneMap[$0].isEmpty {
                    workHourSettings.removeValue(forKey: $0)
                }
            }

            return (instances, calendarIDTimezoneMap,
                    workHourSettings, response.privateCalendarIds)
        })
    }

    func getRustInstances(startTime: Int64,
                         endTime: Int64,
                         filterHidden: Bool,
                         timeZone: String?) -> Observable<[Rust.Instance]> {
        let maxRequestTime = Int64(180 * oneDaySeconds)
        guard (endTime - startTime) < maxRequestTime else {
            assertionFailure("days range error \(startTime) to \(endTime)")
            return .error(NSError(domain: "days range error", code: 0, userInfo: nil))
        }

        var request = GetInstancesRequest()
        request.startTime = startTime
        request.endTime = endTime
        request.filterHidden = filterHidden
        if let timeZone = timeZone, !timeZone.isEmpty {
            request.timezone = timeZone
        }

        CalendarMonitorUtil.startTrackGetInstanceTime(querySpan: endTime - startTime)
        return rustService.async(message: request,
                                 debugParams: ["startTime": String(startTime),
                                               "endTime": String(endTime),
                                               "filterHidden": String(filterHidden)],
                                 debugResponse: nil)
            .map({ (response: GetInstancesResponse) -> [Rust.Instance] in
                CalendarMonitorUtil.endTrackGetInstanceTime(dataLength: response.instances.count)
                return response.instances
            })
    }

    func getLocalInstances(for token: SensitivityControlToken,
                           startTime: Int64,
                           endTime: Int64,
                           filterHidden: Bool,
                           timeZone: String?) -> Observable<[Local.Instance]> {
        let maxRequestTime = Int64(180 * oneDaySeconds)
        guard (endTime - startTime) < maxRequestTime else {
            assertionFailure("days range error \(startTime) to \(endTime)")
            return .error(NSError(domain: "days range error", code: 0, userInfo: nil))
        }
        let localInstance = LocalCalendarManager
            .getLocalEventInstances(for: token,
                                    startTime: startTime,
                                    endTime: endTime,
                                    filterHidden: filterHidden,
                                    timeZone: timeZone)
        return localInstance
    }

    func getEventInstances(startTime: Int64,
                           endTime: Int64,
                           scenarioToken: SensitivityControlToken,
                           ignoreLocal: Bool = false,
                           filterHidden: Bool,
                           timeZone: String?) -> Observable<[CalendarEventInstanceEntity]> {
        let maxRequestTime = Int64(180 * oneDaySeconds)
        guard (endTime - startTime) < maxRequestTime else {
          //  assertionFailure("days range error \(startTime) to \(endTime)")
            return .error(NSError(domain: "days range error", code: 0, userInfo: nil))
        }

        var request = GetInstancesRequest()
        request.startTime = startTime
        request.endTime = endTime
        request.filterHidden = filterHidden
        if let timeZone = timeZone, !timeZone.isEmpty {
            request.timezone = timeZone
        }

        let reqParams = ["startTime": request.startTime.description,
                         "endTime": request.endTime.description,
                         "filterHidden": request.filterHidden.description]

        CalendarMonitorUtil.startTrackGetInstanceTime(querySpan: endTime - startTime)
        let pbInstance = rustService.async(message: request, debugParams: reqParams, debugResponse: nil)
            .map({ (response: GetInstancesResponse) -> [CalendarEventInstanceEntity] in
                CalendarMonitorUtil.endTrackGetInstanceTime(dataLength: response.instances.count)
                return response.instances.map { CalendarEventInstanceEntityFromPB(withInstance: $0) }
            })
//        return pbInstance.logResponse(logger)
        // TODO zhuheng 这里仍旧zip了本地日程，单独调用本地日程可直接调用LocalCalendarManager.getLocalEventInstances
        let observe: Observable<[CalendarEventInstanceEntity]>
        if ignoreLocal {
            observe = pbInstance
        } else {
            let localInstance = LocalCalendarManager
                .getLocalEventInstances(for: scenarioToken,
                                        startTime: startTime,
                                        endTime: endTime,
                                        filterHidden: filterHidden,
                                        timeZone: timeZone)
                .map { (instance) -> [CalendarEventInstanceEntity] in
                    return instance.map { CalendarEventInstanceEntityFromLocal(event: $0) }
                }
            observe = Observable.zip(pbInstance, localInstance) {
                return $0 + $1
            }
        }

        return observe
    }

    func getEvent(calendarId: String, key: String, originalTime: Int64) -> Observable<CalendarEventEntity> {
        return getEventPB(calendarId: calendarId, key: key, originalTime: originalTime)
            .map { PBCalendarEventEntity(pb: $0) }
    }

    func getEventPB(calendarId: String, key: String, originalTime: Int64) -> Observable<CalendarEvent> {
        var request = GetEventRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime
        return rustService.async(message: request,
                                 debugParams: ["calendarId": calendarId,
                                               "key": key,
                                               "originalTime": String(originalTime)]) { response in
            return response.event.debugInfo()
        }.map({ (response: GetEventResponse) -> CalendarEvent in
            response.event
        })

    }

    func saveEvent(
        event: Rust.Event,
        originalEvent: Rust.Event?,
        instance: Rust.Instance?,
        span: RustPB.Calendar_V1_CalendarEvent.Span,
        shareToChatId: String?,
        newSimpleAttendees: Rust.EventSimpleAttendee?,
        originalSimpleAttendees: Rust.EventSimpleAttendee?,
        groupSimpleMembers: [String: [Rust.IndividualSimpleAttendee]]?,
        rejectedUserMap: [String: [Int64]]?,
        createRsvpCardInfo: RustPB.Calendar_V1_EventCreateRsvpCardInfo? = nil,
        instanceRelatedData: Rust.InstanceRelatedData? = nil,
        createEventUid: String = "",
        needRenewalReminder: Bool = false
    ) -> Observable<Rust.Event> {
        CalendarMonitorUtil.startTrackSdkCallTime(command: "saveEvent")

        var request = SaveEventRequest()

        if let newSimpleAttendees = newSimpleAttendees {
            request.newSimpleAttendees = newSimpleAttendees
        }

        if let originalSimpleAttendees = originalSimpleAttendees {
            request.originalSimpleAttendees = originalSimpleAttendees
        }
        request.needRenewalReminder = needRenewalReminder

        if let groupSimpleMembers = groupSimpleMembers {
            request.groupSimpleMembersV2 = groupSimpleMembers.mapValues {
                var attendeePack = Calendar_V1_SimpleAttendees()
                attendeePack.attendees = $0
                return attendeePack
            }
        }

        var event = event
        event.attendees = []  // attendee 与 event 分开存

        request.event = event.strippedGroupMembers()
        if var originalEvent = originalEvent {
            originalEvent.attendees = [] // attendee 与 event 分开存
            let clearGroupMemberEvent = originalEvent.strippedGroupMembers()

            request.originalEvent = clearGroupMemberEvent
        }
        if let instance = instance {
            request.instance = instance
        }

        request.span = span
        if let shareToChatId = shareToChatId {
            request.shareToChatID = shareToChatId
        }

        let data = RustDebug.diffEventInfo(PBCalendarEventEntity(pb: event), originalEvent != nil ? PBCalendarEventEntity(pb: originalEvent!) : nil)

        if let rejectedUserMap = rejectedUserMap {
            request.rejectedUserMap = rejectedUserMap.mapValues({ ids in
                var info = Calendar_V1_SaveEventRequest.RejectedUserInfo()
                info.rejectedUserID = ids
                return info
            })
        }
        
        request.createRsvpCardInfo = createRsvpCardInfo ?? Calendar_V1_EventCreateRsvpCardInfo()

        if let instanceRelatedData = instanceRelatedData {
            request.instanceRelatedData = instanceRelatedData
        }

        /// 用于AI卡片进入编辑场景，预生成key的标识
        if !createEventUid.isEmpty {
            request.createEventUid = createEventUid
        }

        return rustService.async(message: request,
                                 debugParams: data,
                                 debugResponse: { $0.event.debugInfo() })
            .map { (response: SaveEventResponse) -> Rust.Event in
                return response.event
            }.do(
                onCompleted: {
                    CalendarMonitorUtil.endTrackSdkCallTime(command: "saveEvent")
                }
            )
    }

    func saveWebinarEvent(
        event: Rust.Event,
        originalEvent: Rust.Event?,
        newSimpleAttendees: WebinarEventAttendeeInfo?,
        originalSimpleAttendees: WebinarEventAttendeeInfo?,
        rejectedUserMap: [String: [Int64]]?,
        data: String?
    ) -> Observable<Rust.Event> {
        CalendarMonitorUtil.startTrackSdkCallTime(command: "saveWebinarEvent")
        var request = Calendar_V1_SaveWebinarEventRequest()
        request.event = event
        if let originalEvent = originalEvent {
            request.originalEvent = originalEvent
        }
        if let newSimpleAttendees = newSimpleAttendees {
            request.newSimpleAttendees = newSimpleAttendees
        }
        if let originalSimpleAttendees = originalSimpleAttendees {
            request.originalSimpleAttendees = originalSimpleAttendees
        }
        if let rejectedUserMap = rejectedUserMap {
            request.rejectedUserMap = rejectedUserMap.mapValues({ ids in
                var info = Calendar_V1_RejectedUserInfo()
                info.rejectedUserID = ids
                return info
            })
        }
        if let data = data {
            var extraData = RustPB.Calendar_V1_ExtraEventData()
            extraData.data = data
            extraData.dataType = .webinar
            request.extraData = extraData
        }

        let data = RustDebug.diffEventInfo(PBCalendarEventEntity(pb: event), originalEvent != nil ? PBCalendarEventEntity(pb: originalEvent!) : nil)

        return rustService.async(message: request,
                                 debugParams: data,
                                 debugResponse: { $0.calendarEvent.debugInfo() })
            .map { (response: Calendar_V1_SaveWebinarEventResponse) -> Rust.Event in
                return response.calendarEvent
            }.do(
                onCompleted: {
                    CalendarMonitorUtil.endTrackSdkCallTime(command: "saveWebinarEvent")
                }
            )


    }

    func switchEventCalendar(
        from fromCalendarId: String,
        to toCalendarId: String,
        withEventKey eventKey: String,
        originalTime: Int64
    ) -> Observable<Rust.Event> {
        CalendarMonitorUtil.startTrackSdkCallTime(command: "switchEventCalendar")

        var request = Calendar_V1_SwitchEventCalendarRequest()
        request.calendarID = fromCalendarId
        request.destinationCalendarID = toCalendarId
        request.key = eventKey
        request.originalTime = originalTime

        let debugParams = [
            "fromCalendarId": fromCalendarId,
            "toCalendarId": toCalendarId,
            "key": eventKey,
            "originalTime": String(originalTime)
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: { $0.switchedEvent.debugInfo() })
            .map { (response: Calendar_V1_SwitchEventCalendarResponse) -> Rust.Event in
                return response.switchedEvent
            }
            .do(
                onCompleted: { CalendarMonitorUtil.endTrackSdkCallTime(command: "switchEventCalendar") }
            )
    }

    func judgeNotificationBoxType(
        operationType: EventOperationType,
        span: CalendarEvent.Span,
        event: Rust.Event,
        originalEvent: Rust.Event?,
        instanceStartTime: Int64?,
        newSimpleAttendees: Rust.EventSimpleAttendee?,
        originalSimpleAttendees: Rust.EventSimpleAttendee?,
        groupSimpleMembers: [String: [Rust.IndividualSimpleAttendee]]? = nil,
        shareToChatId: String? = nil,
        attendeeTotalNum: Int32? = 0) -> Observable<NotificationBoxParam> {
            
            if event.displayType == .undecryptable || event.disableEncrypt {
                return .just(NotificationBoxParam(notificationInfos: (false, .noNotificationBox),
                                                  meetingRule: .nothing,
                                                  mailRule: .mailRuleNothing,
                                                  chatRule: .meetingChatRuleNothing,
                                                  canCreateRSVPCard: false,
                                                  inviteRSVPChat: Basic_V1_Chat()))
        }

        var request = JudgeNotificationBoxTypeRequest()
        request.operationType = operationType
        request.span = span
        request.event = event
        request.shareToChatID = shareToChatId ?? ""
        request.attendeeTotalNum = attendeeTotalNum ?? 0

        if let groupSimpleMembers = groupSimpleMembers {
            request.groupSimpleMembers = groupSimpleMembers.mapValues {
                var attendeePack = Calendar_V1_SimpleAttendees()
                attendeePack.attendees = $0
                return attendeePack
            }
        }
            
        if let newSimpleAttendees = newSimpleAttendees {
            request.newSimpleAttendees = newSimpleAttendees
        }
        if let originalSimpleAttendees = originalSimpleAttendees {
            request.originalSimpleAttendees = originalSimpleAttendees
        }

        if let originalEvent = originalEvent {
            request.originalEvent = originalEvent
        }
        if let instanceStartTime = instanceStartTime {
            request.instanceStartTime = instanceStartTime
        }

        return rustService.async(message: request,
                                 debugParams: RustDebug.diffRustEventInfo(event, originalEvent),
                                 debugResponse: {
                ["boxType": String($0.boxType.rawValue),
                 "meetingRule": String($0.meetingRule.rawValue),
                 "mailRule": String($0.mailRule.rawValue)]
            })
            .map({ (response: JudgeNotificationBoxTypeResponse) -> NotificationBoxParam in
                return NotificationBoxParam(
                    notificationInfos: (response.forceNotificationDataChanged, response.boxType),
                    meetingRule: response.meetingRule,
                    mailRule: response.mailRule,
                    chatRule: response.meetingChatSpecialRule,
                    canCreateRSVPCard: response.canCreateRsvpCard,
                    inviteRSVPChat: response.inviteRsvpChat)
            })
    }

    func isRSVPCardRemoved(calendarID: String,
                           key: String,
                           originalTime: Int64) -> Observable<(Bool, Any?)> {
        var field = CalendarEventUniqueField()
        field.calendarID = calendarID
        field.key = key
        field.originalTime = originalTime
        return self.getServerEvents(uniqueField: [field]).map({ (entitys) -> (Bool, Any?) in
            guard let entity = entitys.first else {
                return (true, nil)
            }
            return (entity.selfAttendeeStatus == .removed, entity)
        })
    }

    func getServerEvents(uniqueField: [CalendarEventUniqueField]) -> Observable<[CalendarEventEntity]> {
        var request = MGetServerEventsByUniqueFieldsRequest()
        request.uniqueFields = uniqueField
        return rustService.async(message: request, debugParams: ["uniqueField": uniqueField.description], debugResponse: nil)
            .map({ (res: MGetServerEventsByUniqueFieldsResponse) -> [CalendarEventEntity] in
                return res.calendarEvents.map({ (calendarEvent) -> CalendarEventEntity in
                    return PBCalendarEventEntity(pb: calendarEvent)
                })
            })
    }

    /// 更换了SDK接口(通过FG控制)，之前的逻辑是：
    /// 先调用get_calendar_event_info拿到event，如果event的calendarId是当前登陆用户然后从sdk取event（也就是走已加入日程的逻辑）；否则直接显示。
    /// (这么做的原因是后端说如果用卡片消息上的calendarId有点问题)
    /// 新的SDK接口GetSharedCalendarEvent把逻辑收敛到SDK，如果calendar_id不是当前登录用户的id，就从后端取数据，否则返回本地的数据
    func getRemoteEvent(calendarID: String,
                        key: String,
                        originalTime: Int64,
                        token: String?,
                        messageID: String?) -> Observable<(event: CalendarEventEntity, canJoin: Bool)> {
        let debugParams = ["calendarId": calendarID,
                           "key": key,
                           "token": (token ?? ""),
                           "originalTime": String(originalTime),
                           "messageID": messageID ?? ""]

        var request = GetSharedCalendarEventRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        if let messageID = messageID {
            request.messageID = messageID
        }
        if let token = token {
            request.token = token
        }
        return rustService.async(message: request, debugParams: debugParams, debugResponse: { response in
            var dict = response.event.debugInfo() ?? [:]
            dict["canJoin"] = response.isJoinable.description
            return dict
        }).map({ (res: GetSharedCalendarEventResponse) -> (CalendarEventEntity, Bool) in
            let event = PBCalendarEventEntity(pb: res.event)
            let canJoin = res.isJoinable
            return (event, canJoin)
        })
    }

    /// for RSVP card
    func getEventInviteUserId(serverId: String, refidCalendarMap: [String: String], receiverUserId: String?) -> Observable<String?> {
        return self.getServerEvent(serverId: serverId, refidCalendarMap: refidCalendarMap).flatMap({ [weak self] (event) -> Observable<String?> in
            guard let `self` = self else { return .just(event?.userInviteOperatorID) }
            if let receiverUserId = receiverUserId, let receiverUserId = Int64(receiverUserId) {
                return self.checkCanRSVPCommentToOragnizer(receiverUserId: receiverUserId).map { (canSend: Bool) ->  String? in
                    if canSend {
                        return receiverUserId.description
                    } else {
                        return event?.userInviteOperatorID
                    }
                }
            } else {
                return .just(event?.userInviteOperatorID)
            }

        })
    }

    /// getServerEvent
    /// - Parameters:
    ///   - serverId: event serverID
    ///   - refidCalendarMap: eventid & calendarid 的映射
    /// - Returns: CalendarEventEntity
    func getServerEvent(serverId: String,
                        refidCalendarMap: [String: String]) -> Observable<CalendarEventEntity?> {
        if serverId.contains("you must not use local event serverId") {
            assertionFailureLog()
        }

        var request = MGetServerEventsRequest()
        request.isForceUpdated = true
        request.serIds = [serverId]
        request.refidCalendarMap = refidCalendarMap

        return rustService.async(
            message: request, debugParams: ["serverId": request.serIds.description],
            debugResponse: { ["eventInfo": $0.calendarEvents.first?.debugInfo()?.description ?? ""] }
        ).map({ (response: MGetServerEventsResponse) -> CalendarEventEntity? in
            if !response.calendarEvents.isEmpty {
                return PBCalendarEventEntity(pb: response.calendarEvents[0])
            }
            return nil
        })
    }

    func getServerPBEvent(serverId: String) -> Observable<CalendarEvent?> {
        if serverId.contains("you must not use local event serverId") {
            assertionFailureLog()
        }
        var request = MGetServerEventsRequest()
        request.isForceUpdated = true
        request.serIds = [serverId]

        return rustService.async(message: request, debugParams: ["serverId": serverId]) { (res: MGetServerEventsResponse) in
            res.calendarEvents.first?.debugInfo()
        }.map({ (response) -> CalendarEvent? in
            return response.calendarEvents.first
        })
    }

    func getEventApprovalStatus(key: String) -> Observable<Bool> {
        if key.isEmpty {
            assertionFailureLog()
        }
        var request = Calendar_V1_GetEventApprovalStatusRequest()
        request.eventKey = [key]

        return rustService.async(message: request,
                                 debugParams: ["eventKey": key],
                                 debugResponse: { ["eventAttendeeControlStatus": ($0.isEventAttendeeControlApprovalApproved[key] ?? false).description] })
            .map { (response: Calendar_V1_GetEventApprovalStatusResponse) -> Bool in
                return response.isEventAttendeeControlApprovalApproved[key] ?? false
            }.catchError { _ in return .just(false) }
    }

    func replyCalendarEventInvitation(
        calendarId: String,
        key: String,
        originalTime: Int64,
        comment: String,
        inviteOperatorID: String,
        replyStatus: CalendarEventAttendee.Status,
        messageId: String? = nil
    ) -> Observable<(CalendarEventEntity, String, [Int32])> {

        return self.replyCalendarEventInvitationNew(calendarId: calendarId,
                                                    key: key,
                                                    originalTime: originalTime,
                                                    comment: comment,
                                                    inviteOperatorID: inviteOperatorID,
                                                    replyStatus: replyStatus,
                                                    messageId: messageId)
    }

    func removeEvent(_ eventEntity: CalendarEventEntity,
                     instance: CalendarEventInstanceEntity,
                     span: CalendarEvent.Span,
                     scenarioToken: SensitivityControlToken,
                     dissolveMeeting: Bool) -> Observable<Void> {

        if case .webinar = eventEntity.category {
            return removeWebinarEvent(calendarID: eventEntity.calendarId,
                                      uniqueKey: eventEntity.key,
                                      originalTime: eventEntity.originalTime,
                                      notificationType: eventEntity.notificationType)
        }

        if eventEntity.isLocalEvent() {
            do {
                try LocalCalendarManager.deleteEvent(for: scenarioToken, event: eventEntity, span: span)
                return .just(Void())
            } catch {
                SensitivityControlToken.logFailure("delete local event failed, may cause by sensitivity control for :\(scenarioToken), error: \(error)")
                return .error(error)
            }
        }

        var request = DeleteEventRequest()
        request.instance = instance.toPB()
        request.event = eventEntity.getPBModel()
        request.span = span
        request.dissolveMeeting = dissolveMeeting

        var debugParams = eventEntity.getPBModel().debugInfo()?.merging(instance.toPB().debugInfo() ?? [String: String]()) { (l, _) -> String in
            return l
        } ?? [String: String]()
        debugParams["span"] = "\(span)"

        CalendarMonitorUtil.startTrackSdkCallTime(command: "deleteEvent")
        return rustService.async(message: request, debugParams: debugParams)
            .do(onCompleted: {
                CalendarMonitorUtil.endTrackSdkCallTime(command: "deleteEvent")
            })
    }

    func removeWebinarEvent(calendarID: String,
                            uniqueKey: String,
                            originalTime: Int64,
                            notificationType: NotificationType) -> Observable<Void> {
        var request = DeleteWebinarEventRequest()
        request.calendarID = calendarID
        request.uniqueKey = uniqueKey
        request.originalTime = originalTime
        request.notificationType = notificationType

        return rustService.async(message: request, debugParams: nil)
    }

    func getInstancesLayoutRequest(daysInstanceSlotMetrics: [Rust.InstanceLayoutSlotMetric], isSingleDay: Bool) -> Observable<GetInstancesLayoutResponse> {
        var request = GetInstancesLayoutRequest()
        request.daysInstanceSlotMetrics = daysInstanceSlotMetrics
        request.isSingleDay = isSingleDay

        let debugParams = ["DayInstancesSlotMetricCount": String(daysInstanceSlotMetrics.count),
                           "isSingleDay": String(isSingleDay)]
        return rustService.sync(message: request, debugParams: debugParams, debugResponse: { ["daysInstanceLayoutCount": String($0.daysInstanceLayout.count)] }, allowOnMainThread: true)
    }

    func asyncGetInstancesLayoutRequest(daysInstanceSlotMetrics: [Rust.InstanceLayoutSlotMetric], isSingleDay: Bool) -> Observable<GetInstancesLayoutResponse> {
        var request = GetInstancesLayoutRequest()
        request.daysInstanceSlotMetrics = daysInstanceSlotMetrics
        request.isSingleDay = isSingleDay

        return rustService.async(message: request,
                                 debugParams:
                                    ["DayInstancesSlotMetricCount": String(daysInstanceSlotMetrics.count),
                                     "isSingleDay": String(isSingleDay),
                                     "isAsync": "true"],
                                 debugResponse: nil)
    }

    func getMeetingRequest(by chatId: String) -> Observable<GetMeetingsByChatIdsResponse> {
        var request = GetMeetingsByChatIdsRequest()
        request.chatIds = [chatId]
        return rustService.async(message: request, debugParams: ["chatId": chatId]) { response in
            return ["chatMeetingCount": String(response.chatMeetings.count)]
        }
    }

    func asnycMeetingEventRequest(calendarId: String, key: String, originalTime: Int64) -> Observable<GetMeetingEventResponse> {
        var request = GetMeetingEventRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime

        return rustService.async(message: request, debugParams: ["calendarId": calendarId, "key": key]) { (res: GetMeetingEventResponse) in
            return ["MeetingEventID": res.event.id,
                    "MeetingEventKey": res.event.key,
                    "MeetingMeetingID": res.meeting.id,
                    "MeetingChatID": res.meeting.chatID]
        }
    }

    func share(to chatIds: [String],
               eventKey: String,
               originalTime: Int64,
               calendarId: String) -> Observable<ShareCalendarEventMessageResponse> {
            assertLog(!chatIds.isEmpty)
            var request = ShareCalendarEventMessageRequest()
            request.chatIds = chatIds
            request.eventKey = eventKey
            request.calendarID = calendarId
            request.eventOriginalTime = originalTime

        return rustService.async(message: request, debugParams: ["calendarID": calendarId,
                                                                 "chatIds": chatIds.description,
                                                                 "eventKey": eventKey]) { (res: ShareCalendarEventMessageResponse) in
            ["result": "\(res)"]
        }
    }

    func joinToEvent(calendarID: String,
                     key: String,
                     token: String?,
                     originalTime: Int64,
                     messageID: String,
                     requestEvent: Bool = true
    ) -> Observable<JoinCalendarEventResponse.OneOf_Data?> {
        let debugParams = [
            "calendarID": calendarID,
            "messageID": messageID,
            "key": key,
            "token": token ?? "",
            "originalTime": String(originalTime)]

        var joinRequest = JoinCalendarEventRequest()
        joinRequest.calendarID = calendarID
        joinRequest.key = key
        joinRequest.originalTime = originalTime
        joinRequest.messageID = messageID
        joinRequest.requestEvent = requestEvent
        if let token = token {
            joinRequest.token = token
        }
        return rustService.async(message: joinRequest, debugParams: debugParams, debugResponse: { response in
            return ["eventID": response.calendarEvent.id]
        }).map({ (response: JoinCalendarEventResponse) -> JoinCalendarEventResponse.OneOf_Data? in
            return response.data
        })
    }

    func updateToMeeting(calendarID: String,
                         key: String,
                         originalTime: Int64) -> Observable<CalendarMeetingModel> {
        var request = UpgradeToMeetingRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        request.shouldAddToAttendeeList = true

        return rustService.async(message: request, debugParams: ["calendarID": calendarID, "key": key]) { (response: UpgradeToMeetingResponse) in
            [
                "success": "\(response.success)",
                "id": response.meeting.id,
                "chatId": response.meeting.chatID,
                "firstEnter": String(response.meeting.isFirstEntrance),
                "shouldShowScroll": String(response.meeting.shouldShowScroll)
            ]
        }.map({ (res) -> CalendarMeetingModel in
            if !res.success {
                throw(CError.custom(message: "upgrade faild"))
            }
            return CalendarMeetingModel(from: res.meeting, shouldShowMeetingTransfer: false)
        })

    }

    func markMeetingScrollClicked(meetingId: String, type: ServerPB_Entities_ScrollType) -> Observable<Void> {
        var request = MarkMeetingScrollClickedRequest()
        request.meetingID = meetingId
        var scrollType: RustPB.Calendar_V1_ScrollType = .meetingTransferChat
        switch type {
        case .eventInfo:
            scrollType = .eventInfo
        case .meetingTransferChat:
            scrollType = .meetingTransferChat
        @unknown default:
            break
        }
        request.scrollType = scrollType

        return rustService.async(message: request,
                                 debugParams: ["meetingId": meetingId,
                                               "type": String(scrollType.rawValue)])
    }

    func getExceptionEvents(calendarID: String,
                            key: String,
                            startTime: Date? = nil,
                            endTime: Date? = nil) -> Observable<[CalendarEventEntity]> {
        var request = GetExceptionalEventsRequest()
        request.calendarID = calendarID
        request.key = key
        if let startTime = startTime {
            request.startTime = Int64(startTime.timeIntervalSince1970)
        }
        if let endTime = endTime {
            request.endTime = Int64(endTime.timeIntervalSince1970)
        }

        let debugParams = [
            "calendarID": calendarID,
            "key": key,
            "startTime": startTime.map { "\($0)" } ?? "",
            "endTime": endTime.map { "\($0)" } ?? ""
        ]
        return rustService.async(message: request, debugParams: debugParams) { (res: GetExceptionalEventsResponse)  in

            ["exceptionalEvents": res.exceptionalEvents.map { $0.debugInfo()?.description ?? "" }.joined(separator: ",") ]
        }.map({ (res) -> [CalendarEventEntity] in
            return res.exceptionalEvents.map({ PBCalendarEventEntity(pb: $0) })
          })
    }

    func transferEvent(with calendarId: String, key: String, originalTime: Int64, userId: String, removeOriginalOrganizer: Bool) -> Observable<TransferCalendarEventResponse> {
        var request = TransferCalendarEventRequest()
        request.calendarID = calendarId
        request.userID = userId
        request.key = key
        request.needsRemoveOriginalOrganizer = removeOriginalOrganizer
        request.originalTime = originalTime

        let reqParams = ["calendarId": request.calendarID,
                         "key": request.key,
                         "userId": request.userID]

        return rustService.async(message: request, debugParams: reqParams) { res in
            return ["hasTransferBitableURL": res.hasTransferBitableURL.description]
        }
    }

    func isEventRemoved(key: String,
                        calendarId: String,
                        originalTime: Int64) -> Observable<Bool> {
        return getEvent(calendarId: calendarId, key: key, originalTime: originalTime).map { (event) -> Bool in
            return event.selfAttendeeStatus == .removed
        }
    }

    func isEventOnCurrentCalendar(key: String,
                                  calendarId: String,
                                  originalTime: Int64) -> Observable<Bool> {
        return getEvent(calendarId: calendarId, key: key, originalTime: originalTime).catchError({ (_) -> Observable<CalendarEventEntity> in
            return self.getRemoteEvent(calendarID: calendarId, key: key, originalTime: originalTime, token: nil, messageID: nil)
                .map(\.event)
        }).map({ (event) -> Bool in
            return event.calendarId == calendarId
        }).catchErrorJustReturn(false)
    }

    func getBindGoogleCalAddr(forceBindMail: Bool) -> Observable<String> {
        var request = GetGoogleAuthURLRequest()
        request.enableGmail = false
        request.forceEnableMailInvitation = forceBindMail

        let debugParams = ["enableGmail": request.enableGmail.description,
                           "forceBindMail": forceBindMail.description]
        return rustService.async(message: request,
                                 debugParams: debugParams,
                                 debugResponse: nil).map({ (response: GetGoogleAuthURLResponse) -> String in
            return response.authURL
        })
    }

    func cancelImportGoogleCal(account: [String]) -> Observable<Void> {
        var request = RecallGoogleTokenRequest()
        request.externalAccountEmails = account
        return rustService.async(message: request, debugParams: ["externalAccountEmails": account.description])
    }

    func revokeExchangeAccount(account: [String]) -> Observable<Void> {
        var request = RevokeExchangeAccountRequest()
        request.accounts = account
        return rustService.async(message: request, debugParams: ["accounts": account.description])
    }

    func newCalendar(with calendar: CalendarModel, members: [CalendarMember], rejectedUsers: [String]) -> Observable<Void> {
        var request = SaveCalendarWithMembersRequest()
        let pbCalendar = calendar.getCalendarPB()
        let pbMember = members.map { (member) -> RustPB.Calendar_V1_CalendarMember in
            return member.getCalendarMemberPb()
        }
        request.calendar = pbCalendar
        request.members = pbMember
        request.rejectedUserList = rejectedUsers
        return rustService.async(message: request,
                                 debugParams: ["serverId": calendar.serverId,
                                               "member_ids": members.map({ $0.identifier }).description,
                                               "rejectedUsers": rejectedUsers.description])
    }

    func saveCalendar(with saveInfo: RustPB.Calendar_V1_CalendarSaveInfo, isCreating: Bool) -> Observable<[RustPB.Calendar_V1_Calendar]> {
        var request: Message
        if isCreating {
            var createRequest = CreateCalendarRequest()
            createRequest.calendarSaveInfos = [saveInfo]
            request = createRequest
        } else {
            var patchRequest = PatchCalendarRequest()
            patchRequest.calendarSaveInfos = [saveInfo]
            request = patchRequest
        }

        let reqParams = ["isCreating": isCreating.description]

        return rustService.async(message: request, debugParams: reqParams, debugResponse: { ["calendars": $0.calendars.description] })
            .map { (response: CreateCalendarResponse) -> [RustPB.Calendar_V1_Calendar] in
                return response.calendars
            }
    }

    func specifyVisibleOnlyCalendars(ids: [String]) -> Observable<Void> {
        var request = RustPB.Calendar_V1_SpecifyVisibleOnlyCalendarRequest()
        request.ids = ids
        let debugParams = ["calendars": ids.description]
        return rustService.async(message: request, debugParams: debugParams)
    }

    func getCalendarShareInfo(with calendarID: String) -> Observable<Server.CalendarShareInfo> {
        var request = ServerPB_Calendars_GetCalendarShareInfoRequest()
        request.calendarID = calendarID
        let debugParams = ["calendarID": calendarID]
        return rustService.sendPassThroughAsyncRequest(request,
                                                       serCommand: .getCalendarShareInfo,
                                                       debugParams: debugParams, debugResponse: {
            ["share_url": $0.shareURL,
             "owner_uid": $0.ownerInfo.ownerUserID,
             "cover_avatar_key": $0.coverAvatarKey,
             "owner_avatar_key": $0.ownerInfo.ownerAvatarKey]
        })
    }

    func getCalendars(with IDs: [String]) -> Observable<(calendars: [CalendarModel], calendarWithMembers: [CalendarWithMembers])> {
        var request = MGetCalendarsWithIDsRequest()
        request.calendarIds = IDs
        return rustService.async(
            message: request, debugParams: ["IDs": request.calendarIds.description],
            debugResponse: {
                ["CalendarModelCount": $0.calendars.count.description,
                 "calendarWithMembersCount": $0.calendarWithMembers.count.description]
            }).map({ (response: MGetCalendarsWithIDsResponse) -> (calendars: [CalendarModel], calendarWithMembers: [CalendarWithMembers]) in
                let calendars = response.calendars.values.map({ CalendarModelFromPb(pb: $0) })
                let calendarWithMembers = response.calendarWithMembers.map({ CalendarWithMembers(pb: $0) })
                return (calendars, calendarWithMembers)
            })
    }

    func deleteCalendar(with id: String) -> Observable<Void> {
        var request = DeleteCalendarRequest()
        request.id = id
        return rustService.async(message: request, debugParams: ["calendarId": id])
    }

    func getCalendarMembers(with calendarId: String,
                            userIds: [String],
                            chatIds: [String]) -> Observable<[Rust.CalendarMember]> {
        var request = GetCalendarMembersByIdsRequest()
        request.calendarID = calendarId
        request.userIds = userIds
        request.chatIds = chatIds
        let reqParams = ["calendarId": request.calendarID,
                         "userIds": request.userIds.description,
                         "chatIds": request.chatIds.description]
        return rustService.async(message: request, debugParams: reqParams, debugResponse: {
            ["calendarMemberIDs": $0.members.map(\.memberID).description]
        }).map({ (response: GetCalendarMembersByIdsResponse) -> [Rust.CalendarMember] in
            return response.members
        })
    }

    typealias MembersCheckedResult = (members: [Rust.CalendarMember], hasMemberInhibited: Bool, rejectedUsers: [String])
    func getCalendarMembersWithCheck(calendarId: String,
                                     userIds: [String],
                                     chatIds: [String],
                                     ignoreTimeout: Bool = true) -> Observable<MembersCheckedResult> {
        var request = GetCalendarMembersByIdsRequest()
        request.calendarID = calendarId
        request.userIds = userIds
        request.chatIds = chatIds
        let reqParams = ["calendarId": request.calendarID,
                         "userIds": request.userIds.description,
                         "chatIds": request.chatIds.description]

        var chatterCheck = chatIds.isEmpty ? .just([:]) : pullGroupChatterCalendarIDs(chatIDs: chatIds)
            .map(\.chatUserCollaborationForbiddenMap)
        var userCheck = checkCollaborationPermissionIgnoreError(uids: userIds)

        if ignoreTimeout {
            chatterCheck = chatterCheck.timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                .catchErrorJustReturn([:])
            userCheck = userCheck.timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                .catchErrorJustReturn([])
        }

        return Observable.zip(chatterCheck, userCheck, rustService.async(message: request, debugParams: reqParams, debugResponse: nil))
            .map({ (chattersWithRestricted, usersRestricted, response: GetCalendarMembersByIdsResponse) -> MembersCheckedResult in
                var members = response.members.filter { !usersRestricted.contains($0.userID) }
                if !FG.optimizeCalendar {
                    members = members.map({ (member) -> Rust.CalendarMember in
                        // 群成员限制 人数修改
                        if member.memberType == .group, let restrictedGroupMembers = chattersWithRestricted[member.chatID] {
                            var filteredGroup = member
                            filteredGroup.chatMemberCount -= Int32(restrictedGroupMembers.chatterIds.count)
                            return filteredGroup
                        }
                        return member
                    })
                }
                let inhibitedMembersInGroups = chattersWithRestricted.mapValues(\.chatterIds).values.flatMap { $0.map(\.description) }
                let hasInhibitedMember = !usersRestricted.isEmpty || !inhibitedMembersInGroups.isEmpty
                return (members, hasInhibitedMember, inhibitedMembersInGroups)
            })
    }

    func getCalendars<T: CalendarManagerModel>(with id: String,
                                               skinType: CalendarSkinType,
                                               selfUserId: String) -> Observable<T> {
        return getCalendars(with: [id]).map({ (cals, members) -> T in
            guard let cal = cals[safeIndex: 0],
                let calWithMember = members[safeIndex: 0] else {
                    throw CalendarManagerModel.Err.invaildResponseCount
            }
            return T(calendar: cal,
                     members: calWithMember.calendarMember,
                     skinType: skinType,
                     selfUserId: selfUserId)
        })
    }

    func canAppendeedAttendeesSyncToMeeting(event: CalendarEventEntity,
                                            originalEvent: Rust.Event) -> Observable<Bool> {
        var request = JudgeEventAttendeesChangeAffectRequest()
        request.event = event.getPBModel()
        request.originalEvent = originalEvent
        return rustService.async(message: request,
                                 debugParams: ["serverId": event.serverID],
                                 debugResponse: { ["canAppend": ($0.affect == .ok).description] })
            .map({ (response: JudgeEventAttendeesChangeAffectResponse) -> Bool in
                return response.affect == .ok
            })
    }

    func getMeetingroom(with token: String,
                        startTime: Int,
                        endTime: Int,
                        currentTenantId: String) -> Observable<SeizeMeetingRoomModel> {
        var request = GetResourceWithTokenRequest()
        request.resourceToken = token
        request.startTime = Int64(startTime)
        request.endTime = Int64(endTime)

        let reqParams = ["resourceToken": request.resourceToken,
                         "startTime": request.startTime.description,
                         "endTime": request.endTime.description]

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { ["meetingRoom": $0.resource.calendarID,
                              "currentTime": $0.currentTimestamp.description,
                              "shouldShowConfirm": $0.needPopover.description,
                              "instancesNum": $0.eventInstances.count.description,
                              "seizeTime": $0.seizeTime.description]
            }
        ).map({ (response: GetResourceWithTokenResponse) -> SeizeMeetingRoomModel in
                let meetingRoom = CalendarMeetingRoom.makeMeetingRoom(fromResource: response.resource,
                                                                       buildingName: response.building.name,
                                                                       tenantId: currentTenantId)
            let instances = response.eventInstances.map { CalendarEventInstanceEntityFromPB(withInstance: $0) }
            return SeizeMeetingRoomModel(meetingRoom: meetingRoom,
                                         seizeTime: Int(response.seizeTime),
                                         currentTimeStamp: Int(response.currentTimestamp),
                                         shouldShowConfirm: response.needPopover,
                                         instances: instances)
        })
    }

    func seizeMeetingroom(calendarId: String, startTime: Int, endTime: Int) -> Observable<CalendarEventEntity> {
        var request = SeizeResourceRequest()
        request.startTime = Int64(startTime)
        request.endTime = Int64(endTime)
        request.resourceCalendarID = calendarId

        let reqParams = ["resourceCalendarID": request.resourceCalendarID,
                         "startTime": request.startTime.description,
                         "endTime": request.endTime.description]

        return rustService.async(
            message: request, debugParams: reqParams,
            debugResponse: { ["eventKey": $0.event.key] }
        ).map({ (response: SeizeResourceResponse) -> CalendarEventEntity in
            return PBCalendarEventEntity(pb: response.event)
        })
    }

    func setShouldShowPopup(shouldShowPopUp: Bool) -> Observable<Void> {
        var request = SetSeizeResourceWhetherNeedPopUpRequest()
        request.needPopUp = shouldShowPopUp
        return rustService.async(message: request, debugParams: ["needPopUp": request.needPopUp.description])
    }

    func getVideoChatByEvent(calendarID: String,
                         key: String,
                         originalTime: Int,
                         forceRenew: Bool) -> Observable<VideoMeeting> {
        var request = GetVideoMeetingByEventRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = Int64(originalTime)
        request.forceRenew = forceRenew

        let debugParams = [
            "calendarID": calendarID,
            "key": key,
            "origianlTime": "\(originalTime)",
            "forceRenew": "\(forceRenew)"
        ]

        return rustService.async(message: request, debugParams: debugParams) { (response: GetVideoMeetingByEventResponse) in
            ["uniqueId": response.videoMeeting.uniqueID]
        }
        .map({ (response: GetVideoMeetingByEventResponse) -> VideoMeeting in
            return VideoMeeting(pb: response.videoMeeting)
        })
    }

    func getVideoMeetingStatusRequest(instanceDetails: CalendarInstanceDetails, source: VideoMeetingEventType) -> Observable<Server.CalendarVideoChatStatus> {
        var request = ServerPB_Videochat_GetCalendarVchatStatusRequest()
        request.uniqueID = Int64(instanceDetails.uniqueID) ?? 0
        request.calendarInstanceIdentifier.uid = instanceDetails.key
        request.calendarInstanceIdentifier.originalTime = instanceDetails.originalTime
        request.calendarInstanceIdentifier.instanceStartTime = instanceDetails.instanceStartTime
        request.calendarInstanceIdentifier.instanceEndTime = instanceDetails.instanceEndTime
        let reqStart = DispatchTime.now()
        var command: ServerCommand = .getCalendarVchatStatus

        if case .interview = source {
            command = .getInterviewVchatStatus
        }
        return rustService.sendPassThroughAsyncRequest(request, serCommand: command, debugParams: ["uniqueID": instanceDetails.uniqueID, "source": "\(source)"]) { (response: ServerPB_Videochat_GetCalendarVchatStatusResponse) in
            [
                "uniqueID": "\(response.videoChatStatus.uniqueID)",
                "status": "\(response.videoChatStatus.status)"
            ]
        }.map { (response: ServerPB_Videochat_GetCalendarVchatStatusResponse) -> Server.CalendarVideoChatStatus in
            let reqEnd = DispatchTime.now()
            let reqTime = Double(reqEnd.uptimeNanoseconds - reqStart.uptimeNanoseconds) / 1_000_000
            var status = response.videoChatStatus
            status.clientRequestTime = Int64(reqTime)
            return status
        }
    }

    func getVideoLiveHostStatus(associatedId: String) -> Observable<Rust.AssociatedLiveStatus> {
        var request = GetAssociatedLiveStatusWithEventIDRequest()
        request.associatedEventID = associatedId

        let reqStart = DispatchTime.now()

        return rustService.async(message: request, debugParams: ["associatedId": associatedId]) { (response: Videoconference_V1_GetAssociatedLiveStatusWithEventIDResponse) in
            [
                "liveID": response.status.liveID,
                "liveStatus": "\(response.status.liveStatus)"
            ]
        }.map { (response: Videoconference_V1_GetAssociatedLiveStatusWithEventIDResponse) -> Rust.AssociatedLiveStatus in
            let reqEnd = DispatchTime.now()
            let reqTime = Double(reqEnd.uptimeNanoseconds - reqStart.uptimeNanoseconds) / 1_000_000
            var status = response.status
            status.clientRequestTime = Int64(reqTime)
            return status
        }
    }

    func getEvent(uniqueId: String,
                  instance_start_time: Int64,
                  instance_end_time: Int64,
                  original_time: Int64,
                  vchat_meeting_id: String,
                  key: String,
                  startTime: Int64) -> Observable<(eventEntity: CalendarEventEntity, instanceTime: InstanceTime)> {
        var request = GetEventInfoByVideoMeetingIdRequest()
        request.videoMeetingUniqueID = uniqueId
        request.startTime = startTime
        request.instanceStartTime = instance_start_time
        request.instanceEndTime = instance_end_time
        request.originalTime = original_time
        request.key = key
        request.vchatMeetingID = vchat_meeting_id
            return rustService.async(message: request, debugParams: ["uniqueId": uniqueId, "startTime": "\(startTime)"]) { (res: GetEventInfoByVideoMeetingIdResponse) in
                res.event.debugInfo()
            }.map({ (response: GetEventInfoByVideoMeetingIdResponse) -> (eventEntity: CalendarEventEntity, instanceTime: InstanceTime) in
                let eventEntity = PBCalendarEventEntity(pb: response.event)
                let instanceTime = InstanceTime(startTime: response.instanceStartEndTime.startTime, endTime: response.instanceStartEndTime.endTime)
                return (eventEntity: eventEntity, instanceTime: instanceTime)
            })
    }

    func getCanRenewExpiredVideoChat(calendarId: String,
                                     key: String,
                                     originalTime: Int64) -> Observable<Bool> {
        var request = GetCanRenewExpiredVideoMeetingNumberRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime

        return rustService.async(message: request, debugParams: ["calendarId": calendarId, "key": key, "originalTime": "\(originalTime)"]) { (response: GetCanRenewExpiredVideoMeetingNumberResponse) in
            ["canReNew": "\(response.canRenew)"]
        }.map { $0.canRenew }
    }
    func getDocsUrl(by chatId: String) -> Observable<String> {
        var request = CreateMeetingMinuteByChatIdRequest()
        request.chatID = chatId
        return rustService.async(message: request, debugParams: ["chatId": chatId], debugResponse: nil)
            .map({ (response: CreateMeetingMinuteByChatIdResponse) -> String in
            return response.meetingMinuteURL
        })
    }

    func getDocsUrl(calendarId: String, key: String, originalTime: Int64) -> Observable<String> {
        var request = CreateMeetingMinuteByEventRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime

        return rustService.async(message: request, debugParams: ["calendarId": calendarId, "key": key, "originalTime": String(originalTime)], debugResponse: nil).map({ (response: CreateMeetingMinuteByEventResponse) -> String in
            return response.meetingMinuteURL
        })
    }

    func getMeetingSummaryUpdated(uid: String, originalTime: Int64) -> Observable<Bool> {
        var request = ServerPB_Calendarevents_MeetingMinuteUpdateCheckRequest()
        request.uid = uid
        request.originalTime = originalTime
        let debugParams = ["uid": uid.description, "originalTime": originalTime.description]
        return rustService.sendPassThroughAsyncRequest(request,
                                                       serCommand: .meetingMinuteUpdateCheck,
                                                       debugParams: debugParams, debugResponse: nil)
        .map({ (response: ServerPB_Calendarevents_MeetingMinuteUpdateCheckResponse) -> Bool in
            return response.isUpdate
        })
    }

    func transferToNormalGroup(chatID: String) -> Observable<Void> {
        var request = UpgradeToChatRequest()
        request.chatID = chatID
        return rustService.async(message: request, debugParams: ["chatID": chatID])
    }

    func transferScrollCheck(chatID: String) -> Observable<Bool> {
        var request = DisplayTransferChatScrollCheckRequest()
        request.chatID = chatID
        return rustService.async(message: request, debugParams: ["chatID": chatID], debugResponse: nil)
            .map({ (response: DisplayTransferChatScrollCheckResponse) -> Bool in
                return response.shouldShowScroll
            })
    }

    func searchEvent(query: String, filter: CalendarSearchFilter) -> Observable<[(CalendarSearchInstance, CalendarSearchContent)]> {
        var request = AdvanceSearchCalendarEventRequest()
        var eventFilter = EventFilter()
        eventFilter.attendeeCalendarIds = filter.realAttendeeCalendarIds
        eventFilter.calendarIds = filter.calendarIds
        eventFilter.chatIds = filter.chatIds
        eventFilter.resourceCalendarIds = filter.resourceCalendarIds
        if let startTS = filter.startTimeStamp {
            eventFilter.startTime = startTS
        }
        if let endTS = filter.endTimeStamp {
            eventFilter.endTime = endTS
        }
        request.query = query
        request.filter = eventFilter

        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
            .map({ (response: AdvanceSearchCalendarEventResponse) -> [(CalendarSearchInstance, CalendarSearchContent)] in
                var result: [(CalendarSearchInstance, CalendarSearchContent)] = []
                let contentsDic = response.result.contents
                for instance in response.result.instances {
                    guard let content = contentsDic[instance.eventServerID] else { continue }
                    let value = (CalendarSearchInstance(startTimeForInstance: instance.crossDayStartTime,
                                                        endTimeForInstance: instance.crossDayEndTime,
                                                        startTime: instance.startTime,
                                                        endTime: instance.endTime,
                                                        currentDayCount: Int(instance.crossDayNo),
                                                        totalDayCount: Int(instance.crossDaySum)), SerachEntity(content: content) as CalendarSearchContent)
                    result.append(value)
                }
                return result
            })
    }

    func generalCalendarSearchEvent(query: String, is12Hour: Bool) -> Observable<[CalendarGeneralSearchContent]> {
        var request = QuickSearchCalendarEventRequest()
        request.query = query
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
            .map({ (response: QuickSearchCalendarEventResponse) -> [CalendarGeneralSearchContent] in
                let contentsDic = response.result.contents
                return response.result.instances.compactMap { instance -> CalendarGeneralSearchEntity? in
                    if let content = contentsDic[instance.eventServerID] {
                        return CalendarGeneralSearchEntity(startTime: instance.startTime, endTime: instance.endTime, searchContent: content, is12Hour: is12Hour)
                    } else {
                        return nil
                    }
                }
            })
    }

    func getChatFreeBusyChatters(chatId: String) -> Observable<(orderedChatters: [String], selectedChatters: [String])> {
        var request = GetChatFreeBusyFavorRequest()
        request.chatID = chatId
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
            .map({ (response: GetChatFreeBusyFavorResponse) -> ([String], [String]) in
                return (response.orderedFavorChatterIds, response.selectedFavorChatterIds)
            })
    }

    func setChatFreeBusyChatters(chatId: String, orderedChatters: [String], selectedChatters: [String]) -> Observable<Void> {
        var request = SetChatFreeBusyFavorRequest()
        request.chatID = chatId
        request.orderedFavorChatterIds = orderedChatters
        request.selectedFavorChatterIds = selectedChatters

        return rustService.async(message: request, debugParams: ["chatID": request.chatID])
    }

    func sortChatFreeBusyChatters(chatId: String, chatters: [String]) -> Observable<[String]> {
        var request = SortChattersInChatRequest()
        request.chatID = chatId
        request.chatterIds = chatters
        return rustService.async(message: request, debugParams: ["chatID": request.chatID], debugResponse: nil)
            .map({ (response: SortChattersInChatResponse) -> [String] in
            return response.chatterIds
        })
    }

    func replyCalendarEventInvitationNew(
        calendarId: String,
        key: String,
        originalTime: Int64,
        comment: String,
        inviteOperatorID: String,
        replyStatus: CalendarEventAttendee.Status,
        messageId: String? = nil
    ) -> Observable<(CalendarEventEntity, String, [Int32])> {

        var request = OptimisticReplyCalendarEventInvitationRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime
        request.replyStatus = replyStatus
        request.quitMeeting = true
        request.inviteOperatorID = inviteOperatorID
        request.messageID = messageId ?? ""
        request.comment = comment
        return rustService.async(message: request,
                                 debugParams: ["calendarId": calendarId,
                                               "key": key],
                                 debugResponse: { res in
            return res.event.debugInfo()
        }).map({ (response: OptimisticReplyCalendarEventInvitationResponse) -> (CalendarEventEntity, String, [Int32]) in
            return (PBCalendarEventEntity(pb: response.event), response.chatID, errorCodes: response.failedRsvpComments.map({ $0.errorCode }))
        })
    }

    func replyCalendarEventInvitationWithSpan(
        calendarId: String,
        key: String,
        originalTime: Int64,
        comment: String,
        inviteOperatorID: String,
        replyStatus: CalendarEventAttendee.Status,
        span: CalendarEvent.Span,
        messageId: String?
    ) -> Observable<(CalendarEventEntity, String, [Int32])> {
        var request = OptimisticReplyCalendarEventInvitationWithSpanRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originalTime
        request.replyStatus = replyStatus
        request.quitMeeting = true
        request.inviteOperatorID = inviteOperatorID
        request.messageID = messageId ?? ""
        request.comment = comment
        request.span = span

        let debugParam = [
            "calendarId": calendarId,
            "key": key,
            "originalTime": "\(originalTime)",
            "replyStatus": "\(replyStatus)",
            "span": "\(span)",
            "messageId": messageId ?? ""
        ]

        return rustService.async(message: request, debugParams: debugParam) { (response: OptimisticReplyCalendarEventInvitationWithSpanResponse) in
            [
                "event": response.event.debugInfo()?.description ?? "",
                "chatID": response.chatID,
                "errorCodes": response.failedRsvpComments.map { String($0.errorCode) }.joined(separator: ",")
            ]
        }.map({ (response) -> (CalendarEventEntity, String, [Int32]) in
            return (PBCalendarEventEntity(pb: response.event),
                    response.chatID, response.failedRsvpComments.map({ $0.errorCode }))
        })
    }

    func getPrimaryCalendarLoadingStatus() -> Observable<Bool> {
        let request = GetPrimaryCalendarLoadingStatusRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: {
            ["isLoading": $0.isLoading.description]
        }).map({ (response: GetPrimaryCalendarLoadingStatusResponse) -> Bool in
            return response.isLoading
        })
    }

    func getAuthorizedEventByUniqueField(calendarID: String,
                                         key: String,
                                         originalTime: Int64,
                                         startTime: Int64?) -> Observable<Rust.EventByUniqueField> {
        var request = Calendar_V1_GetAuthorizedEventByUniqueFieldRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        if let startTime = startTime {
            request.startTime = Int64(startTime)
        }

        let debugRequest = ["calendarID": request.calendarID,
                            "key": request.key,
                            "originalTime": request.originalTime.description,
                            "startTime": request.startTime.description]
        return rustService.async(message: request,
                                 debugParams: debugRequest,
                                 debugResponse: { $0.event.debugInfo()
        })
    }

    func getHasMeetingEvent(calendarId: String, key: String) -> Observable<Bool> {
        var request = GetHasMeetingEventRequest()
        request.calendarID = calendarId
        request.key = key
        return rustService.async(message: request,
                                 debugParams: ["calendarID": request.calendarID,
                                               "key": request.key],
                                 debugResponse: { resp in
            return ["hasMeeting": "\(resp.hasMeetingEvent_p)"]
        }).map({ (response: GetHasMeetingEventResponse) -> Bool in
            return response.hasMeetingEvent_p
        })
    }

    func getShareLink(calendarId: String,
                      key: String,
                      originTime: Int64,
                      needImg: Bool) -> Observable<ShareDataModel> {
        var request = GetEventShareLinkRequest()
        request.calendarID = calendarId
        request.key = key
        request.originalTime = originTime
        request.needImg = needImg
        return rustService.async(message: request,
                                 debugParams: ["calendarID": calendarId,
                                               "key": key,
                                               "originaTime": originTime.description,
                                               "needImg": needImg.description],
                                 debugResponse: nil).map { (response) -> ShareDataModel in
            return ShareDataModel(pb: response)
        }
    }

    func getTodayReminderCalendarInstance() -> Observable<Calendar_V1_GetTodayReminderCalendarInstanceResponse> {
        let request = Calendar_V1_GetTodayReminderCalendarInstanceRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
    }

    func saveCalendarApplicationCloseInstanceRequest(key: String,
                                                     calendarID: String,
                                                     originalTime: Int64,
                                                     startTime: Int64) -> Observable<Void> {
        var request = Calendar_V1_SaveCalendarApplicationCloseInstanceRequest()
        var calendarEventInstanceKey = Calendar_V1_CalendarEventInstanceKey()
        calendarEventInstanceKey.key = key
        calendarEventInstanceKey.calendarID = calendarID
        calendarEventInstanceKey.originalTime = originalTime
        calendarEventInstanceKey.instanceStartTime = startTime
        request.closeInstanceKeys = [calendarEventInstanceKey]
        return rustService.async(message: request,
                                 debugParams: ["key": key,
                                               "calendarID": calendarID,
                                               "instanceStartTime": String(originalTime),
                                               "startTime": String(startTime)
                                              ])
    }

    func getFeedTopEventSettingRequest() -> Observable<Bool> {
        let request = Feed_V1_GetEventSettingRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
            .map({ (response: Feed_V1_GetEventSettingResponse) -> Bool in
                return response.eventTempTop
            })
    }

    func patchFeedTopEventSettingRequest(value: Bool) -> Observable<Void> {
        var request = Feed_V1_PatchEventSettingRequest()
        request.allowTempTop = value
        return rustService.async(message: request, debugParams: ["allowTempTop": String(value)])
    }
}

extension CalendarRustAPI {
    // 二维码会议室签到
    func checkInInfo(token: String) -> Observable<MeetingRoomCheckInResponseModel> {
        var request = Calendar_V1_GetResourceCheckInInfoRequest()
        request.resourceCheckInToken = token
        return rustService.async(
            message: request, debugParams: ["token": token],
            debugResponse: { ["meetingRoom": $0.resource.id,
                              "currentTime": $0.currentTimestampSecond.description,
                              "instancesStatus": $0.instanceInfos.map(\.instanceCheckInInfo.checkInStatus.rawValue.description).description]
            }
        ).map(MeetingRoomCheckInResponseModel.init(pb:))
    }

    func getLocalMeetingRoomViewFilter() -> Observable<Rust.MeetingRoomViewFilterResult> {
        let request = Calendar_V1_GetLocalRoomViewResourceDataRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
            .map { (response: Calendar_V1_GetLocalRoomViewResourceDataResponse) -> Rust.MeetingRoomViewFilterResult in
                Rust.MeetingRoomViewFilterResult(filterConfig: response.roomViewFilterConfigs,
                                                 meetingRooms: response.resources,
                                                 buildings: response.buildings)
            }
    }

    func getHierarchicalRoomViewSubLevelInfo(levelIds: [String], needTopLevelInfo: Bool = false) -> Observable<[String: Rust.MeetingRoomLevelInfo]> {
        // 多层级下批量获取层级 levelIds 下子属层级信息
        var request = Calendar_V1_GetHierarchicalRoomViewSubLevelInfoRequest()
        request.levelIds = levelIds
        request.needTopLevelInfo = needTopLevelInfo

        return rustService.async(message: request,
                                 debugParams: ["levelIds": levelIds.description],
                                 debugResponse: nil)
        .map { (response: Calendar_V1_GetHierarchicalRoomViewSubLevelInfoResponse) in
            response.levelInfo }
    }

    func pullLevelPathRequest(levelIds: [String]) -> Observable<[String: [String]]> {
        // 多层级下批量获取层级 levelIds 的 levelPath 信息
        var request = ServerPB_Calendarevents_PullLevelPathRequest()
        request.levelIds = levelIds

        return rustService.sendPassThroughAsyncRequest(request,
                                                       serCommand: .pullLevelPath,
                                                       debugParams: ["levelIds": levelIds.description],
                                                       debugResponse: { $0.levelPathMap.mapValues(\.levelIds.description) })
            .map { (response: ServerPB_Calendarevents_PullLevelPathResponse) -> [String: [String]] in
                return response.levelPathMap.mapValues { $0.levelIds }
            }
    }

    func getLocalHierarchicalRoomViewResourceConfig() -> Observable<Calendar_V1_GetLocalHierarchicalRoomViewResourceConfigResponse> {
        // 多层级下获取会议室视图筛选缓存记录
        let request = Calendar_V1_GetLocalHierarchicalRoomViewResourceConfigRequest()
        let debugResponse = { (response: Calendar_V1_GetLocalHierarchicalRoomViewResourceConfigResponse) -> [String: String]? in
            let config = response.hierarchicalRoomViewFilterConfigs
            return ["selectedLevelIds": config.selectedLevelIds.description,
                    "minCapacity": String(config.meetingRoomFilter.minCapacity),
                    "needEquipments": config.meetingRoomFilter.needEquipments.description]

        }
        return rustService.async(message: request,
                                 debugParams: nil,
                                 debugResponse: debugResponse)
    }

    func pullHRoomViewResourceList(config: Rust.HierarchicalRoomViewFilterConfigs, cursor: String = "-1", count: Int32 = 50) -> Observable<Calendar_V1_PullHierarchicalRoomViewResourceListResponse> {
        // 多层级下分页加载会议室视图页列表数据
        var request = Calendar_V1_PullHierarchicalRoomViewResourceListRequest()
        request.hierarchicalRoomViewFilterConfigs = config
        request.count = count
        request.cursor = cursor

        let debugParams: [String: String] = [
            "selectedLevelIds": config.selectedLevelIds.description,
            "needEquipments": config.meetingRoomFilter.needEquipments.description,
            "minCapacity": String(config.meetingRoomFilter.minCapacity),
            "cursor": cursor,
            "count": String(count)
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: {
            ["count": String($0.resources.count),
             "cursor": $0.cursor,
             "isFinished": $0.isFinished.description]
        })
    }

    func updateMeetingRoomViewFilter(filter: Rust.RoomViewFilterConfig) -> Observable<Rust.MeetingRoomViewFilterResult> {
        var request = Calendar_V1_UpdateRoomViewResourceDataRequest()
        request.roomViewFilterConfigs = filter
        let debugParams = ["neededBuildingFloors": request.roomViewFilterConfigs.neededBuildingFloors.description,
                           "minCapacity": request.roomViewFilterConfigs.meetingRoomFilter.minCapacity.description,
                           "needEquipments": request.roomViewFilterConfigs.meetingRoomFilter.needEquipments.description]
        return rustService.async(message: request,
                                 debugParams: debugParams,
                                 debugResponse: {
                ["resourcesCount": $0.resources.count.description]
            })
            .map { (response: Calendar_V1_UpdateRoomViewResourceDataResponse) -> Rust.MeetingRoomViewFilterResult in
                Rust.MeetingRoomViewFilterResult(filterConfig: response.roomViewFilterConfigs,
                                                 meetingRooms: response.resources,
                                                 buildings: response.buildings)
            }
    }
}

extension CalendarRustAPI {
    func parseForm(inputs: Rust.CustomizationFormSelections, originalForm: Rust.CustomizationForm) -> Observable<Rust.CustomizationForm> {

        var request = Calendar_V1_ParseCustomizedConfigurationRequest()
        request.resourceCustomization = originalForm
        request.userInputs = inputs
        let debugParams = ["resourceCustomization": request.resourceCustomization.description,
                           "userInputs": request.userInputs.description]
        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil)
            .map(\Calendar_V1_ParseCustomizedConfigurationResponse.uiLayerCustomization)
    }

    func parseUserIDToName(IDs: [String]) -> Observable<[String: String]> {
        var request = Calendar_V1_ParseCustomizedConfigurationRequest()
        request.contactIds = IDs

        return rustService.async(message: request, debugParams: ["contactIds": IDs.description], debugResponse: nil)
            .map(\Calendar_V1_ParseCustomizedConfigurationResponse.chatters)
    }
}

extension CalendarRustAPI {
    func getInstance(eventUniqueFiledId: [CalendarEventUniqueField],
                     startTime: Int64,
                     endTime: Int64,
                     timezone: String?) -> Observable<[CalendarEventInstanceEntity]> {
        var request = GetInstancesByEventUniqueFieldsRequest()
        request.startTime = startTime
        request.endTime = endTime
        if let timeZone = timezone, !timeZone.isEmpty {
           request.timezone = timeZone
        }
        request.eventUniqueFields = eventUniqueFiledId
        let debugParams = ["eventUniqueFiledId": String(eventUniqueFiledId.description),
                           "startTime": String(startTime),
                           "endTime": String(endTime)]
        return rustService.async(message: request, debugParams: debugParams, debugResponse: { response in
            var log = [String: String]()
            response.instances.forEach { entity in
                log["\(entity.calendarID)-\(entity.key)-\(entity.originalTime)"] = "\(entity.startDay)-\(entity.endDay)"
            }
            return log
        }).map({ (response: GetInstancesByEventUniqueFieldsResponse) -> [CalendarEventInstanceEntity] in
            return response.instances.map { CalendarEventInstanceEntityFromPB(withInstance: $0) }
        })
    }
}

/// 详情页 push
extension CalendarRustAPI {
    func registerActiveEvent(calendarID: String, key: String) -> Observable<Void> {
        var request = RustPB.Calendar_V1_RegisterActiveEventRequest()
        request.calendarID = calendarID
        request.key = key

        return rustService.async(message: request,
                                 debugParams: ["calendarID": calendarID,
                                               "key": key])
    }

    func unRegisterActiveEvent(calendarID: String, key: String) -> Observable<Void> {
        var request = RustPB.Calendar_V1_UnRegisterActiveEventRequest()
        request.calendarID = calendarID
        request.key = key

        return rustService.async(message: request,
                                 debugParams: ["calendarID": calendarID,
                                               "key": key])
    }
}

extension CalendarRustAPI {
    /// 获取最近使用的时区
    func getRecentTimeZoneIds() -> Observable<[TimeZoneModel.ID]> {
        // UserDefaults.standard.object(forKey: "RecentTimeZoneIds")
        let request = Rust.GetRecentTimeZonesRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: { response in
            return ["timezoneIds": response.timezoneIds.description]
        }).map { (response: Rust.GetRecentTimeZonesResponse) in
            return response.timezoneIds
        }
    }

    /// 新增/更新最近使用的时区
    func upsertRecentTimeZone(with timeZoneIdsToAdd: [TimeZoneModel.ID]) -> Observable<Void> {
        var request = Rust.UpdateRecentTimeZonesRequest()
        request.addedTimezoneIds = timeZoneIdsToAdd
        return rustService.async(message: request, debugParams: ["add_ids": timeZoneIdsToAdd.joined(separator: ",")])
    }

    /// 删除最近使用的时区
    func deleteRecentTimeZones(by timeZoneIdsToDelete: [TimeZoneModel.ID]) -> Observable<Void> {
        var request = Rust.UpdateRecentTimeZonesRequest()
        request.deletedTimezoneIds = timeZoneIdsToDelete
        return rustService.async(message: request, debugParams: ["delete_ids": timeZoneIdsToDelete.joined(separator: ",")])
    }

    /// 根据 query 获取对应的时区城市列表
    func getCityTimeZones(by query: String) -> Observable<[TimeZoneCityPair]> {
        var request = Rust.GetTimeZoneByCityRequest()
        request.city = query
        return rustService.async(message: request, debugParams: ["query": query], debugResponse: nil).map { (response: Rust.GetTimeZoneByCityResponse) in
            response.cityTimezones.compactMap {
                guard let timeZone = Foundation.TimeZone(identifier: $0.timezone.timezoneID) else { return nil }
                return (timeZone: timeZone, cityNames: $0.cityNames)
            }
        }
    }

    /// 获取 Preferred 时区
    func getPreferredTimeZoneId() -> Observable<TimeZoneModel.ID> {
        let request = Rust.GetMobileNormalViewTimeZoneRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: { response in
            return ["timezoneIDIsEmpty": response.timezoneID.isEmpty.description]
        }).map { (response: Rust.GetMobileNormalViewTimeZoneResponse) in
            let isEmpty = response.timezoneID.isEmpty
            return !isEmpty ? response.timezoneID : TimeZone.current.identifier
        }
    }

    /// 设置 Preferred 时区
    func setPreferredTimeZone(with timeZoneId: TimeZoneModel.ID) -> Observable<Void> {
        let useSystemTimeZone = TimeZone.current.identifier == timeZoneId

        var request = Rust.SetMobileNormalViewTimeZoneRequest()
        request.timezoneID = timeZoneId
        request.useSystemTimezone = useSystemTimeZone
        return rustService.async(message: request, debugParams: ["timezoneID": timeZoneId, "useSystemTimezone": useSystemTimeZone.description])
    }

}

/// 上传图片
extension CalendarRustAPI {
    func uploadImage(with data: Data) -> Observable<String> {
        var request = Calendar_V1_UploadCalendarCoverImageRequest()
        request.image = data

        return rustService.async(message: request, debugParams: nil) { (response: Calendar_V1_UploadCalendarCoverImageResponse) in
            ["upload_image_key": response.key]
        }
        .map { (response: Calendar_V1_UploadCalendarCoverImageResponse) in
            return response.key
        }
    }
}

extension CalendarRustAPI {
    func downLoadImage(with imagekey: String) -> Observable<String?> {
        var request = Media_V1_MGetResourcesRequest()
        var set = Media_V1_MGetResourcesRequest.Set()
        set.key = imagekey
        request.sets = [set]
        return rustService.async(message: request, debugParams: ["imagekey": imagekey], debugResponse: nil)
            .map { (response: Media_V1_MGetResourcesResponse) in
                let resource = response.resources[imagekey]
                return resource?.path
            }
    }
}

extension CalendarRustAPI {
    func shareCalendar(
        calendarID: String,
        comment: String?,
        shareMembers: [Server.CalendarMemberCommit],
        forbiddenList: [String]
    ) -> Observable<[String]> {
        var request = ServerPB_Calendars_ShareCalendarV2Request()
        request.calendarID = calendarID
        request.userCollaborationForbiddenList = forbiddenList
        request.shareMembers = shareMembers

        if let comment = comment { request.comment = comment }

        return rustService.sendPassThroughAsyncRequest(
            request, serCommand: .shareCalendarV2,
            debugParams: ["calendarID": calendarID, "members": shareMembers.description],
            debugResponse: { ["failedChats": $0.shareFailedChats.map(\.chatID).description] }
        ).map { (response: ServerPB_Calendars_ShareCalendarV2Response) -> [String] in
            return response.shareFailedChats.map(\.chatName)
        }
    }

    func fetchCalendar(calendarID: String) -> Observable<CalendarWithMember?> {
        var request = Rust.FetchCalendarsRequest()
        request.calendarIds = [calendarID]

        return rustService.async(message: request, debugParams: ["calendarIDs": request.calendarIds.description], debugResponse: { res in
            ["membersAuth": res.calendarWithMembers.first?.calendarMembers.map(\.accessRole).description ?? "nil"]
        })
            .map { (response: Rust.FetchCalendarsResponse) in
                if let calendar = response.calendars[calendarID],
                   let tenantInfo = response.calendarTenantInfoMap[calendarID],
                   let members = response.calendarWithMembers.first(where: { $0.calendarID == calendarID })?.calendarMembers {
                    var membersWithOfficial = members
                    if calendar.officialType == .bytedance,
                       FG.optimizeCalendar,
                       let index = membersWithOfficial.firstIndex(where: { $0.memberID == calendar.calendarOwnerID }),
                       var member = members[safeIndex: index] {
                        member.name = I18n.Calendar_Common_Feifei
                        member.avatarKey = ""
                        membersWithOfficial[index] = member
                    }
                    return CalendarWithMember(tenantInfo: tenantInfo, calendar: calendar, members: membersWithOfficial)
                }
                return nil
            }
    }

    func getCalendarIDByShareToken(token: String) -> Observable<String> {
        var request = ServerPB_Calendars_GetCalendarIDByShareTokenRequest()
        request.shareToken = token

        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getCalendarIDByShareToken, debugParams: ["token": token], debugResponse: { res in
            return ["calendarID": res.calendarID]
        }).map { (response: ServerPB_Calendars_GetCalendarIDByShareTokenResponse) -> String in
            return response.calendarID
        }
    }

    // 日程参与人上限审批页面获取审批人等UI展示信息
    func getAttendeeNumberControlApprovalInfo() -> Observable<[String: Calendar_V1_GetAttendeeNumberControlApprovalInfoResponse.ChatterInfo]> {
        var request = Calendar_V1_GetAttendeeNumberControlApprovalInfoRequest()
        return rustService.async(message: request, debugParams: nil, debugResponse: { (response: Calendar_V1_GetAttendeeNumberControlApprovalInfoResponse) in
            ["count": String(response.approvers.values.count)]
        }).map { $0.approvers }
    }

    func createAttendeeNumberControlApproval(
        calendarID: String,
        key uid: String,
        originalTime: Int64,
        summary: String,
        startTime: Int64,
        startTimeZone: String,
        endTime: Int64,
        endTimeZone: String,
        eventType: ServerPB_Calendar_attendee_number_control_CreateAttendeeNumberControlApprovalRequest.EventType,
        attendeeNumber: Int32,
        reason: String
    ) -> Observable<ServerPB_Calendar_attendee_number_control_CreateAttendeeNumberControlApprovalResponse> {
        var request = ServerPB_Calendar_attendee_number_control_CreateAttendeeNumberControlApprovalRequest()
        request.summary = summary
        request.calendarID = calendarID
        request.uid = uid
        request.originalTime = originalTime
        request.startTime = startTime
        request.startTimezone = startTimeZone
        request.endTime = endTime
        request.endTimezone = endTimeZone
        request.durationSecond = endTime - startTime
        request.eventType = eventType
        request.attendeeNumber = attendeeNumber
        request.reason = reason

        return rustService.sendPassThroughAsyncRequest(request, serCommand: .createAttendeeNumberControlApproval,
                                                       debugParams: ["calendarID": calendarID,
                                                                     "key": uid,
                                                                     "originalTime": String(originalTime),
                                                                     "attendeeNumber": String(attendeeNumber),
                                                                     "hasReason": (!reason.isEmpty).description],
                                                       debugResponse: nil)

    }

    func authEventsByEventIDs(eventIds: [String]) -> Observable<ServerPB_Calendarevents_AuthEventsByEventIDsResponse> {
        var request = ServerPB_Calendarevents_AuthEventsByEventIDsRequest()
        request.eventIds = eventIds
        let debugParams = ["eventIds": request.eventIds.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .authEventsByEventIds,
                                                       debugParams: debugParams, debugResponse: nil)
    }

    func getChatCalendarEventInstanceViewRequest(chatIds: [String]) -> Observable<ServerPB_Calendarevents_GetChatCalendarEventInstanceViewResponse> {
        var request = ServerPB_Calendarevents_GetChatCalendarEventInstanceViewRequest()
        request.chatIds = chatIds
        let debugParams = ["chatIds": request.chatIds.description]
        return rustService.sendPassThroughAsyncRequest(request,
                                                       serCommand: .getChatCalendarEventInstanceView,
                                                       debugParams: debugParams, debugResponse: nil)
    }

    enum CheckInInfoCondition: String {
        case checkInUrl
        case image
        case stats
        case visibility
    }

    func getEventCheckInInfo(calendarID: Int64,
                             key: String,
                             originalTime: Int64,
                             startTime: Int64,
                             condition: [CheckInInfoCondition]) -> Observable<ServerPB_Calendarevents_GetEventCheckInInfoResponse> {
        var request = ServerPB_Calendarevents_GetEventCheckInInfoRequest()
        request.calendarID = calendarID
        request.uid = key
        request.originalTime = originalTime
        request.startTime = startTime

        var requestCondition = ServerPB_Calendarevents_GetEventCheckInInfoRequest.Condition()
        requestCondition.needCheckInURL = condition.contains(.checkInUrl)
        requestCondition.needImage = condition.contains(.image)
        requestCondition.needStats = condition.contains(.stats)
        requestCondition.needVisibility = condition.contains(.visibility)

        request.condition = requestCondition

        let debugParams = [
            "calendarID": String(calendarID),
            "key": key,
            "originalTime": String(originalTime),
            "startTime": String(startTime),
            "condition": condition.map({ $0.rawValue }).description
        ]

        return rustService.sendPassThroughAsyncRequest(request,
                                                       serCommand: .getCalendarEventCheckInInfo,
                                                       debugParams: debugParams) { response in
            return ["checkInVisible": response.checkInVisible.description,
                    "checkInDisable": response.checkInDisable.description,
                    "isGenerating": response.isGenerating.description]
        }
    }

    func getSunriseAndSunsetTime(timeZone: [String], date: Int64) -> Observable<Calendar_V1_GetSunriseAndSunsetTimeResponse> {
        var request = Calendar_V1_GetSunriseAndSunsetTimeRequest()
        request.timezone = timeZone
        request.date = date
        return rustService.async(message: request, debugParams: ["timezone": timeZone.description], debugResponse: nil)
    }
    
}

// MARK: - Zoom视频会议
extension CalendarRustAPI {
    func getZoomAccountRequest() -> Observable<ServerPB_Calendar_external_GetZoomAccountResponse> {
        var request = ServerPB_Calendar_external_GetZoomAccountRequest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getZoomAccount, debugParams: nil,
                                                       debugResponse: {(response: ServerPB_Calendar_external_GetZoomAccountResponse) in
            return ["status": response.status.rawValue.description,
                    "account": response.account,
                    "zoom_auth_url": response.zoomAuthURL]
        })
    }
    
    func revokeZoomAccountRequest(account: String) -> Observable<ServerPB_Calendar_external_RevokeZoomAccountResponse> {
        var request = ServerPB_Calendar_external_RevokeZoomAccountRequest()
        request.account = account
        let debugParams = ["account": request.account.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .revokeZoomAccount, debugParams: debugParams,
                                                       debugResponse: {(response: ServerPB_Calendar_external_RevokeZoomAccountResponse) in
            return ["resp_state": response.respState.rawValue.description]
        })
    }
    
    func createZoomMeetingRequest(startTime: Int64, startTimeZone: String, topic: String, duration: Int64, isRecurrence: Bool) -> Observable<ServerPB_Calendar_external_CreateZoomMeetingResponse> {
        var request = ServerPB_Calendar_external_CreateZoomMeetingRequest()
        request.startTime = startTime
        request.startTimezone = startTimeZone
        request.topic = topic
        request.duration = duration
        request.isRecurrence = isRecurrence
        let debugParams = ["startTime": request.startTime.description,
                           "startTimezone": request.startTimezone.description,
                           "topic": request.topic.description,
                           "duration": request.duration.description,
                           "isRecurrence": request.isRecurrence.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .createZoomMeeting, debugParams: debugParams,
                                                       debugResponse: {(response: ServerPB_Calendar_external_CreateZoomMeetingResponse) in
            return ["meeting_id": response.zoomMeeting.meetingID.description,
                    "password": response.zoomMeeting.password.description,
                    "creator_account": response.zoomMeeting.creatorAccount.description,
                    "meeting_url": response.zoomMeeting.meetingURL.description,
                    "is_editable": response.zoomMeeting.isEditable.description]
        })
    }
    
    func deleteZoomMeetingRequest(meetingID: Int64) -> Observable<ServerPB_Calendar_external_DeleteZoomMeetingResponse> {
        var request = ServerPB_Calendar_external_DeleteZoomMeetingRequest()
        request.meetingID = meetingID
        let debugParams = ["meetingID": request.meetingID.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .deleteZoomMeeting, debugParams: debugParams,
                                                       debugResponse: nil)
    }
    
    func getZoomMeetingPhoneNumsRequest(meetingID: Int64, creatorAccount: String, isDefault: Bool, creatorUserID: Int64) -> Observable<ServerPB_Calendar_external_GetZoomMeetingPhoneNumsResponse> {
        var request = ServerPB_Calendar_external_GetZoomMeetingPhoneNumsRequest()
        request.meetingID = meetingID
        request.creatorAccount = creatorAccount
        request.type = isDefault ? .default : .total
        request.creatorUserID = creatorUserID
        let debugParams = ["meetingID": request.meetingID.description,
                           "creatorAccount": creatorAccount.description,
                           "type(isDefault):": isDefault.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getZoomMeetingPhoneNums, debugParams: debugParams,
                                                       debugResponse: {(response: ServerPB_Calendar_external_GetZoomMeetingPhoneNumsResponse) in
            return ["pstn_password": response.pstnPassword.description]
        })
    }
    
    func getZoomMeetingSettingsRequest(meetingID: Int64) -> Observable<ServerPB_Calendar_external_GetZoomMeetingSettingsResponse> {
        var request = ServerPB_Calendar_external_GetZoomMeetingSettingsRequest()
        request.meetingID = meetingID
        let debugParams = ["meetingID": request.meetingID.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getZoomMeetingSettings, debugParams: debugParams,
                                                       debugResponse: nil)
    }
    
    func updateZoomMeetingSettingsRequest(meetingID: Int64, zoomSetting: ServerPB_Calendar_external_ZoomMeetingSettings) -> Observable<ServerPB_Calendar_external_UpdateZoomMeetingSettingsResponse> {
        var request = ServerPB_Calendar_external_UpdateZoomMeetingSettingsRequest()
        request.meetingID = meetingID
        request.zoomSettings = zoomSetting
        let debugParams = ["meetingID": request.meetingID.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .updateZoomMeetingSettings, debugParams: debugParams,
                                                       debugResponse: {(response: ServerPB_Calendar_external_UpdateZoomMeetingSettingsResponse) in
            return ["resp_state": response.respState.rawValue.description,
                    "password_err": response.passwordErr.description,
                    "alternative_hosts_err": response.alternativeHostsErr.description]
        })
    }
}

extension CalendarRustAPI {
    func loadMailContactData(mails: [String]) -> Observable<Calendar_V1_LoadMailContactDataResponse> {
        var request = Calendar_V1_LoadMailContactDataRequest()
        request.emails = mails

        return rustService.async(message: request, debugParams: ["mailcontactdata_count": mails.count.description]) { response in
            ["mailcontactdata_response_count": response.chatterCalendarMap.count.description,
             "count": response.searchMailEntities.count.description]

        }
    }

    func AddMeetingCollaboratorRequest(uniqueKey: String, operatorCalendarID: String, originalTime: Int64, addChatID: [Int64], addCalendarID: [Int64], addMeetingChatChatter: Bool, addMeetingMinuteCollaborator: Bool, addChatterApplyReason: String ) -> Observable<ServerPB_Calendarevents_AddMeetingCollaboratorToChatAndMinuteResponse> {
        var request = ServerPB_Calendarevents_AddMeetingCollaboratorToChatAndMinuteRequest()
        request.uniqueKey = uniqueKey
        request.operatorCalendarID = operatorCalendarID
        request.originalTime = originalTime
        request.addChatID = addChatID
        request.addCalendarID = addCalendarID
        request.addMeetingChatChatter = addMeetingChatChatter
        request.addMeetingMinuteCollaborator = addMeetingMinuteCollaborator
        request.addChatterApplyReason = addChatterApplyReason

        let debugParams = ["uniqueKey": request.uniqueKey.description,
                           "operatorCalendarID": request.operatorCalendarID.description,
                           "originalTime": request.originalTime.description,
                           "addChatID": request.addChatID.description,
                           "addCalendarID": request.addCalendarID.description,
                           "addMeetingChatChatter": request.addMeetingChatChatter.description,
                           "addMeetingMinuteCollaborator": request.addMeetingMinuteCollaborator.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .addMeetingCollaboratorToChatAndMinute, debugParams: nil,
                                                       debugResponse: {(response: ServerPB_Calendarevents_AddMeetingCollaboratorToChatAndMinuteResponse) in
            return ["status": response.status.rawValue.description]
        })
    }
    
    func pullWebinarEventIndividualSimpleAttendees(calendarID: String, key: String, originalTime: Int64, webinarType: WebinarAttendeeType) -> Observable<Calendar_V1_PullWebinarEventIndividualSimpleAttendeeResponse> {
        var request = Calendar_V1_PullWebinarEventIndividualSimpleAttendeeRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        request.webinarType = webinarType

        return rustService.async(message: request, debugParams: nil, debugResponse: nil)
    }
}
// MARK: - 日历详情页列表数据
extension CalendarRustAPI {

    enum CalendarListFetchType: String {
        case previous
        case following

        var rustType: RustPB.Calendar_V1_PullCalendarInstancesRequest.PullType {
            switch self {
            case .previous: return .pastTime
            case .following: return .futureTime
            }
        }
    }

    struct CalendarListFetchExtra {
        let lastMinTimeSpan: Int32?
        let lastEventID: String?
    }

    func fetchInstance(at calendarID: String,
                       anchorTime: Int64,
                       fetchType: CalendarListFetchType,
                       fetchExtra: CalendarListFetchExtra?) -> Single<RustPB.Calendar_V1_PullCalendarInstancesResponse> {
        var request = RustPB.Calendar_V1_PullCalendarInstancesRequest()
        request.calendarID = calendarID
        request.pullType = fetchType.rustType
        request.beginTime = anchorTime
        request.timezone = TimeZone.current.identifier
        if let lastMinTimeSpan = fetchExtra?.lastMinTimeSpan {
            request.lastMinTimespan = lastMinTimeSpan
        }
        if let lastEventID = fetchExtra?.lastEventID {
            request.lastEventID = lastEventID
        }
        let debugParams = [
            "calendarID": calendarID,
            "beginTime": String(anchorTime),
            "fetchType": fetchType.rawValue
        ]
        return rustService.async(message: request, debugParams: debugParams) { (response: Calendar_V1_PullCalendarInstancesResponse) in
            ["instanceCount": "\(response.calendarInstances.count)"]
        }.asSingle()
    }
}

// MARK: - External Calendar Account Auth Check
extension CalendarRustAPI {
    func getShouldSwitchToOAuthExchangeAccounts() -> Observable<[String: String]> {
        var request = ServerPB_Calendar_external_ShouldExchangeAccountSwitchToOAuthRequest()
        return self.rustService.sendPassThroughAsyncRequest(request, serCommand: .shouldExchangeAccountSwitchToOauth, debugParams: nil, debugResponse: { res in
                return ["authUrlCount": "\(res.exchangeAuthUrls.count)"]
            })
            .map { (resp: ServerPB_Calendar_external_ShouldExchangeAccountSwitchToOAuthResponse) in
                resp.exchangeAuthUrls
            }
    }
}

extension CalendarRustAPI {
    func fetchAttachmentRiskTags(fileTokens: [String]) -> Observable<[Server.FileRiskTag]> {
        guard !fileTokens.isEmpty else {
            return .just([])
        }
        var request = ServerPB_Compliance_MGetRiskTagByTokenRequest()
        request.sourceTerminal = .mobile
        request.fileTokenList = fileTokens
        return self.rustService.sendPassThroughAsyncRequest(request, serCommand: .getFileRiskTagList, debugParams: nil, debugResponse: { res in
            return ["riskFileCount": res.result.filter { $0.isRiskFile }.count.description]
        })
        .map { (resp: ServerPB_Compliance_MGetRiskTagByTokenResponse) in
            resp.result
        }
    }
}

extension CalendarRustAPI {
    func parseEventMeetingLinks(eventLocation: String,
                                eventDescription: String,
                                eventSource: Rust.Event.Source,
                                resourceName: [String]) -> Observable<Rust.ParseEventMeetingLinksResponse> {
        var request = Rust.ParseEventMeetingLinksRequest()
        request.location = eventLocation
        request.description_p = eventDescription.decodeHtml()
        request.source = eventSource
        request.resourceName = resourceName

        let debugParams: [String: String] = [
            "source": eventSource.rawValue.description,
            "resourceNameCount": String(resourceName.debugDescription.count)
        ]

        return rustService.async(message: request, debugParams: debugParams, debugResponse: { (response: Rust.ParseEventMeetingLinksResponse) in
            ["locationCount: ": String(response.locationItem.count),
             "DescriptionCount: ": String(response.descriptionLink.count)]
        })
    }
}

extension CalendarRustAPI {
    func replyCalendarEventCardRequest(calendarID: String, key: String, originalTime: Int64, messageID: String, replyStatus: CalendarEventAttendee.Status) -> Observable<Rust.ReplyCalendarEventRsvpCardResponse>{
        var request = Rust.ReplyCalendarEventRsvpCardRequest()
        request.calendarID = calendarID
        request.key = key
        request.originalTime = originalTime
        request.replyStatus = replyStatus
        request.messageID = messageID
        let debugParams = ["calendarID": request.calendarID.description,
                           "key": request.key.description,
                           "originalTime": request.originalTime.description,
                           "messageID": request.messageID.description]
        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil).map{ (response: Rust.ReplyCalendarEventRsvpCardResponse)  in
            return response
        }
    }
}

// Scheduler
extension CalendarRustAPI {
    func getSchedulerAvailableTime(schedulerID: String, startTime: Int64, endTime: Int64) -> Observable<Server.GetSchedulerAvailableTimeResponse> {
        guard !schedulerID.isEmpty else { return .empty() }
        var request = Server.GetSchedulerAvailableTimeRequest()
        request.schedulerID = schedulerID
        request.startTime = startTime
        request.endTime = endTime
        let debugParams = ["schedulerID": request.schedulerID.description]
        return self.rustService.sendPassThroughAsyncRequest(request,
                                                            serCommand: .getSchedulerAvailableTime,
                                                            debugParams: debugParams,
                                                            debugResponse: { ["availableCount": $0.userAvailableTimes.count.description] })
    }

    func recheduleAppointment(appointmentID: String,
                              email: String,
                              timeZone: String,
                              startTime: Int64,
                              endTime: Int64,
                              message: String,
                              hostUserIDs: [String]) -> Observable<Server.GetSchedulerAvailableTimeResponse> {
        guard !appointmentID.isEmpty else { return .empty() }
        var request = Server.RescheduleAppointmentRequest()
        request.appointmentID = appointmentID
        request.email = email
        request.timezone = timeZone
        request.startTime = startTime
        request.endTime = endTime
        request.message = message
        request.hostUserIds = hostUserIDs
        let debugParams = ["appointmentID": request.appointmentID.description]
        return self.rustService.sendPassThroughAsyncRequest(request, serCommand: .rescheduleAppointment, debugParams: debugParams, debugResponse: nil)
    }

    func getAppointmentToken(appointmentID: String, email: String) -> Observable<Server.GetAppointmentTokenResponse> {
        guard !appointmentID.isEmpty else { return .empty() }
        var request = Server.GetAppointmentTokenRequest()
        request.appointmentID = appointmentID
        request.email = email
        let debugParams = ["appointmentID": request.appointmentID.description]
        return self.rustService.sendPassThroughAsyncRequest(request, serCommand: .getAppointmentToken, debugParams: debugParams, debugResponse: nil)
    }
}

/// my AI
extension CalendarRustAPI {
    ///AI场景通过token拉取日程精简信息
    func loadEventInfoByKeyForMyAIRequest(token: String) -> Observable<Server.LoadEventInfoByKeyForMyAIResponse> {
        var request = Server.LoadEventInfoByKeyForMyAIRequest()
        request.token = token
        return self.rustService.sendPassThroughAsyncRequest(request,
                                                            serCommand: .loadEventInfoByKeyForMyai,
                                                            debugParams: nil,
                                                            debugResponse: {["summary": $0.eventInfo.summary,
                                                                             "startTime": $0.eventInfo.startTime.description,
                                                                             "endTime": $0.eventInfo.endTime.description,
                                                                             "startTimezone": $0.eventInfo.startTimezone.description,
                                                                             "endTimezone": $0.eventInfo.endTimezone.description,
                                                                             "key": $0.eventInfo.uid.description,
                                                                             "rrule": $0.eventInfo.rrule.description,
                                                                             "attendeeUserCount": $0.eventInfo.attendeeUserIds.count.description,
                                                                             "resourceCalendarIdsCount": $0.eventInfo.resourceCalendarIds.count.description
                                                            ]})
    }
    
    /// 拉取会议室信息
    func loadResourcesByCalendarIdsRequest(calendarIDs: [String]) -> Observable<Rust.LoadResourcesByCalendarIdsResponse> {
        var request = Rust.LoadResourcesByCalendarIdsRequest()
        request.calendarIds = calendarIDs
        let debugParams = ["calendarIDsCount": calendarIDs.count.description]
        return rustService.async(message: request,
                                 debugParams: debugParams,
                                 debugResponse: {["buildingCount": $0.buildings.count.description,
                                                  "resourcesCount": $0.resources.count.description]})
    }
}

extension RustPB.Calendar_V1_PullCalendarInstancesResponse {

    /// Rust 无法生成option的值
    var optionalNextMinTimeSpan: Int32? {
        return hasNextMinTimespan ? nextMinTimespan : nil
    }

    /// Rust 无法生成option的值
    var optionalNextEventID: String? {
        return hasNextEventID ? nextEventID : nil
    }
}

extension CalendarEventInstance {
    var isSyncFromLark: Bool {
        // lark ---> exchange 日历日程，用于端上过滤展示
        return key.starts(with: "sync_from_lark_")
    }
}

// MARK: 有效会议接口 https://bytedance.feishu.cn/wiki/QVgcwWOaNijKdvkkrfzcA1ggncf
extension CalendarRustAPI {

    struct InstanceFourTupleRequest {
        var calendarID: String
        var key: String
        var originalTime: Int64
        var instanceStartTime: Int64

        func toServerCalendarEventForm() -> ServerPB_Calendarevents_CalendarEventForm {
            var form = ServerPB_Calendarevents_CalendarEventForm()
            form.calendarID = Int64(calendarID) ?? 0
            form.eventUid = key
            form.originalTime = originalTime
            return form
        }
    }

    struct InstanceNotesInfoRequest {
        var docToken: String
        var docType: Int
        var docOwnerId: Int64?
        var docBotId: Int64?
    }

    /// 获取 Instance 绑定的 Notes
    func getInstanceRelatedInfo(fourTuple: InstanceFourTupleRequest,
                                needNotesInfoType: [Calendar_V1_NotesInfoType] = Calendar_V1_NotesInfoType.allCases) -> Observable<Calendar_V1_GetCalendarInstanceRelatedInfoResponse> {
        var req = Calendar_V1_GetCalendarInstanceRelatedInfoRequest()
        req.calendarID = fourTuple.calendarID
        req.key = fourTuple.key
        req.originalTime = fourTuple.originalTime
        req.instanceStartTime = fourTuple.instanceStartTime
        req.needNotesInfoType = needNotesInfoType

        let debugParams = [
            "calendarID": fourTuple.calendarID,
            "key": fourTuple.key,
            "originalTime": String(fourTuple.originalTime),
            "instanceStartTime": String(fourTuple.instanceStartTime)
        ]

        return rustService.async(message: req,
                                 debugParams: debugParams,
                                 debugResponse: {
            ["inNotesFg": $0.inNotesFg.description,
             "notesInfo": $0.hasNotesInfo.description,
             "showEventPermission": $0.notesInfo.showEventPermission.description]
        })
    }


    /// 通过 token 获取 NotesInfo
    func getNotesInfo(
        notes: InstanceNotesInfoRequest,
        needNotesInfoType: [ServerPB_Calendar_entities_NotesInfoType] = ServerPB_Calendar_entities_NotesInfoType.allCases
    ) -> Observable<ServerPB_Calendarevents_GetNotesInfoResponse> {
        var req = ServerPB_Calendarevents_GetNotesInfoRequest()
        req.docToken = notes.docToken
        req.docType = ServerPB_Entities_DocType(rawValue: Int(notes.docType)) ?? ServerPB_Entities_DocType.docx
        req.needNotesInfoType = needNotesInfoType
        return rustService.sendPassThroughAsyncRequest(req, serCommand: .getMeetingNotesInfo, debugParams: nil, debugResponse: nil)
    }

    /// 绑定 instance 与 notes
    func saveInstanceNotes(fourTuple: InstanceFourTupleRequest,
                           model: MeetingNotesModel,
                           originalDocToken: String?) -> Observable<ServerPB_Calendarevents_SaveInstanceNotesResponse> {
        let notes = CalendarRustAPI.InstanceNotesInfoRequest(docToken: model.token,
                                                             docType: model.type,
                                                             docOwnerId: model.docOwnerId,
                                                             docBotId: model.docBotId)
        var req = ServerPB_Calendarevents_SaveInstanceNotesRequest()
        req.calendarEventForm = fourTuple.toServerCalendarEventForm()
        req.instanceStartTime = fourTuple.instanceStartTime
        req.docToken = notes.docToken
        req.docType = ServerPB_Entities_DocType(rawValue: Int(notes.docType)) ?? ServerPB_Entities_DocType.docx
        if let docOwnerID = notes.docOwnerId {
            req.docOwnerID = docOwnerID
        }
        if let botId = notes.docBotId {
            req.docBotID = botId
        }
        if let originalDocToken = originalDocToken {
            req.originalDocToken = originalDocToken
        }
        req.eventPermission = Server.NotesEventPermission(rawValue: model.eventPermission.rawValue) ?? .canEdit
        if let notesType = model.notesType {
            req.notesType = notesType.toServerPB()
        }

        return rustService.sendPassThroughAsyncRequest(req, serCommand: .saveInstanceNotes, debugParams: nil, debugResponse: nil)
    }

    /// 删除文档接口
    func deleteMeetingNotes(fourTuple: InstanceFourTupleRequest?, notes: InstanceNotesInfoRequest) -> Observable<ServerPB_Calendarevents_DelNotesDocResponse> {
        var req = ServerPB_Calendarevents_DelNotesDocRequest()
        if let fourTuple = fourTuple {
            req.calendarEventForm = fourTuple.toServerCalendarEventForm()
        }
        if let ownerId = notes.docOwnerId {
            req.docOwnerID = ownerId
        }
        req.docToken = notes.docToken
        req.docType = ServerPB_Entities_DocType(rawValue: Int(notes.docType)) ?? ServerPB_Entities_DocType.docx

        return rustService.sendPassThroughAsyncRequest(req, serCommand: .delNotesDoc, debugParams: nil, debugResponse: nil)
    }

    /// 创建文档接口
    func createMeetingNotes(fourTuple: InstanceFourTupleRequest?, templateToken: String?, templateType: Int?, templateId: String?, docTitle: Server.NotesTitleForm) -> Observable<ServerPB_Calendarevents_CreateNotesDocResponse> {
        var req = ServerPB_Calendarevents_CreateNotesDocRequest()
        if let tuple = fourTuple {
            req.calendarEventForm = tuple.toServerCalendarEventForm()
        }
        if let templateId = templateId {
            req.templateID = templateId
        }
        if let templateToken = templateToken {
            req.templateToken = templateToken
        }
        if let templateType = templateType {
            req.templateType = ServerPB_Entities_DocType(rawValue: templateType) ?? ServerPB_Entities_DocType.docx
        }
        req.notesTitleForm = docTitle

        return rustService.sendPassThroughAsyncRequest(req, serCommand: .createNotesDoc, debugParams: nil, debugResponse: nil)
    }
}

// MARK: 冲突视图
extension CalendarRustAPI {
    func getMeetingConflict(meetingId: String) -> Observable<Calendar_V1_GetMeetingConflictResponse> {
        var req = Calendar_V1_GetMeetingConflictRequest()
        req.meetingID = meetingId

        return rustService.async(message: req, debugParams: nil, debugResponse: nil)
    }

    func getDayInstancesForEventConflict(
        rrule: String,
        timezone: String,
        startTime: Int64,
        endTime: Int64,
        isAllDay: Bool,
        eventSerId: String,
        eventCalendarId: String?
    ) -> Observable<Calendar_V1_GetDayInstancesForEventConflictResponse> {
        var req = Calendar_V1_GetDayInstancesForEventConflictRequest()
        req.rrule = rrule
        req.timezone = timezone
        req.startTime = startTime
        req.endTime = endTime
        req.isAllDay = isAllDay
        req.eventSerID = eventSerId
        if let eventCalendarId = eventCalendarId {
            req.eventCalendarID = eventCalendarId
        }

        return rustService.async(message: req, debugParams: nil, debugResponse: nil)
    }

    func getDayInstancesForEventConflictWithEvent(event: Rust.Event) -> Observable<Calendar_V1_GetDayInstancesForEventConflictWithEventResponse> {
        var req = Calendar_V1_GetDayInstancesForEventConflictWithEventRequest()
        req.event = event

        return rustService.async(message: req,
                                 debugParams: event.debugInfo(),
                                 debugResponse: { res in
            ["conflictTime": res.conflictTime.description,
             "conflictType": res.conflictType.rawValue.description,
             "instance_count": res.dayInstances.count.description]
        })
    }
}

/// MyAI & 蓝牙会议室
extension CalendarRustAPI {
    /// 通过 token 获取 NotesInfo
    func uploadNearbyMeetingRoomInfoRequest(bleScanResultList: String) -> Observable<ServerPB_Calendarevents_UploadNearbyMeetingRoomInfoResponse> {
        var req = ServerPB_Calendarevents_UploadNearbyMeetingRoomInfoRequest()
        req.bleScanResultList = bleScanResultList
        let debugParams = ["bleScanResultList": bleScanResultList]
        return rustService.sendPassThroughAsyncRequest(req, serCommand: .uploadNearbyRoomInfo, debugParams: debugParams, debugResponse: nil)
    }
    
    func getCalendarDevicePermissionBleRequest() -> Observable<ServerPB_Calendarevents_GetCalendarDevicePermissionBleResponse> {
        let req = ServerPB_Calendarevents_GetCalendarDevicePermissionBleRequest()
        return rustService.sendPassThroughAsyncRequest(req, serCommand: .getCalendarDevicePermissionBle, debugParams: nil, debugResponse: {["needBle": $0.needBle.description]})
    }

}

/// InLineAI浮窗组件接入
extension CalendarRustAPI {
    
    /// 获取优化后的自由指令
    func getCalendarMyAIUserQueryRequest(inputType: Server.MyAIInlineInputType, userInput: String) -> Observable<Server.MyAIUserQueryResponse> {
        var request = Server.MyAIUserQueryRequest()
        request.inputType = inputType
        request.userInput = userInput
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getCalendarMyAiUserQuery, debugParams: [:], debugResponse: {["output_content": $0.outputContent.description]})
    }
    
    /// 轮训接口
    func getCalendarMyAIInlineEventRequest(aiTaskID: String, aiTaskEnd: Bool) -> Observable<Server.GetCalendarMyAIInlineEventResponse> {
        var request = Server.GetCalendarMyAIInlineEventRequest()
        request.aiTaskID = aiTaskID
        request.aiTaskEnd = aiTaskEnd
        let debugParams = ["aiTaskID": "\(aiTaskID)",
                           "aiTaskEnd": aiTaskEnd.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getCalendarMyAiInlineEvent,
                                                       debugParams: debugParams,
                                                       debugResponse: {["aiTaskID": $0.aiTaskID.description,
                                                                        "stage": $0.stage.rawValue.description]})
    }
    /// 获取快捷指令
    func fetchQuickActionList(triggerParamsMap: [String: String]) -> Observable<Server.FetchQuickActionResponse> {
        var request = Server.FetchQuickActionRequest()
        request.scenario = .calendar
        request.triggerParamsMap = triggerParamsMap
        let debugParams = ["scenario": "calendar",
                           "triggerParamsMap": triggerParamsMap.description]
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiInlineFetchQuickAction, debugParams: debugParams, debugResponse: {["actions": $0.actions.description]})
    }

    /// 指令调用
    /// - Parameters:
    ///   - sectionID: 会话 ID, 第一次不传
    ///   - uniqueTaskID: task唯一id
    ///   - scenario: 场景类型
    ///   - actionID: 快捷指令ID
    ///   - actionType: 指令类型。
    ///   - userPrompt: 自由指令参数
    ///   - displayContent: 用户看到的指令内容
    ///   - params: 快捷指令参数
    func createTaskRequest(sectionID: String?,
                    uniqueTaskID: String,
                    scenario: Int,
                    actionID: String?,
                    actionType: CalendarPromptActionType,
                    userPrompt: String?,
                    displayContent: String,
                    params: [String: String]) -> Observable<Rust.InlineAICreateTaskResponse> {

        var request = Rust.InlineAICreateTaskRequest()
        request.uniqueTaskID = uniqueTaskID
        request.scenario = .calendar
        if let sId = sectionID, !sId.isEmpty {
            request.sessionID = sId
        }
        if let aId = actionID {
            request.actionID = aId
        }
        if let userInput = userPrompt {
            request.userPrompt = userInput
        }
        request.actionType = actionType.rawValue
        request.displayContent = displayContent
        request.params = params
        let debugParams = ["uniqueTaskID": uniqueTaskID,
                           "sessionID": sectionID ?? "",
                           "actionID": actionID ?? "",
                           "actionType": actionType.rawValue]
        return rustService.async(message: request,
                                 debugParams: debugParams,
                                 debugResponse: {["sessionID": $0.sessionID,
                                                  "uniqueTaskID": $0.uniqueTaskID]})
    }
    
    /// 指令中断
    func cancelTaskRequest(taskId: String) -> Observable<Rust.InlineAICancelTaskResponse> {
        var request = Rust.InlineAICancelTaskRequest()
        request.uniqueTaskID = taskId
        return rustService.async(message: request,
                                 debugParams: ["uniqueTaskID": taskId],
                                 debugResponse: nil)
    }
    
    /// 获取debug Info
    func getDebugInfo(aiMessageId: String, completion: @escaping (Swift.Result<String, Error>) -> Void) -> Observable<Server.AIEngineDebugInfoResponse> {
        var request = Server.AIEngineDebugInfoRequest()
        request.messageID = aiMessageId
        request.mode = .inline
        // 透传请求
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .larkAiFeedbackReasonSubmit, debugParams: nil, debugResponse: nil)
    }

    /// 批量删除会议纪要
    func batchDelNotesDocRequest(notesDocInfo: [Server.NotesDocInfo]) -> Observable<Server.BatchDelNotesDocResponse> {
        var request = Server.BatchDelNotesDocRequest()
        request.notesDocInfo = notesDocInfo

        return rustService.sendPassThroughAsyncRequest(request,
                                                       serCommand: .batchDelNotesDoc,
                                                       debugParams: nil,
                                                       debugResponse: nil)
    }
}

extension CalendarRustAPI {
    /// 检查判断能否发消息
    func checkCanRSVPCommentToOragnizer(receiverUserId: Int64) -> Observable<Bool> {
        var request = ServerPB_Calendarevents_CheckCanRSVPCommentRequest()
        request.receiverUserID = receiverUserId
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .checkCanRsvpComment, debugParams: nil, debugResponse: nil).map { (request:  ServerPB_Calendarevents_CheckCanRSVPCommentResponse) -> Bool in
            return request.canSend
        }
    }
}

// 时间块相关API实现
extension CalendarRustAPI: TimeBlockAPI {
    //修改时间
    func patchTimeBlock(id: String, 
                        containerIDOnDisplay: String,
                        startTime: Int64?,
                        endTime: Int64?,
                        actionType: UpdateTimeBlockActionType) -> Observable<UpdateTimeBlockTimeRangeResponse> {
        var request = RustPB.Calendar_V1_UpdateTimeBlockTimeRangeRequest()
        request.blockID = id
        request.containerIDOnDisplay = containerIDOnDisplay
        if let startTime = startTime {
            request.newStartTime = startTime
        }
        if let endTime = endTime {
            request.newEndTime = endTime
        }
        request.actionType = actionType
        return rustService.async(message: request, debugParams: [:], debugResponse: nil)
    }

    //获取当前用户给定范围的时间块
    func fetchTimeBlock(startTime: Int64,
                        endTime: Int64,
                        timezone: String,
                        needContainer: Bool) -> Observable<GetTimeBlocksWithTimeRangeResponse> {
        var request = RustPB.Calendar_V1_GetTimeBlocksWithTimeRangeRequest()
        request.timeRange.startTime = startTime
        request.timeRange.endTime = endTime
        request.timezone = timezone
        request.needContainer = needContainer
        return rustService.async(message: request, debugParams: [:], debugResponse: nil)
    }
    
    // 可点击icon被点击
    func finishTask(id: String, containerIDOnDisplay: String, isCompleted: Bool) -> Observable<CompleteTaskBlockWithIDInTimeContainerResponse> {
        var request = RustPB.Calendar_V1_CompleteTaskBlockWithIDInTimeContainerRequest()
        request.blockID = id
        request.containerIDOnDisplay = containerIDOnDisplay
        request.isCompleted = isCompleted
        return rustService.async(message: request, debugParams: [:], debugResponse: nil)
    }
    
    func fetchTimeBlockById(_ id: String, 
                            containerIDOnDisplay: String,
                            timezone: TimeZone) -> Observable<TimeBlockWithIDResponse> {
        var request = RustPB.Calendar_V1_GetTimeBlockWithIDRequest()
        request.blockID = id
        request.containerIDOnDisplay = containerIDOnDisplay
        request.timezone = timezone.identifier
        return rustService.async(message: request, debugParams: [:], debugResponse: nil)
    }
    
    func getTimeContainers(with ids: [String], fromServer: Bool = false) -> Observable<Calendar_V1_GetTimeContainerWithIDsResponse> {
        var req = Calendar_V1_GetTimeContainerWithIDsRequest()
        req.serverContainerID = ids
        req.source = fromServer ? .server : .local
        
        return rustService.async(message: req, debugParams: ["ids": ids.description, "fromService": fromServer.description], debugResponse: nil)
    }
}

// 时间容器相关API实现
extension CalendarRustAPI: TimeContainerAPI {

    func fetchTimeContainers() -> Observable<GetAllTimeContainersResponse> {
        let request = RustPB.Calendar_V1_GetAllTimeContainersRequest()
        return rustService.async(message: request, debugParams: [:], debugResponse: nil)
    }
    
    /// 更改时间容器
    func updateTimeContainerInfo(id: String, isVisibile: Bool? = nil, colorIndex: ColorIndex? = nil) -> Observable<Calendar_V1_UpdateTimeContainerInfoResponse> {
        var saveInfo = Calendar_V1_UpdateTimeContainerInfoRequest.TimeContainerSaveInfo()
        if let isVisible = isVisibile {
            saveInfo.isVisible = isVisible
        }
        if let colorIndex = colorIndex {
            saveInfo.colorIndex = colorIndex
        }
        guard saveInfo.hasIsVisible || saveInfo.hasColorIndex else {
            assertionFailure("updateTimeContainerInfo with no change")
            return .empty()
        }
        
        var request = Calendar_V1_UpdateTimeContainerInfoRequest()
        request.serverContainerID = id
        request.saveInfo = saveInfo
        
        let debugParams = [
            "id": id,
            "isVisibile": isVisibile?.description ?? "none",
            "colorIndex": colorIndex?.rawValue.description ?? "none",
        ]
        
        return rustService.async(message: request, debugParams: debugParams, debugResponse: nil)
    }
    
    
    func specifyVisibleOnlyTimeContainer(with id: String) -> Observable<Calendar_V1_SpecifyVisibleOnlyTimeContainerResponse> {
        var req = Calendar_V1_SpecifyVisibleOnlyTimeContainerRequest()
        req.serverContainerID = id
        
        return rustService.async(message: req, debugParams: ["id": id], debugResponse: nil)
    }
}
