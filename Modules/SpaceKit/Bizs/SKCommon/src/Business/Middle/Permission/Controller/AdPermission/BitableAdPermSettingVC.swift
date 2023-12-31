//
//  BitableAdPermSettingVC.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/19.
//
//  swiftlint:disable file_length

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import LarkUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignSwitch
import UIKit
import UniverseDesignNotice
import UniverseDesignButton
import SKInfra

public enum BitableAdPermAddDisableReason {
    case none
    // 付费要求不满足
    case payment
    // 高级权限未打开
    case adPermOff
    
    var addable: Bool {
        switch self {
        case .none:
            return true
        case .payment, .adPermOff:
            return false
        }
    }
}

public enum BitableAdPermEditDisableReason {
    case none
    // 高级权限未打开
    case adPermOff
    
    var editable: Bool {
        switch self {
        case .none:
            return true
        case .adPermOff:
            return false
        }
    }
}

enum BitableAdPermUnitData {
    case temp(_ data: BitableAdPermUnitDataTemp)
    case admin(_ data: BitableAdPermUnitDataAdmin)
    case rule(_ data: BitableAdPermUnitDataRule)
    case empty
    case fallback(_ data: BitableAdPermUnitDataFallback)
}

enum BitableAdPermTagType {
    case none, origin, advance
}

class BitableAdPermUnitDataTemp {
    var rule: BitablePermissionRule
    
    var title: String
    var subTitle: String
    var tagType: BitableAdPermTagType
    
    init(
        rule: BitablePermissionRule,
        title: String,
        subTitle: String,
        tagType: BitableAdPermTagType
    ) {
        self.rule = rule
        self.title = title
        self.subTitle = subTitle
        self.tagType = tagType
    }
}

class BitableAdPermUnitDataAdmin {
    var administrators: [Collaborator]
    
    init(_ administrators: [Collaborator]) {
        self.administrators = administrators
    }
}

class BitableAdPermUnitDataFallback {
    let linkShareEntity: LinkShareEntityV2
    
    let fallbackConfig: BitablePermissionRules.AccessConfig?
    
    let currentFallbackRole: BitablePermissionRule?
    
    let fallbackCollaborators: [Collaborator]
    
    let isEditable: Bool
    
    let isTemplate: Bool
    
    init(
        linkShareEntity: LinkShareEntityV2,
        fallbackConfig: BitablePermissionRules.AccessConfig?,
        currentFallbackRole: BitablePermissionRule?,
        fallbackCollaborators: [Collaborator],
        isEditable: Bool,
        isTemplate: Bool
    ) {
        self.linkShareEntity = linkShareEntity
        self.fallbackConfig = fallbackConfig
        self.currentFallbackRole = currentFallbackRole
        self.fallbackCollaborators = fallbackCollaborators
        self.isEditable = isEditable
        self.isTemplate = isTemplate
    }
}

class BitableAdPermUnitDataRule {
    var rule: BitablePermissionRule
    
    var title: String
    var subTitle: String
    var collaborators: [Collaborator]
    var tagType: BitableAdPermTagType
    var addedAvailability: BitableAdPermAddDisableReason
    var managedAvailability: BitableAdPermEditDisableReason

    init(
        rule: BitablePermissionRule,
        tilte: String,
        subTitle: String,
        collaborators: [Collaborator],
        tagType: BitableAdPermTagType,
        addedAvailability: BitableAdPermAddDisableReason,
        managedAvailability: BitableAdPermEditDisableReason
    ) {
        self.rule = rule
        self.title = tilte
        self.subTitle = subTitle
        self.collaborators = collaborators
        self.tagType = tagType
        self.addedAvailability = addedAvailability
        self.managedAvailability = managedAvailability
    }
}

private enum PermSwitchPreOpenAction {
    case openAndKeep
    case openAndClearRoles
    case cancel
}

private enum PermSwitchPreCloseAction {
    case confirm
    case cancel
}
// 前端数据结构部分
enum PermissionUpdateStatus: String {
    case ReadyToUpdate
    case Updated
}
enum PermissionUpdateStatusError: String, Error {
    case hasNoModel
    case hasNoResult
    case hasNoStatus
    case newPermissionUpdateStatusError
}

public protocol BitableAdPermSettingVCDelegate: AnyObject {
    var jsService: SKExecJSFuncService? { get }
    
    func bitableAdPermBridgeDataDidChange(_ vc: BitableAdPermSettingVC, data: BitableBridgeData)
}

extension BitableAdPermSettingVCDelegate {
    public func bitableAdPermBridgeDataDidChange(_ vc: BitableAdPermSettingVC, data: BitableBridgeData) {}
}

public final class BitableAdPermSettingVC: BaseViewController, UDNoticeDelegate, AdPermUpdateVCDelegate {
    
    public weak var delegate: BitableAdPermSettingVCDelegate?

    private let docsInfo: DocsInfo
    private var permStatistics: PermissionStatistics?
    private let token: String
    private let initialBridgeData: BitableBridgeData
    private var rules: BitablePermissionRules?
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var datas = [BitableAdPermUnitData]()
    private let isTemplate: Bool
    private var isAdPermEnabled: Bool {
        didSet {
            adPermEnabledDidChange()
        }
    }
    private var allCollaborators: [Collaborator] = []
    private var administrators: [Collaborator]?
    private var costInfo: BitablePermissionCostInfo?
    private let needCloseBarItem: Bool
    private var rulesRequest: DocsRequest<JSON>?
    private var costRequest: DocsRequest<JSON>?
    private var crMebRequest: DocsRequest<JSON>?
    private var upgradeRequest: DocsRequest<JSON>?
    private weak var hostViewController: UIViewController?
    
    private let permOpQueue = DispatchQueue(label: "com.lark.bitable.permOperation")
    private var permOpSemaphore: DispatchSemaphore?
    private var permOpResult: [AnyHashable: Any]?
    
    private var needAutoSelectNewCreatedFallbackRole = false
    
    private var openDefaultRole: Bool = false

    private lazy var listEmptyView = UDEmptyView(config: listEmptyConfig).construct { it in
        it.backgroundColor = UDColor.bgFloatBase
        it.useCenterConstraints = true
    }

    private let listEmptyConfig = UDEmptyConfig(
        title: .init(titleText: BundleI18n.SKResource.Bitable_AdvancedPermission_EmptyStatusTitle),
        description: .init(descriptionText: BundleI18n.SKResource.Bitable_AdvancedPermission_EmptyStatusText),
        type: .ccmEditorLimit,
        labelHandler: nil,
        primaryButtonConfig: nil,
        secondaryButtonConfig: nil
    )
    
    private lazy var permSwitchHeader: BitableAdPermSwitchHeader = {
        // 非模板情况下，只有 FA 能进入设置页，因此只需要判断非模板就 showSwitch
        BitableAdPermSwitchHeader(
            showSwitch: !isTemplate,
            initialSwitchState: initialBridgeData.isPro
        )
    }()
    // 多维表格设置需要在升级的时候展示升级notice
    private lazy var notice: UDNotice = {
        var noticeCfg = UDNoticeUIConfig(backgroundColor: UDColor.functionSuccessFillSolid02, attributedText: NSAttributedString(string: BundleI18n.SKResource.Bitable_AdvancedPermission_YouCanUpgradeAdvancedPermission_Title))
        noticeCfg.leadingIcon = UDIcon.softwareUpdateColorful
        noticeCfg.leadingButtonText = BundleI18n.SKResource.Bitable_AdvancedPermission_GoToUpgrade_Button
        var view = UDNotice(config: noticeCfg)
        view.delegate = self
        return view
    }()
    public func handleLeadingButtonEvent(_ button: UIButton) {
        // 立刻升级按钮点击
        getProUpdateEffectData { result in
            switch result {
            case .success(let effectData):
                // 需要展示，从nav present
                let vc = AdPermUpdateVC(vcMode: .canUpdata, info: effectData.effectFormulaInfo, dele: self)
                vc.modalPresentationStyle = .overFullScreen
                if SKDisplay.pad {
                    vc.modalPresentationStyle = .formSheet
                }
                self.navigationController?.present(vc, animated: false)
                self.permStatistics?.reportBitablePremiumPermissionCalculationTypeView(params: [
                    "calculation_type": "frontend"
                ])
            case.failure(_):
                break // 底层已经打了日志，避免重复打
            }
        }
        self.permStatistics?.reportBitablePremiumPermissionSettingClick(action: .upgrade, isTemplate: self.isTemplate, params: nil)
    }
    public func handleTrailingButtonEvent(_ button: UIButton) {}
    public func handleTextButtonEvent(URL: URL, characterRange: NSRange) {}
    func reqProStatus() {
        guard UserScopeNoChangeFG.WJS.bitableRemoteComputeUpgrade else {
            DocsLogger.info("UserScopeNoChangeFG.WJS.bitableRemoteComputeUpgrade is false, not getProUpdateStatus")
            return
        }
        if datas.isEmpty {
            // 主流程数据没加载出来
            DocsLogger.error("datas.isEmpty cancel getProUpdateStatus")
            return
        }
        getProUpdateStatus { result in
            switch result {
            case .success(let status):
                if status == .ReadyToUpdate {
                    self.notice.snp.remakeConstraints { make in
                        make.top.equalTo(self.navigationBar.snp.bottom)
                        make.left.right.equalToSuperview()
                    }
                    self.permStatistics?.reportBitablePremiumPermissionBackendUpgradeTipsView()
                } else {
                    self.notice.snp.remakeConstraints { make in
                        make.top.equalTo(self.navigationBar.snp.bottom)
                        make.left.right.equalToSuperview()
                        make.height.equalTo(0)
                    }
                }
            case.failure(_):
                self.notice.snp.remakeConstraints { make in
                    make.top.equalTo(self.navigationBar.snp.bottom)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(0)
                }
            }
        }
    }
    func getProUpdateStatus(resultHandler: @escaping (Result<PermissionUpdateStatus, Error>) -> Void) {
        guard let jsService = delegate?.jsService else {
            resultHandler(.failure(PermissionUpdateStatusError.hasNoModel))
            DocsLogger.error("getProUpdateStatus error ,model is nil")
            return
        }
        jsService.callFunction(.getProUpdateStatus, params: nil, completion: { result, error in
            if let error = error {
                DocsLogger.error("getProUpdateStatus error", error: error)
                resultHandler(.failure(error))
                return
            }
            guard let result = result as? [AnyHashable: Any] else {
                DocsLogger.error("getProUpdateStatus error, has no result")
                resultHandler(.failure(PermissionUpdateStatusError.hasNoResult))
                return
            }
            guard let statusString = result["status"] as? String else {
                DocsLogger.error("getProUpdateStatus error, has no status")
                resultHandler(.failure(PermissionUpdateStatusError.hasNoStatus))
                return
            }
            guard let status = PermissionUpdateStatus(rawValue: statusString) else {
                DocsLogger.error("getProUpdateStatus error, new PermissionUpdateStatus error, statusString is \(statusString)")
                resultHandler(.failure(PermissionUpdateStatusError.newPermissionUpdateStatusError))
                return
            }
            DocsLogger.info("[SYNC] js getProUpdateStatus result: \(statusString)")
            resultHandler(.success(status))
        })
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            BitableAdPermTempCell.self,
            forCellWithReuseIdentifier: BitableAdPermTempCell.defaultReuseID
        )
        collectionView.register(
            BitableAdPermAdminCell.self,
            forCellWithReuseIdentifier: BitableAdPermAdminCell.defaultReuseID
        )
        collectionView.register(
            BitableAdPermRuleCell.self,
            forCellWithReuseIdentifier: BitableAdPermRuleCell.defaultReuseID
        )
        collectionView.register(
            BitableAdPermEmptyCell.self,
            forCellWithReuseIdentifier: BitableAdPermEmptyCell.defaultReuseID
        )
        collectionView.register(
            BitableAdPermBaseCell.self,
            forCellWithReuseIdentifier: BitableAdPermBaseCell.unknownReuseID
        )
        collectionView.register(
            BitableAdPermFallbackCell.self,
            forCellWithReuseIdentifier: BitableAdPermFallbackCell.defaultReuseID
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    public init(
        docsInfo: DocsInfo,
        bridgeData: BitableBridgeData,
        delegate: BitableAdPermSettingVCDelegate?,
        needCloseBarItem: Bool,
        permStatistics: PermissionStatistics?,
        openDefaultRole: Bool = false
    ) {
        self.docsInfo = docsInfo
        self.token = docsInfo.objToken
        self.initialBridgeData = bridgeData
        self.permStatistics = permStatistics
        self.needCloseBarItem = needCloseBarItem
        self.delegate = delegate
        self.isTemplate = (docsInfo.templateType?.isTemplate == true)
        self.isAdPermEnabled = initialBridgeData.isPro
        self.openDefaultRole = openDefaultRole
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        var params: [String: Any] = [:]
        params["role_id"] = rules?.accessConfig?.defaultConfig.roleId
        params["is_default_role_visit_allow"] = rules?.accessConfig?.defaultConfig.accessStrategy == .forbidden ? "false" : "true"
        permStatistics?.reportBitablePremiumPermissionSettingClick(
            action: .back,
            isTemplate: isTemplate,
            params: params
        )
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.SKResource.Bitable_AdvancedPermission_Setting
        setupView()
        loadData(loading: true) { [weak self] in
            guard let self = self else { return }
            if self.openDefaultRole && self.isAdPermEnabled {
                // 只有高级权限开启时候，才根据 URL 调起配置面板
                self.openDefaultRole = false
                self.presentFallbackConfigPanel()
            }
        }
//        tracker.reportShowPermissionPage()
        addNotification()
        permStatistics?.reportBitablePremiumPermissionSettingView(isTemplate: isTemplate)
        hostViewController = presentingViewController
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    public override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupView() {
        statusBar.backgroundColor = UDColor.bgFloatBase
        navigationBar.customizeBarAppearance(backgroundColor: UDColor.bgFloatBase, itemForegroundColorMapping: nil, separatorColor: nil)
        view.backgroundColor = UDColor.bgFloatBase
        view.insertSubview(listEmptyView, belowSubview: navigationBar)
        view.insertSubview(collectionView, belowSubview: navigationBar)
        view.insertSubview(permSwitchHeader, belowSubview: navigationBar)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            view.insertSubview(notice, belowSubview: navigationBar)
        }
        
        listEmptyView.isHidden = true
        collectionView.isHidden = true
        permSwitchHeader.isHidden = true
        
        permSwitchHeader.permSwitch.valueWillChanged = { [weak self] value in
            guard let self = self else { return }
            if value {
                self.tryOpenAdPerm()
            } else {
                self.permStatistics?.reportBitablePremiumPermissionSettingClick(action: .adPermTurnOff, isTemplate: self.isTemplate)
                self.tryCloseAdPerm()
            }
        }
        
        listEmptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            notice.snp.remakeConstraints { make in
                make.top.equalTo(navigationBar.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(0)
            }
        }
        permSwitchHeader.snp.makeConstraints { make in
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                make.top.equalTo(notice.snp.bottom).offset(16)
            } else {
                make.top.equalTo(navigationBar.snp.bottom).offset(16)
            }
            make.left.right.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(permSwitchHeader.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        }
        addCloseBarItemIfNeed()
    }
    
    private func addCloseBarItemIfNeed() {
        guard needCloseBarItem else { return }
        let btnItem = SKBarButtonItem(image: UDIcon.closeSmallOutlined,
                                      style: .plain,
                                      target: self,
                                      action: #selector(didClickedCloseBarItem))
        btnItem.id = .close
        self.navigationBar.leadingBarButtonItem = btnItem
    }

    private func addNotification() {
        NotificationCenter.default.addObserver(self,
                                           selector: #selector(handleReceiveBitableRulesUpdateNotification),
                                           name: Notification.Name.Docs.bitableRulesUpdate,
                                           object: nil)
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReceiveBitableRulesRemoveSuccessNotification),
                                               name: Notification.Name.Docs.bitableRulesRemoveSuccess,
                                               object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didReviceSSCUpgrade(_:)),
                                                   name: .SSCUpgradeNotification,
                                                   object: nil)
        }
    }

    @objc
    func handleReceiveBitableRulesUpdateNotification() {
        DispatchQueue.main.async {
            self.loadData()
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) { // 避免动画冲突
                    self.checkProUpdateEffectData()
                }
            }
        }
    }
    @objc
    func handleReceiveBitableRulesRemoveSuccessNotification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) { // 避免动画冲突
            self.checkProUpdateEffectData()
        }
    }
    func checkProUpdateEffectData() {
        getProUpdateEffectData { result in
            switch result {
            case .success(let effectData):
                if !OnboardingManager.shared.hasFinished(OnboardingID.bitablePermissionUpgradeSsc) {
                    // 需要展示，从nav present
                    let vc = AdPermUpdateVC(vcMode: .updated, info: effectData.effectFormulaInfo, dele: self)
                    vc.modalPresentationStyle = .overFullScreen
                    if SKDisplay.pad {
                        vc.modalPresentationStyle = .formSheet
                    }
                    self.navigationController?.present(vc, animated: false)
                    self.permStatistics?.reportBitablePremiumPermissionCalculationTypeView(params: [
                        "calculation_type": "backend"
                    ])
                } else {
                    DocsLogger.info("getProUpdateEffectData and bitable_permission_upgrade_ssc is finished")
                    // 不需要展示
                }
            case.failure(_):
                break
            }
        }
    }
    func clickUpdateButton(vc: UIViewController) {
        vc.dismiss(animated: false) { [weak self] in
            self?.delegate?.jsService?.callFunction(.upgradeSSC, params: [:], completion: { _, _ in
                
            })
        }
        self.permStatistics?.reportBitablePremiumPermissionCalculationTypeClick(params: [
            "click": "upgrade"
        ])
    }
    func clickLaterButton(vc: UIViewController) {
        self.permStatistics?.reportBitablePremiumPermissionCalculationTypeClick(params: [
            "click": "cancel"
        ])
        vc.dismiss(animated: false)
    }
    func clickKnownButton(vc: UIViewController) {
        OnboardingManager.shared.markFinished(for: [OnboardingID.bitablePermissionUpgradeSsc])
        self.permStatistics?.reportBitablePremiumPermissionCalculationTypeClick(params: [
            "click": "known"
        ])
        vc.dismiss(animated: false)
    }
    func getProUpdateEffectData(resultHandler: @escaping (Result<ProUpdateEffectData, Error>) -> Void) {
        guard UserScopeNoChangeFG.WJS.bitableRemoteComputeUpgrade else {
            DocsLogger.info("UserScopeNoChangeFG.WJS.bitableRemoteComputeUpgrade is false, not getProUpdateEffectData")
            return
        }
        guard let jsService = delegate?.jsService else {
            resultHandler(.failure(PermissionUpdateStatusError.hasNoModel))
            DocsLogger.error("getProUpdateEffectData error ,model is nil")
            return
        }
        jsService.callFunction(.getProUpdateEffectData, params: nil, completion: { result, error in
            if let error = error {
                DocsLogger.error("getProUpdateEffectData error", error: error)
                resultHandler(.failure(error))
                return
            }
            guard let result = result as? [AnyHashable: Any] else {
                DocsLogger.error("getProUpdateEffectData error, has no result")
                resultHandler(.failure(ProUpdateEffectDataError.hasNoResult))
                return
            }
            guard JSONSerialization.isValidJSONObject(result) else {
                DocsLogger.error("getProUpdateEffectData error, inValidJSONObject")
                resultHandler(.failure(ProUpdateEffectDataError.inValidJSONObject))
                return
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: result)
                let decoder = JSONDecoder()
                let da = try decoder.decode(ProUpdateEffectData.self, from: data)
                resultHandler(.success(da))
            } catch {
                DocsLogger.error("getProUpdateEffectData error, JSONSerialization.data or decode error", error: error)
                resultHandler(.failure(ProUpdateEffectDataError.dataWithJSONObjectOrDecode))
                return
            }
        })
    }
    @objc func didReviceSSCUpgrade(_ notification: Notification) {
        if let result = notification.userInfo as? [String: Any],
           let isSuccess = result["success"] as? Bool,
           isSuccess {
            let isIPad = self.isMyWindowRegularSizeInPad
            if isIPad {
                self.dismiss(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    @objc
    func didClickedCloseBarItem() {
        if preventDismissWhenFallbackConfigNotSet() {
            return
        }
        dismiss(animated: true, completion: nil)
    }

    public override func backBarButtonItemAction() {
        if preventDismissWhenFallbackConfigNotSet() {
            return
        }
        super.backBarButtonItemAction()
    }
    
    private func preventDismissWhenFallbackConfigNotSet() -> Bool {
        guard UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance else {
            return false
        }
        guard !isTemplate, isAdPermEnabled, let roles = rules, !roles.isFallbackConfigProperlySet else {
            return false
        }
        if UserScopeNoChangeFG.ZYS.baseAdPermAggressiveDefaultPolicy {
            if let fallbackConfig = getFallbackCell()?.fallbackContext.fallbackConfig {
                roles.updateFallbackConfig(fallbackConfig)
                if roles.isFallbackConfigProperlySet {
                    permissionManager.updateBitableFallbackRoleConfig(token: token, config: fallbackConfig.defaultConfig) { _ in }
                    return false
                }
            }
        }
        
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_AdvancedPermissionsInherit_NotAssignedRoles_ForOtherCollaborators_Title)
        dialog.setContent(text: BundleI18n.SKResource.Bitable_AdvancedPermissions_AccessWith_SelectRole_Placeholder)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_AdvancedPermission_SetAdvancedPerm, dismissCompletion: { [weak self] in
            self?.presentFallbackConfigPanel()
        })
        self.present(dialog, animated: true)
        return true
    }
    
    private func adPermEnabledDidChange() {
        let data = BitableBridgeData(isPro: isAdPermEnabled, tables: initialBridgeData.tables)
        delegate?.bitableAdPermBridgeDataDidChange(self, data: data)
    }
}

extension BitableAdPermSettingVC: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == navigationController?.interactivePopGestureRecognizer else {
            return false
        }
        
        if preventDismissWhenFallbackConfigNotSet() {
            return false
        }
        return true
    }
}

// MARK: - data 相关
extension BitableAdPermSettingVC {
    func loadData(loading: Bool = false, updateAdmin: Bool = true, updateCost: Bool = true, updateRules: Bool = true, updatePublicPermission: Bool = true, completion: (() -> Void)? = nil) {
        DocsLogger.info("[BAP] load page data start, admin: \(updateAdmin), cost: \(updateCost), rules: \(updateRules)")
        if loading {
            showLoading(duration: 0, isBehindNavBar: true, backgroundAlpha: 0.05)
        }
        let group = DispatchGroup()
        let queue = DispatchQueue.global()
        if updateAdmin {
            group.enter()
            queue.async(execute: {
                self.permissionManager.fetchAllBitableCollaborators(token: self.token) { result in
                    switch result {
                    case .success(let data):
                        self.allCollaborators = data
                        self.administrators = data.filter({ $0.userPermissions.isFA })
                    case .failure:
                        break
                    }
                    group.leave()
                }
            })
        }
        if updateCost {
            group.enter()
            queue.async(execute: {
                self.costRequest = self.permissionManager.fetchBitableCostInfo(token: self.token) { result in
                    switch result {
                    case .success(let info):
                        self.costInfo = info
                    case .failure:
                        break
                    }
                    group.leave()
                }
            })
        }
        if updateRules {
            group.enter()
            queue.async(execute: {
                self.rulesRequest = self.permissionManager.fetchBitableRulesInfo(token: self.token, bridgeData: self.initialBridgeData, completion: { result in
                    switch result {
                    case .success(let data):
                        self.rules = data
                    case .failure:
                        break
                    }
                    group.leave()
                })
            })
        }
        if updatePublicPermission {
            if permissionManager.getPublicPermissionMeta(token: token) == nil {
                group.enter()
                queue.async(execute: {
                    self.permissionManager.fetchPublicPermissions(token: self.token, type: self.docsInfo.inherentType.rawValue) { _, _ in
                        group.leave()
                    }
                })
            }
        }
        group.notify(queue: DispatchQueue.main, execute: {
            self.hideLoading()
            self.buildData()
            self.updateUI()
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                if loading {
                    self.reqProStatus()
                }
            }
            completion?()
        })
    }
    
    private func buildData() {
        guard let administrators = administrators, let rules = rules, let costInfo = costInfo else {
            self.datas = []
            return
        }
        
        var arr = [BitableAdPermUnitData]()
        
        if !administrators.isEmpty {
            let adminData = BitableAdPermUnitDataAdmin(administrators)
            arr.append(.admin(adminData))
        } else {
            DocsLogger.error("[BAP] empty administrators!")
        }

        rules.allRoles.forEach({ rule in
            let tagType: BitableAdPermTagType
            let isCustomRow = rule.tables.contains(where: { $0.advanceRowPerm })
            let canUseCustomRow = (costInfo.rowPermitted == true)
            let isCustomField = rule.tables.contains(where: { $0.advanceFieldPerm })
            let canUseCustomField = (costInfo.fieldPermitted == true)
            if (isCustomRow && !canUseCustomRow) || (isCustomField && !canUseCustomField) {
                tagType = .advance
            } else if rule.ruleType.defaultRule {
                tagType = .origin
            } else {
                tagType = .none
            }
            
            if self.isTemplate {
                let tempData = BitableAdPermUnitDataTemp(
                    rule: rule,
                    title: rule.name,
                    subTitle: rule.ruleDes,
                    tagType: tagType
                )
                arr.append(.temp(tempData))
            } else {
                let addedAvailability: BitableAdPermAddDisableReason
                let managedAvailability: BitableAdPermEditDisableReason
                
                if !self.isAdPermEnabled {
                    addedAvailability = .adPermOff
                    managedAvailability = .adPermOff
                } else {
                    if tagType == .advance {
                        addedAvailability = .payment
                    } else {
                        addedAvailability = .none
                    }
                    managedAvailability = .none
                }
                
                let ruleData = BitableAdPermUnitDataRule(
                    rule: rule,
                    tilte: rule.name,
                    subTitle: rule.ruleDes,
                    collaborators: rule.collaborators,
                    tagType: tagType,
                    addedAvailability: addedAvailability,
                    managedAvailability: managedAvailability
                )
                arr.append(.rule(ruleData))
            }
        })
        
        if rules.isEmpty {
            arr.append(.empty)
        }
        
        if UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance {
            let config: BitablePermissionRules.AccessConfig
            let fallbackRole: BitablePermissionRule?
            
            if let existConfig = rules.accessConfig {
                // 已存在 fallback 配置，直接选中
                config = existConfig
                fallbackRole = rules.allRoles.first(where: { $0.ruleID == existConfig.defaultConfig.roleId })
            } else {
                // 没有已存在 fallback 配置，创建一个
                if UserScopeNoChangeFG.ZYS.baseAdPermAggressiveDefaultPolicy && needAutoSelectNewCreatedFallbackRole {
                    needAutoSelectNewCreatedFallbackRole = false
                    let newCreatedName = BundleI18n.SKResource.Bitable_AdvancedPermissions_AccessWith_DefaultRole_Text
                    if let newCreatedRole = rules.allRoles.first(where: { $0.name == newCreatedName }) {
                        // 开启了激进策略，并且用户是首次开启高级权限，帮他选中开启时创建的默认角色
                        config = .init(defaultConfig: .init(accessStrategy: .bindRule, roleId: newCreatedRole.ruleID))
                        fallbackRole = newCreatedRole
                    } else {
                        // 是首次开启高级权限，但是没找到创建的角色，理论上不会出现这种情况，兜底创建空策略
                        config = .init(defaultConfig: .init(accessStrategy: .bindRule, roleId: nil))
                        fallbackRole = nil
                    }
                } else {
                    // 没有开启激进策略，或者不是在移动端首次开启，创建空策略，显示「请选择」
                    config = .init(defaultConfig: .init(accessStrategy: .bindRule, roleId: nil))
                    fallbackRole = nil
                }
            }
            let membersInRoles = Set(rules.allRoles.flatMap({ $0.collaborators }))
            let membersToFallback = allCollaborators.filter({ !$0.userPermissions.isFA && !membersInRoles.contains($0) && $0.type != .app })
            arr.append(.fallback(BitableAdPermUnitDataFallback(
                linkShareEntity: permissionManager.getPublicPermissionMeta(token: token)?.linkShareEntityV2 ?? .close,
                fallbackConfig: config,
                currentFallbackRole: fallbackRole,
                fallbackCollaborators: membersToFallback,
                isEditable: !isTemplate && isAdPermEnabled,
                isTemplate: isTemplate
            )))
        }
        
        DocsLogger.info("[BAP] data build end: \(arr), isTemp: \(isTemplate), permOn: \(isAdPermEnabled)")
        self.datas = arr
    }
    
    private func updateUI() {
        let showEmpty = datas.isEmpty
        permSwitchHeader.isHidden = showEmpty
        collectionView.isHidden = showEmpty
        listEmptyView.isHidden = !showEmpty
        
        collectionView.reloadData()
    }
}

// MARK: - nav

extension BitableAdPermSettingVC {
    private func toAddCollaboratorVC(
        from: UIViewController,
        rule: BitablePermissionRule
    ) {
        let allCollaborators = permissionManager.getCollaborators(for: token, collaboratorSource: .defaultType)
        let wikiMembers = allCollaborators?.filter({ $0.type == .newWikiMember })
        
        let fileModel = CollaboratorFileModel(
            objToken: token,
            docsType: .bitable,
            title: "",
            isOWner: docsInfo.isOwner,
            ownerID: docsInfo.ownerID ?? "",
            displayName: "",
            spaceID: "",
            folderType: nil,
            tenantID: docsInfo.tenantID ?? "",
            createTime: docsInfo.createTime ?? 0,
            createDate: docsInfo.createDate ?? "",
            creatorID: docsInfo.creatorID ?? "",
            enableTransferOwner: true,
            formMeta: nil
        )
        let viewModel = CollaboratorSearchViewModel(
            existedCollaborators: rule.collaborators,
            selectedItems: [],
            wikiMembers: wikiMembers,
            fileModel: fileModel,
            lastPageLabel: nil,
            statistics: nil,
            userPermission: nil,
            publicPermisson: nil,
            isBitableAdvancedPermissions: true,
            bitablePermissonRule: rule
        )
        let dependency = CollaboratorSearchVCDependency(
            statistics: nil,
            permStatistics: permStatistics,
            needShowOptionBar: false
        )
        var inviteSrc: CollaboratorInviteSource = .sharePanel
        if from is BitableCollaboratorEditViewController {
            inviteSrc = .collaboratorEdit
        }
        let uiConfig = CollaboratorSearchVCUIConfig(
            needActivateKeyboard: true,
            source: inviteSrc
        )
        let vc = CollaboratorSearchViewController(
            viewModel: viewModel,
            dependency: dependency,
            uiConfig: uiConfig
        )
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .formSheet
        from.present(navVC, animated: true, completion: nil)
    }
    
    private func toRuleDisplayVC(rule: BitablePermissionRule) {
        let vc = BitableAdvancedPermissionsRuleVC(rule: rule, permStatistics: self.permStatistics)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func toRuleEditVC(unit: BitableAdPermUnitDataRule) {
        let vc = BitableCollaboratorEditViewController(
            token: token,
            bridgeData: initialBridgeData,
            rule: unit.rule,
            delegate: self,
            permStatistics: permStatistics,
            addAvailability: unit.addedAvailability
        )
        vc.watermarkConfig.needAddWatermark = self.watermarkConfig.needAddWatermark
            self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentFallbackConfigPanel() {
        guard let roles = rules else {
            return
        }
        let vc = BitableAdPermFallbackVC(roles: roles, dismissCallback: { [weak self] result in
            guard let self = self else { return }
            DocsLogger.info("[BAP] ad perm role fallback config did update")
            let config: BitablePermissionRules.AccessConfig.Config?
            switch result {
            case .role(let role):
                config = .init(accessStrategy: .bindRule, roleId: role.ruleID)
            case .forbidden:
                config = .init(accessStrategy: .forbidden, roleId: nil)
            case .empty:
                config = nil
            }
            guard let config = config, config != roles.accessConfig?.defaultConfig else {
                DocsLogger.info("[BAP] ad perm role fallback config not change")
                return
            }
            self.permStatistics?.reportBitablePremiumPermissionSettingClick(
                action: .roleDistributionByDefault,
                isTemplate: self.isTemplate,
                params: [
                    "is_visit_allow": config.accessStrategy == .forbidden ? "false" : "true"
                ]
            )
            self.updateFallbackConfig(config)
        })
        present(vc, animated: true)
    }
    
    private func updateFallbackConfig(_ config: BitablePermissionRules.AccessConfig.Config) {
        getFallbackCell()?.isLoading = true
        permissionManager.updateBitableFallbackRoleConfig(token: token, config: config) { [weak self] error in
            guard let self = self else {
                return
            }
            self.getFallbackCell()?.isLoading = false
            if error != nil {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Common_UnableToSave, on: self.toastView, dismissCallBack: { [weak self] in
                    self?.loadData()
                })
            } else {
                UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_SaveCustomTemplSuccess, on: self.toastView)
                self.rules?.updateFallbackConfig(.init(defaultConfig: config))
                self.buildData()
                self.updateUI()
            }
        }
    }
    
    private func getFallbackCell() -> BitableAdPermFallbackCell? {
        guard let index = datas.firstIndex(where: { data in
            if case .fallback = data {
                return true
            }
            return false
        }) else {
            return nil
        }
        let indexPath = IndexPath(item: index, section: 0)
        let cell = collectionView.cellForItem(at: indexPath) as? BitableAdPermFallbackCell
        return cell
    }
}

// MARK: - Ad Perm Modify

extension BitableAdPermSettingVC {
    private func tryOpenAdPerm() {
        guard rules?.allRoles.contains(where: { !$0.collaborators.isEmpty }) == true else {
            // rules == nil || rules.isEmpty == true || All rule members are empty
            DocsLogger.info("[BAP] tryOpenAdPerm without dialog, rules count: \(rules?.allRoles.count ?? -1)")
            UDToast.showLoading(
                with: BundleI18n.SKResource.Bitable_AdavancedPermission_TuringOnToast_Mobile,
                on: self.toastView,
                disableUserInteraction: true
            )
            jsUpdatePermissionState(to: true, completion: { ret in
                UDToast.removeToast(on: self.toastView)
                self.handleJSAdPermOpenResult(ret, keepRoles: true)
            })
            return
        }
        showOpenAdPermPreDialog { action in
            switch action {
            case .openAndKeep:
                DocsLogger.info("[BAP] tryOpenAdPerm and keep")
                UDToast.showLoading(
                    with: BundleI18n.SKResource.Bitable_AdavancedPermission_TuringOnToast_Mobile,
                    on: self.toastView,
                    disableUserInteraction: true
                )
                self.jsUpdatePermissionState(to: true) { ret in
                    UDToast.removeToast(on: self.toastView)
                    self.handleJSAdPermOpenResult(ret, keepRoles: true)
                }
            case .openAndClearRoles:
                DocsLogger.info("[BAP] tryOpenAdPerm but clear")
                UDToast.showLoading(
                    with: BundleI18n.SKResource.Bitable_AdavancedPermission_TuringOnToast_Mobile,
                    on: self.toastView,
                    disableUserInteraction: true
                )
                self.jsUpdatePermissionState(to: true) { ret in
                    self.handleJSAdPermOpenResult(ret, keepRoles: false)
                }
            case .cancel:
                DocsLogger.info("[BAP] tryOpenAdPerm but cancel")
                // stopAnimating() 不能刷新 backgroundColor，只能设置 isEnabled 刷新 state
                self.permSwitchHeader.permSwitch.isEnabled = true
            }
        }
    }
    
    private func handleJSAdPermOpenResult(_ result: Bool, keepRoles: Bool) {
        DocsLogger.info("[BAP] handleJSAdPermOpenResult reslut: \(result), keepRoles: \(keepRoles)")
        if result {
            self.isAdPermEnabled = true
            self.permSwitchHeader.permSwitch.setOn(true, animated: true)
            if !keepRoles {
                self.crMebRequest = self.permissionManager.clearBitableAdPermMembers(token: self.token) { error in
                    UDToast.removeToast(on: self.toastView)
                    if let err = error {
                        DocsLogger.error("[BAP] clearBitableAdPermMembers fail", error: err)
                        UDToast.showFailure(
                            with: BundleI18n.SKResource.Bitable_AdvancedPermission_FailedToClearMember_Mobile,
                            operationText: BundleI18n.SKResource.Bitable_Common_ButtonRetry,
                            on: self.toastView,
                            operationCallBack: { _ in
                                DocsLogger.info("[BAP] clearBitableAdPermMembers retry!")
                                UDToast.removeToast(on: self.toastView)
                                UDToast.showLoading(
                                    with: BundleI18n.SKResource.Bitable_AdavancedPermission_TuringOnToast_Mobile,
                                    on: self.toastView,
                                    disableUserInteraction: true
                                )
                                self.handleJSAdPermOpenResult(true, keepRoles: false)
                            }
                        )
                    } else {
                        DocsLogger.error("[BAP] clearBitableAdPermMembers success!")
                        self.rules?.allRoles.forEach({ $0.removeAllMembers() })
                        UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_AdavancedPermission_TurnedOnoast_Mobile, on: self.toastView)
                    }
                    self.reloadDataAfterAdPermTurnOn()
                }
            } else {
                UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_AdavancedPermission_TurnedOnoast_Mobile, on: self.toastView)
                self.reloadDataAfterAdPermTurnOn()
            }
        } else {
            self.isAdPermEnabled = false
            self.permSwitchHeader.permSwitch.isEnabled = true
            UDToast.showFailure(
                with: BundleI18n.SKResource.Bitable_AdavancedPermission_FailedToTurnOnToast_Mobile,
                operationText: BundleI18n.SKResource.Bitable_Common_ButtonRetry,
                on: self.toastView,
                operationCallBack: { _ in
                    DocsLogger.info("[BAP] js open ad perm retry!")
                    UDToast.removeToast(on: self.toastView)
                    UDToast.showLoading(
                        with: BundleI18n.SKResource.Bitable_AdavancedPermission_TuringOnToast_Mobile,
                        on: self.toastView,
                        disableUserInteraction: true
                    )
                    self.jsUpdatePermissionState(to: true) { ret in
                        self.handleJSAdPermOpenResult(ret, keepRoles: keepRoles)
                    }
                }
            )
            self.buildData()
            self.updateUI()
        }
    }
    
    private func reloadDataAfterAdPermTurnOn() {
        if self.needAutoSelectNewCreatedFallbackRole {
            // 客户端开启高级权限时创建了默认角色，需要刷新 roles
            self.loadData(updateAdmin: false, updateCost: false, updatePublicPermission: false)
        } else {
            // 不需要更新 roles 时候，直接重新重新构建本地数据刷新即可
            self.buildData()
            self.updateUI()
        }
    }
    
    private func tryCloseAdPerm() {
        showCloseAdPermPreDialog { action in
            switch action {
            case .confirm:
                DocsLogger.info("[BAP] tryCloseAdPerm confirm")
                UDToast.showLoading(
                    with: BundleI18n.SKResource.Bitable_AdavancedPermission_TurningOffToast_Mobile,
                    on: self.toastView,
                    disableUserInteraction: true
                )
                self.jsUpdatePermissionState(to: false) { ret in
                    UDToast.removeToast(on: self.toastView)
                    self.handleJSAdPermCloseResult(ret)
                }
            case .cancel:
                DocsLogger.info("[BAP] tryCloseAdPerm cancel")
                // stopAnimating() 不能刷新 backgroundColor，只能设置 isEnabled 刷新 state
                self.permSwitchHeader.permSwitch.isEnabled = true
            }
        }
    }
    
    private func handleJSAdPermCloseResult(_ result: Bool) {
        DocsLogger.info("[BAP] handleJSAdPermCloseResult, result: \(result)")
        if result {
            self.isAdPermEnabled = false
            self.permSwitchHeader.permSwitch.setOn(false, animated: true)
            UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_AdavancedPermission_TurnedOffToast_Mobile, on: self.toastView)
        } else {
            self.isAdPermEnabled = true
            self.permSwitchHeader.permSwitch.isEnabled = true
            UDToast.showFailure(
                with: BundleI18n.SKResource.Bitable_AdavancedPermission_FailedToTurnOffToast_Mobile,
                operationText: BundleI18n.SKResource.Bitable_Common_ButtonRetry,
                on: self.toastView,
                operationCallBack: { _ in
                    DocsLogger.info("[BAP] handleJSAdPermCloseResult retry!")
                    UDToast.removeToast(on: self.toastView)
                    UDToast.showLoading(
                        with: BundleI18n.SKResource.Bitable_AdavancedPermission_TurningOffToast_Mobile,
                        on: self.toastView,
                        disableUserInteraction: true
                    )
                    self.jsUpdatePermissionState(to: false) { ret in
                        UDToast.removeToast(on: self.toastView)
                        self.handleJSAdPermCloseResult(ret)
                    }
                }
            )
        }
        self.buildData()
        self.updateUI()
    }
    
    private func showOpenAdPermPreDialog(_ callback: @escaping (PermSwitchPreOpenAction) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_AdvancedPermission_KeepRolePopup)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_AdvancedPermission_KeepRolePopupButtonYes, dismissCompletion: {
            callback(.openAndKeep)
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_AdvancedPermission_KeepRolePopupButtonNo, dismissCompletion: {
            callback(.openAndClearRoles)
        })
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCompletion: {
            callback(.cancel)
        })
        self.present(dialog, animated: true)
    }
    
    private func showCloseAdPermPreDialog(_ callback: @escaping (PermSwitchPreCloseAction) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_AdvancedPermission_DisablePopupTitle)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCompletion: {
            callback(.cancel)
        })
        let confirmBtn = dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonConfirm_Mobile, dismissCompletion: {
            callback(.confirm)
        })
        confirmBtn.isEnabled = false
        confirmBtn.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        let cv = BitableAdPermDialogContentView(
            contentText: BundleI18n.SKResource.Bitable_AdvancedPermission_DisablePopupContent1,
            confirmText: BundleI18n.SKResource.Bitable_AdvancedPermission_DisablePopupContent2,
            confirmAction: { confirmBtn.isEnabled = $0 }
        )
        dialog.setContent(view: cv)
        self.present(dialog, animated: true)
    }
    
    private func jsUpdatePermissionState(to value: Bool, completion: @escaping (Bool) -> Void) {
        permOpQueue.async {
            DocsLogger.info("[BAP] js switch start: \(value)")
            
            var params: [String: Any] = [
                "checked": value,
                "needSendCS": true,
            ]
            
            if UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance, value, self.rules?.allRoles.isEmpty != false {
                // 当前没有角色，则传入默认角色名，让前端创建一个默认角色
                self.needAutoSelectNewCreatedFallbackRole = true
                params["roleName"] = BundleI18n.SKResource.Bitable_AdvancedPermissions_AccessWith_DefaultRole_Text
            } else {
                self.needAutoSelectNewCreatedFallbackRole = false
            }
            
            self.delegate?.jsService?.callFunction(
                DocsJSCallBack.btUpgradeBase,
                params: params,
                completion: nil
            )
            let sem = DispatchSemaphore(value: 0)
            self.permOpSemaphore = sem
            sem.wait()
            DocsLogger.info("[BAP] js switch wait end: \(String(describing: self.permOpResult))")
            guard let code = self.permOpResult?["code"] as? Int, code == 0 else {
                DispatchQueue.main.async(execute: {
                    completion(false)
                })
                return
            }
            if value {
                self.permStatistics?.reportBitableAdPermSwitchOpenSuccess()
            }
            DispatchQueue.main.async(execute: {
                completion(true)
            })
        }
    }
    
    public func handleAdPermUpdateCompletion(_ result: [AnyHashable: Any]) {
        DocsLogger.info("[BAP] js switch callback: \(result)")
        guard let sem = self.permOpSemaphore else {
            DocsLogger.error("[BAP] js switch callback, but sem is not exist")
            return
        }
        self.permOpResult = result
        sem.signal()
        self.permOpSemaphore = nil
    }
}

// MARK: -

extension BitableAdPermSettingVC: CollaboratorSearchViewControllerDelegate, BitableCollaboratorEditViewControllerDelegate {
    public func shouldShowFallbackToastAfterCollaboratorDidRemove(_ collaborator: Collaborator, from: BitablePermissionRule) -> Bool {
        if rules?.accessConfig?.defaultConfig.accessStrategy == .forbidden {
            // 如果当前默认角色是策略是禁止访问，不需要提示
            return false
        }
        if rules?.allRoles.contains(where: { $0.ruleID != from.ruleID && $0.collaborators.contains(collaborator) }) == true {
            // 如果协作者从角色组中移除时，还存在于其它角色组，不需要提示
            return false
        }
        // 如果协作者从角色组中移除后，不存在于任一其它角色，协作者会进入默认角色组，给与提示
        return true
    }
    
    public func requestToAddCollaborator(from: BitableCollaboratorEditViewController, rule: BitablePermissionRule) {
        toAddCollaboratorVC(from: from, rule: rule)
    }
    

    public func collaboratorsDidUpdated() {
        DispatchQueue.main.async {
            self.loadData()
        }
    }
    
}


// MARK: - UICollectionViewDelegate/DataSource
extension BitableAdPermSettingVC: UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas.count
    }

    // swiftlint:disable cyclomatic_complexity
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < datas.count else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermBaseCell.unknownReuseID, for: indexPath)
        }
        let model = datas[indexPath.row]
        var permCell: BitableAdPermBaseCell?
        switch model {
        case .temp(let data):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermTempCell.defaultReuseID, for: indexPath) as? BitableAdPermTempCell else {
                break
            }
            cell.setModel(data)
            permCell = cell
        case .admin(let data):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermAdminCell.defaultReuseID, for: indexPath) as? BitableAdPermAdminCell else {
                break
            }
            cell.update(data)
            permCell = cell
        case .rule(let data):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermRuleCell.defaultReuseID, for: indexPath) as? BitableAdPermRuleCell else {
                break
            }
            cell.setModel(data)
            cell.addCollaboratorEvent = { [weak self] data in
                DocsLogger.info("[BAP] rule cell addCollaboratorEvent: \(data.addedAvailability)")
                guard let self = self else { return }
                switch data.addedAvailability {
                case .adPermOff:
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdavancedPermission_TurnOnToAddMember_Mobile, on: self.toastView)
                case .payment:
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_PremiumFeatureIncludedInRoleTip, on: self.toastView)
                    self.permStatistics?.reportBitablePremiumPermissionSettingClick(action: .addCollaborator, isTemplate: self.isTemplate, params: [
                        "role_id": data.rule.ruleID,
                        "is_success": "false"
                    ])
                case .none:
                    self.permStatistics?.reportBitablePremiumPermissionSettingClick(action: .addCollaborator, isTemplate: self.isTemplate, params: [
                        "role_id": data.rule.ruleID,
                        "is_success": "true"
                    ])
                    self.toAddCollaboratorVC(from: self, rule: data.rule)
                }
            }
            cell.editCollaboratorEvent = { [weak self] data in
                DocsLogger.info("[BAP] rule cell editCollaboratorEvent: \(data.managedAvailability)")
                guard let self = self else { return }
                switch data.managedAvailability {
                case .none:
                    self.toRuleEditVC(unit: data)
                    self.permStatistics?.reportBitablePremiumPermissionSettingClick(action: .manageCollaborator, isTemplate: self.isTemplate, params: [
                        "role_id": data.rule.ruleID
                    ])
                case .adPermOff:
                    UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_EnableFirstTip, on: self.toastView)
                }
            }
            permCell = cell
        case .empty:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermEmptyCell.defaultReuseID, for: indexPath) as? BitableAdPermEmptyCell else {
                break
            }
            permCell = cell
        case .fallback(let data):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermFallbackCell.defaultReuseID, for: indexPath) as? BitableAdPermFallbackCell else {
                break
            }
            cell.updateWidth(collectionView.bounds.width - 2 * 16)
            cell.delegate = self
            cell.fallbackContext = data
            permCell = cell
        }
        if let cell = permCell {
            cell.updateWidth(collectionView.bounds.width - 2 * 16)
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdPermBaseCell.unknownReuseID, for: indexPath)
        }
    }
    // swiftlint:enable cyclomatic_complexity

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < datas.count else { return }
        let model = datas[indexPath.row]
        switch model {
        case .temp(let data):
            toRuleDisplayVC(rule: data.rule)
            permStatistics?.reportBitablePremiumPermissionSettingClick(
                action: .permissionRulesetting,
                isTemplate: isTemplate,
                params: [
                    "role_id": data.rule.ruleID
                ]
            )
        case .rule(let data):
            permStatistics?.reportBitablePremiumPermissionSettingClick(
                action: .permissionRulesetting,
                isTemplate: isTemplate,
                params: [
                    "role_id": data.rule.ruleID
                ]
            )
            toRuleDisplayVC(rule: data.rule)
        case .admin:
            UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_WhoCanManageOnboarding, on: self.toastView)
        case .empty:
            // do nothing
            break
        case .fallback(let data):
            if data.isTemplate {
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_DescOnTemplate, on: self.toastView)
            }
        }
    }
}

extension BitableAdPermSettingVC: BitableAdPermFallbackCellDelegate {
    func fallbackCellCollaboratorDidTap(_ cell: BitableAdPermFallbackCell, collaborator: Collaborator) {
        if collaborator.type == .user {
            let service = ShowUserProfileService(userId: collaborator.userID, fileName: nil, fromVC: self)
            HostAppBridge.shared.call(service)
        } else {
            
        }
    }
    
    func fallbackCellLinkAvatarDidPress(_ cell: BitableAdPermFallbackCell, linkEntity: LinkShareEntityV2, fromView: UIView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTooltip(_:)))
        view.addGestureRecognizer(tap)
    }
    
    func fallbackCellCollaboratorMoreDidTap(_ cell: BitableAdPermFallbackCell) {
        
    }
    
    func fallbackCellConfigAreaDidTap(_ cell: BitableAdPermFallbackCell) {
        presentFallbackConfigPanel()
    }
    
    @objc
    private func dismissTooltip(_ sender: UITapGestureRecognizer) {
        getFallbackCell()?.hideTooltipViewIfNeeded()
        view.removeGestureRecognizer(sender)
    }
}

extension BitableAdPermSettingVC {
    private var toastView: UIView {
        return self.view.window ?? self.view
    }
}
