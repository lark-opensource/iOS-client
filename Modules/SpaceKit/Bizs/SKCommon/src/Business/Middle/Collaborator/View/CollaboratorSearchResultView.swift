//
//  CollaboratorSearchResultView.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/16.
//

import Foundation
import UIKit
import Kingfisher
import SnapKit
import SKResource
import SKUIKit
import UniverseDesignColor

protocol CollaboratorSearchResultViewDelegate: AnyObject {
    func collaboratorSearched(_ view: CollaboratorSearchResultView, didUpdateWithSearchResults searchResults: [Collaborator]?)
    func collaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator)
    func collaboratorRemoved(_ view: CollaboratorSearchResultView, removedItem: Collaborator)
    func blockedCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator)
    func blockedExternalCollaboratorInvited(_ view: CollaboratorSearchResultView, invitedItem: Collaborator)
    func blockedEmailCollaborator(_ message: String)
}

protocol CollaboratorSearchResultScrollViewDelegate: AnyObject {
    func willBeginDragging(_ scrollView: UIScrollView)
}

enum SelectType {
    case none
    case blue
    case gray
    case hasSelected
    case disable
}

struct CollaboratorSearchResultCellItem {
    var collaboratorID: String = ""
    var selectType: SelectType
    var imageURL: String?
    var imageKey: String?
    let title: String
    var detail: String?
    var isExternal: Bool
    var blockExternal: Bool //外部租户用户置灰
    var isCrossTenanet: Bool
    var roleType: CollaboratorType?
    var isExist: Bool = false // 是否存在协作者列表
    var userCount: Int = 1 //群人数
    var canShowMemberCount: Bool = false
    var organizationTagValue: String? //下发的admin自定义关联组织标签
}

public final class CollaboratorSearchResultView: UIView {

    // ViewModel
    let viewModel: CollaboratorSearchTableViewModel
    let adjustSettingsHandler: AdjustSettingsHandler
    weak var searchDelegate: CollaboratorSearchResultViewDelegate?
    weak var scrollDelegate: CollaboratorSearchResultScrollViewDelegate?

    private lazy var tableView: UITableView = {
        let tbView = UITableView()
        tbView.tableHeaderView = UIView()
        tbView.tableFooterView = UIView()
        tbView.showsVerticalScrollIndicator = false
        tbView.showsHorizontalScrollIndicator = false
        tbView.separatorStyle = .none
        tbView.dataSource = self
        tbView.delegate = self
        return tbView
    }()

    private lazy var noFoundMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.docs.pfsc(18)
        label.textColor = UIColor.ud.N500
        label.text = BundleI18n.SKResource.Doc_Share_NothingFound
        label.isHidden = true
        return label
    }()

    private let cellReuseIdentifier = String(describing: CollaboratorSearchResultCell.self)

    init(viewModel: CollaboratorSearchTableViewModel) {
        self.viewModel = viewModel
        self.adjustSettingsHandler = AdjustSettingsHandler(token: viewModel.objToken, type: viewModel.docsType, isSpaceV2: viewModel.spaceSingleContainer, isWiki: viewModel.wikiV2SingleContainer, followAPIDelegate: viewModel.followAPIDelegate)
        super.init(frame: .zero)
        self.viewModel.delegate = self
        self.backgroundColor = UIColor.ud.N00

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

    func search(query: String) {
        viewModel.searchCollaborator(with: query)
    }

    func loadMore(query: String) {
        viewModel.updateSearchRequest(query: query)
    }

    func clear() {
        viewModel.searchResults.removeAll()
    }

    func updateSelectItems(_ items: [Collaborator]) {
        viewModel.selectedItems = items
    }

//    func updateSearchItem(with collaborator: Collaborator) {
//        guard let item = viewModel.searchResults.first(where: { (result) -> Bool in
//            return result.userID == collaborator.userID
//        }) else { return }
//        item.name = collaborator.name
//        viewModel.reloadDatas()
//    }
}

extension CollaboratorSearchResultView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CollaboratorSearchResultCell
        if let tempCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? CollaboratorSearchResultCell) {
            cell = tempCell
        } else {
            cell = CollaboratorSearchResultCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        cell.update(item: viewModel.datas[indexPath.row])
        cell.backgroundColor = UDColor.bgBody
        return cell
    }
}

extension CollaboratorSearchResultView: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row >= 0, indexPath.row < viewModel.searchResults.count else { return }
        let currentItem = viewModel.searchResults[indexPath.row]
        // 当前用户不可添加
        if User.current.info?.userID == currentItem.userID {
            return
        }
        // Owner不可添加
        if currentItem.userID == viewModel.ownerId {
            return
        }
        
        // 对外分享关闭(非admin关闭)需本地限制下
        if (currentItem.isExternal || currentItem.isCrossTenant) && (viewModel.searchConfig.inviteExternalOption == .none) {
            adjustSettingsHandler.toAdjustSettingsIfEnabled(sceneType: .inviteExternalMember(currentItem.tenantID ?? ""), topVC: self.btd_viewController()) { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .success:
                    self.viewModel.searchConfig.inviteExternalOption = .all
                    self.viewModel.reloadDatas()
                    self.viewModel.selectedItems.append(currentItem)
                    self.searchDelegate?.collaboratorInvited(self, invitedItem: currentItem)
                case .disabled:
                    self.searchDelegate?.blockedExternalCollaboratorInvited(self, invitedItem: currentItem)
                default: break
                }
            }
            return
        }

        if (currentItem.isExternal || currentItem.isCrossTenant) && (viewModel.searchConfig.inviteExternalOption == .userOnly) && currentItem.type != .user {
            searchDelegate?.blockedExternalCollaboratorInvited(self, invitedItem: currentItem)
            return
        }
        
        // 已存在协作者列表不能添加,wiki2.0
        if currentItem.isExist {
            return
        }
        // 存在屏蔽关系的用户不可添加，需要报错前置
        if currentItem.blockStatus != .none {
            searchDelegate?.blockedCollaboratorInvited(self, invitedItem: currentItem)
            return
        }
        if currentItem.type == .email {
            if !viewModel.canInviteEmailCollaborator {
                searchDelegate?.blockedEmailCollaborator(BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_ManagePermOnly_Toast)
                return
            }
            if !viewModel.adminCanInviteEmailCollaborator {
                searchDelegate?.blockedEmailCollaborator(BundleI18n.SKResource.Doc_Share_AdministratorCloseShare)
                return
            }
            // 邀请的邮箱协作者数量一次不能超过10个
            if viewModel.emailCollaboratorCount == 10 {
                searchDelegate?.blockedEmailCollaborator(BundleI18n.SKResource.LarkCCM_Docs_InviteEmail_LimitPerInvite_Toast(10))
                return
            }
        }
        
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
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row >= 0, indexPath.row < viewModel.searchResults.count else { return 0 }
        let currentItem = viewModel.searchResults[indexPath.row]
        if currentItem.type == .email {
            return 86
        } else {
            return 66
        }
    }
}

extension CollaboratorSearchResultView: CollaboratorSearchTableViewModelDelegate {

    func collaboratorSearched(_ viewModel: CollaboratorSearchTableViewModel, didUpdateWithSearchResults searchResults: [Collaborator]?, error: Error?) {
        tableView.reloadData()
        noFoundMessageLabel.isHidden = viewModel.datas.count > 0
        searchDelegate?.collaboratorSearched(self, didUpdateWithSearchResults: searchResults)
    }

    func collaboratorInvited(_ viewModel: CollaboratorSearchTableViewModel, didUpdateWithSelectedItems selectedItems: [Collaborator]) {
        tableView.reloadData()
    }
}

extension CollaboratorSearchResultView: UIScrollViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrollDelegate?.willBeginDragging(scrollView)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.tableView.contentOffset.y > 0 else { return }
        guard self.tableView.contentOffset.y + self.tableView.bounds.size.height > self.tableView.contentSize.height + 10 else { return }
        guard let query = self.viewModel.query, query.isEmpty == false else { return }
        self.loadMore(query: query)
    }
}
