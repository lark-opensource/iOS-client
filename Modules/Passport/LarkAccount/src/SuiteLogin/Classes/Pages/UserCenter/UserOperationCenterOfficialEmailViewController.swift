//
//  UserOperationCenterOfficialEmailViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/6/22.
//

import Foundation
import Homeric
import LKCommonsLogging
import RxSwift
import LarkUIKit

class UserOperationCenterOfficialEmailViewController: BaseUIViewController, V3ViewModelProtocol, UITableViewDelegate, UITableViewDataSource {

    var viewModel: V3ViewModel { return vm }

    private lazy var errorHandle: V3ErrorHandler = {
        return V3ErrorHandler(vc: self, context: vm.context)
    }()

    static let logger = Logger.log(UserOperationCenterOfficialEmailViewController.self)

    private let vm: UserOperationCenterViewModel

    private var officialEmailItems: [OfficialEmailItem] = []

    init(vm: UserOperationCenterViewModel) {
        self.vm = vm
        if let emailItems = vm.officialEmailItems, !emailItems.isEmpty {
            self.officialEmailItems = emailItems
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var table: UITableView = {
        let tb = UITableView(frame: .zero, style: .plain)
        tb.lu.register(cellSelf: UserOperationCenterCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tb.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tb.rowHeight = Layout.cellHeight
        tb.dataSource = self
        tb.delegate = self
        return tb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = I18N.Lark_Passport_AddAccount_DirectJoinViaMailTitle
        table.isScrollEnabled = false
        self.view.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = UIColor.ud.bgBase
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.userCenterInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_AUTHED_EMAIL_TENANT_LIST_VIEW, params: params)
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return Layout.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: Layout.headerLabelFont)
        lbl.textAlignment = .left
        lbl.lineBreakMode = .byWordWrapping
        lbl.attributedText = V3ViewModel.attributedString(for: I18N.Lark_Passport_AddAccount_DirectJoinViaMailDesc(self.officialEmailItems[section].emailSuffix), UIColor.ud.textCaption)
        headerView.addSubview(lbl)
        lbl.preferredMaxLayoutWidth = self.table.frame.size.width - CL.itemSpace * 2
        lbl.snp.makeConstraints { (make) in
            make.left.equalTo(CL.itemSpace)
            make.bottom.equalToSuperview().inset(Layout.headerLabelBottomSpace)
            make.width.lessThanOrEqualTo(self.table.frame.size.width - CL.itemSpace * 2)
        }
        lbl.sizeToFit()
        return headerView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackJoinTeam, target: "")
        SuiteLoginTracker.track(Homeric.PASSPORT_AUTHED_EMAIL_TENANT_LIST_CLICK, params: params)
        let cell = tableView.cellForRow(at: indexPath) as? UserOperationCenterCell
        cell?.updateSelection(false)
        let tenant = self.officialEmailItems[indexPath.section].tenantItems[indexPath.row]
        vm.initOfficialEmail(tenant: tenant)?.subscribe(
            onError: { [weak self] (error) in
            self?.errorHandle.handle(error)
        }).disposed(by: DisposeBag())
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? V3JoinTenantTableViewCell
        cell?.updateSelection(true)
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? V3JoinTenantTableViewCell
        cell?.updateSelection(false)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.officialEmailItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.officialEmailItems[section].tenantItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserOperationCenterCell") as? UserOperationCenterCell else {
            return UITableViewCell()
        }
        let item = self.officialEmailItems[indexPath.section].tenantItems[indexPath.row]
        cell.data = UserOperationCenterCellData(title: item.name, subtitle: nil, iconURL: item.iconURL, icon: nil)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.cellHeight
    }
    
}

extension UserOperationCenterOfficialEmailViewController {
    struct Layout {
        static let headerHeight: CGFloat = 46.0
        static let headerSpaceHeight: CGFloat = 20.0
        static let headerLabelHeight: CGFloat = 20.0
        static let headerLabelBottomSpace: CGFloat = 6.0
        static let headerLabelFont: CGFloat = 14

        static let cellHeight: CGFloat = 68.0
    }
}
