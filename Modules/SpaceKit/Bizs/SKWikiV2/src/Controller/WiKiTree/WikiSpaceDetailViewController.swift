//
//  WikiSpaceDetailViewController.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/19.
//  

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import SKWorkspace

class WikiSpaceDetailViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let spaceDetailCellReuseIdentifier = "wiki.space.info.detail"
    private let memberCellReuseIdentifier = "wiki.space.info.member"
    private let loadingCellReuseIdentifier = "wiki.space.info.placeholder"
    private let errorCellReuseIdentifier = "wiki.space.info.error"

    private lazy var memberTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WikiSpaceDetailTableViewCell.self, forCellReuseIdentifier: spaceDetailCellReuseIdentifier)
        tableView.register(WikiMemberTableViewCell.self, forCellReuseIdentifier: memberCellReuseIdentifier)
        tableView.register(WikiMemberPlaceholderTableViewCell.self, forCellReuseIdentifier: loadingCellReuseIdentifier)
        tableView.register(WikiMemberErrorTableViewCell.self, forCellReuseIdentifier: errorCellReuseIdentifier)
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorStyle = .none
        return tableView
    }()

    private var headerCanExpand = true
    private var headerIsExpanded = false
    private var headerPreferHeight: CGFloat = 0

    private let viewModel: WikiSpaceDetailViewModel
//    private var userRole: WikiUserRole?
    private var members: [WikiMember] = []
    private let disposeBag = DisposeBag()

    private var isLoading = true
    private var showingError = false

    init(viewModel: WikiSpaceDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func setupUI() {
        title = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_Title
        view.backgroundColor = UDColor.bgBase
        view.addSubview(memberTableView)
        memberTableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        memberTableView.backgroundColor = UDColor.bgBody
        let cellWidth: CGFloat
        if view.frame.width != 0 {
            cellWidth = view.frame.width
        } else if modalPresentationStyle == .formSheet {
            cellWidth = 540
        } else {
            cellWidth = 0
        }
        let (canExpand, preferHeight) = WikiSpaceDetailTableViewCell.preferedHeightFor(cellWidth: cellWidth, isExpanded: false, content: viewModel.spaceDescription)
        headerCanExpand = canExpand
        headerPreferHeight = preferHeight
        if self.modalPresentationStyle == .formSheet {
            self.navigationBar.leadingBarButtonItems.append(closeButtonItem)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let (canExpand, preferHeight) = WikiSpaceDetailTableViewCell.preferedHeightFor(cellWidth: view.frame.width, isExpanded: false, content: viewModel.spaceDescription)
        headerCanExpand = canExpand
        headerPreferHeight = preferHeight
        memberTableView.reloadData()
    }

    private func bindViewModel() {
        viewModel.memberTableUpdated
            .drive(onNext: { [weak self] (event) in
                guard let self = self else { return }
                self.isLoading = false
                switch event {
                case let .error(error):
                    DocsLogger.error("Refresh member list failed", error: error)
                    self.showingError = true
                    UIView.performWithoutAnimation {
                        self.memberTableView.reloadSections([2, 3], with: .none)
                    }
                case let .next(members):
                    self.members = members.filter({ $0.memberRole == .admin })
                    UIView.performWithoutAnimation {
                        self.memberTableView.reloadSections([1, 2], with: .none)
                    }
                case .completed:
                    return
                }
            })
            .disposed(by: disposeBag)


        viewModel.spaceDescriptionUpdated
            .drive(onNext: { [weak self] (description) in
                guard let self = self else { return }
                let (canExpand, preferHeight) = WikiSpaceDetailTableViewCell.preferedHeightFor(cellWidth: self.view.frame.width, isExpanded: self.headerIsExpanded, content: description)
                self.headerCanExpand = canExpand
                self.headerPreferHeight = preferHeight
                UIView.performWithoutAnimation {
                    self.memberTableView.reloadSections([0], with: .none)
                }
            })
            .disposed(by: disposeBag)
        viewModel.refresh()
    }

    private func toggleHeaderCell() {
        headerIsExpanded = !headerIsExpanded
        let (canExpand, preferHeight) = WikiSpaceDetailTableViewCell.preferedHeightFor(cellWidth: memberTableView.frame.width, isExpanded: headerIsExpanded, content: viewModel.spaceDescription)
        headerCanExpand = canExpand
        headerPreferHeight = preferHeight
        UIView.performWithoutAnimation {
            memberTableView.reloadSections([0], with: .none)
        }
    }

    private func retry() {
        viewModel.refresh()
        isLoading = true
        showingError = false
        UIView.performWithoutAnimation {
            memberTableView.reloadSections([2, 3], with: .none)
        }
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // HeaderSection
            return 1
        case 1:
            // MemberSection
            return members.count
        case 2:
            // LoadingSection
            return isLoading ? 10 : 0
        case 3:
            // ErrorSection
            return showingError ? 1 : 0
        default:
            // ???
            spaceAssertionFailure("wiki.space.detail --- section out of bounds")
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.section {
        case 0:
            return self.tableView(tableView, detailCellForRowAt: indexPath)
        case 1:
            return self.tableView(tableView, memberCellForRowAt: indexPath)
        case 2:
            return self.tableView(tableView, loadingCellForRowAt: indexPath)
        case 3:
            return self.tableView(tableView, errorCellForRowAt: indexPath)
        default:
            spaceAssertionFailure("wiki.space.detail --- section out of bounds")
            return UITableViewCell()
        }
    }

    private func tableView(_ tableView: UITableView, detailCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: spaceDetailCellReuseIdentifier, for: indexPath)
        guard let detailCell = cell as? WikiSpaceDetailTableViewCell else {
            spaceAssertionFailure("wiki.space.detail --- failed to convert detail cell")
            return cell
        }
        detailCell.update(description: viewModel.spaceDescription, canExpand: headerCanExpand, isExpanded: headerIsExpanded)
        detailCell.expandCallback = { [weak self] in
            guard let self = self else { return }
            self.toggleHeaderCell()
        }
        return cell
    }

    private func tableView(_ tableView: UITableView, memberCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: memberCellReuseIdentifier, for: indexPath)
        guard let memberCell = cell as? WikiMemberTableViewCell else {
            spaceAssertionFailure("wiki.space.detail --- failed to convert member cell")
            return cell
        }
        guard members.count > indexPath.row else {
            spaceAssertionFailure("wiki.space.detail --- cell index out of bounds")
            return cell
        }
        let member = members[indexPath.row]
        memberCell.update(member: member)
        memberCell.avatarDidClick = { [weak self] in
            self?.didClickMemberAvatar(memberID: member.memberID)
        }
        return memberCell
    }

    private func tableView(_ tableView: UITableView, loadingCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: loadingCellReuseIdentifier, for: indexPath)
        guard let loadingCell = cell as? WikiMemberPlaceholderTableViewCell else {
            spaceAssertionFailure("wiki.space.detail --- failed to convert loading cell")
            return cell
        }
        return loadingCell
    }

    private func tableView(_ tableView: UITableView, errorCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: errorCellReuseIdentifier, for: indexPath)
        guard let errorCell = cell as? WikiMemberErrorTableViewCell else {
            spaceAssertionFailure("wiki.space.detail --- failed to convert error cell")
            return cell
        }
        errorCell.retryBlock = { [weak self] in
            self?.retry()
        }
        return errorCell
    }

    private func didClickMemberAvatar(memberID: String) {
        DocsLogger.info("did click member avatar")
        let profileService = ShowUserProfileService(userId: memberID, fromVC: self)
        HostAppBridge.shared.call(profileService)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0, 2, 3:
            return 0
        case 1:
            return 44
        default:
            spaceAssertionFailure("wiki.space.detail --- section out of bounds")
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let title = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_MemberListHeader
            return WikiMemberSectionHeaderView(title: title)
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return headerPreferHeight
        case 1, 2:
            return 68
        case 3:
            return 370
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
