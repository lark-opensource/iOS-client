import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import RxSwift
import EENavigator
import LarkUIKit
import UniverseDesignToast
import SKResource
import UIKit
import LarkWebViewContainer
import SpaceInterface
import SKInfra

class SecretLevelService: BaseJSService {
    private lazy var docsInfoDetailUpdater: DocsInfoDetailUpdater = DocsInfoDetailHelper.detailUpdater(for: hostDocsInfo)
    private var disposeBag = DisposeBag()
    private var updateDetailDisposeBag = DisposeBag()
    private var updateSecLabelDisposeBag = DisposeBag()
    private var secretMonitor: SecretPushManager?
    private(set) lazy var secretBannerView: SecretBannerView = SecretBannerView()
    private var permStatistics: PermissionStatistics?
    private var currentTopMost: UIViewController? {
        guard let currentBrowserVC = navigator?.currentBrowserVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: currentBrowserVC)
    }
    private var secretLevelSelectProxy: SecretLevelSelectProxy?

    private var bannerType: SecretBannerView.BannerType = .hide
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
    private var collaboratorsCount = 0 ///协作者数量
    private var firstDisplay = true
    
    private let deadlineTime = 0.5
    
    private var firstReportEventTracking = true

}

extension SecretLevelService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] { return [.secretLevelNewbieLearnMore] }
    
    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("secretLevelService handle \(serviceName)")
        let service = DocsJSService(serviceName)
        switch service {
        case .secretLevelNewbieLearnMore:
            showSecretLearnMore()
        default:
            break
        }
    }
        
    private func updateDetail() {
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.error("failed to get docsInfo when handle set name event")
            return
        }
        updateDetailDisposeBag = DisposeBag()
        docsInfoDetailUpdater.updateDetail(for: docsInfo, headers: model?.requestAgent.requestHeader ?? [:])
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.setupSecretTitleAndBanner()
            }).disposed(by: updateDetailDisposeBag)
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor - PermissionSDK")
    private func updateSecretBannerView(canModifySecretLevel: Bool,
                                        canManageMeta: Bool,
                                        userPermission: UserPermissionAbility?,
                                        docsInfo: DocsInfo) {
        if docsInfo.isVersion {
            DocsLogger.info("updateSecretBannerView not need")
            return
        }
        DocsLogger.info("SecretLevelService: docsId: \(docsInfo.objId)")
        guard let level = docsInfo.secLabel, level.canSetSecLabel == .yes else {
            DocsLogger.info("updateSecretBannerView level nil or can not set")
            return
        }
        guard canModifySecretLevel else {
            DocsLogger.info("updateSecretBannerView userPermission can not modify secret level")
            ui?.bannerAgent.requestHideItem(secretBannerView)
            return
        }
                
        var type: SecretBannerView.BannerType = .hide
        if UserScopeNoChangeFG.TYP.permissionSecretAuto {
            type = SecretBannerCreater.checkForceSecretLableAutoOrRecommend(canManageMeta: canManageMeta, level: level, collaboratorsCount: collaboratorsCount)
            switch type {
            case .recommendMarkBanner, .forceRecommendMarkBanner:
                self.requestUpdateRecommandBanner(level: level, type: type, docsInfo: docsInfo, userPermisson: userPermission)
            default:
                self.handleBannerType(type: type, docsInfo: docsInfo, level: level)
            }
        } else {
            if LKFeatureGating.sensitivityLabelForcedEnable {
                ///强制打标
                type = SecretBannerCreater.forcibleBannerType(canManageMeta: canManageMeta, level: level, collaboratorsCount: collaboratorsCount)
            } else {
                /// 非强制打标
                type = SecretBannerCreater.unForcibleBannerType(level: level, collaboratorsCount: collaboratorsCount)
            }
            handleBannerType(type: type, docsInfo: docsInfo, level: level)
        }
        bannerType = type
        reportPermissionSecurityBanner(docsInfo: docsInfo, userPermission: userPermission, level: level)
    }
    
    private func showSecretSettingVCIfNeed(canManageMeta: Bool, docsInfo: DocsInfo) {
        guard let secLabel = docsInfo.secLabel, secLabel.canSetSecLabel == .yes,
              let createTime = docsInfo.createTime, let serverTime = docsInfo.serverTime else { return }
        let isNewDocs = abs(createTime - serverTime) < 10
        let isForcible = SecretBannerCreater.checkForcibleSL(canManageMeta: canManageMeta, level: secLabel)
        if isForcible && isNewDocs {
            let uid = User.current.info?.userID ?? ""
            let settingKey = "ccm.permission.secret.setting" + docsInfo.objToken + uid
            if !CacheService.normalCache.containsObject(forKey: settingKey) {
                if let saveData = try? JSONEncoder().encode(true) {
                    CacheService.normalCache.set(object: saveData, forKey: settingKey)
                } else {
                    DocsLogger.error("SaveData encode fail", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                }
                // 在iPad端从模板创建文档时，因为前面还有个模板弹窗的退出动画未结束，所以延时0.5秒再打开密级弹框
                if SKDisplay.pad {
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                        self.secretBannerViewDidClickSetButton(self.secretBannerView)
                    }
                } else {
                    self.secretBannerViewDidClickSetButton(self.secretBannerView)
                }
            }
        }
    }
    
    private func reportPermissionSecurityBanner(docsInfo: DocsInfo, userPermission: UserPermissionAbility?, level: SecretLevel, type: SecretBannerView.BannerType? = nil) {
        guard permStatistics == nil else { return }
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        let publicPermissionMeta = permissionManager?.getPublicPermissionMeta(token: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermission?.permRoleValue,
                                                      userPermissionRawValue: userPermission?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        if type == nil {
            permStatistics?.reportPermissionSecurityDocsBannerView(hasDefaultSecretLevel: level.bannerType == .defaultSecret)
        }
    }
    
    //推荐打标出现时上报
    private func reportPermissionRecommendBannerView(type: SecretBannerView.BannerType) {
        guard firstReportEventTracking else { return }
        firstReportEventTracking = false
        var parameters: [String: Any] = [:]
        var isCompulsoryLabeling = false
        if case .forceRecommendMarkBanner = type {
            isCompulsoryLabeling = true
        }
        parameters["is_compulsory_labeling"] = isCompulsoryLabeling ? "true" : "false"
        DocsTracker.newLog(enumEvent: .scsFileRecommendedLabelBannerView, parameters: parameters)
    }
    
    //推荐打标发生动作时上报
    private func reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: Bool, action: String) {
        var parameters: [String: Any] = [:]
        parameters["is_compulsory_labeling"] = isCompulsoryLabeling ? "true" : "false"
        parameters["click"] = action
        DocsTracker.newLog(enumEvent: .scsFileRecommendedLabelBannerClick, parameters: parameters)
    }
    
    private func requestUpdateRecommandBanner(level: SecretLevel, type:SecretBannerView.BannerType, docsInfo: DocsInfo, userPermisson: UserPermissionAbility?) {
        SecretLevelLabelList.fetchLabelList()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                guard let self = self else { return }
                guard !list.labels.isEmpty else { return }
                for label in list.labels {
                    if label.id == level.recommendLabelId {
                        if case .recommendMarkBanner = type {
                            self.secretBannerView.setBannerType(.recommendMarkBanner(title: label.name))
                        } else {
                            self.secretBannerView.setBannerType(.forceRecommendMarkBanner(title: label.name))
                        }
                        self.reportPermissionSecurityBanner(docsInfo: docsInfo, userPermission: userPermisson, level: level, type: type)
                        self.reportPermissionRecommendBannerView(type: type)
                        self.secretBannerView.actionDelegate = self
                        DocsLogger.info("updateSecretBannerView show with by \(type)")
                        self.ui?.bannerAgent.requestShowItem(self.secretBannerView)
                    }
                }
            }, onError: {  error in
                DocsLogger.error("fetchLabelList failed!", error: error)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleBannerType(type: SecretBannerView.BannerType, docsInfo: DocsInfo, level: SecretLevel) {
        if case .hide = type {
            DocsLogger.info("hide bannerType")
            ui?.bannerAgent.requestHideItem(secretBannerView)
            return
        }
        if case .autoMarkBanner(_) = type {
            DocsLogger.info("should autoMarkBanner")
            SecretLevel.updateSecLabelBanner(token: docsInfo.objId ?? "0",
                                             type: docsInfo.inherentType.rawValue,
                                             secLabelId: level.label.id,
                                             bannerType: level.secLableTypeBannerType?.rawValue ?? 0,
                                             bannerStatus: level.secLableTypeBannerStatus?.rawValue ?? 0)
                .subscribe { 
                    DocsLogger.info("update secret level success")
                } onError: {  error in
                    DocsLogger.error("update secret level fail", error: error)
                }
                .disposed(by: disposeBag)
        }
        if case .unChangetype = type {
            return
        }
        secretBannerView.setBannerType(type)
        secretBannerView.actionDelegate = self
        DocsLogger.info("updateSecretBannerView show with by \(type)")
        ui?.bannerAgent.requestShowItem(secretBannerView)
    }
    
    private func setupSecretTitleAndBanner() {
        guard LKFeatureGating.sensitivtyLabelEnable else {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner fg close")
            return
        }
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner docsInfo is nil")
            return
        }
        guard docsInfo.typeSupportSecurityLevel else {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner type unSupport")
            return
        }
        guard !docsInfo.token.isFakeToken else {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner is fake token")
            return
        }
        
        if docsInfo.token.hasPrefix("wiki") {
            spaceAssertionFailure("SecretLevelService setupSecretTitleAndBanner token is a wikiToken")
            DocsLogger.error("SecretLevelService setupSecretTitleAndBanner token is a wikiToken")
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            updatePermissionService { [weak self] canModifySecretLevel, canManageMeta in
                guard let self else { return }
                self.updateSecretBannerView(canModifySecretLevel: canModifySecretLevel,
                                            canManageMeta: canManageMeta,
                                            userPermission: nil,
                                            docsInfo: docsInfo)
                self.showSecretSettingVCIfNeed(canManageMeta: canManageMeta,
                                               docsInfo: docsInfo)
            }
        } else {
            ///获取权限
            fetchUserPermissions(docsInfo: docsInfo) { [weak self] userPermissions in
                guard let `self` = self else { return }
                self.updateSecretBannerView(canModifySecretLevel: userPermissions.canModifySecretLevel(),
                                            canManageMeta: userPermissions.isFA,
                                            userPermission: userPermissions,
                                            docsInfo: docsInfo)
                self.showSecretSettingVCIfNeed(canManageMeta: userPermissions.isFA,
                                               docsInfo: docsInfo)
            }
        }
        
        ///获取协作者
        fetchCollaboratorsCount(docsInfo: docsInfo)
        
        ///注册密级变化协同
        setupSecretMonitor(token: docsInfo.token, type: docsInfo.inherentType)
    }

    private func updatePermissionService(completion: @escaping (Bool, Bool) -> Void) {
        guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
            spaceAssertionFailure()
            completion(false, false)
            return
        }
        if permissionService.ready {
            let canManageMeta = permissionService.validate(operation: .managePermissionMeta).allow
            let modifySecretLevel = permissionService.validate(operation: .modifySecretLabel).allow
            completion(modifySecretLevel, canManageMeta)
        } else {
            permissionService.updateUserPermission().subscribe { [weak permissionService] _ in
                guard let permissionService else { return }
                let canManageMeta = permissionService.validate(operation: .managePermissionMeta).allow
                let modifySecretLevel = permissionService.validate(operation: .modifySecretLabel).allow
                completion(modifySecretLevel, canManageMeta)
            } onError: { error in
                DocsLogger.error("SecretLevelService setupSecretTitleAndBanner fetch user permission error", error: error, component: LogComponents.permission)
            }
            .disposed(by: disposeBag)
        }
    }
    
    ///获取权限
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor - PermissionSDK")
    private func fetchUserPermissions(docsInfo: DocsInfo, complete: ((UserPermissionAbility) -> Void)? = nil) {
        if let userPermissions = model?.permissionConfig.hostUserPermissions {
            complete?(userPermissions)
        } else {
            let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
            permissionManager.fetchUserPermissions(token: docsInfo.token, type: docsInfo.type.rawValue) { [weak self] info, error in
                guard let `self` = self else { return }
                if let error = error {
                    DocsLogger.error("SecretLevelService setupSecretTitleAndBanner fetch user permission error", error: error, component: LogComponents.permission)
                    return
                }
                guard let mask = info?.mask else {
                    DocsLogger.error("SecretLevelService setupSecretTitleAndBanner mask is nil")
                    return
                }
                complete?(mask)
            }
        }
    }
    
    ///获取协作者
    private func fetchCollaboratorsCount(docsInfo: DocsInfo) {
        guard LKFeatureGating.sensitivityLabelForcedEnable || UserScopeNoChangeFG.GQP.sensitivityLabelsecretopt else {
            DocsLogger.info("fg close")
            return
        }
        guard collaboratorsCount == 0 else {
            DocsLogger.info("execute once")
            return
        }
        addCollaboratorListChangedNotification(docsInfo: docsInfo)
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        permissionManager.fetchCollaborators(token: docsInfo.token, type: docsInfo.inherentType.rawValue, shouldFetchNextPage: true, collaboratorSource: .defaultType)
    }
    private func addCollaboratorListChangedNotification(docsInfo: DocsInfo) {
        NotificationCenter.default.rx.notification(Notification.Name.Docs.CollaboratorListChanged)
            .subscribe { [weak self] (notification: Notification) in
                guard let self = self else { return }
                if let info = notification.userInfo,
                   let token = info["token"] as? String,
                   token == docsInfo.token,
                    let count = info["count"] as? Int,
                   count != self.collaboratorsCount {
                    DocsLogger.info("get collaborator list changed notification, new count = \(count), old count =\(self.collaboratorsCount)")
                    self.collaboratorsCount = count
                    self.setupSecretTitleAndBanner()
                }
            }
            .disposed(by: disposeBag)
    }
}

extension SecretLevelService: BrowserViewLifeCycleEvent {
    func browserDidUpdateDocsInfo() {
        if hostDocsInfo?.originType == .sync {
            //同步块独立页不展示密级banner
            return
        }
        DocsLogger.info("SecretLevelService browserDidUpdateDocsInfo")
        setupSecretTitleAndBanner()
    }
}
extension SecretLevelService {
    private func showSecretLearnMore() {
        do {
            let url = try HelpCenterURLGenerator.generateURL(article: .secretBannerHelpCenter)
            secretBannerViewDidClickLink(secretBannerView, url: url)
        } catch {
            DocsLogger.error("failed to generate helper center URL when showSecretLearnMore from secret banner", error: error)
        }
    }
}

extension SecretLevelService: SecretPushDelegate {
    private func setupSecretMonitor(token: String, type: DocsType) {
        DocsLogger.info("setupSecretMonitor token \((DocsTracker.encrypt(id: token))), \(type)")
        guard secretMonitor == nil else {
            DocsLogger.info("setupSecretMonitor secretMonitor exist \((DocsTracker.encrypt(id: token))), \(type)")
            return
        }
        let newSecretMonitor = SecretPushManager(fileToken: token, type: type)
        secretMonitor = newSecretMonitor
        newSecretMonitor.start(with: self)
    }
    
    func secretDidChanged(token: String, type: Int) {
        DocsLogger.info("secretDidChanged token \((DocsTracker.encrypt(id: token))), \(type)")
        updateDetail()
    }
}

extension SecretLevelService: SecretBannerViewDelegate {
    
    func secretBannerViewDidClickSetButton(_ view: SecretBannerView) {
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner docsInfo is nil")
            return
        }
        let userPermission = model?.permissionConfig.hostUserPermissions
        if userPermission == nil {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner userPermission is nil")
        }
        guard let topVC = navigator?.currentBrowserVC else {
            DocsLogger.info("SecretLevelService setupSecretTitleAndBanner topVC is nil")
            return
        }
        self.secretLevelSelectProxy = SecretLevelSelectProxy(docsInfo: docsInfo, userPermission: userPermission, topVC: topVC)
        self.secretLevelSelectProxy?.toSetSecretVC()
    }
    func secretBannerViewDidClickLink(_ view: SecretBannerView, url: URL) {
        guard let currentTopMost = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.error("docsInfo is nil")
            return
        }
        guard let level = docsInfo.secLabel else {
            DocsLogger.warning("level nil")
            return
        }
        permStatistics?.reportPermissionSecurityDocsBannerClick(hasDefaultSecretLevel: level.bannerType == .defaultSecret, action: .knowDetail)
        
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: self.navigator?.currentBrowserVC,
                                                   followDelegate: self.model?.vcFollowDelegate) {
            return
        }

        DocsLogger.info("not open in VideoConference")
        if let type = DocsType(url: url),
           let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            model?.userResolver.navigator.docs.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: currentTopMost)
        } else {
            model?.userResolver.navigator.push(url, from: currentTopMost)
        }
    }
    
    func secretBannerClose(_ secretBannerView: SecretBannerView) {
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.info("SecretLevelService shouldClose docsInfo is nil")
            return
        }
        if case .forceRecommendMarkBanner = bannerType {
            reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: true, action: "close")
        } else {
            reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: false, action: "close")
        }
        let bannerId: String
        if docsInfo.secLabel?.secLableTypeBannerType == .recommendMark {
            bannerId = docsInfo.secLabel?.recommendLabelId ?? "0"
        } else {
            bannerId = docsInfo.secLabel?.label.id ?? "0"
        }
        DocsLogger.info("hide bannerType")
        ui?.bannerAgent.requestHideItem(secretBannerView)
        SecretLevel.updateSecLabelBanner(token: docsInfo.objId ?? "0",
                                         type: docsInfo.inherentType.rawValue,
                                         secLabelId: bannerId,
                                         bannerType: docsInfo.secLabel?.secLableTypeBannerType?.rawValue ?? 0,
                                         bannerStatus: docsInfo.secLabel?.secLableTypeBannerStatus?.rawValue ?? 0)
            .subscribe { 
                DocsLogger.info("update secret level success")
            } onError: {  error in
                DocsLogger.error("update secret level fail", error: error)
            }
            .disposed(by: disposeBag)
    }
    
    func secretBannerViewDidClickSetConfirmButton(_ view: SecretBannerView) {
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.info("SecretLevelService secretBannerViewDidClickSetConfirmButton docsInfo is nil")
            return
        }
        if case .forceRecommendMarkBanner = bannerType {
            reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: true, action: "confirm")
        } else {
            reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: false, action: "confirm")
        }
        let bannerId: String
        if docsInfo.secLabel?.secLableTypeBannerType == .recommendMark {
            bannerId = docsInfo.secLabel?.recommendLabelId ?? "0"
        } else {
            bannerId = docsInfo.secLabel?.defaultLabelId ?? "0"
        }
        ui?.bannerAgent.requestHideItem(view)
        SecretLevel.updateSecLabel(token: docsInfo.token, type: docsInfo.inherentType.rawValue, id: bannerId, reason: "")
            .subscribe {
                DocsLogger.info("update secret level success")
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.updateSecurity(objToken: docsInfo.token, newSecurityName: view.secLabelTitleName)
                self.showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, success: true)
            } onError: {  error in
                DocsLogger.error("update secret level fail", error: error)
                self.showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, success: false)
            }
            .disposed(by: updateSecLabelDisposeBag)
    }
    
    private func showToast(text: String, success: Bool = true) {
        guard !text.isEmpty else {
            return
        }
        guard let currentTopMost = currentTopMost, let view = currentTopMost.view.window ?? currentTopMost.view else {
            DocsLogger.error("currentTopMost is nil", component: LogComponents.comment)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + deadlineTime) {
            if success {
                UDToast.showSuccess(with: text, on: view)
            } else {
                UDToast.showFailure(with: text, on: view)
            }
        }
    }
}
