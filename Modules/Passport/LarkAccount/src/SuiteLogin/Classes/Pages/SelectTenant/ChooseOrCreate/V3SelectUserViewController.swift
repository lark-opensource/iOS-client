//
//  V3SelectUserViewController.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/2.
//

import UIKit
import RxSwift
import Homeric
import LarkUIKit
import LarkPerf
import UniverseDesignActionPanel
import LarkAlertController
import LarkContainer
import UniverseDesignToast
import ECOProbeMeta

class V3SelectUserViewController: BaseViewController {

    @Provider var loginService: V3LoginService
    
    var passportEventBus: PassportEventBusProtocol { LoginPassportEventBus.shared }

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18N.Lark_Passport_Login_User_Enterprise_ChooseAll_Cancel_Button, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(cancelEdit), for: .touchUpInside)
        return button
    }()
    
    lazy var table: UITableView = {
        let tb = UITableView(frame: .zero, style: .grouped)
        tb.lu.register(cellSelf: SelectUserTableViewCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.rowHeight = SelectTenantLayoutConst.designedCellHeight
        tb.sectionHeaderHeight = UITableView.automaticDimension
        tb.sectionFooterHeight = UITableView.automaticDimension
        tb.estimatedSectionHeaderHeight = 0.01
        tb.estimatedSectionFooterHeight = 0.01
        tb.dataSource = self
        tb.delegate = self
        tb.showsVerticalScrollIndicator = false
        return tb
    }()

    lazy var bottomBtns: [CustomTextImageControl] = {
        return createBtns()
    }()
    lazy var bottomCreateUserView: SelectUserBottomView = {
        let axis: SelectUserBottomView.BtnAxis =  Display.pad
            ? .horizontal(btnHeight: Layout.phoneBottomBtnHeight)
            :  .vertical(btnHeight: Layout.phoneBottomBtnHeight)
        return SelectUserBottomView(
            type: .createBtns(bottomBtns, axis: axis)
        )
    }()
    lazy var bottomRefuseView: RefuseItemView = {
        let refuseView = RefuseItemView(joinButtonInfo: vm.selectUserInfo.joinButton,
                                        refuseItem: vm.selectUserInfo.refuseItem) { [weak self] actionType in
            guard let self = self else { return }
            self.logger.info("n_action_join_tenant", body: "type: \(actionType)")
            switch actionType {
            case .select:
                self.vm.startEdit()
            case .refuse:
                self.checkRefuseInvitation()
            case .join:
                self.joinTenants()
            }
        }
        return refuseView
    }()
    lazy var refuseToolBar: RefuseToolBar = {
        let toolBar = RefuseToolBar(refuseButtonInfo: vm.selectUserInfo.refuseItem?.refuseButton) { [weak self] actionType in
            guard let self = self else { return }
            self.logger.info("n_action_join_tenant", body: "type: \(actionType)")
            
            switch actionType {
            case .selectAll:
                self.vm.selectAll()
            case .deselectAll:
                self.vm.deselectAll()
            case .refuse:
                self.checkRefuseInvitation()
                break
            }
        }
        
        return toolBar
    }()
    
    weak var registerPanel: UDActionPanel?
    let transition = PanelTransition()

    var showCounts: [Int]
    var didUpdateShowCount: Bool = false

    let vm: V3SelectUserViewModel

    init(vm: V3SelectUserViewModel) {
        self.vm = vm
        self.showCounts = vm.dataSource.value.map({ (data) -> Int in
            return data.data.count
        })
        super.init(viewModel: vm)
        vm.stopLoadingBlock = { [weak self] in
            self?.stopLoading()
        }
        vm.dataSource
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] dataSource in
                guard let self = self else { return }
                
                // 仅剩一个租户时展示拒绝按钮，否则展示选择按钮
                self.bottomRefuseView.showRefuseButton = dataSource.reduce(0) { $0 + $1.data.count } <= 1
                
                // 更新 RefuseToolBar 状态
                self.refuseToolBar.isUserSelected = dataSource.contains { _, data in
                    data.contains { $0.isSelected }
                }
                
                self.refuseToolBar.isAllSelected = dataSource.allSatisfy({ _, data in
                    data.allSatisfy { $0.isSelected }
                })
                
                self.table.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private lazy var nextTipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = UIColor.clear
        return button
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        centerInputView.removeFromSuperview()
        switchButtonContainer.removeFromSuperview()
        inputAdjustView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        detailLabel.removeFromSuperview()

        configTopInfo(vm.title, detail: NSAttributedString())
        
        let headerView = UIView()
        moveBoddyView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseLayout.visualNaviBarHeight + CL.itemSpace)
            make.left.right.equalToSuperview()
        }

        headerView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.bottom.equalToSuperview().inset(10.0)
        }

        moveBoddyView.addSubview(table)

        switch vm.bottomStyle() {
        case .none:
            table.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(viewBottomConstraint)
            }
        case .doubleButton:
            table.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
            }
            moveBoddyView.addSubview(bottomCreateUserView)
            bottomCreateUserView.snp.makeConstraints { (make) in
                make.top.equalTo(table.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(viewBottomConstraint)
            }
        case .refuseButton:
            cancelButton.isHidden = true
            view.addSubview(cancelButton)
            cancelButton.snp.makeConstraints { make in
                make.centerY.equalTo(view.safeAreaLayoutGuide.snp.top).offset(22)
                make.right.equalToSuperview().inset(CL.itemSpace)
            }
            
            table.allowsMultipleSelection = true
            table.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(viewBottomConstraint)
            }
            table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
            
            vm.joinButtonInfo
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] joinButtonInfo in
                    if joinButtonInfo != nil {
                        self?.bottomRefuseView.joinButtonInfo = joinButtonInfo
                    }
                })
                .disposed(by: disposeBag)
            moveBoddyView.addSubview(bottomRefuseView)
            bottomRefuseView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(viewBottomConstraint)
            }

            moveBoddyView.addSubview(refuseToolBar)
            refuseToolBar.isHidden = true
            refuseToolBar.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(viewBottomConstraint)
            }
            
            vm.isEditing
                .skip(1) // 忽略初始值，否则 reloadSections 和 reloadData 交替执行可能导致显示不正确
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isEditing in
                    guard let self = self else { return }
                    
                    self.cancelButton.isHidden = false
                    self.cancelButton.alpha = isEditing ? 0 : 1.0
                    self.refuseToolBar.isHidden = false
                    self.refuseToolBar.alpha = isEditing ? 0 : 1.0
                    
                    UIView.animate(withDuration: 0.25) { [weak self] in
                        self?.bottomRefuseView.alpha = isEditing ? 0 : 1.0
                        self?.cancelButton.alpha = isEditing ? 1.0 : 0
                        self?.refuseToolBar.alpha = isEditing ? 1.0 : 0
                    } completion: { [weak self] _ in
                        self?.bottomRefuseView.isHidden = isEditing
                        self?.cancelButton.isHidden = !isEditing
                        self?.refuseToolBar.isHidden = !isEditing
                    }
                    
                    UIView.animate(withDuration: 0.125) { [weak self] in
                        self?.titleLabel.alpha = 0.25
                    } completion: { [weak self] _ in
                        guard let self = self else { return }
                        
                        if isEditing {
                            self.configInfo(self.vm.selectUserInfo.refuseItem?.selectTitle ?? "", detail: "")
                        } else {
                            self.configInfo(self.vm.title, detail: "")
                        }
                        
                        UIView.animate(withDuration: 0.125) { [weak self] in
                            self?.titleLabel.alpha = 1.0
                        }
                    }
                    
                    let count = self.numberOfSections(in: self.table)
                    if count > 0 {
                        self.table.reloadSections(IndexSet(0..<count), with: .automatic)
                    }
                    
                    self.refuseToolBar.isUserSelected = false
                    self.refuseToolBar.isAllSelected = false
                })
                .disposed(by: disposeBag)
            
        case .singleButton:
            nextButton.setTitle(vm.selectUserInfo.registerButton?.text, for: .normal)
            nextButton.isEnabled = true
            table.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(bottomView.snp.top).offset(-CL.itemSpace)
            }

            nextButton.rx.tap.subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.selectUserInfo.flowType ?? "",
                                                                     click: "continue_create",
                                                                     target: "",
                                                                     data:["user_list_type": self.vm.selectUserInfo.userListType])
                SuiteLoginTracker.track(Homeric.PASSPORT_CHOOSE_TEAM_CLICK, params: params)
                self.createTenant()
            }).disposed(by: disposeBag)
        case .singleTips:
            moveBoddyView.addSubview(nextTipButton)
            nextTipButton.setTitle(vm.selectUserInfo.joinButton?.text, for: .normal)
            table.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
                make.bottom.equalTo(nextTipButton.snp.top).offset(-CL.itemSpace / 2)
            }
            nextTipButton.snp.makeConstraints { (make) in
                make.centerX.bottom.equalToSuperview()
                make.height.equalTo(40)
                make.left.right.equalToSuperview().inset(CL.itemSpace)
            }

            nextTipButton.rx.tap.subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                let type = self.vm.selectUserInfo.joinButton?.actionType
                self.trace(by: type)
                self.logger.info("single tips button click")
                if let nextStep = self.vm.selectUserInfo.joinButton?.next {
                    self.handleStep(stepData: nextStep)
                }
            }).disposed(by: disposeBag)
        }

        self.table.reloadData()
        // 如果有加入/拒绝团队相关按钮则认为这个页面是邀请加入页面，与Android逻辑保持一致
        if let refuseItem = vm.selectUserInfo.refuseItem {
            PassportMonitor.flush(PassportMonitorMetaJoin.loginJoinEnter,
                    eventName: ProbeConst.monitorEventName,
                    categoryValueMap: [ProbeConst.flowType: vm.selectUserInfo.flowType],
                    context: vm.context)
        } else {
            PassportMonitor.flush(PassportMonitorMetaStep.chooseTenantEnter,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: ["user_list_size": self.vm.cellDataList.count,
                                                     "user_list_type": self.vm.selectUserInfo.userListType],
                                  context: vm.context)
        }
    }
    
    private func trace(by buttonType: ActionIconType?) {
        var click = ""
        var target = ""
        switch buttonType {
        case .register:
            click = TrackConst.passportClickTrackCreateTeam
            target = TrackConst.passportTeamInfoSettingView
        case .join:
            click = TrackConst.passportClickTrackJoinTeam
        case .createTenant:
            click = TrackConst.passportClickTrackCreateTeam
        case .createPersonal:
            click = TrackConst.passportClickTrackPersonalUse
        default:
            break
        }
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.selectUserInfo.flowType ?? "",
                                                             click: click,
                                                             target: target,
                                                             data:["user_list_type": vm.selectUserInfo.userListType])
        SuiteLoginTracker.track(Homeric.PASSPORT_CHOOSE_TEAM_CLICK, params: params)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.selectUserInfo.flowType ?? "",
                                                            data:["user_list_type": vm.selectUserInfo.userListType])
        SuiteLoginTracker.track(Homeric.PASSPORT_CHOOSE_TEAM_VIEW, params: params)
        if let pn = pageName() {
            SuiteLoginTracker.track(pn)
            PassportMonitor.flush(EPMClientPassportMonitorLoginCode.login_goto_user_list_page_succ, context: vm.context)
        }
        logger.info("n_page_userList_start")
    }

    override func needBottmBtnView() -> Bool {
        return vm.bottomStyle() == .singleButton
    }

    override func needSwitchButton() -> Bool {
        return false
    }

    override func pageName() -> String? {
        return Homeric.REGISTER_ENTER_SELECT_USER
    }

    override func clickBackOrClose(isBack: Bool) {
        if let refuseItem = vm.selectUserInfo.refuseItem {
            PassportMonitor.flush(PassportMonitorMetaJoin.loginJoinCancel,
                    eventName: ProbeConst.monitorEventName,
                    categoryValueMap: [ProbeConst.flowType: vm.selectUserInfo.flowType],
                    context: vm.context)
        } else {
            PassportMonitor.flush(PassportMonitorMetaStep.chooseTenantCancel,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: ["user_list_size": self.vm.cellDataList.count,
                                                     "user_list_type": self.vm.selectUserInfo.userListType],
                                  context: vm.context)
        }
            
        super.clickBackOrClose(isBack: isBack)
    }
    
    override var needSkipWhilePop: Bool { return vm.needSkipWhilePop }

}

extension V3SelectUserViewController: UITableViewDelegate {

    func headerLabel(text: String) -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = Layout.sectionHeaderFont
        label.textColor = UIColor.ud.N600
        label.attributedText = V3ViewModel.attributedString(for: text, UIColor.ud.N600)
        return label
    }

    func headerView(section: Int) -> UIView {
        let headerView = UIView()
        if !vm.isEditing.value, let name = vm.dataSource.value[section].name {
            let label = headerLabel(text: name)
            headerView.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(Layout.sectionHeaderHorizonal)
                make.top.equalToSuperview().inset(section == 0 ? 0 : Layout.sectionHeaderVertical * 2)
                make.bottom.equalToSuperview().inset(section == 0 ? Layout.firstSectionHeaderVertical : Layout.sectionHeaderVertical)
            }
        } else {
            headerView.frame = CGRect(x: 0, y: 0, width: table.bounds.width, height: 0.01)
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.frame = CGRect(x: 0, y: 0, width: table.bounds.width, height: 0.01)
        return footerView
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView(section: section)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return vm.bottomStyle() != .refuseButton || vm.isEditing.value
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? SelectUserTableViewCell
        cell?.updateSelection(true)
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? SelectUserTableViewCell
        cell?.updateSelection(false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let c = tableView.cellForRow(at: indexPath)
        guard let cell = c as? SelectUserTableViewCell, let userInfo = cell.data else {
            logger.error("did Select fail cell isNil: \(c == nil)")
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        logger.info("n_action_userlist_select_item: \(cell.data?.userId)")
        if vm.bottomStyle() == .refuseButton {
            // 未加入状态
            vm.toggleSelectionForUser(at: indexPath)
            return
        }

        ProbeDurationHelper.startDuration(ProbeDurationHelper.chooseTenantFlow)
        PassportMonitor.flush(PassportMonitorMetaStep.startChooseTenant,
                        eventName: ProbeConst.monitorEventName,
                        context: vm.context)
        
        let status = V4UserItem.getStatus(from: userInfo.status)
        var click = TrackConst.passportClickTrackEnterTeam
        switch status {
        case .forbidden:
            click = TrackConst.passportClickTrackAppeal
        default:
            break
        }
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.selectUserInfo.flowType ?? "",
                                                             click: click, target: "",
                                                             data:["user_list_type": vm.selectUserInfo.userListType])
        SuiteLoginTracker.track(Homeric.PASSPORT_CHOOSE_TEAM_CLICK, params: params)
        
        func showErrorMessage(message: String) {
            let alert = LarkAlertController()
            alert.setContent(text: message)
            alert.addPrimaryButton(text: BundleI18n.LarkAccount.Lark_Legacy_IKnow)
            present(alert, animated: true, completion: nil)
        }
        
        if userInfo.isInReview {
            showErrorMessage(message: I18N.Lark_Passport_SelectTeamTeamInReviewTagTip)
            PassportMonitor.monitor(PassportMonitorMetaStep.chooseTenantResult,
                                    eventName: ProbeConst.monitorEventName,
                                    categoryValueMap: ["user_list_size": vm.cellDataList.count,
                                                       "user_list_type": vm.selectUserInfo.userListType],
                                    context: vm.context)
            .setResultTypeFail()
            .setUserOperationError(with: .userIsPending)
            .flush()
        } else {
            showLoading()
            vm.choose(userIndex: indexPath)?
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    self.logger.info("n_action_userList_next", additionalData: ["user": "\(userInfo.userId)"])
                    let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.chooseTenantFlow)
                    PassportMonitor.monitor(PassportMonitorMetaStep.chooseTenantResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: ["user_list_size": self.vm.cellDataList.count,
                                                               "user_list_type": self.vm.selectUserInfo.userListType,
                                                               ProbeConst.duration: duration],
                                            context: self.vm.context)
                    .setResultTypeSuccess()
                    .flush()
                    self.stopLoading()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    PassportMonitor.monitor(PassportMonitorMetaStep.chooseTenantResult,
                                            eventName: ProbeConst.monitorEventName,
                                            categoryValueMap: ["user_list_size": self.vm.cellDataList.count,
                                                               "user_list_type": self.vm.selectUserInfo.userListType],
                                            context: self.vm.context)
                    .setResultTypeFail()
                    .setPassportErrorParams(error: error)
                    .flush()
                    self.handle(error)
                }).disposed(by: disposeBag)
        }
    }
}

extension V3SelectUserViewController: UITableViewDataSource {

    func dataSource(section: Int) -> [SelectUserCellData] {
        return vm.dataSource.value[section].data
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return vm.dataSource.value.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource(section: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userInfo = vm.getData(of: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SelectUserTableViewCell.lu.reuseIdentifier,
                                                       for: indexPath) as? SelectUserTableViewCell else {
            return UITableViewCell()
        }
        cell.showCheckBox = vm.isEditing.value
        cell.data = userInfo
        return cell
    }
}

extension V3SelectUserViewController {
    func createBtns() -> [CustomTextImageControl] {
        var buttons: [CustomTextImageControl] = []
        if let buttonInfo = vm.selectUserInfo.joinButton {
            buttons.append(
                CustomTextImageControl(text: buttonInfo.text, image: vm.image(by: buttonInfo.actionType)) { [weak self] in
                    guard let self = self else { return }
                    self.trace(by: buttonInfo.actionType)
                    if let nextStep = buttonInfo.next {
                        self.handleStep(stepData: nextStep)
                    }
                }
            )
        }

        if let buttonInfo = vm.selectUserInfo.registerButton {
            buttons.append(
                CustomTextImageControl(text: buttonInfo.text, image: vm.image(by: buttonInfo.actionType)) { [weak self] in
                    guard let self = self else { return }
                    self.register()
                }
            )
        }
        logger.info("create button count is \(buttons.count)")
        return buttons
    }

    func register() {
        let buttons = createRegisterItems()
        if let registerItem = vm.selectUserInfo.registerItem, !buttons.isEmpty {
            self.logger.info("click to open panel")
            let registerItemView = RegisterItemView(title: registerItem.title, btnList: buttons)
            let vc = UIViewController()
            vc.view.addSubview(registerItemView)
            registerItemView.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
            }

            let config = UDActionPanelUIConfig(originY: UIScreen.main.bounds.height - registerItemView.viewHeight - self.safeAreaBottom, canBeDragged: false)
            let panel = UDActionPanel(customViewController: vc, config: config)
            panel.transitioningDelegate = transition
            present(panel, animated: true, completion: nil)
            registerPanel = panel
        } else if let buttonInfo = vm.selectUserInfo.registerButton {
            self.logger.info("click to register")
            if let nextStep = buttonInfo.next {
                self.handleStep(stepData: nextStep)
            }
        }
    }

    func dismissRegisterPanelIfNeeded(completion:@escaping () -> Void) {
        if let panel = registerPanel {
            panel.dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
    }

    func createRegisterItems() -> [CustomSubtitleImageControl] {
        var buttons: [CustomSubtitleImageControl] = []
        if let registerItem = vm.selectUserInfo.registerItem, let dispatchList = registerItem.dispatchList {
            dispatchList.forEach { (item) in
                buttons.append(CustomSubtitleImageControl(title: item.text, subtitle: item.desc, image: vm.image(by: item.actionType)) { [weak self] in
                    guard let self = self else { return }
                    self.logger.info("click panel item \(item.text)")
                    self.dismissRegisterPanelIfNeeded {
                        if let nextStep = item.next {
                            self.handleStep(stepData: nextStep)
                        }
                    }
                })
            }
        }
        logger.info("create register item count is \(buttons.count)")
        return buttons
    }

    func createTenant() {
        self.logger.info("click to create tenant")
        showLoading()
        vm.createTenant()?.subscribe(onNext: { [weak self] (_) in
            self?.stopLoading()
        }, onError: { [weak self] (error) in
            self?.handle(error)
        }).disposed(by: disposeBag)
    }

    func handleStep(stepData: V4StepData) {
        LoginPassportEventBus.shared.post(
            event: stepData.stepName ?? "",
            context: V3RawLoginContext(stepInfo: stepData.stepInfo, context: vm.context),
            success: { [weak self] in
                self?.logger.info("\(stepData.stepName ?? "") success")
            },
            error: { [weak self] error in
                self?.logger.error("\(stepData.stepName ?? "") failed", error: error)
            }
        )
    }
}

extension V3SelectUserViewController {
    
    func joinTenants() {
        self.logger.info("n_action_join_tenant_req_start")
        PassportMonitor.flush(PassportMonitorMetaJoin.loginJoinConfirmStart,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.selectUserInfo.flowType],
                context: vm.context)
        let startTime = Date()
        showLoading()
        vm.joinTenants()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("n_action_join_tenant_req_succ")
                PassportMonitor.monitor(PassportMonitorMetaJoin.loginJoinConfirmResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.selectUserInfo.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
                self.stopLoading()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("n_action_join_tenant_req_fail", error: error)
                PassportMonitor.monitor(PassportMonitorMetaJoin
                    .loginJoinConfirmResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.selectUserInfo.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
                self.handle(error)
            })
            .disposed(by: self.disposeBag)
    }
    
    func checkRefuseInvitation() {
        self.logger.info("n_action_check_refuse_req_start")
        PassportMonitor.flush(PassportMonitorMetaJoin.loginJoinRefuseCheckStart,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.selectUserInfo.flowType],
                context: vm.context)
        let startTime = Date()
        showLoading()
        vm.checkRefuseInvitation()
            .subscribe(onNext: { [weak self] serverInfo in
                guard let self = self else { return }
                self.logger.info("n_action_check_refuse_req_succ")
                PassportMonitor.monitor(PassportMonitorMetaJoin.loginJoinRefuseCheckResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.selectUserInfo.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
                self.stopLoading()
                self.showRefuseDialog(stepInfo: serverInfo)
                
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("n_action_check_refuse_req_fail", error: error)
                PassportMonitor.monitor(PassportMonitorMetaJoin
                    .loginJoinRefuseCheckResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.selectUserInfo.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
                self.handle(error)
            }).disposed(by: disposeBag)
    }
    
    func showRefuseDialog(stepInfo: V4ShowDialogStepInfo) {
        guard let title = stepInfo.title, !title.isEmpty,
              let subtitle = stepInfo.subTitle, !subtitle.isEmpty else {
                  self.logger.info("showDialog no title no suTitle do nothing")
                  return
              }
        
        let buttonList = stepInfo.btnList ?? []
        let buttonInfo: [String] = buttonList.map { $0.description }
        self.logger.info("n_action_refuse_invitation", additionalData: [ "buttons" : buttonInfo])
        
        guard buttonList.count > 1 else {
            self.logger.error("n_action_refuse_invitation: not enough button")
            return
        }
        
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: subtitle)
        if let cancelButton = buttonList.last {
            alertController.addSecondaryButton(text: cancelButton.text ?? "", numberOfLines: 0, dismissCheck: { true }) {
                self.logger.info("n_action_refuse_invitation_cancel")
            }
        }
        
        if let mainButton = buttonList.first {
            alertController.addDestructiveButton(text: mainButton.text ?? "", numberOfLines: 0, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                
                self.refuse()
            })
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func refuse() {
        self.logger.info("n_action_refuse_invitation_req_start")
        PassportMonitor.flush(PassportMonitorMetaJoin.loginJoinRefuseConfirmStart,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.selectUserInfo.flowType],
                context: vm.context)
        let startTime = Date()
        self.showLoading()
        self.vm.refuseInvitation()
            .subscribe(onNext: { [weak self] toast in
                guard let `self` = self else { return }
                PassportMonitor.monitor(PassportMonitorMetaJoin.loginJoinRefuseConfirmResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.selectUserInfo.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
                self.logger.info("n_action_refuse_invitation_req_succ")
                self.stopLoading()
                if let toast = toast, !toast.isEmpty {
                    let config = UDToastConfig(toastType: .info, text: toast, operation: nil)
                    UDToast.showToast(with: config, on: self.view)
                }
                
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("n_action_refuse_invitation_req_fail", error: error)
                PassportMonitor.monitor(PassportMonitorMetaJoin
                    .loginJoinRefuseConfirmResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.selectUserInfo.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: error)
                .flush()
                self.handle(error)
            }).disposed(by: self.disposeBag)
    }
    
    @objc
    func cancelEdit() {
        self.logger.info("n_action_join_tenant_cancel_edit")
        vm.cancelEdit()
    }
}

extension V3SelectUserViewController {
    fileprivate struct Layout {
        static let footerHeight: CGFloat = SelectTenantLayoutConst.designedTableFooterHeight
        static let topSpace: CGFloat = 25
        static let bottomCreateViewSpace: CGFloat = 16
        static let bottomCreateViewHight: CGFloat = 200
        static let tableHeaderHeight: CGFloat = 84
        static let headerTitleTop: CGFloat = 42
        static let sectionHeaderVertical: CGFloat = CL.itemSpace / 2
        static let firstSectionHeaderVertical: CGFloat = 24.0
        static let sectionHeaderHorizonal: CGFloat = CL.itemSpace / 4
        static let sectionHeaderFont: UIFont = UIFont.systemFont(ofSize: 14.0)
        static let phoneBottomBtnHeight: CGFloat = 54
        static let iPadBottomBtnHeight: CGFloat = 54
    }
}
