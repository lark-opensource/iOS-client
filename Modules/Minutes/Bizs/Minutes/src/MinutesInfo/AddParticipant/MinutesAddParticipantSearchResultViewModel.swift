//
//  MinutesAddParticipantSearchResultViewModel.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork

protocol MinutesAddParticipantSearchResultViewModelDelegate: AnyObject {
    func collaboratorSearched(_ viewModel: MinutesAddParticipantSearchResultViewModel, didUpdateWithSearchResults searchResults: [Participant]?, error: Error?)
    func collaboratorInvited(_ viewModel: MinutesAddParticipantSearchResultViewModel, didUpdateWithSelectedItems selectedItems: [Participant])
    func collaboratorInvited(_ viewModel: MinutesAddParticipantSearchResultViewModel, didUpdateWithSelectedItem selectedItem: Participant)
}

public final class MinutesAddParticipantSearchResultViewModel {

    public var minutes: Minutes

    let participantAddUUID: String

    weak var delegate: MinutesAddParticipantSearchResultViewModelDelegate?

    // 当前搜索的关键字
    var query: String?
    // Model
    var datas = [MinutesAddParticipantCellItem]()
    var searchResults = [Participant]() {
        didSet {
            self.reloadDatas()
        }
    }

    var shouldSelected: String? //should selected userid

    var selectedItems = [Participant]() {
        didSet {
            self.datas = self.mapToCollaboratorCellItem(searchResults)
            self.delegate?.collaboratorInvited(self, didUpdateWithSelectedItems: selectedItems)
        }
    }

    public init(minutes: Minutes,
                selectedItems: [Participant],
                uuid: String) {
        self.minutes = minutes
        self.selectedItems = selectedItems
        self.participantAddUUID = uuid
    }

    // 将后台数据转换为UI数据
    private func mapToCollaboratorCellItem(_ searchResults: [Participant]) -> [MinutesAddParticipantCellItem] {
        return searchResults.map {
            return MinutesAddParticipantCellItem(userId: $0.userID,
                                                 selectType: getSelectType(with: $0, originalCollaborators: minutes.info.participants),
                                                 imageURL: $0.avatarURL,
                                                 imageKey: $0.avatarKey,
                                                 title: $0.userName,
                                                 detail: self.getDetail(with: $0),
                                                 isExternal: $0.isExternal,
                                                 isInParticipants: $0.isInParticipants,
                                                 tenantName: $0.tenantName,
                                                 departmentName: $0.departmentName,
                                                 displayTag: $0.displayTag)
        }
    }

    private func getSelectType(with collaborator: Participant, originalCollaborators: [Participant]) -> ParticipantSelectType {

        let selectType: ParticipantSelectType

        if let index = originalCollaborators.firstIndex(where: { $0.userID == collaborator.userID }) {
            selectType = .disable
        } else if isCollaboratorSelected(collaborator) {
            selectType = .selected
        } else if let shouldSelected = shouldSelected, collaborator.userID == shouldSelected {
            if !selectedItems.contains(where: { item in
                item.userID == collaborator.userID
            }) {
                delegate?.collaboratorInvited(self, didUpdateWithSelectedItem: collaborator)
            }
            selectType = .selected
            self.shouldSelected = nil
        } else {
            selectType = .unselected
        }
        return selectType
    }

    private func isCollaboratorSelected(_ collaborator: Participant) -> Bool {
        for item in selectedItems where item.userID == collaborator.userID {
            return true
        }
        return false
    }

    private func getDetail(with collaborator: Participant) -> String? {
        if collaborator.isExternal == true {
            return collaborator.tenantName
        } else {
            return collaborator.departmentName
        }
    }

    func reloadDatas() {
        self.datas = self.mapToCollaboratorCellItem(searchResults)
        self.delegate?.collaboratorSearched(self, didUpdateWithSearchResults: searchResults, error: nil)
    }

    func searchCollaborator(with query: String, completionHandler: (([Participant]) -> Void)? = nil) {
        self.query = query
        if !query.isEmpty {
            minutes.info.fetchParticipantSearch(text: query, uuid: self.participantAddUUID) {  [weak self] result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        if let items = response.list {
                            self?.searchResults = items
                            completionHandler?(items)
                        } else {
                            self?.searchResults = []
                            completionHandler?([])
                        }
                    }
                case .failure(let error):
                    break
                }
            }
        } else {
            minutes.info.fetchParticipantSuggestion(completionHandler: { [weak self] result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        if let items = response.list {
                            self?.searchResults = items
                            completionHandler?(items)
                        } else {
                            self?.searchResults = []
                            completionHandler?([])
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.searchResults = []
                        completionHandler?([])
                    }
                }
            })
        }
    }
}
