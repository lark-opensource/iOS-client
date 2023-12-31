//
//  MinutesHomePageViewModel.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/9.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import LarkContainer
import LarkAccountInterface
import LarkStorage

enum PersistenceKey: String {
    case key = "minutes.filter"
    case newKey = "filter"
    case schedulerType = "schedulerType"
    case rankType = "rankType"
    case ownerType = "ownerType"
    case isFilterIconActived = "isFilterIconActived"
    case asc = "asc"
}

class MinutesSpaceListViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    @ScopedProvider var passportUserService: PassportUserService?

    var spaceType = MinutesSpaceType.home
    var rankType = MinutesRankType.createTime
    var ownerType = MinutesOwnerType.byAnyone
    var schedulerType: MinutesSchedulerType = MinutesSchedulerType.none
    var asc = false
    var feedList: MinutesSpaceList?
    var successHandler: (() -> Void)?
    var failureHandler: ((Error?) -> Void)?
    var reloadDataOnly: (() -> Void)?
    var removeCellSuccess: (([IndexPath]) -> Void)?
    var removeCellFailure: (([IndexPath]) -> Void)?
    var isFilterIconActived = false
    var toast: String = ""
    var isRefreshing: Bool = true
    var minutesTranscribeProcessCenter: MinutesTranscribeProcessCenter
    var shouldForceReload: Bool = false
    let hash = UUID().uuidString
    var isEnabled: Bool = false

    private let spaceAPI = MinutesSapceAPI()
    private var timestamp: String = "0"
    private let initialTimeStamp = "0"
    private let pageCount = 20
    private var timer: Timer?
    private var isRequestOnAir = false

    init(resolver: UserResolver, spaceType: MinutesSpaceType) {
        self.userResolver = resolver
        self.spaceType = spaceType
        self.minutesTranscribeProcessCenter = MinutesTranscribeProcessCenter()

        let result = getFilterValue(spaceType: spaceType)
        if result == false {
            setInitValue()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(topicDidUpdate(noti:)), name: NSNotification.Name.SpaceList.topicDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(minutesDidDelete(noti:)), name: NSNotification.Name.SpaceList.minutesDidDelete, object: nil)
        if spaceType == .home {
            NotificationCenter.default.addObserver(self, selector: #selector(minutesDidRestore(noti:)), name: NSNotification.Name.SpaceList.minutesDidRestore, object: nil)
        }
    }
    
    func setInitValue() {
        if spaceType == .share {
            rankType = MinutesRankType.shareTime
        }
        if spaceType == .trash {
            rankType = .expireTime
        }
    }
    
    func getFilterValue(spaceType: MinutesSpaceType) -> Bool {
        guard let userId = passportUserService?.user.userID else { return false }
        let store: KVStore = KVStores.udkv(
            space: .user(id: userId),
            domain: Domain.biz.minutes
        )
        guard let persistenceDict: [String: [String: [String: Int]]] = store.value(forKey: PersistenceKey.newKey.rawValue) else { return false }

        guard let dict = persistenceDict[userId] as? [String: [String: Int]] else { return false }
        guard let sceneDict = dict[spaceType.stringValue] as? [String: Int] else {
            return false
        }
        if let value = sceneDict[PersistenceKey.schedulerType.rawValue] as? Int {
            schedulerType = MinutesSchedulerType(rawValue: value) ?? MinutesSchedulerType.none
        }

        if let value = sceneDict[PersistenceKey.rankType.rawValue] as? Int {
            if let type = MinutesRankType(rawValue: value) {
                rankType = type
            } else {
                switch spaceType {
                case .home:
                    rankType = .createTime
                case .my:
                    rankType = .createTime
                case .share:
                    rankType = .shareTime
                case .trash:
                    rankType = .expireTime
                }
            }
        }
        if let value = sceneDict[PersistenceKey.ownerType.rawValue] as? Int {
            ownerType = MinutesOwnerType(rawValue: value) ?? MinutesOwnerType.byAnyone
        }
        if let value = sceneDict[PersistenceKey.isFilterIconActived.rawValue] as? Int {
            isFilterIconActived = value == 1 ? true : false
        }
        if let value = sceneDict[PersistenceKey.asc.rawValue] as? Int {
            asc = value == 1 ? true : false
        }
        return true
    }

    deinit {
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(self)
    }

    func refreshFeedList() {
        timestamp = initialTimeStamp
        isRefreshing = true
        fetchFeedList()
    }

    func loadMoreFeedList() {
        if isRequestOnAir {
            return
        }
        isRefreshing = false
        fetchFeedList()
    }

    func preLoadFeedList(with indexPath: IndexPath) {
        if isRequestOnAir {
            return
        }
        guard let feedList = feedList else {
            return
        }
        if !feedList.hasMore {
            return
        }
        if indexPath.row > feedList.list.count - 10 {
            loadMoreFeedList()
            isRequestOnAir = true
        }
    }

    private func fetchFeedList() {
        spaceAPI.doHomeSpaceListRequest(timestamp: timestamp, spaceName: spaceType, size: pageCount, ownerType: ownerType, rank: rankType, asc: asc) { [weak self] res in
            guard let `self` = self else {
                return
            }
            self.isRequestOnAir = false
            switch res {
            case .success(let data):
                DispatchQueue.main.async {
                    if self.timestamp == self.initialTimeStamp {
                        self.feedList = data
                    } else {
                        self.feedList?.list.append(contentsOf: data.list)
                    }
                    self.feedList?.hasMore = data.hasMore
                    self.feedList?.hasDeleteTag = data.hasDeleteTag
                    if data.hasDeleteTag {
                        self.isEnabled = true
                    } else {
                        self.isEnabled = false
                    }
                    if self.rankType == .schedulerExecuteTime, let ts = data.list.last?.schedulerExecuteTimestamp {
                        self.timestamp = "\(ts)"
                    } else {
                        if self.spaceType == .trash, let ts = data.list.last?.expireTime {
                            self.timestamp = "\(ts)"
                        } else {
                            if let ts = data.list.last?.time {
                                self.timestamp = "\(ts)"
                            }
                        }
                    }

                    self.successHandler?()
                    self.startToFetchBatchStatus()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.failureHandler?(error)
                }
            }
        }
    }

}

// MARK: - update status
extension MinutesSpaceListViewModel {

    func startToFetchBatchStatus() {
        if getObjectTokens().isEmpty {
            return
        }
        if spaceType != .trash {
            timer?.fire()
        }
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            self.fetchFeedListBatchStatus()
        })
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchFeedListBatchStatus() {
        let tokens = getObjectTokens()
        if tokens.isEmpty {
            stopTimer()
            minutesTranscribeProcessCenter.stopTranscribeTimer()
            return
        }
        spaceAPI.fetchSpaceFeedListBatchStatus(catchError: false, objectToken: tokens) { [weak self] res in
            guard let `self` = self else {
                return
            }
            switch res {
            case .success(let data):
                DispatchQueue.main.async {
                    if self.spaceType == .trash {
                        self.processTrashBatchStatus(data.status)
                    } else {
                        self.processNormalBatchStatus(data.status)
                    }
                    self.reloadDataOnly?()
                    if self.getObjectTokens().isEmpty {
                        self.stopTimer()
                        self.minutesTranscribeProcessCenter.stopTranscribeTimer()
                    }
                }
            case .failure:
                break
            }
        }
    }

    private func processTrashBatchStatus(_ status: [MinutesFeedListItemStatus]) {
        var validStatus = [MinutesFeedListItemStatus]()
        var restoreTokens: Set<String> = []
        var deletedTokens: Set<String> = []
        status.forEach { statusItem in
            if statusItem.objectStatus == .deleted {
                deletedTokens.insert(statusItem.objectToken)
                shouldForceReload = true
            } else {
                if statusItem.inTrash {
                    validStatus.append(statusItem)
                } else {
                    restoreTokens.insert(statusItem.objectToken)
                    shouldForceReload = true
                }
            }
        }
        postRestoreMinutesNotification(withTokens: Array(restoreTokens))
        var statusMap = [String: MinutesFeedListItemStatus]()
        for s in validStatus where s.expireTime != -1 {
            statusMap[s.objectToken] = s
        }
        let validItems = feedList?.list.filter({ item in
            if deletedTokens.contains(item.objectToken) {
                return false
            }
            if restoreTokens.contains(item.objectToken) {
                return false
            }
            return true
        })
        var newItems = [MinutesSpaceListItem]()
        validItems?.forEach({ i in
            var item = i
            if let status = statusMap[item.objectToken] {
                item.time = status.expireTime
                item.expireTime = status.expireTime
            }
            newItems.append(item)
        })
        feedList?.list = newItems
    }

    private func processNormalBatchStatus(_ status: [MinutesFeedListItemStatus]) {
        var statusMap = [String: MinutesFeedListItemStatus]()
        for item in status {
            statusMap[item.objectToken] = item
        }
        minutesTranscribeProcessCenter.updateTranscribeStatus(status: status)

        guard  let count = feedList?.list.count, count > 0 else {
            return
        }
        for index in 0..<count {
            if let token = feedList?.list[index].objectToken, let feedListItemStatus = statusMap[token] {
                var finalObjectStatus = feedListItemStatus.objectStatus
                if feedListItemStatus.objectStatus == .audioRecordUploading ||
                           feedListItemStatus.objectStatus == .audioRecordUploadingForced ||
                           feedListItemStatus.objectStatus == .audioRecordCompleteUpload {
                    finalObjectStatus = .audioRecordUploading
                }
                if feedListItemStatus.objectStatus == .audioRecording ||
                           feedListItemStatus.objectStatus == .audioRecordPause,
                   spaceType == .home || spaceType == .my {
                    if let item = self.feedList?.list[index],
                       item.isRecordingDevice == true,
                       MinutesAudioRecorder.shared.minutes?.objectToken != item.objectToken {
                        finalObjectStatus = .audioRecordUploading
                        self.spaceAPI.api.recordComplete(for: item.objectToken)
                    }
                }
                self.feedList?.list[index].objectStatus = finalObjectStatus
                self.feedList?.list[index].topic = feedListItemStatus.topic
                self.feedList?.list[index].duration = feedListItemStatus.duration
            }
        }
    }

    // disable-lint: magic number
    private func getObjectTokens() -> [String] {
        if spaceType == .trash {
            return feedList?.list.prefix(50).map {
                $0.objectToken
            } ?? []
        } else {
            return feedList?.list.filter {
                        $0.objectStatus.minutesIsNeedBashStatus()
                    }
                    .map {
                        $0.objectToken
                    } ?? []
        }
    }
    // enable-lint: magic number


    func updateRecordingListItem(with minutes: Minutes, canAddNewItem: Bool, isRecordingStop: Bool = false) {
        var objectStatus: ObjectStatus
        switch MinutesAudioRecorder.shared.status {
        case .recording:
            objectStatus = .audioRecording
        case .paused:
            objectStatus = .audioRecording
        case .idle:
            objectStatus = .audioRecordUploading
        }
        if isRecordingStop {
            objectStatus = .audioRecordUploading
        }
        if let someIndex = feedList?.list.firstIndex(where: { $0.objectToken == minutes.objectToken }) {
            feedList?.list[someIndex].objectStatus = objectStatus
            feedList?.list[someIndex].duration = Int(MinutesAudioRecorder.shared.recordingTime * 1000)
        } else if canAddNewItem {
            let time = minutes.basicInfo?.startTime ?? Int(Date().timeIntervalSince1970 * 1000)
            var item = MinutesSpaceListItem(url: minutes.baseURL.absoluteString, objectToken: minutes.objectToken, topic: minutes.basicInfo?.topic ?? "", videoCover: minutes.basicInfo?.videoCover ?? "", time: time, createTime: time, shareTime: time, openTime: time, expireTime: 0, duration: Int(MinutesAudioRecorder.shared.recordingTime * 1000), objectStatus: objectStatus, objectType: .recording, reviewStatus: .normal, showExternalTag: false, mediaType: .audio, isRecordingDevice: true, schedulerType: .none, schedulerDeltaExecuteTime: -1, displayTag: minutes.basicInfo?.displayTag)
            item.startTime = time
            item.ownerName = minutes.recordDisplayName
            item.isOwner = true
            if feedList?.list.isEmpty == false {
                feedList?.list.insert(item, at: 0)
            } else {
                feedList?.list.append(item)
            }
        }
        successHandler?()
    }

}

// MARK: - rename
extension MinutesSpaceListViewModel {

    func updateItemTitle(catchError: Bool, objectToken: String, newTopic: String, completionHandler: @escaping ((Bool, Error?) -> Void)) {
        spaceAPI.updateTitle(catchError: catchError, objectToken: objectToken, topic: newTopic) { [weak self] res in
            DispatchQueue.main.async {
                switch res {
                case .success:
                    self?.updateMinutesTopic(objectToken: objectToken, newTopic: newTopic)
                    self?.postUpdateTopicNotification(objectToken: objectToken, newTopic: newTopic)
                    completionHandler(true, nil)
                case .failure(let err):
                    completionHandler(false, err)
                }
            }
        }
    }

    private func updateMinutesTopic(objectToken: String, newTopic: String) {
        if let someList = self.feedList?.list, someList.count > 0,
           let someIndex = self.feedList?.list.firstIndex(where: { $0.objectToken == objectToken }) {
            self.feedList?.list[someIndex].topic = newTopic
        }
    }

    @objc private func topicDidUpdate(noti: Notification) {
        if let object = noti.object as? MinutesSpaceListViewModel, object == self {
            return
        }
        if let token = noti.userInfo?["token"] as? String, let topic = noti.userInfo?["topic"] as? String {
            updateMinutesTopic(objectToken: token, newTopic: topic)
            successHandler?()
        }
    }

    private func postUpdateTopicNotification(objectToken: String, newTopic: String) {
        if spaceType != .home {
            NotificationCenter.default.post(name: NSNotification.Name.SpaceList.topicDidUpdate, object: self, userInfo: ["token": objectToken, "topic": newTopic])
        }
    }
}

// MARK: - delete & restore
extension MinutesSpaceListViewModel {

    func deleteItems(catchError: Bool, withObjectTokens tokens: [String], isDestroyed: Bool = false) {
        spaceAPI.doMinutesDeleteRequest(catchError: catchError, objectTokens: tokens, isDestroyed: isDestroyed) { [weak self] res in
            guard let `self` = self else {
                return
            }
            DispatchQueue.main.async {
                switch res {
                case .success:
                    self.toast = BundleI18n.Minutes.MMWeb_G_My_FileDeletedSingular_Toast
                    self.deleteMinutesSuccess(withObjectTokens: tokens)
                    if !isDestroyed {
                        self.postDeleteMinutesNotification(withTokens: tokens)
                    }
                case .failure(let err): break
                }
            }
        }
    }

    func restoreDeletedItems(withObjectTokens tokens: [String]) {
        spaceAPI.doMinutesDeleteRestoreRequest(objectTokens: tokens) { [weak self] res in
            guard let `self` = self else {
                return
            }
            DispatchQueue.main.async {
                switch res {
                case .success:
                    self.postRestoreMinutesNotification(withTokens: tokens)
                    self.toast = BundleI18n.Minutes.MMWeb_G_Trash_RestoredOneFile_Toast
                    self.deleteMinutesSuccess(withObjectTokens: tokens)
                case .failure(let err):
                    self.deleteMinutesFailure(withObjectTokens: tokens, error: err)
                }
            }
        }
    }

    func removeItems(withObjectTokens tokens: [String]) {
        spaceAPI.doMinutesRemoveRequest(objectTokens: tokens, spaceName: spaceType) { [weak self] res in
            guard let `self` = self else {
                return
            }
            DispatchQueue.main.async {
                switch res {
                case .success:
                    self.toast = BundleI18n.Minutes.MMWeb_M_Home_RemovedOne_Toast
                    self.deleteMinutesSuccess(withObjectTokens: tokens)
                    self.postDeleteMinutesNotification(withTokens: tokens)
                case .failure(let err):
                    self.deleteMinutesFailure(withObjectTokens: tokens, error: err)
                }
            }
        }
    }

    func restoreRemovedItems(withObjectTokens tokens: [String]) {
        spaceAPI.doMinutesRemoveRestoreRequest(objectTokens: tokens, spaceName: spaceType) { [weak self] res in
            guard let `self` = self else {
                return
            }
            DispatchQueue.main.async {
                switch res {
                case .success:
                    self.deleteMinutesSuccess(withObjectTokens: tokens)
                case .failure(let err):
                    self.deleteMinutesFailure(withObjectTokens: tokens, error: err)
                }
            }
        }
    }

    private func deleteMinutesSuccess(withObjectTokens tokens: [String]) {
        let paths = deleteMinutesItems(withObjectTokens: tokens)
        removeCellSuccess?(paths)
        toast = ""
    }

    private func deleteMinutesFailure(withObjectTokens tokens: [String], error: Error) {
        if let someError = error as? ResponseError, someError == .resourceDeleted {
            let paths = deleteMinutesItems(withObjectTokens: tokens)
            toast = BundleI18n.Minutes.MMWeb_G_DeletedByOwner
            removeCellFailure?(paths)
        } else {
            removeCellFailure?([])
        }
    }

    private func deleteMinutesItems(withObjectTokens tokens: [String]) -> [IndexPath] {
        let paths = indexPaths(with: tokens)
        if paths.isEmpty {
            return []
        }
        var items: [MinutesSpaceListItem] = []
        for (index, item) in (feedList?.list ?? []).enumerated() {
            if !paths.contains(where: { indexPath in
                return indexPath.row == index
            }) {
                items.append(item)
            }
        }
        feedList?.list = items
        return paths
    }

    private func indexPaths(with tokens: [String]) -> [IndexPath] {
        if tokens.isEmpty {
            return []
        }
        guard let list = feedList?.list, !list.isEmpty else {
            return []
        }
        var paths: [IndexPath] = []
        let tokenSet = Set(tokens)
        for (index, item) in list.enumerated() where tokenSet.contains(item.objectToken) {
            paths.append(IndexPath(row: index, section: 0))
        }
        return paths
    }

    @objc private func minutesDidDelete(noti: Notification) {
        if let object = noti.object as? MinutesSpaceListViewModel, object == self {
            return
        }
        if let tokens = noti.userInfo?["tokens"] as? [String] {
            deleteMinutesSuccess(withObjectTokens: tokens)
        }
    }

    private func postDeleteMinutesNotification(withTokens tokens: [String]) {
        NotificationCenter.default.post(name: NSNotification.Name.SpaceList.minutesDidDelete, object: self, userInfo: ["tokens": tokens])
    }

    @objc private func minutesDidRestore(noti: Notification) {
        if ownerType == .shareWithMe {
            return
        }
        guard let items = noti.userInfo?["restoredItems"] as? [MinutesSpaceListItem], let list = feedList?.list else {
            return
        }
        if list.isEmpty {
            feedList?.list = items.sorted { item1, item2 in
                return item1.time > item2.time
            }
        } else {
            let last = list[list.count - 1]
            var validItems = items.sorted { item1, item2 in
                return item1.time > item2.time
            }
            if list.count >= pageCount {
                validItems = validItems.filter { item in
                    return item.time > last.time
                }
            }
            if validItems.isEmpty {
                return
            }
            let res = mergeItems(list, list2: validItems)
            feedList?.list = res
        }
        successHandler?()
    }

    private func mergeItems(_ list1: [MinutesSpaceListItem], list2: [MinutesSpaceListItem]) -> [MinutesSpaceListItem] {
        let m = list1.count, n = list2.count
        var i = 0, j = 0
        var list = [MinutesSpaceListItem]()

        func appendListItem(_ item: MinutesSpaceListItem) {
            if list.last?.objectToken == item.objectToken {
                return
            }
            list.append(item)
        }

        while i < m && j < n {
            if list1[i].time > list2[j].time {
                appendListItem(list1[i])
                i += 1
            } else {
                appendListItem(list2[j])
                j += 1
            }
        }
        while i < m {
            appendListItem(list1[i])
            i += 1
        }
        while j < n {
            appendListItem(list2[j])
            j += 1
        }
        return list
    }

    private func postRestoreMinutesNotification(withTokens tokens: [String]) {
        let tokenSet = Set(tokens)
        let items = feedList?.list.filter({ item in
                    return tokenSet.contains(item.objectToken)
                })
                .map({ item -> MinutesSpaceListItem in
                    var newItem = item
                    newItem.time = item.createTime ?? 0
                    return newItem
                }) ?? []
        if !items.isEmpty {
            NotificationCenter.default.post(name: NSNotification.Name.SpaceList.minutesDidRestore, object: nil, userInfo: ["restoredItems": items])
        }
    }

}

// MARK: - last open
extension MinutesSpaceListViewModel {

    func didOpenMinutes(withIndex index: Int) {
        guard (spaceType == .my || spaceType == .share), rankType == .openTime else {
            return
        }
        guard let list = feedList?.list, list.count > index else {
            return
        }
        var tmpList = list
        var openedItem = tmpList.remove(at: index)
        openedItem.time = Int(Date().timeIntervalSince1970) * 1000
        if asc {
            if feedList?.hasMore == false {
                tmpList.append(openedItem)
            }
        } else {
            tmpList.insert(openedItem, at: 0)
        }
        feedList?.list = tmpList
        successHandler?()
    }

}

extension MinutesSpaceListViewModel: Equatable {
    static func ==(lhs: MinutesSpaceListViewModel, rhs: MinutesSpaceListViewModel) -> Bool {
        return lhs.hash == rhs.hash
    }
}

extension MinutesSpaceType {

    var title: String {
        switch self {
        case .home:
            return BundleI18n.Minutes.MMWeb_G_MinutesNameShort
        case .my:
            return BundleI18n.Minutes.MMWeb_G_MyContent
        case .share:
            return BundleI18n.Minutes.MMWeb_G_SharedContent
        case .trash:
            return BundleI18n.Minutes.MMWeb_G_Trash_TabTitle
        }
    }

    var sectionTitle: String {
        switch self {
        case .home:
            return BundleI18n.Minutes.MMWeb_G_Recent
        case .my:
            return BundleI18n.Minutes.MMWeb_M_Home_OwnedByMe_Button
        case .share:
            return BundleI18n.Minutes.MMWeb_M_Home_SharedWithMe_Button
        case .trash:
            return ""
        }
    }

    var removeTitle: String {
        switch self {
        case .home:
            return BundleI18n.Minutes.MMWeb_M_Home_SharedRemoveFromAllList_PopupTitle
        case .share:
            return BundleI18n.Minutes.MMWeb_G_Shared_RemoveFromShared_PopupTitle
        default:
            return ""
        }
    }

    var removeText: String {
        switch self {
        case .home:
            return BundleI18n.Minutes.MMWeb_M_Home_SharedRemoveFromAllList_PopupText
        case .share:
            return BundleI18n.Minutes.MMWeb_G_Shared_RemoveFromShared_PopupText
        default:
            return ""
        }
    }

    var listType: Int {
        switch self {
        case .home:
            return 2
        case .my:
            return 0
        case .share:
            return 1
        case .trash:
            return 3
        }
    }

    var pageName: String {
        switch self {
        case .home:
            return "home_page"
        case .my:
            return "my_content"
        case .share:
            return "shared_with_me"
        case .trash:
            return "trash_box"
        }
    }

    var urlType: String {
        switch self {
        case .home:
            return "home"
        case .my:
            return "me"
        case .share:
            return "shared"
        case .trash:
            return "trash"
        }
    }
}

extension MinutesOwnerType {
    var trackerKey: String {
        switch self {
        case .byAnyone:
            return "owned_by_anyone"
        case .byMe:
            return "owned_by_me"
        case .shareWithMe:
            return "shared_with_me"
        case .recentlyCreate:
            return "recent_create"
        case .recentlyOpen:
            return "recent_open"
        }
    }
}

extension MinutesRankType {
    var trackerKey: String {
        switch self {
        case .createTime:
            return "created"
        case .openTime:
            return "opened"
        case .shareTime:
            return "shared"
        case .expireTime:
            return "opened"
        case .schedulerExecuteTime:
            return "scheduled"
        }
    }

    func subtitle(withTime time: String) -> String {
        switch self {
        case .createTime:
            return BundleI18n.Minutes.MMWeb_G_Created + " " + time
        case .openTime:
            return BundleI18n.Minutes.MMWeb_M_LastOpenedAt_Text(time)
        case .shareTime:
            return BundleI18n.Minutes.MMWeb_G_Shared + " " + time
        case .expireTime:
            return ""
        case .schedulerExecuteTime:
            return ""
        }
    }
}

extension Notification.Name {
    struct SpaceList {
        static let topicDidUpdate = Notification.Name(rawValue: "spaceList.topicDidUpdate")
        static let minutesDidDelete = Notification.Name(rawValue: "spaceList.minutesDidDelete")
        static let minutesDidRestore = Notification.Name(rawValue: "spaceList.minutesDidRestore")
        static let minutesTranscribing = Notification.Name(rawValue: "spaceList.minutesTranscribing")
    }
}
