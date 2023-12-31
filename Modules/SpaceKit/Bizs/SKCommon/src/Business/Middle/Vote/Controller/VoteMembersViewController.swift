//
//  VoteMembersViewController.swift
//  SKCommon
//
//  Created by zhysan on 2022/9/13.
//

import UIKit
import SnapKit
import SKResource
import RxCocoa
import RxSwift
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignEmpty
import SKUIKit

public final class VoteMembersViewController: BaseViewController {
    
    // MARK: - private vars
    
    private let vm: VoteMembersViewModel
    
    private let toProfileAction: ((DocVote.VoteMember) -> Void)?
    
    private let tableView: UITableView = {
        let vi = UITableView(frame: .zero, style: .plain)
        vi.register(VoteUserCell.self, forCellReuseIdentifier: VoteUserCell.defaultReuseId)
        vi.backgroundColor = UDColor.bgBody
        vi.separatorStyle = .none
        vi.alwaysBounceVertical = true
        return vi
    }()
    
    private let emptyView: UDEmptyView = {
        let config = UDEmptyConfig(type: .noData)
        return UDEmptyView(config: config)
    }()
    
    // MARK: - lifecycle
    
    public init(optionContext: DocVote.OptionContext, toProfileAction: ((DocVote.VoteMember) -> Void)?) {
        self.vm = VoteMembersViewModel(optionContext: optionContext)
        self.toProfileAction = toProfileAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        subviewsInit()
        dataBind()
        dataInit()
    }
    
    // MARK: - private
    
    private func updateUI(error: VoteMemberError?, isLoadMore: Bool) {
        if let error = error {
            switch error {
            case .request, .decode, .inner:
                UDToast.showFailure(
                    with: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry,
                    on: self.view.window ?? self.view
                )
                if !isLoadMore {
                    tableView.isHidden = true
                    emptyView.isHidden = false
                    emptyView.update(config: UDEmptyConfig(description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry), type: .loadingFailure))
                }
            case .noMore:
                tableView.isHidden = false
                emptyView.isHidden = true
                tableView.es.noticeNoMoreData()
            }
            return
        }
        if let count = vm.voteTotalCount {
            title = BundleI18n.SKResource.LarkCCM_Docx_Poll_VoteDetails_Header(count)
        } else {
            title = ""
        }
        if vm.members.isEmpty {
            tableView.isHidden = true
            emptyView.isHidden = false
            emptyView.update(config: UDEmptyConfig(type: .noData))
        } else {
            tableView.isHidden = false
            emptyView.isHidden = true
        }
        tableView.reloadData()
    }
    
    private func dataInit() {
        showLoading(duration: 0, isBehindNavBar: true)
        vm.updateVoteMembers { error in
            self.hideLoading()
            self.updateUI(error: error, isLoadMore: false)
        }
    }
    
    private func dataBind() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.vm.updateVoteMembers() { error in
                self.tableView.es.stopLoadingMore()
                self.updateUI(error: error, isLoadMore: true)
            }
        }
    }
    
    private func subviewsInit() {
        if let count = vm.voteTotalCount {
            title = BundleI18n.SKResource.LarkCCM_Docx_Poll_VoteDetails_Header(count)
        }
        
        view.backgroundColor = UDColor.bgBody
        view.insertSubview(tableView, belowSubview: navigationBar)
        view.insertSubview(emptyView, belowSubview: tableView)
        
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension VoteMembersViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vm.members.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VoteUserCell.defaultReuseId, for: indexPath)
        if let vCell = cell as? VoteUserCell {
            vCell.update(vm.members[indexPath.row])
            vCell.showSpLine(indexPath.row != 0)
            vCell.avatarAction = { [weak self] user in
                self?.toProfileAction?(user)
            }
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }
}
