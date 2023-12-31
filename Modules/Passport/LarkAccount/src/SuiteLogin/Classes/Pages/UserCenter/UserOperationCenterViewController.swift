//
//  UserOperationCenterViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2021/6/11.
//

import Foundation
import Homeric
import LKCommonsLogging
import RxSwift
import EENavigator
import LarkContainer
import LarkUIKit

class UserOperationCenterViewController: BaseUIViewController, V3ViewModelProtocol, UITableViewDelegate, UITableViewDataSource{
    var viewModel: V3ViewModel { return vm }

    static let logger = Logger.log(UserOperationCenterViewController.self)

    private var tableContentHeight: CGFloat = 0

    lazy var safeAreaBottom: CGFloat = {
        if let window = UIApplication.shared.keyWindow {
            return window.safeAreaInsets.bottom
        }
        return 0
    }()

    @InjectedLazy private var loginService: V3LoginService

    @Provider var switchUserService: NewSwitchUserService

    private let vm: UserOperationCenterViewModel

    private var firstLayout: Bool = true
    
    private var headerHeights: [CGFloat] = []

    init(vm: UserOperationCenterViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = true
        self.view.addSubview(scrollView)
        return scrollView
    }()

    private lazy var table: UITableView = {
        let tb = UITableView(frame: .zero, style: .plain)
        tb.lu.register(cellSelf: UserOperationCenterCell.self)
        tb.backgroundColor = .clear
        tb.isScrollEnabled = false
        tb.separatorStyle = .none
        tb.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tb.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tb.estimatedRowHeight = Layout.cellHeight
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tb.sectionHeaderTopPadding = 0
        }
        #endif
        tb.dataSource = self
        tb.delegate = self
        return tb
    }()

    private lazy var contentView = UIView()
    private lazy var bottomLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: Layout.bottomLabelFont)
        lbl.text = I18N.Lark_Passport_AddAccount_SwitchAnotherPhoneMail
        lbl.textColor = UIColor.ud.primaryContentDefault
        lbl.textAlignment = .center
        lbl.lineBreakMode = .byWordWrapping
        lbl.preferredMaxLayoutWidth = self.view.frame.width - CL.itemSpace * 2
        lbl.isUserInteractionEnabled = true

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toLoginVC(recognizer:)))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        lbl.addGestureRecognizer(tapRecognizer)

        return lbl
    }()

    private func tenantHeaderLabel(_ cp: String) -> (UILabel, CGFloat) {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: Layout.headerLabelFont)
        lbl.textAlignment = .left
        lbl.lineBreakMode = .byWordWrapping
        lbl.attributedText = V3ViewModel.attributedString(for: I18N.Lark_Passport_AddAccountAlreadyAddedDesc(cp), UIColor.ud.textCaption)
        lbl.preferredMaxLayoutWidth = self.table.frame.size.width - CL.itemSpace * 2
        lbl.sizeToFit()
        return (lbl, lbl.frame.height)
//        guard let attText = lbl.attributedText else {
//            return (lbl, 0)
//        }
//
//        let height = attText.boundingRect(with: CGSize(width: lbl.preferredMaxLayoutWidth, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil).height
//
//
//        return (lbl, height)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.title = I18N.Lark_Passport_AddAccountTitle
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.userCenterInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_VIEW, params: params)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard self.firstLayout else {
            return
        }
        self.firstLayout = false
        self.view.backgroundColor = UIColor.ud.bgBase

        self.vm.generateItems {
            print("UserOperationCenterViewModel.reloadData")
            self.table.reloadData()
        }
        self.scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.scrollView.addSubview(self.contentView)
        let scrollHeight: CGFloat
        if Display.pad {
            scrollHeight = self.view.frame.size.height
        } else {
            scrollHeight = self.view.frame.size.height - self.safeAreaBottom
        }
        self.tableContentHeight = self.vm.estimateTableHeight() + self.getAllHeaderHeight()

        let labelHeight = self.bottomLabel.text?.boundingRect(with: CGSize(width: self.view.frame.width - CL.itemSpace * 2, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil).height ?? Layout.bottomLabelHeight

        let contentHeight = max(self.tableContentHeight + Layout.bottomViewSpaceHeight + labelHeight, scrollHeight)
        self.contentView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(contentHeight)
        }
        self.contentView.addSubview(self.table)
        self.table.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.tableContentHeight)
        }
        self.scrollView.contentSize = CGSize(width: 0, height: contentHeight)

        self.contentView.addSubview(self.bottomLabel)
        let size = self.bottomLabel.sizeThatFits(CGSize(width: CGFloat(self.view.frame.width - CL.itemSpace * 2), height: CGFloat(Layout.bottomLabelHeight)))
        self.bottomLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-Layout.bottomLabelBottomSpace)
            make.width.equalTo(size.width)
            make.centerX.equalToSuperview()
        }
    }

    @objc
    private func toLoginVC(recognizer: UITapGestureRecognizer) {
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackLoginAnother, target: "")
        SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_CLICK, params: params)
        Self.logger.info("free register: pop to login page")
        let loginVC = loginService.createLoginVC(fromUserCenter: true, context: UniContextCreator.create(.operationCenterLogin))
        if Display.pad {
            let targetVC: UIViewController
            if loginVC is UINavigationController {
                Navigator.shared.present(loginVC, from: self) // user:checked (navigator)
            } else {
                Navigator.shared.push(loginVC, from: self) // user:checked (navigator)
            }
        } else {
            //iPad上 current navigation VC 已经是 passport loginNavVC；
            //因为不确定iPad为啥改成push，所以本次修改保留iPad老逻辑，只修改iPhone
            let targetVC: UIViewController
            if loginVC is UINavigationController {
                targetVC = loginVC
            } else {
                targetVC = LoginNaviController(rootViewController: loginVC)
            }
            targetVC.modalPresentationStyle = .fullScreen
            Navigator.shared.present(targetVC, from: self) // user:checked (navigator)
        }
    }
    
    private func getAllHeaderHeight() -> CGFloat {
        var height: CGFloat = 0.0
        _ = (0...self.vm.items.count - 1).map({ i in
            let currentHeaderHeight = getHeightForHeaderInSection(i)
            self.headerHeights.append(currentHeaderHeight)
            height += currentHeaderHeight
        })
        return height
    }

    private func getHeightForHeaderInSection(_ section: Int) -> CGFloat {
        switch vm.items[section] {
        case .unLoginTenantItems(let item):
            guard let cp = item.credential?.credential else {
                return Layout.headerSpaceHeight
            }
            let labelHeight = self.tenantHeaderLabel(cp).1
            return Layout.headerHeight + labelHeight
        default:
            return Layout.headerSpaceHeight
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.headerHeights[section]
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: UIView = UIView()
        view.backgroundColor = .clear
        let splitLineView = UIView()
        view.addSubview(splitLineView)
        splitLineView.backgroundColor = UIColor.ud.lineBorderCard
        splitLineView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.right.equalToSuperview()
        }
        switch vm.items[section] {
        case .unLoginTenantItems(let item):
            guard let cp = item.credential?.credential else {
                return view
            }
            let lbl = self.tenantHeaderLabel(cp).0
            view.addSubview(lbl)
            lbl.snp.makeConstraints { (make) in
                make.left.equalTo(CL.itemSpace)
                make.bottom.equalToSuperview().inset(Layout.headerLabelBottomSpace)
                make.width.lessThanOrEqualTo(self.table.frame.size.width - CL.itemSpace * 2)
            }
            return view
        default:
            return view
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let userCenterItems = vm.items[indexPath.section]
        //lynn modify
        switch userCenterItems {
        case .officialEmailTenantItems(_, _):
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackAuthedEmailTenant, target: TrackConst.passportAuthedEmailTenantListView)
            SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_CLICK, params: params)
            let vc = UserOperationCenterOfficialEmailViewController(vm: self.vm)
            Navigator.shared.push(vc, from: self) // user:checked (navigator)
        case .unLoginTenantItems(let items):
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.userCenterInfo.flowType ?? "", click: TrackConst.passportClickTrackEnterTeam, target: "")
            SuiteLoginTracker.track(Homeric.PASSPORT_CHANGE_OR_CREATE_TEAM_CLICK, params: params)
            let item = items.userList[indexPath.row]
            let user = UserManager.shared.getUserByResponseUser(responseUser: item.user)
            self.switchUserService.switchTo(userInfo: user, complete: { (success) in
                Self.logger.info("switch tenant with v4UserInfo action success = \(success), userId = \(item.user.id)")
            }, context: UniContextCreator.create(.operationCenter))
        case .operationItems(let operateButtons):
            let btn = operateButtons[indexPath.row]
            btn.action()
                .observeOn(MainScheduler.instance)
                .subscribe(onError: {  (err) in
                    Self.logger.error("enter operation items failed at row: \(indexPath.row + 1)")
                }).disposed(by: DisposeBag())
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? UserOperationCenterCell
        cell?.updateSelection(true)
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? UserOperationCenterCell
        cell?.updateSelection(false)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.vm.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch vm.items[section] {
        case .unLoginTenantItems(let unloginItems):
            return unloginItems.userList.count
        case .officialEmailTenantItems(_, _):
            return 1
        case .operationItems(let operationButtons):
            return operationButtons.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserOperationCenterCell") as? UserOperationCenterCell else {
            return UITableViewCell()
        }
        switch vm.items[indexPath.section] {
        case .unLoginTenantItems(let unloginItems):
            let item = unloginItems.userList[indexPath.row]
            cell.data = UserOperationCenterCellData(title: item.user.tenant.getCurrentLocalName(), subtitle: item.user.getCurrentLocalDisplayName(), iconURL: item.user.tenant.iconURL, tag: item.tagDesc, status: item.user.status, buttonInfo: item.button, isValid: item.isValid)
        case .officialEmailTenantItems(let image, let num):
            cell.data = UserOperationCenterCellData(title: I18N.Lark_Passport_AddAccount_DirectJoinViaMailEntry(num), subtitle: nil, iconURL: nil, icon: image)
        case .operationItems(let buttonItems):
            let item = buttonItems[indexPath.row]
            cell.data = UserOperationCenterCellData(title: item.title, subtitle: nil, icon: item.icon)
        }
        
        cell.isLastRow = indexPath.row == (table.numberOfRows(inSection: indexPath.section) - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.cellHeight
    }
}


extension UserOperationCenterViewController {
    struct Layout {
        static let headerHeight: CGFloat = 36.0
        static let headerSpaceHeight: CGFloat = 20.0
        static let headerLabelHeight: CGFloat = 20.0
        static let headerLabelBottomSpace: CGFloat = 6.0
        static let headerLabelFont: CGFloat = 14

        static let bottomLabelFont: CGFloat = 14
        static let bottomLabelTopSpace: CGFloat = 32.0
        static let bottomLabelBottomSpace: CGFloat = 52.0
        static let bottomLabelHeight: CGFloat = 20.0
        static let bottomViewSpaceHeight: CGFloat = Self.bottomLabelTopSpace + Self.bottomLabelBottomSpace
        static let cellHeight: CGFloat = 68.0
    }
}

