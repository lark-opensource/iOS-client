//
//  BTChatterPanelViewModel.swift
//  SKBrowser
//
//  Created by X-MAN on 2023/1/12.
//


import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import SpaceInterface
import LarkRustClient
import RustPB
import LarkContainer
import SwiftyJSON

public final class BTChatterPanelViewModel {
    
    @InjectedSafeLazy var service: RustService
    
    public enum OpenSource: Equatable {
        case record(chatterType: BTChatterType) // 卡片
        case form // 表单
        case indRecord // 分享记录
        case sheetReminder // sheet reminder 场景
    }
    
    public enum NotifyMode: Equatable {
        // 能够展示面板
        case enabled(notifies: Bool) // 入口启用，关联属性为 checkbox 的 bool 值（卡片 场景）
        case disabled // 入口禁用（表单 场景）
        // 不能够展示面板
        case hidden // 入口隐藏（sheet reminder 场景）
        
        public var notifiesEnabled: Bool {
            switch self {
            case .enabled(notifies: true):
                return true
            case .enabled(notifies: false):
                return false
            default:
                return false
            }
        }
    }

    private let disposeBag = DisposeBag()
    private(set) var searchText = BehaviorRelay<String>(value: "")
    private(set) var recommendData = BehaviorRelay<[RecommendData]>(value: [])
    // 为了区分数据是用户操作还是协同，分了两个数据源
    // 用户操作和协同都会走 `selectedData` 的逻辑
    // 而协同不会走 `updatedData` 逻辑，避免重复回调给前端
    private(set) var selectedData = BehaviorRelay<[BTCapsuleModel]>(value: [])
    private(set) var updatedData = BehaviorRelay<([BTCapsuleModel], BTCapsuleModel?)>(value: ([], nil))
    private var chatId: String?
    public var isMultipleMembers: Bool = false // 是否多选
    public var openSource: OpenSource
    public var lastSelectNotifies: Bool
    private(set) var chatterType: BTChatterType
    
    private var _notifyMode: BTChatterPanelViewModel.NotifyMode?
    public var notifyMode: BTChatterPanelViewModel.NotifyMode {
        get {
            if let curValue = _notifyMode {
                return curValue
            }
            var initializeValue: BTChatterPanelViewModel.NotifyMode
            switch openSource {
            case let .record(memberType):
                switch memberType {
                case .group:
                    initializeValue = .hidden
                default:
                    initializeValue = .enabled(notifies: self.lastSelectNotifies)
                }
            case .form:
                initializeValue = .disabled
            case .indRecord:
                initializeValue = .hidden
            case .sheetReminder:
                initializeValue = .hidden
            }
            _notifyMode = initializeValue
            return initializeValue
        }
        set {
            _notifyMode = newValue
        }
    }
    // 方便索引
    private var selectedMemberIds: [String] = []
    private var selectedInfo: [BTCapsuleModel] = []

    private var hostToken: String {
        if self.hostDocsInfo == nil { spaceAssertionFailure("Docs Info Shoud not be nil") }
        return self.hostDocsInfo?.objToken ?? ""
    }
    private var hostType: DocsType {
        if self.hostDocsInfo == nil { spaceAssertionFailure("Docs Info Shoud not be nil") }
        return self.hostDocsInfo?.type ?? .sheet
    }
    var hostFileTitle: String? {
        return self.hostDocsInfo?.title
    }
    private let hostDocsInfo: DocsInfo?
    lazy var hostAtDataSource: AtDataSource = {
        let config = AtDataSource.Config(chatID: self.chatId,
                                         sourceFileType: self.hostType,
                                         location: .comment,
                                         token: self.hostToken )
        return AtDataSource(config: config)
    }()

    public init(_ hostDocsInfo: DocsInfo?,
                chatId: String?,
                openSource: OpenSource,
                lastSelectNotifies: Bool,
                chatterType: BTChatterType) {
        self.hostDocsInfo = hostDocsInfo
        self.chatId = chatId
        self.openSource = openSource
        self.lastSelectNotifies = lastSelectNotifies
        self.chatterType = chatterType
        _bind()
    }

    // 点击搜索结果时，使用这个方法修改数据
    func changeSelectStatus(at index: Int, token: String?) {
        if recommendData.value.count <= index {
            _handleSingleMemberIfNeed()
            selectedInfo.removeAll { return $0.id == token }
            selectedMemberIds.removeAll { return $0 == token }
            selectedData.accept(selectedInfo)
            updatedData.accept((selectedInfo, nil))
        } else {
            _changeSelectStatus(at: index)
        }
    }

    private func _changeSelectStatus(at recommandIndex: Int) {
        _handleSingleMemberIfNeed()
        let recommend = recommendData.value[recommandIndex]
        recommend.selectType.changedSelectStatus()
        if recommend.selectType == .blue {
            selectedInfo.append(convertRecommendData(recommend))
            selectedMemberIds.append(recommend.token)
        } else {
            selectedInfo.removeAll { return recommend.token == $0.userID }
            selectedMemberIds.removeAll { return $0 == recommend.token }
        }
        selectedData.accept(selectedInfo)
        let added = recommend.selectType == .blue ? convertRecommendData(recommend) : nil
        updatedData.accept((selectedInfo, added))
        recommendData.accept(recommendData.value)
    }

    private func _handleSingleMemberIfNeed() {
        guard !isMultipleMembers else { return }
        selectedInfo.removeAll()
        selectedMemberIds.removeAll()
    }

    // 点击人员胶囊时，使用这个方法修改数据
    func deselect(at selectedIndex: Int) {
        guard selectedInfo.count > selectedIndex else { return }
        let info = selectedInfo[selectedIndex]
        var needUpdate = false
        let newData = recommendData.value.map { (data) -> RecommendData in
            if data.token == info.userID {
                data.selectType = .gray
                needUpdate = true
            }
            return data
        }
        selectedInfo.remove(at: selectedIndex)
        selectedMemberIds.removeAll { return $0 == info.userID }
        selectedData.accept(selectedInfo)
        updatedData.accept((selectedInfo, nil))
        if needUpdate {
            recommendData.accept(newData)
        }
    }

    // 外部数据源更新了数据，执行全量覆盖
    func updateSelected(_ models: [BTCapsuleModel]) {
        selectedInfo = models
        selectedMemberIds = models.map { return $0.userID }
        selectedData.accept(models)
        // 需要重新过滤一遍数据
        _filterRecommendDatas(recommendData.value)
    }

    private func _bind() {
        searchText.subscribe(onNext: { [weak self] (text) in
            self?._search(text)
        }).disposed(by: disposeBag)
    }
    // 把搜索结果中，状态为选中的更改一下
    private func _filterRecommendDatas(_ list: [RecommendData]) {
        let recommend = list.map { [weak self] data -> RecommendData in
            if self?.selectedMemberIds.contains(data.token) ?? false {
                data.selectType = .blue
            } else {
                data.selectType = .gray
            }
            return data
        }.filter({ return chatterType == .group ? $0.hasJoinChat : true})
        recommendData.accept(recommend)
    }
}

extension BTChatterPanelViewModel {
    
    private func convertRecommendData(_ recommend: RecommendData) -> BTCapsuleModel {
        var showingText: String = recommend.userCnName ?? recommend.content ?? ""
        if DocsSDK.currentLanguage == .en_US,
            let enName = recommend.userEnName,
            !enName.isEmpty {
            showingText = enName
        }
        var model = BTCapsuleModel(id: recommend.token,
                              text: showingText,
                              color: BTColorModel(),
                              isSelected: true,
                              avatarUrl: recommend.url ?? "",
                              userID: recommend.token,
                              name: (recommend.name ?? recommend.userCnName) ?? "",
                              enName: recommend.userEnName ?? "",
                              displayName: recommend.displayName,
                              chatterType: self.chatterType)
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel {
            model.avatarKey = recommend.avatarKey
        }
        return model
    }
    
    private func _search(_ keyword: String) {
        var filter: Set<AtDataSource.RequestType> = AtDataSource.RequestType.userTypeSet
        switch self.chatterType {
        case .user:
            filter = AtDataSource.RequestType.userTypeSet
        case .group:
            filter = AtDataSource.RequestType.groupTypeSet
        }
        if UserScopeNoChangeFG.WJS.bitableFieldGroupNewEditPanel, keyword.isEmpty, chatterType == .group {
            searchRecentVisitGroup()
            return
        }
        hostAtDataSource.getData(with: keyword, filter: filter.joinedType) { [weak self] (data, error) in
            guard error == nil, let self = self else { return }
            self._filterRecommendDatas(data)
        }
    }
    
    func searchRecentVisitGroup() {
        
        var request = RustPB.Feed_V1_GetRecentVisitTargetsRequest()
        
        var includeConfigs = [Feed_V1_GetRecentVisitTargetsRequest.IncludeItem]()
        var includeItem = Feed_V1_GetRecentVisitTargetsRequest.IncludeItem()
        includeItem.config = .groupChatConfigs(includeItem.groupChatConfigs)
        includeConfigs.append(includeItem)
        
        request.includeItems = includeConfigs
        
        service.async(RequestPacket(message: request)) { [weak self] (responsePacket: ResponsePacket<RustPB.Feed_V1_GetRecentVisitTargetsResponse>) -> Void in
            do {
                let value = try responsePacket
                    .result
                    .get()
                    .previews
                let result = value.map { preview in
                    return RecommendData(
                        withToken: preview.feedID,
                        keyword: "",
                        type: .group,
                        infos: JSON([
                            "name": preview.chatData.name,
                            "desc": preview.chatData.chatDescription,
                            "has_join_chat": true,
                            "rust_avatar_key": preview.chatData.avatarKey
                        ])
                    )
                }
                DispatchQueue.main.async {
                    self?._filterRecommendDatas(result)
                }
            } catch {
                DocsLogger.error("Feed_V1_GetRecentVisitTargetsRequest error", error: error)
            }
        }
    }
}

