//
//  ParticipantSearchViewModel.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/11/21.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker

final class ParticipantSearchViewModel: InMeetDataListener, InMeetParticipantListener {

    enum LeftNavItem {
        case icon
        case button
    }

    enum FromSource {
        case changeOrder
        case interpreter
    }

    enum TapParticipantType {
        case inMeet(Participant)
        case idle(ByteviewUser)
    }

    struct SearchResult {
        let type: TapParticipantType
        let name: String?
        let avatarInfo: AvatarInfo?
        let searchVC: UIViewController
    }

    typealias SelectClosure = (SearchResult) -> Void

    let meeting: InMeetMeeting
    let title: String
    var startInfo: VideoChatInfo { meeting.info }

    var preInterpreters: [SetInterpreter] = [] {
        didSet {
            self.updateSectionModels()
        }
    }

    var selectedClosure: SelectClosure?

    let fromSource: FromSource

    var httpClient: HttpClient { meeting.httpClient }

    var leftNavItem: LeftNavItem {
        switch fromSource {
        case .interpreter: return .button
        default: return .icon
        }
    }

    var onlySearchInMeet: Bool {
        switch fromSource {
        case .changeOrder: return true
        default: return false
        }
    }

    init(meeting: InMeetMeeting,
         title: String,
         fromSource: FromSource) {
        self.meeting = meeting
        self.title = title
        self.fromSource = fromSource
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
    }

    // MARK: - Others
    let disposeBag = DisposeBag()

    // MARK: - Search
    lazy var paginatedList = MatchPaginatedList<ParticipantSearchBox>(generateSearchAction())
    private func generateSearchAction() -> Action<(String?, Range<Int>), ([ParticipantSearchBox], Bool)> {
        return Action<(String?, Range<Int>), ([ParticipantSearchBox], Bool)>(
            workFactory: { [weak self] string, _ -> Observable<([ParticipantSearchBox], Bool)> in
                guard let text = string, let self = self else {
                    return .just(([ParticipantSearchBox](), false))
                }
                self.trackToggleSearch()
                // 会前设置的传译员未入会，支持搜索
                let preInterprerIds = self.preInterpreters.map { $0.user.id }

                let httpClient = self.httpClient
                let canShowExternal = self.meeting.accountInfo.canShowExternal
                let request = SearchParticipantRequest(meetingId: self.meeting.meetingId, breakoutRoomId: self.meeting.setting.breakoutRoomId,
                                                       query: text, count: 50, queryType: .queryAll)
                // 获取搜索结果
                let results = RxTransform.single {
                    httpClient.getResponse(request, context: request, completion: $0)
                }.map { (resp: SearchParticipantResponse) in
                    SearchCallBack(hasMore: false, searchResults: resp.users.compactMap { $0.toVideoSearchResult(canShowExternal: canShowExternal) })
                }.asObservable().map { callBack -> ([ParticipantSearchBox], Bool) in
                    var items = callBack.searchResults.compactMap({ (result: VideoSearchResult) -> ParticipantSearchBox? in
                        switch result.searchMeta {
                        case let .chatter(user):
                            return ParticipantSearchUserBox(user, highlightPattern: text)
                        case let .room(room):
                            return ParticipantSearchRoomBox(room, highlightPattern: text)
                        default: return nil
                        }
                    })
                    if self.onlySearchInMeet {
                        items = items.filter { (result: ParticipantSearchBox) -> Bool  in
                            if let user = result.participant?.user,
                               self.meeting.participant.contains(user: user, in: .activePanels) {
                                return true
                            }
                            return false
                        }
                    }
                    if items.isEmpty {
                        self.trackNoResult()
                    }
                    return (items, callBack.hasMore)
                }.share()

                let rule: [ParticipantState] = [.joined]
                let userInfos = results.flatMapLatest { [weak self] (searchBoxes: [ParticipantSearchBox], _) -> Observable<[ParticipantUserInfo]> in
                    guard let self = self else { return .just([]) }
                    var participants: [Participant] = []
                    searchBoxes.filter { rule.contains($0.state) }.forEach { (searchBox: ParticipantSearchBox) in
                        guard let user = searchBox.participant?.user,
                              self.meeting.participant.contains(user: user, in: .activePanels, status: .all) else {
                            return
                        }
                        if let participant = searchBox.participant {
                            participants.append(participant)
                        }
                    }
                    if participants.isEmpty {
                        return .just([])
                    }
                    return Observable<[ParticipantUserInfo]>.create { [weak self] (ob) -> Disposable in
                        if let self = self {
                            httpClient.participantService.participantInfo(pids: participants, meetingId: self.meeting.meetingId) { aps in
                                ob.onNext(aps)
                                ob.onCompleted()
                            }
                        } else {
                            ob.onCompleted()
                        }
                        return Disposables.create()
                    }
                }

                // 将原始搜索结果与userInfos匹配填充，得到最终的完整搜索结果
                return Observable.combineLatest(results, userInfos)
                    .map { (searchBoxes, aps) -> ([ParticipantSearchBox], Bool) in
                        // 将userInfos根据identifier存储为字典
                        var userInfosDic: [String: ParticipantUserInfo] = [:]
                        aps.filter { $0.pid != nil }.forEach { userInfosDic[$0.pid!.identifier] = $0 }
                        // userInfos与原始搜索结果进行匹配
                        let filterResult = searchBoxes.0.filter { rule.contains($0.state) || preInterprerIds.contains($0.id)  }
                        filterResult.forEach {
                            if let p = $0.participant {
                                $0.userInfo = userInfosDic[p.identifier]
                            }
                        }
                        return (filterResult, searchBoxes.1)
                    }
            })
    }

    // MARK: - Participant
    private(set) lazy var sectionModels: Observable<[ParticipantSearchSectionModel]> = sectionModelsRelay.asObservable()
    // 多设备参会人
    var duplicatedParticipantIds: Set<String> = []

    let sectionModelsRelay = BehaviorRelay<[ParticipantSearchSectionModel]>(value: [])
    private func updateSectionModels() {
        let candidates = meeting.participant.activePanel.nonRingingDict.map(\.value)
        let ids: [String] = candidates.map { $0.user.id }
        duplicatedParticipantIds = Set(Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.map { $0.key })
        let participantService = httpClient.participantService
        participantService.participantInfo(pids: candidates, meetingId: meeting.meetingId, completion: { [weak self] aps in
            guard let self = self else { return }
            let roleStrategy = self.meeting.data.roleStrategy
            let hasCohostAuthority = self.meeting.setting.hasCohostAuthority
            let hostEnabled = self.meeting.setting.isHostEnabled
            var inMeetItems: [InMeetParticipantCellModel] = []
            for (p, ap) in zip(candidates, aps) {
                var participant = p
                let role = participant.role
                participant.isHost = participant.isHost && !participant.isLarkGuest &&
                roleStrategy.participantCanBecomeHost(role: role)
                let item = self.createInMeetParticipantCellModel(participant, userInfo: ap, hasCohostAuthority: hasCohostAuthority, hostEnabled: hostEnabled)
                inMeetItems.append(item)
            }
            // rust在拆分participants时去除了排序逻辑，端上自行排序
            inMeetItems = ParticipantsSortTool.partitionAndSort(inMeetItems, currentUser: self.meeting.account)
            if self.preInterpreters.isEmpty {
                let sectionModel: [ParticipantSearchSectionModel] = [ParticipantSearchSectionModel(items: inMeetItems)]
                if self.sectionModelsRelay.value != sectionModel {
                    self.sectionModelsRelay.accept(sectionModel)
                }
            } else {
                // 可以被选择的未入会候选人
                let preCandidates = self.preInterpreters.filter { !ids.contains($0.user.id) }
                // 拉取未入会传译员信息
                self.httpClient.getResponse(GetChattersRequest(chatterIds: preCandidates.map { $0.user.id })) { [weak self] r in
                    guard let self = self else { return }
                    if let users = r.value?.chatters {
                        var idleItems: [InterpreterIdleParticipantCellModel] = []
                        for (pre, user) in zip(preCandidates, users) {
                            let item = self.createIdleInterpreterCellModel(pre, user: user)
                            idleItems.append(item)
                        }
                        let items: [BaseParticipantCellModel] = idleItems + inMeetItems
                        let sectionModel: [ParticipantSearchSectionModel] = [ParticipantSearchSectionModel(items: items)]
                        if self.sectionModelsRelay.value != sectionModel {
                            self.sectionModelsRelay.accept(sectionModel)
                        }
                    }
                }
            }
        })
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        updateSectionModels()
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        updateSectionModels()
    }

    func createSearchCellModel(_ searchBox: ParticipantSearchBox, hasCohostAuthority: Bool, hostEnabled: Bool, meetingSubType: MeetingSubType) -> SearchParticipantCellModel {
        let model = SearchParticipantCellModel.create(with: searchBox,
                                                      meeting: meeting,
                                                      hasCohostAuthority: hasCohostAuthority,
                                                      hostEnabled: hostEnabled,
                                                      meetingSubType: meetingSubType,
                                                      duplicatedParticipantIds: duplicatedParticipantIds,
                                                      from: .commonSearch)
        return model
    }

    func createInMeetParticipantCellModel(_ participant: Participant, userInfo: ParticipantUserInfo, hasCohostAuthority: Bool, hostEnabled: Bool) -> InMeetParticipantCellModel {
        InMeetParticipantCellModel.create(with: participant,
                                          userInfo: userInfo,
                                          meeting: meeting,
                                          hasCohostAuthority: hasCohostAuthority,
                                          hostEnabled: hostEnabled,
                                          isDuplicated: duplicatedParticipantIds.contains(participant.user.id),
                                          magicShareDocument: nil,
                                          forceMicState: .hidden,
                                          forceCameraImg: ParticipantImgKey.empty)
    }

    func createIdleInterpreterCellModel(_ preInterpreter: SetInterpreter, user: User) -> InterpreterIdleParticipantCellModel {
        let model = InterpreterIdleParticipantCellModel.create(with: preInterpreter, user: user, meeting: meeting)
        return model
    }
}

extension ParticipantSearchViewModel {

    func trackShowPanel() {
        if fromSource == .changeOrder {
            VCTracker.post(name: .vc_meeting_popup_view, params: ["content": "change_video_order_toolbar"])
        }
    }

    func trackNoResult() {
        if fromSource == .changeOrder {
            VCTracker.post(name: .vc_meeting_popup_view, params: ["content": "change_video_order_search_noresult"])
        }
    }

    func trackToggleSearch() {
        if fromSource == .changeOrder {
            VCTracker.post(name: .vc_meeting_popup_click, params: ["click": "change_video_order_search",
                                                                   "content": "change_video_order_toolbar"])
        }
    }
}
