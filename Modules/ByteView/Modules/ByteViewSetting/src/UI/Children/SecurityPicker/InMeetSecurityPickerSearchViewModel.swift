//
//  InMeetSecurityPickerSearchViewModel.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

protocol InMeetSecurityPickerSearchDelegate: AnyObject {
    func securityPickerDidUpdateSearchResult(isChanged: Bool)
}

final class InMeetSecurityPickerSearchViewModel {
    private let setting: MeetingSettingManager
    private let pageSize: Int = 30
    @RwAtomic private var query = InMeetSecurityPickerSearchQuery(key: "", offset: 0, count: 0)
    @RwAtomic private var data = InMeetSecurityPickerSearchData(query: .init(key: "", offset: 0, count: 0))
    @RwAtomic private(set) var isRequesting = false
    @RwAtomic private(set) var isCancelled = false
    weak var delegate: InMeetSecurityPickerSearchDelegate?
    private var httpClient: HttpClient { setting.service.httpClient }
    var hasMore: Bool { data.hasMore }

    init(setting: MeetingSettingManager) {
        self.setting = setting
    }

    func buildRows(selectedData: InMeetSecurityPickerSelectedData) -> [InMeetSecurityPickerRow] {
        if query.key.isEmpty { return [] }
        return data.items.map { InMeetSecurityPickerRow(item: .search($0), selectedData: selectedData) }
    }

    func search(key: String) {
        if key == query.key {
            delegate?.securityPickerDidUpdateSearchResult(isChanged: false)
            return
        }

        if key.isEmpty {
            isRequesting = false
            delegate?.securityPickerDidUpdateSearchResult(isChanged: !self.data.items.isEmpty)
            return
        }
        self.query = InMeetSecurityPickerSearchQuery(key: key, offset: 0, count: pageSize)
        self.data = InMeetSecurityPickerSearchData(query: query)
        startRequest()
    }

    func loadMore() {
        self.query.offset += self.pageSize
        startRequest()
    }

    func cancel() {
        self.isRequesting = false
        self.isCancelled = true
        self.delegate?.securityPickerDidUpdateSearchResult(isChanged: false)
    }

    private func startRequest() {
        self.isRequesting = true
        self.isCancelled = false

        let query = self.query
        let request = SearchUsersAndChatsRequest(query: query.key, offset: query.offset, count: query.count, queryType: .searchForJoinLimit)
        httpClient.getResponse(request) { [weak self] result in
            guard let self = self, self.canProcessQuery(query) else { return }
            switch result {
            case .success(let response):
                // 获取外部用户的租户名称
                let ids = response.items.filter { $0.idType == .user && $0.isExternal }.map { $0.id }
                self.setting.requestCache.fetchTenantNames(Set(ids)) { [weak self] tenantNames in
                    guard let self = self, self.canProcessQuery(query) else { return }
                    for var item in response.items {
                        // 信息安全要求: 将外部用户的desc替换成对应租户名称
                        if item.idType == .user && item.isExternal {
                            if let name = tenantNames[item.id] {
                                item.desc = name
                            } else {
                                item.desc = ""
                            }
                        }
                        self.data.items.append(item)
                    }
                    self.data.hasMore = response.hasMore
                    self.isRequesting = false
                    self.delegate?.securityPickerDidUpdateSearchResult(isChanged: true)
                }
            case .failure:
                self.isRequesting = false
                self.delegate?.securityPickerDidUpdateSearchResult(isChanged: false)
            }
        }
    }

    private func canProcessQuery(_ query: InMeetSecurityPickerSearchQuery) -> Bool {
        !self.isCancelled && self.query == query
    }
}

struct InMeetSecurityPickerSearchQuery: Equatable {
    var key: String
    var offset: Int
    var count: Int
}

struct InMeetSecurityPickerSearchData {
    var query: InMeetSecurityPickerSearchQuery
    var hasMore: Bool = false
    var items: [SearchUsersAndChatsResponse.UserAndCardItem] = []
}
