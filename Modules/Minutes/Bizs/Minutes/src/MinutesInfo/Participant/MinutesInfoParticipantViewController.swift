//
//  MinutesInfoParticipantViewController.swift
//  Minutes
//
//  Created by sihuahao on 2021/4/14.
//

import UIKit
import SnapKit
import Kingfisher
import LarkUIKit
import EENavigator
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import LarkFeatureGating
import UniverseDesignIcon
import LarkAlertController
import LarkContainer
import LarkSetting

protocol MinutesInfoParticipantViewControllerDelegate: AnyObject {
    func participantsChanged(_ controller: MinutesInfoParticipantViewController)
}

class MinutesInfoParticipantViewController: UIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedProvider var featureGatingService: FeatureGatingService?
    
    private var isNewExternalTagEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .archUserOrganizationName) == true
    }
        
    private var viewModel: MinutesInfoParticipantViewModel
    weak var delegate: MinutesInfoParticipantViewControllerDelegate?

    let participantSize = 10000
    private lazy var backButtonItem = UIBarButtonItem(image: UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1),
                                                      style: .plain,
                                                      target: self,
                                                      action: #selector(onClickBackButton(_:)))

    private lazy var inviteButtonItem = UIBarButtonItem(image: UDIcon.getIconByKey(.memberAddOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(onClickInviteButtonItem(_:)))

    private lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 4))
        tableView.register(MinutesInfoParticipantTableViewCell.self,
                           forCellReuseIdentifier: MinutesInfoParticipantTableViewCell.description())
        return tableView
    }()

    private var tracker: MinutesTracker?

    init(resolver: UserResolver, minutes: Minutes) {
        self.userResolver = resolver
        viewModel = MinutesInfoParticipantViewModel(minutes: minutes)
        tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isMinutesEditable: Bool {
        // 编辑权限 或者是所有者可以重命名
        let permission = viewModel.minutes.info.currentUserPermission
        return permission.contains(.edit) || permission.contains(.owner)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.backgroundColor = UIColor.ud.bgBody
            navBarAppearance.shadowColor = nil
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
            navigationController?.navigationBar.standardAppearance = navBarAppearance
        } else {
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        navigationController?.navigationBar.layoutIfNeeded()
        navigationItem.leftBarButtonItem = backButtonItem
        navigationItem.leftBarButtonItem?.tintColor = UIColor.ud.iconN1

        if isMinutesEditable {
            navigationItem.rightBarButtonItem = inviteButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        title = BundleI18n.Minutes.MMWeb_G_AllParticipants(viewModel.minutes.info.participants.count)

        viewModel.minutes.info.listeners.addListener(self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @objc
    private func onClickBackButton(_ sender: UIButton) {
        if navigationController?.presentingViewController == nil {
            navigationController?.popViewController(animated: true)
        } else {
            navigationController?.dismiss(animated: true)
        }
    }

    @objc
    private func onClickInviteButtonItem(_ sender: UIButton) {
        let minutesParticipantsSearchController = MinutesAddParticipantSearchViewController(resolver: userResolver, minutes: self.viewModel.minutes)
        minutesParticipantsSearchController.delegate = self
        let nav = LkNavigationController(rootViewController: minutesParticipantsSearchController)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen

        userResolver.navigator.present(nav, from: self)
    }
}

extension MinutesInfoParticipantViewController: MinutesInfoChangedListener {
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        DispatchQueue.main.async {
            switch info.status {
            case .ready:
                self.tableView.reloadData()
            case .otherError(let error):
                let se = error
            default:
                break
            }
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension MinutesInfoParticipantViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.minutes.info.participants.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedParticipant = viewModel.minutes.info.participants[indexPath.row]
        self.tracker?.tracker(name: .clickButton, params: ["action_name": "profile_picture", "page_name": "detail_page", "from_source": " participant_picture"])
        
        if selectedParticipant.userType == .lark {
            let from = userResolver.navigator.mainSceneTopMost
            MinutesProfile.personProfile(chatterId: selectedParticipant.userID, from: from, resolver: userResolver)
            tracker?.tracker(name: .detailClick, params: ["click": "profile", "location": "participant_picture", "target": "none"])
        } else if selectedParticipant.userType == .pstn {
            if let isBind = selectedParticipant.isBind, isBind == true, let bindID = selectedParticipant.bindID {
                let from = userResolver.navigator.mainSceneTopMost
                MinutesProfile.personProfile(chatterId: bindID, from: from, resolver: userResolver)
                tracker?.tracker(name: .detailClick, params: ["click": "profile", "location": "participant_picture", "target": "none"])
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesInfoParticipantTableViewCell.description(), for: indexPath)
                as? MinutesInfoParticipantTableViewCell else { return UITableViewCell() }
        let someParticipants = viewModel.minutes.info.participants
        if someParticipants.count <= indexPath.row { return UITableViewCell() }
        cell.update(item: someParticipants[indexPath.row], isNewExternalTagEnabled: isNewExternalTagEnabled)
        cell.selectionStyle = .none
        return cell
    }
}

extension MinutesInfoParticipantViewController: MinutesAddParticipantSearchViewControllerDelegate {
    func participantsInvited(_ controller: MinutesAddParticipantSearchViewController) {
        let size = participantSize
        fetchBasicInfoRequest(size: size)
    }
    
    func fetchBasicInfoRequest(size: Int) {
        self.viewModel.minutes.info.fetchBasicInfo(catchError: true, completionHandler: {[weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let response):
                self.viewModel.minutes.info.fetchParticipant(catchError: false, size: size, completionHandler: { [weak self] _ in
                    self?.handleFetchSuccess()
                })
            case .failure(let error): break
            }
        })
    }
    
    func handleFetchSuccess() {
        DispatchQueue.main.async {
            UDToast.removeToast(on: self.view)
            self.tableView.reloadData()
            self.delegate?.participantsChanged(self)
            self.title = BundleI18n.Minutes.MMWeb_G_AllParticipants(self.viewModel.minutes.info.participants.count)
        }
    }
}

// MARK: - Delete
extension MinutesInfoParticipantViewController {

    func showDeleteAlert(with row: Int) {
        let someMyList = self.viewModel.minutes.info.participants
        let alertController: LarkAlertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Minutes.MMWeb_G_DeleteQuestion(someMyList[row].userName), color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        alertController.setContent(text: BundleI18n.Minutes.MMWeb_G_DeleteInfo, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17))
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: nil)
        alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_Delete, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            if someMyList.count > row {
                self.onDeleteCell(index: row)
            }
        })
        self.present(alertController, animated: true)
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return canDelete(tableView: tableView, indexPath: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) {[weak self] _, _, completion in
            self?.showDeleteAlert(with: indexPath.row)
            completion(false)
        }
        deleteAction.backgroundColor = UIColor.ud.R600
        deleteAction.image = UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func onDeleteCell(index: Int) {

        self.tracker?.tracker(name: .detailClick, params: ["click": "participant_edit", "target": "none", "edit_type": "delete_participant"])

        let list = self.viewModel.minutes.info.participants
        let size = participantSize
        if list.count > index {
            let item = list[index]
            UDToast.showLoading(with: BundleI18n.Minutes.MMWeb_G_Loading, on: self.view)
            viewModel.participantsDelete(catchError: true, with: item) {[weak self] in
                guard let self = self else {
                    return
                }
                self.viewModel.minutes.info.fetchBasicInfo(catchError: true, completionHandler: {[weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let response):
                        self.viewModel.minutes.info.fetchParticipant(catchError: false, size: size, completionHandler: { _ in
                            DispatchQueue.main.async {
                                UDToast.removeToast(on: self.view)
                                self.tableView.reloadData()
                                self.delegate?.participantsChanged(self)
                                self.title = BundleI18n.Minutes.MMWeb_G_AllParticipants(self.viewModel.minutes.info.participants.count)
                            }
                        })
                    case .failure(let error): break
                    }
                })
            } failureHandler: {
                return
            }
        }
    }

    private func canDelete(tableView: UITableView, indexPath: IndexPath) -> Bool {
        guard isMinutesEditable else {
            return false
        }

        let list = self.viewModel.minutes.info.participants
        if list.count > indexPath.row {
            let item = list[indexPath.row]
            if item.actionId?.isEmpty == false {
                return true
            }
        }
        return false
    }
}
