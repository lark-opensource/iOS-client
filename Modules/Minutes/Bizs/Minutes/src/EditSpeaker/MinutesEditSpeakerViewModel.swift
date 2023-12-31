//
//  MinutesEditSpeakerViewModel.swift
//  Minutes
//
//  Created by chenlehui on 2021/6/18.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import AppReciableSDK

class MinutesEditSpeakerViewModel {
    // disable-lint: magic number
    enum CellType {
        case new(Participant)
        case normal(Participant)

        var height: CGFloat {
            switch self {
            case .new:
                return 52
            case .normal:
                return 66
            }
        }

        var rawValue: Participant {
            switch self {
            case .new(let speaker):
                return speaker
            case .normal(let speaker):
                return speaker
            }
        }
    }
    // enable-lint: magic number

    let session: MinutesEditSession

    var cellItems: [[CellType]] {
        return isSearching ? searchItems : suggestionItems
    }

    let participantRequestUUID: String = UUID().uuidString

    var isSearching: Bool = false

    var paragraphId: String
    var userType: UserType

    private var lastQuery: String = ""

    private var suggestionItems: [[CellType]] = []
    private var searchItems: [[CellType]] = []
    private var currentSpeaker: Participant?
    private var searchResult: [Participant] = []

    init(session: MinutesEditSession, paragraphId: String, userType: UserType) {
        self.session = session
        self.paragraphId = paragraphId
        self.userType = userType
    }

    func cellItem(from indexPath: IndexPath) -> CellType? {
        if cellItems.indices.contains(indexPath.section) {
            let items = cellItems[indexPath.section]
            let item = items[indexPath.row]
            return item
        }
        return nil
    }

    public func fetchUserChoiceStatus(completion: @escaping ((Int) -> Void)) {
        session.fetchUserChoiceStatus(userType: self.userType.rawValue) { [weak self] (result) in
            switch result {
            case .success(let batched):
                DispatchQueue.main.async {
                    completion(batched.batchUpdateStatus ?? 0)
                }
            case .failure(let error):
                break
            }
        }
    }

    func fetchSpeakerSuggestion(completion: @escaping (Result<SpeakerSuggestion, Error>) -> Void) {
        session.fetchSpeakerSuggestion(paragraphId: paragraphId) { [weak self] (result) in
            switch result {
            case .success(let suggestion):
                self?.processSuggestionSpeakers(suggestion.list ?? [])
                DispatchQueue.main.async {
                    completion(result)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }

    func searchParticipants(with query: String, completion: @escaping (String?, ParticipantsSearch?, Error?) -> Void) {
        isSearching = !query.isEmpty
        if lastQuery == query { return }
        lastQuery = query
        processSearchSpeakers(searchResult, query: query)
        if query.isEmpty {
            searchResult = []
            return
        }
        session.searchParticipants(with: query, uuid: participantRequestUUID) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let parti):
                    self?.searchResult = parti.list ?? []
                    completion(query, parti, nil)
                case .failure(let error):
                    completion(query, nil, error)
                }
            }
        }
    }

    func updateSpeaker(catchError: Bool, _ speaker: Participant, _ batch: Bool, completion: @escaping (Participant?, String?, Bool) -> Void) {
        if let cs = currentSpeaker, cs.isSame(to: speaker) {
            completion(nil, nil, true)
            return
        }

        NotificationCenter.default.post(name: NSNotification.Name.EditSpeaker.updateSpeakerBegin, object: nil)
        let token = session.minutes.objectToken
        session.updateSpeaker(catchError: catchError, withParagraphId: paragraphId, userType: speaker.userType.rawValue, userId: speaker.userID, userName: speaker.userName, batch: batch) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    var toast: String?
                    if let count = model.user?.paragraphIds?.count, count > 1 {
                        toast = BundleI18n.Minutes.MMWeb_G_EditMoreSpeakers_Toast(count)
                    }

                    if model.clusterAllUpdated == 1 {
                        toast = BundleI18n.Minutes.MMWeb_G_YayMatchedAll_Toast
                    }

                    if let type = model.error?.denyType {
                        if type == "1" {
                            toast = BundleI18n.Minutes.MMWeb_G_EditOnOtherDeviceQuitEdit_Toast
                        }
                        if type == "2" {
                            toast = BundleI18n.Minutes.MMWeb_G_NoActionForLongQuitEdit_Toast
                        }
                    }
                    completion(model.user, toast, true)
                    if model.user == nil {
                        NotificationCenter.default.post(name: NSNotification.Name.EditSpeaker.updateSpeakerFailed, object: nil)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name.EditSpeaker.updateSpeakerSuccess, object: nil)
                    }
                    if model.error != nil {
                        NotificationCenter.default.post(name: NSNotification.Name.EditSpeaker.quitEditSpeaker, object: nil)
                    }
                case .failure(let error):
                    completion(nil, BundleI18n.Minutes.MMWeb_G_SaveFailedCheckConnection, false)
                    NotificationCenter.default.post(name: NSNotification.Name.EditSpeaker.updateSpeakerFailed, object: nil)
                    let extra = Extra(isNeedNet: true, category: ["object_token": token])
                    MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                        event: .minutes_edit_detail_error,
                                                        userAction: "editSpeaker",
                                                        error: error,
                                                        extra: extra)
                }
            }
        }
    }

    private func processSuggestionSpeakers(_ speakers: [Participant]) {
        var list0: [CellType] = []
        var list1: [CellType] = []
        speakers.forEach { (speaker) in
            if let isParagraphSpeaker = speaker.isParagraphSpeaker, isParagraphSpeaker {
                list0.append(CellType.normal(speaker))
                self.currentSpeaker = speaker
            } else {
                list1.append(CellType.normal(speaker))
            }
        }
        var cells: [[CellType]] = []
        if !list0.isEmpty {
            cells.append(list0)
        }
        if !list1.isEmpty {
            cells.append(list1)
        }
        suggestionItems = cells
    }

    func suggestionParticipantsNumber() -> Int {
        return suggestionItems.count
    }

    func processSearchSpeakers(_ speakers: [Participant], query: String) {
        var list0: [CellType] = []
        var list1: [CellType] = []
        var list2: [CellType] = []
        if !query.isEmpty {
            let userName = String(query.filter { !" \n\t\r".contains($0) })
            var ns = Participant(userID: "", deviceID: nil, userType: .unknow, userName: userName, avatarURL: URL(fileURLWithPath: ""))
            list0.append(CellType.new(ns))
        }

        speakers.forEach { (speaker) in
            if speaker.isSame(to: currentSpeaker) {
                var sp = speaker
                sp.isParagraphSpeaker = true
                list1.append(CellType.normal(sp))
            } else {
                list2.append(CellType.normal(speaker))
            }
        }

        var cells: [[CellType]] = []
        if !list0.isEmpty {
            cells.append(list0)
        }
        if !list1.isEmpty {
            cells.append(list1)
        }
        if !list2.isEmpty {
            cells.append(list2)
        }
        searchItems = cells
    }
}

extension Notification.Name {

    struct EditSpeaker {
        static let updateSpeakerBegin = Notification.Name("EditSpeaker.updateSpeakerBegin")
        static let updateSpeakerSuccess = Notification.Name("EditSpeaker.updateSpeakerSuccess")
        static let updateSpeakerFailed = Notification.Name("EditSpeaker.updateSpeakerFailed")
        static let quitEditSpeaker = Notification.Name("EditSpeaker.quitEditSpeaker")
    }
}
