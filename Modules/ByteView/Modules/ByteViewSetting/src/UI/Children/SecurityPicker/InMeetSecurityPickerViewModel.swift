//
//  InMeetSecurityPickerViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

protocol InMeetSecurityPickerViewModelDelegate: AnyObject {
    func securityPickerDidFinishLoading()
    func securityPickerDidChangeSecuritySetting(_ setting: VideoChatSettings.SecuritySetting)
}

final class InMeetSecurityPickerViewModel: MeetingInternalSettingListener {
    let setting: MeetingSettingManager
    private(set) lazy var search = InMeetSecurityPickerSearchViewModel(setting: setting)
    private lazy var requestor = InMeetSecurityRequestor(setting: setting)

    @RwAtomic private var data = InMeetSecurityPickerRecommendedData()
    @RwAtomic private(set) var selectedData = InMeetSecurityPickerSelectedData()
    @RwAtomic private(set) var securitySetting: VideoChatSettings.SecuritySetting
    weak var delegate: InMeetSecurityPickerViewModelDelegate?
    private var httpClient: HttpClient { requestor.httpClient }
    var isLoading: Bool { data.isRequesting }
    var selectedCount: Int { selectedData.count }

    init(setting: MeetingSettingManager) {
        self.setting = setting
        self.securitySetting = setting.videoChatSettings.securitySetting
        loadUsers()
        setting.addInternalListener(self)
    }

    func buildRows() -> [InMeetSecurityPickerRow] {
        if isLoading { return [] }
        var rows: [InMeetSecurityPickerRow] = []
        if self.setting.isCalendarMeeting, data.calendarGuests.status != .unknown {
            let isExpanded = data.isCalendarExpanded
            let status = data.calendarGuests.status
            rows.append(InMeetSecurityPickerRow(item: .calendarHeader(.init(isExpanded: isExpanded, status: status)), selectedData: selectedData))
            if isExpanded, status == .success, !data.calendarGuests.resultList.isEmpty {
                data.calendarGuests.resultList.forEach { item in
                    rows.append(InMeetSecurityPickerRow(item: .calendarGuest(item), selectedData: selectedData, showsSeparator: false))
                }
                rows[rows.count - 1].showsSeparator = true
            }
        }
        data.items.forEach { item in
            rows.append(InMeetSecurityPickerRow(item: item, selectedData: selectedData))
        }
        return rows
    }

    func buildSearchRows() -> [InMeetSecurityPickerRow] {
        search.buildRows(selectedData: selectedData)
    }

    func toggleCalendarExpand() {
        if isLoading { return }
        self.data.isCalendarExpanded = !self.data.isCalendarExpanded
    }

    func saveSetting() {
        var securitySettings = self.securitySetting
        securitySettings.securityLevel = .contactsAndGroup
        securitySettings.userIds = selectedData.userIds
        securitySettings.groupIds = selectedData.groupIds
        securitySettings.roomIds = selectedData.roomIds
        securitySettings.specialGroupType = selectedData.hasCalendarGuests ? [.calendarGuestList] : []
        setting.updateHostManage(.setSecurityLevel, update: { $0.securitySetting = securitySettings })
    }

    private func loadUsers() {
        var initialValue: InMeetSecurityRequestor.UserValue?
        let group = DispatchGroup()
        group.enter()
        requestor.updateSecuritySetting(self.securitySetting) { value in
            initialValue = value
            group.leave()
        }

        group.enter()
        fetchRecommendItems { [weak self] in
            self?.data.items = $0
            group.leave()
        }

        if self.setting.isCalendarMeeting {
            group.enter()
            httpClient.getResponse(GetCalendarGuestListRequest(meetingID: self.setting.meetingId)) { [weak self] result in
                if case .success(let resp) = result {
                    self?.data.calendarGuests = resp
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            if let value = initialValue {
                self?.updateRemoteSecuritySettings(value)
            }
            self?.data.isRequesting = false
            self?.delegate?.securityPickerDidFinishLoading()
        }
    }

    func toggleRowSelection(_ row: InMeetSecurityPickerRow) {
        selectedData.toggleSelection(row.item)
    }

    func unselectItems(_ items: [InMeetSecurityPickerItem]) {
        selectedData.unselectItems(items)
    }

    func didChangeVideoChatSettings(_ settings: MeetingSettingManager, value: VideoChatSettings, oldValue: VideoChatSettings?) {
        let newSetting = value.securitySetting
        if newSetting != self.securitySetting {
            self.securitySetting = newSetting
            requestor.updateSecuritySetting(newSetting) { [weak self] in
                self?.updateRemoteSecuritySettings($0)
            }
        }
    }

    private func updateRemoteSecuritySettings(_ value: InMeetSecurityRequestor.UserValue) {
        self.selectedData.resetSelectedItems(service: setting, setting: securitySetting, value: value, data: data)
        if !self.isLoading {
            delegate?.securityPickerDidChangeSecuritySetting(self.securitySetting)
        }
    }

    private func fetchRecommendItems(completion: @escaping ([InMeetSecurityPickerItem]) -> Void) {
        let currentTenantId = self.setting.service.tenantId
        httpClient.getResponse(GetFeedCardsRequest(count: 30)) { [weak self] result in
            guard let self = self, case let .success(resp) = result, !resp.previews.isEmpty else {
                completion([])
                return
            }

            let previews = resp.previews
            var userIds: [String] = []
            var groupIds: [String] = []
            var userIdAndChatIds: [String: String] = [:]
            for preview in previews {
                if preview.isGroup {
                    groupIds.append(preview.feedID)
                } else {
                    userIds.append(preview.chatterID)
                    userIdAndChatIds[preview.chatterID] = preview.feedID
                }
            }

            var users: [String: ParticipantUserInfo] = [:]
            var groups: [String: Chat] = [:]
            var tenantNames: [String: String] = [:]
            var collaborationTypes: [String: LarkUserCollaborationType] = [:]

            let group = DispatchGroup()
            group.enter()
            self.requestor.fetchUserInfos(.init(groupIds: groupIds, userIds: userIds, roomIds: [])) { [weak self] value in
                var crossUserIds = Set<String>()
                for user in value.users {
                    users[user.id] = user
                    if user.tenantId != currentTenantId {
                        crossUserIds.insert(user.id)
                    }
                }
                for g in value.groups {
                    groups[g.id] = g
                }
                if let self = self, !crossUserIds.isEmpty {
                    self.requestor.requestCache.fetchTenantNames(crossUserIds) {
                        tenantNames = $0
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }

            if self.setting.fg.isOnewayRelationshipEnabled {
                group.enter()
                self.httpClient.getResponse(GetAuthChattersRequest(authInfo: userIdAndChatIds)) { result in
                    if case .success(let resp) = result {
                        collaborationTypes = resp.authResult.deniedReasons.mapValues({ $0 == .blocked ? .blocked : .default })
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard self != nil else { return }
                var items: [InMeetSecurityPickerItem] = []
                previews.forEach { preview in
                    if preview.isGroup {
                        if let g = groups[preview.feedID] {
                            items.append(.group(g))
                        }
                    } else {
                        if let user = users[preview.chatterID] {
                            let isCrossTenant = user.tenantId != currentTenantId
                            var recommendUser = InMeetSecurityPickerItem.RecommandUser(user: user, isCrossTenant: isCrossTenant, collaborationType: collaborationTypes[user.id, default: .default])
                            if isCrossTenant {
                                // 信息安全要求: 将外部用户的description替换成对应租户名称
                                recommendUser.tenantName = tenantNames[user.id, default: ""]
                            }
                            items.append(.user(recommendUser))
                        }
                    }
                }
                completion(items)
            }
        }
    }
}

struct InMeetSecurityPickerRecommendedData {
    var isCalendarExpanded: Bool = false
    var items: [InMeetSecurityPickerItem] = []
    var calendarGuests: GetCalendarGuestListResponse = .init(status: .unknown, resultList: [])
    var isRequesting: Bool = true
}

private extension UserSettingManager {

    struct AccountInfo {
        let userId: String
        let deviceId: String
        let tenantId: String
        let tenantTag: TenantTag?

        /// 是否外部租户
        func isExternal(tenantId: String?) -> Bool {
            canShowExternal ? self.tenantId != tenantId : false
        }

        /// 小B用户不显示外部标签
        var canShowExternal: Bool {
            if let tenantTag = self.tenantTag, tenantTag != .standard {
                return false // 小B用户不显示外部标签
            } else {
                return true
            }
        }
    }
}

private extension InMeetSecurityPickerSelectedData {
    mutating func resetSelectedItems(service: MeetingSettingManager, setting: VideoChatSettings.SecuritySetting,
                                     value: InMeetSecurityRequestor.UserValue, data: InMeetSecurityPickerRecommendedData) {
        self.hasCalendarGuests = setting.specialGroupType.contains(.calendarGuestList)
        self.userIds = value.key.userIds
        self.groupIds = value.key.groupIds
        self.roomIds = value.key.roomIds
        self.items = []
        var groupsInData: [String: InMeetSecurityPickerItem] = [:]
        var usersInData: [String: InMeetSecurityPickerItem] = [:]
        var roomsInData: [String: InMeetSecurityPickerItem] = [:]
        for cache in data.items {
            switch cache {
            case .user(let info):
                usersInData[info.id] = cache
            case .group(let info):
                groupsInData[info.id] = cache
            case .room(let info):
                roomsInData[info.id] = cache
            default:
                break
            }
        }
        if self.hasCalendarGuests {
            self.items.append(.calendarHeader(.init(isExpanded: data.isCalendarExpanded, status: data.calendarGuests.status)))
        }
        for group in value.groups {
            self.items.append(groupsInData[group.id, default: .group(group)])
        }
        let currentTenantId = service.service.tenantId
        for user in value.users {
            let isCrossTenant = user.tenantId != currentTenantId
            self.items.append(usersInData[user.id, default: .user(InMeetSecurityPickerItem.RecommandUser(user: user, isCrossTenant: isCrossTenant, collaborationType: .default))])
        }
        for room in value.rooms {
            self.items.append(roomsInData[room.id, default: .room(room)])
        }
    }
}
