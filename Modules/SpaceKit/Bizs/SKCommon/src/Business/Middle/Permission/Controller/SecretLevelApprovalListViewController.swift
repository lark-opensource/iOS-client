//
//  SecretLevelApprovalListViewController.swift
//  SKCommon
//
//  Created by guoqp on 2022/8/4.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignIcon
import EENavigator
import LarkUIKit
import SKInfra
import SpaceInterface

public final class SecretLevelApprovalListViewController: BaseViewController {
    var instances: [SecretLevelApprovalInstance] { viewModel.instances }
    private var viewModel: SecretApprovalListViewModel
    private let disposeBag = DisposeBag()
    private var permStatistic: PermissionStatistics? { viewModel.permStatistic }
    private let needCloseBarItem: Bool
    weak var followAPIDelegate: BrowserVCFollowDelegate?

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.ud.commonTableSeparatorColor
        tableView.register(ApprovalListCell.self,
                           forCellReuseIdentifier: ApprovalListCell.reuseIdentifier)
        tableView.estimatedRowHeight = 56
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UDColor.bgBase
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()


    public init(viewModel: SecretApprovalListViewModel,
                needCloseBarItem: Bool,
                followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.viewModel = viewModel
        self.needCloseBarItem = needCloseBarItem
        self.followAPIDelegate = followAPIDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override public func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Records_Mob
        setupView()
        viewModel.reportCcmPermissionSecurityResubmitToastView()
    }

    private func addCloseBarItemIfNeed() {
        guard needCloseBarItem else { return }
        let btnItem = SKBarButtonItem(image: UDIcon.closeSmallOutlined,
                                      style: .plain,
                                      target: self,
                                      action: #selector(didClickedCloseBarItem))
        btnItem.id = .close
        navigationBar.leadingBarButtonItems = [btnItem]
    }

    private func dismissSelf() {
        if needCloseBarItem {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func didClickedCloseBarItem() {
        dismissSelf()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    private func setupView() {
        view.backgroundColor = UDColor.bgBase
//        navigationBar.customizeBarAppearance(backgroundColor: UDColor.bgBody)
//        statusBar.backgroundColor = view.backgroundColor

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        addCloseBarItemIfNeed()
    }

    public override func backBarButtonItemAction() {
        super.backBarButtonItemAction()
    }

    func applink(instanceId: String) -> URL? {
        guard let config = SettingConfig.approveRecordProcessUrlConfig else {
            DocsLogger.warning("config is nil")
            return nil
        }
        let urlString = config.url + instanceId
        return URL(string: urlString)
    }
}


extension SecretLevelApprovalListViewController: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return instances.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ApprovalListCell.reuseIdentifier, for: indexPath) as? ApprovalListCell else {
            return UITableViewCell()
        }
        let row = indexPath.row
        guard row >= 0, row < instances.count else { return UITableViewCell() }
        let instance = instances[indexPath.row]
        cell.update(avatarURL: instance.userAvatarUrl, nickName: instance.userName, time: TimeInterval(instance.createTime),
                    canShowProgress: instance.belongsToTheCurrentUser)
        cell.linkButtonTap = { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("link button click")
            guard let url = self.applink(instanceId: instance.instanceCode) else {
                DocsLogger.error("url is nil")
                return
            }
            if let followAPIDelegate = self.followAPIDelegate {
                followAPIDelegate.follow(onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { from in
                    guard let from else { return }
                    Navigator.shared.push(url, from: from)
                })))
            } else {
                Navigator.shared.push(url, from: self)
            }

            self.viewModel.reportCcmPermissionSecurityResubmitToastClick()
//            Navigator.shared.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: self)
        }
        cell.avatarTap = {
            DocsLogger.info("avatar view tap, userid \(instance.userId)")
            HostAppBridge.shared.call(ShowUserProfileService(userId: instance.userId, fromVC: self))
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var title = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_xRequest2Adjust_1_Mob(viewModel.label.name)
        if instances.count > 0 {
            title = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_xRequest2Adjust_N_Mob(instances.count, viewModel.label.name)
        }
        let view = ApprovalListCellSectionHeaderView(title: title)
        return view
    }
}
