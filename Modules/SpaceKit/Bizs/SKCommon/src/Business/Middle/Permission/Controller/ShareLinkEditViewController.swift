//
//  ShareLinkEditViewController.swift
//  SpaceKit
//
//  Created by 杨子曦 on 2020/1/11.
//  swiftlint:disable file_length cyclomatic_complexity

import UIKit
import SwiftyJSON
import EENavigator
import RxSwift
import RxCocoa
import SKFoundation
import SKResource
import SKUIKit
import LarkButton
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignNotice
import SKInfra

public enum ShareLinkChoice: Int, Equatable, Comparable {
    case close
    case orgRead
    case orgEdit
    case anyoneRead
    case anyoneEdit
    case partnerRead
    case partnerEdit

    // 直接比较 rawValue 判断范围不再正确
    public static func < (lhs: ShareLinkChoice, rhs: ShareLinkChoice) -> Bool {
        switch (lhs, rhs) {
        case (.partnerRead, .anyoneRead),
            (.partnerRead, .anyoneEdit),
            (.partnerEdit, .anyoneRead),
            (.partnerEdit, .anyoneEdit):
            return true
        default:
            return lhs.rawValue < rhs.rawValue
        }
    }
}

public final class ShareLinkEditViewController: BaseViewController {
    private(set) var previousChoice: ShareLinkChoice?
    private(set) var currentChoice: ShareLinkChoice = .close
    public private(set) var shareEntity: SKShareEntity
    var publicPermissionMeta: PublicPermissionMeta
    private var userPermisson: UserPermissionAbility?
    
    var createPasswordForShareFolderRequest: DocsRequest<JSON>?
    var refreshPasswordForShareFolderRequest: DocsRequest<JSON>?
    var deletePasswordForShareFolderRequest: DocsRequest<JSON>?

    /// 网络请求
    var updatePermissionRequest: DocsRequest<JSON>?
    /// 链接共享设置项的数据源
    var editLinkInfoDataSource = [EditLinkInfoProtocol]()
    /// 可搜索设置项的数据源
    var searchSettingDataSource = [SearchSettingInfo]()
    /// 密码设置的数据源
    var passwordSettingDataSource: [PasswordTableViewCellModel] = []
    var permissionObserver: PermissionObserver

    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    //ask owner监听请求发送
    public var sendRequestObserver: PublishSubject<Bool>?
    private var askOwnerRequest: DocsRequest<[String: Any]>?
    public var checkLockPermission: DocsRequest<JSON>?

    /// 链接分享密码
    var hasLinkPassword: Bool
    var linkPassword: String
    ///埋点相关
    private var statistics: CollaboratorStatistics?
    private var requestDataModal: EditLinkInfo?
    ///placeholder
    private var placeHolderString: String = ""
    /// 打点相关
    private(set) var shareSource: ShareSource
    private(set) var publicPermissionTracker: PublicPermissionTracker
    private(set) var passwordSettingTracker: PasswordSettingTracker

    // UI
    private(set) var passwordSwitchCellIdentifier = "Space.PasswordSwitchTableViewCell"
    private(set) var passwordDisplayCellIdentifier = "Space.PasswordDisplayTableViewCell"
    private(set) var passwordSettingPlainTextCellIdentifier = "Space.PasswordSettingPlainTextCellIdentifier"

    private let needCloseBarItem: Bool
    let disposeBag: DisposeBag = DisposeBag()
    var permStatistics: PermissionStatistics?

    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.ud.commonTableSeparatorColor
        tableView.register(LinkEditChoiceCell.self, forCellReuseIdentifier: LinkEditChoiceCell.reuseIdentifier)
        tableView.register(SearchSettingCell.self, forCellReuseIdentifier: SearchSettingCell.reuseIdentifier)
        tableView.register(PasswordSwitchTableViewCell.self, forCellReuseIdentifier: passwordSwitchCellIdentifier)
        tableView.register(PasswordDisplayTableViewCell.self, forCellReuseIdentifier: passwordDisplayCellIdentifier)
        tableView.register(PasswordSettingPlainTextCell.self, forCellReuseIdentifier: passwordSettingPlainTextCellIdentifier)
        tableView.estimatedRowHeight = 96
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UDColor.bgBase
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    private(set) lazy var toastTextView: UITextView = {
        let t = UITextView()
        t.backgroundColor = UDColor.bgFloat
        t.textColor = UDColor.textTitle
        t.textAlignment = .center
        t.isEditable = false
        t.isUserInteractionEnabled = true
        t.isSelectable = true
        t.isScrollEnabled = false
        t.showsHorizontalScrollIndicator = false
        t.showsVerticalScrollIndicator = false
        return t
    }()

//    private lazy var linkConstraintBannerView: UDNotice = {
//        let attributedText = NSAttributedString(string: "",
//                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
//                                                             .foregroundColor: UIColor.ud.textTitle])
//        return UDNotice(config: UDNoticeUIConfig(type: .info, attributedText: attributedText))
//    }()
    
    public var isNewForm = false
    
    public init(shareEntity: SKShareEntity,
                userPermisson: UserPermissionAbility?,
         publicPermissionMeta: PublicPermissionMeta,
         chosenType: ShareLinkChoice?,
         shareSource: ShareSource,
         permStatistics: PermissionStatistics?,
         needCloseBarItem: Bool) {
        self.shareEntity = shareEntity
        self.userPermisson = userPermisson
        self.publicPermissionMeta = publicPermissionMeta
        self.previousChoice = chosenType
        self.permStatistics = permStatistics
        let permissionTrackerModel = PublicPermissionTracker.FileModel(objToken: shareEntity.objToken,
                                                          type: shareEntity.type,
                                                          ownerID: shareEntity.ownerID,
                                                          tenantID: shareEntity.tenantID,
                                                          createTime: shareEntity.createTime,
                                                          createDate: shareEntity.createDate, createID: shareEntity.creatorID)
        self.publicPermissionTracker = PublicPermissionTracker(fileModel: permissionTrackerModel)
        let settingTrackerModel = PasswordSettingTracker.FileModel(objToken: shareEntity.objToken,
                                                                   type: shareEntity.type,
                                                                   ownerID: shareEntity.ownerID,
                                                                   fileType: shareEntity.fileType)
        self.passwordSettingTracker = PasswordSettingTracker(fileModel: settingTrackerModel, source: shareSource)
        self.permissionObserver = PermissionObserver(fileToken: shareEntity.objToken, shareToken: shareEntity.formShareFormMeta?.shareToken ?? "", type: shareEntity.type.rawValue)
        self.shareSource = shareSource
        self.hasLinkPassword = publicPermissionMeta.hasLinkPassword
        self.linkPassword = publicPermissionMeta.linkPassword
        self.needCloseBarItem = needCloseBarItem
        super.init(nibName: nil, bundle: nil)
        self.loadData()
    }

    func loadData() {
        if shareEntity.wikiV2SingleContainer {
            editLinkInfoDataSource = wikiV2EditLinkInfos
        } else if shareEntity.type == .form {
            editLinkInfoDataSource = formEditLinkInfos
        } else if shareEntity.isBitableSubShare {
            editLinkInfoDataSource = bitableLinkInfos
        } else {
            if isToC {
                editLinkInfoDataSource = toCEditLinkInfos
            } else {
                editLinkInfoDataSource = toBEditLinkInfos
                if canShowPartnerTenantAccessLinkInfos {
                    editLinkInfoDataSource.append(contentsOf: partnerTenantAccessLinkInfos)
                }
                if publicPermissionMeta.canShowExternalAccessSwitch {
                    editLinkInfoDataSource.append(contentsOf: toBExternalAccessLinkInfos)
                }
            }
        }

        editLinkInfoDataSource.forEach {
            guard let model = $0 as? EditLinkInfo else { return }
            if model.chosenType == previousChoice {
                model.isSelect = true
            }
            if model.isSelect {  //初始化currentChoice
                currentChoice = model.chosenType
            }
            model.updateState(publicPermissionMeta: publicPermissionMeta)
        }
        
        setupSearchableDataSource()
        setupPasswordSettingDataSource()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addCloseBarItemIfNeed()
        if shareEntity.isForm {
            self.title = BundleI18n.SKResource.Bitable_Form_PermissionSettings
        } else if shareEntity.isBitableSubShare {
            self.title = BundleI18n.SKResource.Bitable_Share_WhoCanVisitThisLink
        } else {
            self.title = BundleI18n.SKResource.Doc_Share_LinkTitle
        }
        if isNewForm {
            self.title = BundleI18n.SKResource.Bitable_NewSurvey_Sharing_Mobile_ResponsePermission_Title
        }
        
        self.view.backgroundColor = UDColor.bgBase
//        self.view.addSubview(linkConstraintBannerView)
        self.view.addSubview(tableView)

        navigationBar.customizeBarAppearance(backgroundColor: view.backgroundColor)
        statusBar.backgroundColor = view.backgroundColor

//        linkConstraintBannerView.snp.makeConstraints { make in
//            make.top.equalTo(self.navigationBar.snp.bottom).offset(10)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(0)
//        }

        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        permStatistics?.reportPermissionShareEncryptedLinkView(shareEntity: shareEntity)
    }

//    func updateLinkConstraintBannerView() {
//        guard shareEntity.wikiV2SingleContainer, LKFeatureGating.wikiSinglePageEnable else {
//            return
//        }
//        let text = (editLinkInfoDataSource.first {
//            ($0 as? EditLinkInfo)?.chosenType == previousChoice
//        } as? EditLinkInfo)?.mainStr ?? ""
//        let bannerText = publicPermissionMeta.entityConstraint?.linkShareEntityBannerText(text)
//        
//        let attributedText = NSAttributedString(string: bannerText ?? "",
//                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
//                                                             .foregroundColor: UIColor.ud.textTitle])
//        let config = UDNoticeUIConfig(type: .info, attributedText: attributedText)
//        linkConstraintBannerView.updateConfigAndRefreshUI(config)
//
//        let hideBanner: Bool = (bannerText?.isEmpty == true)
//        linkConstraintBannerView.isHidden = hideBanner
//        linkConstraintBannerView.snp.updateConstraints { make in
//            make.height.equalTo(hideBanner ? 0 : linkConstraintBannerView.sizeThatFits(CGSize(width: view.frame.width, height: 100)))
//        }
//    }

    private func addCloseBarItemIfNeed() {
        guard needCloseBarItem else { return }
        let closeButton = UIButton()
        closeButton.setImage(BundleResources.SKResource.Common.Collaborator.icon_close_outlinedV2.ud.withTintColor(UDColor.iconN1), for: .normal)
        closeButton.addTarget(self, action: #selector(didClickedCloseBarItem), for: .touchUpInside)
        closeButton.docs.addHighlight(with: UIEdgeInsets(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        backgroundView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let btnItem = SKBarButtonItem(customView: backgroundView)
        btnItem.id = .close
        self.navigationBar.leadingBarButtonItem = btnItem
    }

    @objc
    func didClickedCloseBarItem() {
        permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: shareEntity.type, click: .back, target: .noneTargetView)
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    func updatePermissions(editLinkInfo: EditLinkInfo) {
        currentChoice = editLinkInfo.chosenType
        //链接分享的设置修改了才修改权限
        guard currentChoice != previousChoice else {
            return
        }
        var click: LinkShareSettingPageClickAction = .onlyCollaborator
        switch currentChoice {
        case .close:
            click = .onlyCollaborator
        case .orgRead:
            click = .organizationRead
        case .orgEdit:
            click = .organizationEdit
        case .anyoneRead:
            click = .internetRead
        case .anyoneEdit:
            click = .internetEdit
        case .partnerRead:
            click = .partnerTenantRead
        case .partnerEdit:
            click = .PartnerTenantEdit
        }
        
        let checkExternal: Set<ShareLinkChoice> = [.anyoneRead, .anyoneEdit]
        if checkExternal.contains(editLinkInfo.chosenType), isToC != true {
            publicPermissionMeta.update(externalAccessEnable: true)
        }

        let checkPartnerAccess: Set<ShareLinkChoice> = [.partnerEdit, .partnerRead]
        if checkPartnerAccess.contains(editLinkInfo.chosenType), isToC != true {
            publicPermissionMeta.externalAccessEntity = .partnerTenant
        }

//        let isExpand: Bool = currentChoice > previousChoice
        ///产品要求链接设置缩权也弹 权限选择框，后端鉴权失败时弹错误提示😶
        var isExpand: Bool = true
        /// 选中关闭，默认不弹框
        if currentChoice == .close {
            isExpand = false
        }
        checkLockByUpdatePublicPermission(isExpand: isExpand) { [weak self] in
            guard let self = self else { return }
            self.startLoading()
            if self.isFolder {
                self.updateFolderPublicPermission()
            } else if self.shareEntity.isFormV1 {
                self.updateFormPublicPermission(linkShareEntityValue: self.currentChoice)
            } else if self.shareEntity.isBitableSubShare {
                self.updateBitablePublicPermission(linkShareEntityValue: self.currentChoice)
            } else {
                let isFullAccess = self.userPermisson?.canManageMeta() ?? false
                let isSinglePageFullAccess = self.userPermisson?.canSinglePageManageMeta() ?? false
                var permType: PermTypeValue.PermType = .defaultType
                if self.shareEntity.wikiV2SingleContainer, !isFullAccess, isSinglePageFullAccess {
                    permType = .singlePage
                }
                self.updateDocsPublicPermission(linkShareEntityValue: self.currentChoice,
                                                permType: permType)
            }
        } statisticsCompletion: { [weak self] ret in
            guard let self = self else { return }
            self.permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: self.shareEntity.type,
                                                                         click: click,
                                                                         target: ret ? .permissionScopeChangeView : .noneTargetView)
        }
    }
    
    func updatePermissions(searchSettingInfo: SearchSettingInfo) {
        var click: LinkShareSettingPageClickAction = .internetSearch
        switch searchSettingInfo.chosenType {
        case .tenantCanSearch:
            click = .organizationSearch
        case .linkCanSearch:
            click = .internetSearch
        }

        let completion = { [weak self] in
            guard let self = self else { return }
            self.startLoading()
            
            let isFullAccess = self.userPermisson?.canManageMeta() ?? false
            let isSinglePageFullAccess = self.userPermisson?.canSinglePageManageMeta() ?? false
            var permType: PermTypeValue.PermType = .defaultType
            if self.shareEntity.wikiV2SingleContainer, !isFullAccess, isSinglePageFullAccess {
                permType = .singlePage
            }
            self.updateDocsPublicPermission(searchSettingInfo: searchSettingInfo,
                                            permType: permType)
        }
        checkLockByUpdatePublicPermission(linkShareEntityValue: nil, searchEntityValue: searchSettingInfo.chosenType) { [weak self] (success, needLock) in
            guard let self = self else { return }
            if success, needLock {
                self.showPermisionLockAlert(reason: .reduceSearch, completion: completion)
            } else {
                completion()
            }
            self.permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: self.shareEntity.type,
                                                                         click: click,
                                                                         target: .noneTargetView)
        }
    }
    
    private func checkLockByUpdatePublicPermission(isExpand: Bool, completion: (() -> Void)?,
                                                   statisticsCompletion: ((Bool) -> Void)?) {
        checkLockByUpdatePublicPermission(linkShareEntityValue: currentChoice, searchEntityValue: nil) { [weak self] (success, needLock) in
            guard let self = self else { return }
            /// wiki2.0 fg开 扩权 有容器权限， 展示权限选择框
            if self.shareEntity.wikiV2SingleContainer,
               isExpand,
               self.userPermisson?.canManageMeta() == true {
                self.showPermissonScopeSelectView(showLockTip: success && needLock)
                statisticsCompletion?(true)
            } else {
                if success, needLock {
                    self.showPermisionLockAlert(reason: .reduceSharelink, completion: completion)
                } else {
                    completion?()
                }
                statisticsCompletion?(false)
            }
        }
    }
    // 是否加锁提示弹窗
    private func showPermisionLockAlert(reason: LockReason, completion: (() -> Void)?) {
        self.permStatistics?.reportLockAlertView(reason: reason)
        var content: String = ""
        if shareEntity.wikiV2SingleContainer {
            content = BundleI18n.SKResource.CreationMobile_Wiki_Permission_SettingsDivision_Placeholder
        } else {
            if shareEntity.isFolder {
                content = BundleI18n.SKResource.CreationMobile_ECM_InheritDesc
            } else {
                content = BundleI18n.SKResource.CreationMobile_ECM_PermissionChangedDesc
            }
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Wiki_Permission_ChangePermission_Title)
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            self?.permStatistics?.reportLockAlertClick(click: .cancel,
                                                       target: .noneTargetView,
                                                       reason: reason)
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            self?.permStatistics?.reportLockAlertClick(click: .confirm,
                                                       target: .noneTargetView,
                                                       reason: reason)
            completion?()
        })
        present(dialog, animated: true, completion: nil)
    }
    
    func updateSelectedState() {
        guard currentChoice != previousChoice else { return }
            ///通知外部更新权限
        NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
        /// 取消原来的选择
        if let pre = previousChoice,
           let previousIndex = getEditLinkInfoIndex(with: pre),
           previousIndex >= 0,
           previousIndex < editLinkInfoDataSource.count,
           let previousModel = editLinkInfoDataSource[previousIndex] as? EditLinkInfo {
            previousModel.isSelect = false
        }

        /// 新增现在的选择
        guard let currentIndex = getEditLinkInfoIndex(with: currentChoice) else {
            DocsLogger.error("currentIndex is nil!")
            return
        }
        guard currentIndex >= 0, currentIndex < editLinkInfoDataSource.count else {
            DocsLogger.error("currentIndex is out of bounds!")
            return
        }
        guard let currentModel = editLinkInfoDataSource[currentIndex] as? EditLinkInfo else { return }
        currentModel.isSelect = true

        previousChoice = currentChoice
        // 更新选择后刷新一下列表，原因是可能需要隐藏掉部分选项
        loadData()
        tableView.reloadData()
    }
    
    func updateSearchSettingSelectedState(searchSettingInfo: SearchSettingInfo) {
        ///通知外部更新权限
        NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
        
        if let currentSetting = searchSettingDataSource.filter({ $0.isSelect }).first {
            searchSettingInfo.preChosenType = currentSetting.chosenType
            currentSetting.isSelect = false
        }
        searchSettingInfo.isSelect = true
        
        // 更新选择后刷新一下列表，原因是可能需要隐藏掉部分选项
        loadData()
        tableView.reloadData()
    }

    @objc
    public override func backBarButtonItemAction() {
        permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: shareEntity.type, click: .back, target: .noneTargetView)
        navigationController?.popViewController(animated: true)
    }

    func getEditLinkInfoIndex(with currentChoice: ShareLinkChoice) -> Int? {
        guard editLinkInfoDataSource.count >= 0 else { return nil }
        for i in 0..<editLinkInfoDataSource.count {
            guard let editLinkInfo = editLinkInfoDataSource[i] as? EditLinkInfo else { return nil }
            if editLinkInfo.chosenType == currentChoice {
                return i
            }
        }
        return nil
    }
    
    func setupSearchableDataSource() {
        if searchSettingEnable {
            let tips = BundleI18n.SKResource.LarkCCM_Perm_SearchableWithLinkExplanation_Tooltip()
            searchSettingDataSource = [
                SearchSettingInfo(mainStr: BundleI18n.SKResource.LarkCCM_Perm_SearchableWithLink_Dropdown, chosenType: .linkCanSearch, tips: tips),
                SearchSettingInfo(mainStr: BundleI18n.SKResource.LarkCCM_Perm_SearchableInOrg_Dropdown, chosenType: .tenantCanSearch)
            ]
            searchSettingDataSource.forEach { info in
                if publicPermissionMeta.searchEntityType == .container && userPermisson?.canManageMeta() == false {
                    info.isGray = true
                } else if let type = publicPermissionMeta.blockOptions?.searchEntity(with: info.chosenType.rawValue), type != .none {
                    info.isGray = true
                    info.blockType = type
                } else {
                    info.isGray = false
                    info.blockType = nil
                }
                info.isSelect = publicPermissionMeta.searchEntity == info.chosenType
            }
        } else {
            searchSettingDataSource = []
        }
    }

    func setupPasswordSettingDataSource() {
        passwordSettingDataSource.removeAll()
        passwordSettingDataSource.append(PasswordSwitchTableViewCellModel())
        if hasLinkPassword, !linkPassword.isEmpty {
            passwordSettingDataSource.append(PasswordDisplayTableViewCellModel(password: linkPassword))
        }
    }
    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }
}

extension ShareLinkEditViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let serviceURL = NSURL(string: Self.links.0)
        let privaceURL = NSURL(string: Self.links.1)
        if URL == serviceURL! as URL || URL == privaceURL! as URL {
            return true
        } else {
            return false
        }
    }
}

extension ShareLinkEditViewController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = ShareLinkEditSection.instance(rawValue: section, searchSettingEnable: searchSettingEnable) else { return 1 }
        switch section {
        case .shareLinkSetting:
            return editLinkInfoDataSource.count
        case .searchableSetting:
            return searchSettingDataSource.count
        case .passwordSwitch:
            return passwordSettingDataSource.count
        case .passwordChangeAndCopy:
            return 2
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = ShareLinkEditSection.instance(rawValue: indexPath.section, searchSettingEnable: searchSettingEnable) else { return UITableViewCell() }
        switch section {
        case .shareLinkSetting:
            return makeShareLinkSettingCell(indexPath: indexPath)
        case .searchableSetting:
            return makeSearchSettingCell(indexPath: indexPath)
        case .passwordSwitch:
            return makePasswordSwitchCell(indexPath: indexPath)
        case .passwordChangeAndCopy:
            return makePasswordChangeAndCopyCell(indexPath: indexPath)
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let section = ShareLinkEditSection.instance(rawValue: indexPath.section, searchSettingEnable: searchSettingEnable) else { return }
        didSelectRowAt(indexPath: indexPath, section: section)
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = ShareLinkEditSection.instance(rawValue: section, searchSettingEnable: searchSettingEnable) else { return 0 }
        return section.heightForHeaderInSection
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let section = ShareLinkEditSection.instance(rawValue: section, searchSettingEnable: searchSettingEnable) else { return 0 }
        return section.heightForFooterInSection(enableAnonymousAccess: enableAnonymousAccess)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = ShareLinkEditSection.instance(rawValue: section, searchSettingEnable: searchSettingEnable) else { return nil }
        return section.viewForHeaderInSection
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let section = ShareLinkEditSection.instance(rawValue: section, searchSettingEnable: searchSettingEnable) else { return nil }
        return section.viewForFooterInSection(enableAnonymousAccess: enableAnonymousAccess, isFolder: fileEntryIsFolder)
    }

    private func confirmUpdate(info: EditLinkInfo) {
        if shouldShowAnyOneAccessAlert(info: info) {
            showAnyOneAccessAlertByState(info: info)
        } else {
            updatePermissions(editLinkInfo: info)
            publicPermissionTracker.report(getReportingAction(chosenType: info.chosenType))
            permStatistics?.reportPermissionShareEditClick(shareEntity: shareEntity, editLinkInfo: info)
            return
        }
    }

    private func didSelectRowAt(indexPath: IndexPath, section: ShareLinkEditSection) {
        let row = indexPath.row
        switch section {
        case .shareLinkSetting:
            guard row >= 0, row < editLinkInfoDataSource.count else { return }
            let model = editLinkInfoDataSource[indexPath.row]
            
            if let dataModel = model as? EditLinkInfo {
                // 点击已选中的选项，忽略不处理
                guard dataModel.chosenType != previousChoice else { return }
                if showExternalAccessTip(info: dataModel) {
                    return
                }
                if showBlockOptionTip(info: dataModel) {
                    return
                }
                if showPartnerAccessTip(info: dataModel) {
                    return
                }
                if notifyPartnerAccessConflict(info: dataModel) {
                    return
                }
                confirmUpdate(info: dataModel)
            }
        case .searchableSetting:
            guard row >= 0, row < searchSettingDataSource.count else {
                DocsLogger.error("row: \(row) out of bounds! searchSettingDataSource.count: \(searchSettingDataSource.count)")
                return
            }
            let model = searchSettingDataSource[indexPath.row]
            if model.isSelect {
                return
            }
            if showSearchBlockOptionTip(info: model) {
                return
            }
            updatePermissions(searchSettingInfo: model)
            return
        case .passwordSwitch:
            return
        case .passwordChangeAndCopy:
            guard let cellType = PasswordSettingPlainTextCellType(rawValue: row) else { return }
            switch cellType {
            case .changePassword:
                permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: shareEntity.type, click: .changePassword, target: .noneTargetView)
                self.refreshPassword()
                self.passwordSettingTracker.report(action: .changePassword)
            case .copyLinkAndPassword:
                guard !linkPassword.isEmpty else {
                    DocsLogger.info("passowrd is nil!")
                    return
                }
                permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: shareEntity.type, click: .copyLinkAndPassword, target: .noneTargetView)
                self.copyLinkAndPassword(with: linkPassword)
                self.passwordSettingTracker.report(action: .copy)
            }
        }
    }

    private func showBlockOptionTip(info: EditLinkInfo) -> Bool {
        if info.isGray, let blockType = info.blockType {
            let externalAccessType: BlockOptions.ExternalAccessSwitchType
            if let adminExternalAccess = publicPermissionMeta.adminExternalAccess {
                externalAccessType = adminExternalAccess
            } else {
                externalAccessType = publicPermissionMeta.canCross ? .open : .close
            }
            let reason = blockType.linkShareEntityBlockReason(isWiki: shareEntity.wikiV2SingleContainer,
                                                              isFolder: shareEntity.isFolder,
                                                              externalAccessType: externalAccessType)
            showToast(text: reason, type: .tips)
            return true
        }
        return false
    }
    
    private func showSearchBlockOptionTip(info: SearchSettingInfo) -> Bool {
        if publicPermissionMeta.searchEntityType == .container && userPermisson?.canManageMeta() == false && userPermisson?.canSinglePageManageMeta() == true {
            showToast(text: BundleI18n.SKResource.LarkCCM_Perm_UnableToModifySearchSettingsForCurrentPageAndSubpage_Tooltip, type: .tips)
            return true
        }
        if info.isGray, let blockType = info.blockType {
            let externalAccessType: BlockOptions.ExternalAccessSwitchType
            if let adminExternalAccess = publicPermissionMeta.adminExternalAccess {
                externalAccessType = adminExternalAccess
            } else {
                externalAccessType = publicPermissionMeta.canCross ? .open : .close
            }
            let reason = blockType.linkShareEntityBlockReason(isWiki: shareEntity.wikiV2SingleContainer,
                                                              isFolder: shareEntity.isFolder,
                                                              externalAccessType: externalAccessType)
            showToast(text: reason, type: .tips)
            return true
        }
        return false
    }

    //2.0 提示 "无法切换至该选项，请先开启"允许文档被分享至关联组织""
    private func showPartnerAccessTip(info: EditLinkInfo) -> Bool {
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare {
            return false
        }
        guard shareEntity.spaceSingleContainer || shareEntity.wikiV2SingleContainer else {
            return false
        }
        guard !publicPermissionMeta.partnerTenantAccessEnable else {
            return false
        }
        if info.chosenType == .partnerRead || info.chosenType == .partnerEdit {
            let text = shareEntity.isFolder
                ? BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_EnableTrustParty_folder_toast
                : BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_EnableTrustParty_toast
            showToast(text: text, type: .tips)
            return true
        }
        return false
    }

    // 从关联组织切换到其他类型时，需要给提示
    private func notifyPartnerAccessConflict(info: EditLinkInfo) -> Bool {
        guard let adminExternalAccess = publicPermissionMeta.adminExternalAccess,
              let externalAccessEntity = publicPermissionMeta.externalAccessEntity else {
                  // 读不到关联组织相关字段不处理
                  return false
              }
        let partnerTenantChoices: Set<ShareLinkChoice> = [.partnerEdit, .partnerRead]
        guard let previousChoice = previousChoice, partnerTenantChoices.contains(previousChoice), !partnerTenantChoices.contains(info.chosenType) else {
            // 不是从 partnerTenant 调整到其他选项不处理
            return false
        }
        guard adminExternalAccess != .partnerTenant else {
            // 如果admin允许关联组织共享，不需要提示
            return false
        }
        // 提醒修改后无法选回关联组织链接分享
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Share_Confirm)
        dialog.setContent(text: BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario3)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            self?.confirmUpdate(info: info)
        })
        present(dialog, animated: true, completion: nil)
        return true
    }

    //2.0 提示 "无法切换至该选项，请先开启"允许文档被分享至组织外""
    private func showExternalAccessTip(info: EditLinkInfo) -> Bool {
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare {
            return false
        }
        guard shareEntity.spaceSingleContainer || shareEntity.wikiV2SingleContainer else {
            return false
        }
        guard !publicPermissionMeta.externalAccessEnable else {
            return false
        }
        if info.chosenType >= ShareLinkChoice.anyoneRead {
            let text = shareEntity.isFolder
                ? BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_Enable_folder_toast
                : BundleI18n.SKResource.CreationMobile_ECM_ExternalShare_SwitchOption_Enable_toast
            showToast(text: text, type: .tips)
            return true
        }
        return false
    }

    /// 是否 显示任何人都可以访问、编辑弹框
    private func shouldShowAnyOneAccessAlert(info: EditLinkInfo) -> Bool {
        // 上一次选中互联网，不显示弹窗
        if previousChoice == .anyoneRead || previousChoice == .anyoneEdit {
            return false
        }
        // 海外C端用户
        let outsideToCFlag = DomainConfig.envInfo.isChinaMainland != true && isToC == true
        if outsideToCFlag {
            return false
        }
        return info.chosenType >= ShareLinkChoice.anyoneRead
    }

    /// 显示任何人都可以访问、编辑弹框
    private func showAnyOneAccessAlertByState(info: EditLinkInfo) {
        permStatistics?.reportPermissionPromptView(fromScene: .shareLink)
        let isForm = shareEntity.isForm
        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()
        if isForm {
            if hasUserField || hasAttachmentField {
                showFormAnyOneAccessAlertBySpecialField(info: info)
                return
            }
            self.updatePermissions(editLinkInfo: info)
            return
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Share_Confirm)
        let textView = makeToastMessage(selectedData: info)
        textView.textColor = UDColor.textTitle
        dialog.setContent(view: textView)
        let cancelButtonText = BundleI18n.SKResource.Doc_Facade_Cancel
        let okButtonText = BundleI18n.SKResource.Doc_Facade_Confirm
        dialog.addSecondaryButton(text: cancelButtonText, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else {
                return true
            }
            self.permStatistics?.reportPermissionPromptClick(click: .cancel,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            self.publicPermissionTracker.shareLinkReport(.externalPublicShareCancel,
                                                         permissionCount: self.publicPermissionMeta.linkShareEntity.rawValue,
                                                         whetherRemind: dialog.isChecked)
            return true
        })
        dialog.addDestructiveButton(text: okButtonText, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else {
                return true
            }
            self.permStatistics?.reportPermissionPromptClick(click: .confirm,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            self.updatePermissions(editLinkInfo: info)
            self.publicPermissionTracker.shareLinkReport(.externalPublicShareOK, permissionCount: self.publicPermissionMeta.linkShareEntity.rawValue, whetherRemind: dialog.isChecked)
            self.publicPermissionTracker.report(self.getReportingAction(chosenType: info.chosenType))
            self.permStatistics?.reportPermissionShareEditClick(shareEntity: self.shareEntity, editLinkInfo: info)
            return true
        })
        present(dialog, animated: true, completion: nil)
    }

    /// 有附件和人员字段时bitable表单显示任何人都可以访问、编辑弹框
    func showFormAnyOneAccessAlertBySpecialField(info: EditLinkInfo) {
        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()

        let dialog = UDDialog()

        var title = ""
        if hasUserField {
            if hasAttachmentField {
                title = BundleI18n.SKResource.Bitable_Form_AttachmentAndPersonFieldNoticeTitle
            } else {
                title = BundleI18n.SKResource.Bitable_Form_PersonFieldNoticeTitle
            }
        } else if hasAttachmentField {
            title = BundleI18n.SKResource.Bitable_Form_AttachmentFieldNoticeTitle
        }
        if isNewForm {
            self.title = BundleI18n.SKResource.Bitable_NewSurvey_Sharing_Mobile_ResponsePermission_Title
        }

        dialog.setTitle(text: title)
        let textView = makeFormToastMessage(selectedData: info)
        textView.textColor = UDColor.textTitle

        dialog.setContent(view: textView)
        let okButtonText = BundleI18n.SKResource.Bitable_Common_ButtonGotIt

        dialog.addPrimaryButton(text: okButtonText, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else {
                return true
            }
            self.permStatistics?.reportPermissionPromptClick(click: .confirm,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            self.updatePermissions(editLinkInfo: info)
            self.publicPermissionTracker.shareLinkReport(.externalPublicShareOK, permissionCount: self.publicPermissionMeta.linkShareEntity.rawValue, whetherRemind: dialog.isChecked)
            self.publicPermissionTracker.report(self.getReportingAction(chosenType: info.chosenType))
            return true
        })

        present(dialog, animated: true, completion: { [weak self] in
            self?.shareEntity.formsCallbackBlocks.formEventTracing()
        })
    }

    func getReportingAction(chosenType: ShareLinkChoice) -> PublicPermissionTracker.Action {
        switch chosenType {
        case .close:
            return .urlVisitSwtichClose
        case .orgRead:
            return .visitWithPermissionReadable
        case .orgEdit:
            return .visitWithPermissionEditable
        case .anyoneRead:
            return .visitWithPermissionAnyReadable
        case .anyoneEdit:
            return .visitWithPermissionAnyEditable
        // TODO: 更新埋点字段
        case .partnerRead:
            return .visitWithPermissionAnyReadable
        case .partnerEdit:
            return .visitWithPermissionAnyEditable
        }
    }
}

extension ShareLinkEditViewController: PermissionTopTipViewDelegate {
    public func handleTitleLabelClicked(_ tipView: PermissionTopTipView, index: Int, range: NSRange) {
        let params = ["type": shareEntity.type.rawValue]
        HostAppBridge.shared.call(ShowUserProfileService(userId: shareEntity.ownerID, fileName: shareEntity.title, fromVC: self, params: params))
    }
}

extension ShareLinkEditViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
