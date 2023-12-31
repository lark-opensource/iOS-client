//
//  MinutesAddParticipantSearchResultView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import UniverseDesignToast
import LarkContainer
import LarkSetting
import MinutesNetwork

protocol MinutesAddParticipantSearchResultViewDelegate: AnyObject {
    func collaboratorSearched(_ view: MinutesAddParticipantSearchResultView, didUpdateWithSearchResults searchResults: [Participant]?)
    func collaboratorInvited(_ view: MinutesAddParticipantSearchResultView, invitedItem: Participant)
    func collaboratorRemoved(_ view: MinutesAddParticipantSearchResultView, removedItem: Participant)
    func blockedCollaboratorInvited(_ view: MinutesAddParticipantSearchResultView, invitedItem: Participant)
}

public final class MinutesAddParticipantSearchResultView: UIView, UserResolverWrapper {
    public let userResolver: UserResolver
    @ScopedProvider var featureGatingService: FeatureGatingService?
    
    private var isNewExternalTagEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .archUserOrganizationName) == true
    }
    
    let viewModel: MinutesAddParticipantSearchResultViewModel
    weak var searchDelegate: MinutesAddParticipantSearchResultViewDelegate?

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.rowHeight = 80
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 104, bottom: 0, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    private lazy var noFoundMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.Minutes.MMWeb_G_NoResultsFound
        label.isHidden = true
        return label
    }()

    private let cellReuseIdentifier = String(describing: MinutesAddParticipantSearchCell.self)

    init(resolver: UserResolver, viewModel: MinutesAddParticipantSearchResultViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.viewModel.delegate = self

        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addSubview(noFoundMessageLabel)
        noFoundMessageLabel.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func shouldSelect(userId: String) {
        viewModel.shouldSelected = userId
    }

    func search(query: String) {
        viewModel.searchCollaborator(with: query)
    }

    func clear() {
        viewModel.searchResults.removeAll()
    }

    func updateSelectItems(_ items: [Participant]) {
        viewModel.selectedItems = items
    }

    func reload() {
        tableView.reloadData()
    }
}

extension MinutesAddParticipantSearchResultView: MinutesAddParticipantSearchCellDelegate {
    func checkboxClicked(item: MinutesAddParticipantCellItem?, isSelected: Bool) {
        if let currentItem = item {
            if let index = viewModel.selectedItems.firstIndex(where: { $0.userID == currentItem.userId }) {
                // 已经选择的，则删除
                let deletedItem = viewModel.selectedItems[index]
                viewModel.selectedItems.remove(at: index)
                searchDelegate?.collaboratorRemoved(self, removedItem: deletedItem)
            } else {
                if let selectedItem = viewModel.searchResults.first(where: { $0.userID == currentItem.userId }) {
                    viewModel.selectedItems.append(selectedItem)
                    searchDelegate?.collaboratorInvited(self, invitedItem: selectedItem)
                }
            }
        }
    }
}

extension MinutesAddParticipantSearchResultView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MinutesAddParticipantSearchCell
        if let tempCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? MinutesAddParticipantSearchCell) {
            cell = tempCell
        } else {
            cell = MinutesAddParticipantSearchCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
            cell.delegate = self
        }
        cell.update(item: viewModel.datas[indexPath.row], isNewExternalTagEnabled: isNewExternalTagEnabled)
        return cell
    }
}

extension MinutesAddParticipantSearchResultView: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row >= 0, indexPath.row < viewModel.datas.count, indexPath.row < viewModel.searchResults.count else { return }
        let currentData = viewModel.datas[indexPath.row]
        if currentData.selectType == .disable {
            return
        }

        let currentItem = viewModel.searchResults[indexPath.row]
        if let index = viewModel.selectedItems.firstIndex(where: { $0 == currentItem }) {
            // 已经选择的，则删除
            let deletedItem = viewModel.selectedItems[index]
            viewModel.selectedItems.remove(at: index)
            searchDelegate?.collaboratorRemoved(self, removedItem: deletedItem)
        } else {
            viewModel.selectedItems.append(currentItem)
            searchDelegate?.collaboratorInvited(self, invitedItem: currentItem)
        }
    }
}

extension MinutesAddParticipantSearchResultView: MinutesAddParticipantSearchResultViewModelDelegate {

    func collaboratorSearched(_ viewModel: MinutesAddParticipantSearchResultViewModel, didUpdateWithSearchResults searchResults: [Participant]?, error: Error?) {
        tableView.reloadData()
        if viewModel.datas.isEmpty {
            noFoundMessageLabel.isHidden = false
        } else {
            noFoundMessageLabel.isHidden = true
        }
        searchDelegate?.collaboratorSearched(self, didUpdateWithSearchResults: searchResults)
    }

    func collaboratorInvited(_ viewModel: MinutesAddParticipantSearchResultViewModel, didUpdateWithSelectedItems selectedItems: [Participant]) {
        self.tableView.reloadData()
    }

    func collaboratorInvited(_ viewModel: MinutesAddParticipantSearchResultViewModel, didUpdateWithSelectedItem selectedItem: Participant) {
        viewModel.selectedItems.append(selectedItem)
        searchDelegate?.collaboratorInvited(self, invitedItem: selectedItem)
    }
}
