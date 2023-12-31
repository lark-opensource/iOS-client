//
//  V3JoinTenantViewController.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import LKCommonsLogging
import RxSwift
import Homeric
import UniverseDesignActionPanel
import UniverseDesignToast

class V3JoinTenantViewController: BaseViewController {

    var passportEventBus: PassportEventBusProtocol { LoginPassportEventBus.shared }

    private let vm: V3JoinTenantViewModel

    weak var registerPanel: UDActionPanel?

    init(vm: V3JoinTenantViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var table: UITableView = {
        let tb = UITableView(frame: .zero, style: .plain)
        tb.lu.register(cellSelf: V3JoinTenantTableViewCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tb.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.1))
        tb.dataSource = self
        tb.delegate = self
        return tb
    }()

    lazy var bottomLabel: UITextView = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainer.maximumNumberOfLines = 3
        lbl.font = UIFont.systemFont(ofSize: 14)
        lbl.textColor = UIColor.ud.textCaption
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        lbl.textAlignment = .left
        lbl.contentMode = .scaleToFill
        return lbl
    }()

    lazy var freeRegisterLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        lbl.preferredMaxLayoutWidth = self.view.frame.width - CL.itemSpace * 2
        lbl.textColor = UIColor.ud.colorfulBlue
        lbl.textAlignment = .center
        lbl.contentMode = .scaleToFill
        return lbl
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.isPad {
            super.view.backgroundColor = UIColor.ud.bgBody
            self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgLogin
        table.isScrollEnabled = false
        configTopInfo(vm.title, detail: vm.subtitle)
        moveBoddyView.addSubview(table)
        table.snp.makeConstraints { (make) in
            make.top.equalTo(detailLabel.snp.bottom).offset(Layout.topSpace)
            make.top.equalTo(inputAdjustView.snp.bottom).offset(Layout.topSpace)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-(Layout.bottomButtonBottomSpace + Layout.bottomLabelHeight + CL.tableBottom))
        }

        if let text = vm.joinTenantInfo.registerButton?.text, !text.isEmpty {
            self.logger.info("n_action_show_bottom_button", body: "visible: true")
            moveBoddyView.addSubview(freeRegisterLabel)
            freeRegisterLabel.text = text
            freeRegisterLabel.sizeToFit()
            freeRegisterLabel.isUserInteractionEnabled = true
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(popPanel(recognizer:)))
            tapRecognizer.numberOfTouchesRequired = 1
            tapRecognizer.numberOfTapsRequired = 1
            freeRegisterLabel.addGestureRecognizer(tapRecognizer)

            freeRegisterLabel.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview().inset(Layout.bottomButtonBottomSpace)
                make.width.lessThanOrEqualTo(self.view.frame.width - CL.itemSpace * 2)
                make.centerX.equalToSuperview()
            }
        } else {
            self.logger.info("n_action_show_bottom_button", body: "visible: false")
        }
        PassportMonitor.flush(PassportMonitorMetaJoin.joinTenantEnter,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.joinTenantInfo.flowType],
                context: vm.context)

    }

    @objc
    private func popPanel(recognizer: UITapGestureRecognizer) {
        logger.info("n_action_click_personal_user_or_create_team")
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.joinTenantInfo.flowType ?? "", click: "create_team_or_pesonal_use", target: TrackConst.passportCreateTeamOrPersonalUserView)
        SuiteLoginTracker.track(Homeric.PASSPORT_JOIN_TEAM_VIEW, params: params)
        self.register()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let pn = pageName() {
            SuiteLoginTracker.track(pn, params: [TrackConst.path: vm.trackPath])
        }
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: vm.joinTenantInfo.flowType ?? "")
        SuiteLoginTracker.track(Homeric.PASSPORT_JOIN_TEAM_VIEW, params: params)
        logger.info("n_page_tenant_join_way", method: .local)
        
        if let toastMessage =  vm.joinTenantInfo.toast, !toastMessage.isEmpty  {
            let config = UDToastConfig(toastType: .info, text: toastMessage, operation: nil)
            UDToast.showToast(with: config, on: view)
        }
    }

    override func needBottmBtnView() -> Bool {
        return false
    }

    override func pageName() -> String? {
        return Homeric.ENTER_JOIN_TENANT
    }

    override func needPanGesture() -> Bool {
        return false
    }

    override func handleClickLink(_ URL: URL, textView: UITextView) {
        if URL.host == Link.personalUseURL.host {
            showLoading()
            vm.usePersonal()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                        guard let `self` = self else { return }
                        self.stopLoading()
                    }, onError: { [weak self] (err) in
                        guard let `self` = self else { return }
                        self.stopLoading()
                        self.handle(err)
                }).disposed(by: self.disposeBag)
            return
        }
        super.handleClickLink(URL, textView: textView)
    }

    override func clickBackOrClose(isBack: Bool) {
        PassportMonitor.flush(PassportMonitorMetaJoin.joinTenantCancel,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.joinTenantInfo.flowType],
                context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }
}

extension V3JoinTenantViewController {
    func register() {
        logger.info("click register item")
        let btns = createRegisterItems()
        if let registerItem = vm.joinTenantInfo.registerItem, !btns.isEmpty {
            let registerItemView = RegisterItemView(title: registerItem.title, btnList: btns)
            let vc = UIViewController()
            vc.view.addSubview(registerItemView)
            registerItemView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(vc.view.safeAreaLayoutGuide.snp.top)
            }

            let config = UDActionPanelUIConfig(originY: UIScreen.main.bounds.height - registerItemView.viewHeight - self.safeAreaBottom, canBeDragged: false)
            let panel = UDActionPanel(customViewController: vc, config: config)
            present(panel, animated: true, completion: nil)
            registerPanel = panel
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
        var btns: [CustomSubtitleImageControl] = []
        if let registerItem = vm.joinTenantInfo.registerItem, let dispatchList = registerItem.dispatchList {
            dispatchList.forEach { (item) in
                btns.append(CustomSubtitleImageControl(title: item.text, subtitle: item.desc, image: vm.image(by: item.actionType)) { [weak self] in
                    guard let self = self else { return }
                    var click = ""
                    var target = ""
                    switch item.actionType {
                    case .createTenant:
                        click = TrackConst.passportClickTrackCreateTeam
                        target = TrackConst.passportTeamInfoSettingView
                        self.logger.info("n_action_click_create_team")
                    case .createPersonal:
                        click = TrackConst.passportClickTrackPersonalUse
                        target = TrackConst.passportUserInfoSettingView
                        self.logger.info("n_action_click_personal_use")
                    default:
                        break
                    }
                    let params = SuiteLoginTracker.makeCommonClickParams(flowType: self.vm.joinTenantInfo.flowType ?? "", click: click, target: target)
                    SuiteLoginTracker.track(Homeric.PASSPORT_CREATE_TEAM_OR_PERSONAL_USE_CLICK, params: params)
                    self.dismissRegisterPanelIfNeeded {
                        if let nextStep = item.next {
                            self.handleStep(stepData: nextStep)
                        }
                    }
                })
            }
        }
        logger.info("create register item count is \(btns.count)")
        return btns
    }

    func handleStep(stepData: V4StepData) {
        guard let stepName = stepData.stepName else {
            self.logger.error("no step name in V3JoinTenantViewController")
            return
        }

        switch stepData.stepName {
        case PassportStep.joinTenantCode.rawValue:
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.joinTenantInfo.flowType ?? "", click: "input_team_code", target: TrackConst.passportTeamCodeInputView)
            SuiteLoginTracker.track(Homeric.PASSPORT_JOIN_TEAM_CLICK, params: params)
            logger.info("n_action_click_input_team_code")
        case PassportStep.joinTenantScan.rawValue:
            let params = SuiteLoginTracker.makeCommonClickParams(flowType: vm.joinTenantInfo.flowType ?? "", click: "scan_qr_code", target: TrackConst.passportTeamQRCodeScanView)
            SuiteLoginTracker.track(Homeric.PASSPORT_JOIN_TEAM_VIEW, params: params)
            logger.info("n_action_click_scan_qrcode")
        default:
            break
        }

        self.vm.post(
            event: stepName,
            serverInfo: stepData.nextServerInfo(),
            additionalInfo: self.vm.additionalInfo,
            success: {[weak self] in
                self?.logger.info("\(stepName) success")
            }, error: { [weak self] (error) in
                self?.logger.error("\(stepName) failed", error: error)
            })
    }
}

extension V3JoinTenantViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
           // 去除footer 偏移
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? V3JoinTenantTableViewCell
        cell?.updateSelection(true)
        let item = vm.item(indexPath.row)
        if item.needLoading {
            showLoading()
        }
        vm.handleSelect(indexPath.row)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                if item.needLoading {
                    self.stopLoading()
                }
                cell?.updateSelection(false)
            }, onError: { [weak self] (err) in
                guard let `self` = self else { return }
                if item.needLoading {
                    self.stopLoading()
                }
                cell?.updateSelection(false)
                self.handle(err)
            }).disposed(by: self.disposeBag)
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? V3JoinTenantTableViewCell
        cell?.updateSelection(true)
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? V3JoinTenantTableViewCell
        cell?.updateSelection(false)
    }
}

extension V3JoinTenantViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else { return 0 }
        return vm.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: V3JoinTenantTableViewCell.lu.reuseIdentifier,
            for: indexPath
            ) as? V3JoinTenantTableViewCell,
            indexPath.item < vm.items.count else {
            return UITableViewCell()
        }
        cell.updateCell(vm.items[indexPath.item])
        cell.backgroundColor = .clear
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.rowHeight + CL.cardVerticalSpace * 2
    }

}

extension V3JoinTenantViewController {
    struct Layout {
        static let bottomButtonBottomSpace: CGFloat = 16
        static let bottomButtonHeight: CGFloat = 24
        static let bottomLabelTop: CGFloat = 40.0
        static let bottomLabelHeight: CGFloat = 80.0
        static let rowHeight: CGFloat = 80.0
        static let detailLabelHeight: CGFloat = 80.0
        static let topDescriptionTopSpace: CGFloat = Layout.detailLabelHeight + Layout.topSpace
        static let topSpace: CGFloat = 20
    }
}
