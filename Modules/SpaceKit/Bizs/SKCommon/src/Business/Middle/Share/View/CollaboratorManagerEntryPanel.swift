//
//  CollaboratorManagerEntryPanel.swift
//  SKBrowser
//
//  Created by liweiye on 2020/10/27.
//
//  swiftlint:disable file_length

import Foundation
import SkeletonView
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignIcon
import SKInfra

protocol CollaboratorManagerPanelDelegate: AnyObject {
    func requestOpenCollaboratorList()
    func collaboratorInvitedEnableUpdated(enable: Bool)
    func requestDisplayUserProfile(userId: String, fileName: String?)
}

/// 协作者管理 入口面板
class CollaboratorManagerEntryPanel: UIControl {

    weak var delegate: CollaboratorManagerPanelDelegate?
    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var publicPermissionsRequest: DocsRequest<PublicPermissionMeta>?
    private var folderCollaboratorsRequest: DocsRequest<[Collaborator]>?

    private var totalCollaboratorCount: Int = 0 // 文档的协作者是分页拉取的，这个数字用来保存总数
    private(set) var publicPermissions: PublicPermissionMeta?
    private(set) var userPermissions: UserPermissionAbility?

    private(set) var collaborators: [Collaborator] = []
    private(set) var lastPageLabel: String?

    private(set) var containerPageCollaborators: [Collaborator] = []
    private(set) var containerPageLastPageLabel: String?
    private(set) var singlePageCollaborators: [Collaborator] = []
    private(set) var singlePageLastPageLabel: String?


    // 从业务数据角度判断是否可用
    var panelEnabled: Bool = false {
        didSet {
            self.delegate?.collaboratorInvitedEnableUpdated(enable: canInviteCollaborator)
            reloadTitleStatus()
        }
    }

    // 无权限分享面板优化需求下，可以直接搜索和邀请协作者
    var canSearchCollaborator: Bool {
        return panelEnabled || shareEntity.type.isBizDoc
    }

    var canInviteCollaborator: Bool {
        canSearchCollaborator
    }
    
    // 用于控制是否置灰和是否可点击
    private(set) var requestState: RequestState = .requesting

    private let shareEntity: SKShareEntity
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UDColor.iconN1
        imageView.image = UDIcon.groupOutlined.withRenderingMode(.alwaysTemplate)
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private lazy var avatarGroupView: CollaboratorAvatarGroupView = {
        let view = CollaboratorAvatarGroupView(maxAvatarCount: 5)
        return view
    }()
    
    private lazy var bottomSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = UDColor.bgFloat
            }
        }
    }

//    // 强制置灰使用此属性
//    override var isEnabled: Bool {
//        didSet {
//            reloadTitleStatus()
//        }
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(_ shareEntity: SKShareEntity) {
        self.shareEntity = shareEntity
        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UDColor.bgFloat
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(avatarGroupView)
        addTapGesture()
        iconImageView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(avatarGroupView.snp.left).offset(-12)
        }

        avatarGroupView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        reloadTitleStatus()
        
        if UserScopeNoChangeFG.WJS.baseLarkFormRemindInviterEnable, shareEntity.formsShareModel != nil {
            addSubview(bottomSeperatorView)
            bottomSeperatorView.snp.makeConstraints { (make) in
                make.left.equalTo(iconImageView)
                make.right.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
    }

    private func addTapGesture() {
        addTarget(self, action: #selector(didReceiveTapGesture), for: .touchUpInside)
    }

    private func reloadTitleStatus() {
        switch requestState {
        case .success where panelEnabled:
            isEnabled = true
            avatarGroupView.isEnabled = true
            iconImageView.tintColor = UDColor.iconN1
            titleLabel.textColor = UDColor.textTitle
            
        case .success where !panelEnabled:
            isEnabled = true
            avatarGroupView.isEnabled = false
            iconImageView.tintColor = UDColor.iconDisabled
            titleLabel.textColor = UDColor.textDisabled
            
        case .failure:
            isEnabled = true
            avatarGroupView.isEnabled = false
            iconImageView.tintColor = UDColor.iconDisabled
            titleLabel.textColor = UDColor.textDisabled
            
        default:
            isEnabled = false
            avatarGroupView.isEnabled = false
            iconImageView.tintColor = UDColor.iconDisabled
            titleLabel.textColor = UDColor.textDisabled
        }
    }

    @objc
    private func didReceiveTapGesture() {
        //1.0文件夹，共享文件夹-子目录 不能分享
        if shareEntity.isFolder, !shareEntity.spaceSingleContainer,
           shareEntity.isOldShareFolder, !shareEntity.isShareFolderRoot {
            return
        }
        
        switch requestState {
        case .failure:
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Wiki_SeverError, on: self.window ?? self)
            
        case .success where !panelEnabled:
            self.showToast(text: BundleI18n.SKResource.Doc_Permission_NoPermissionAccessCollaborators, type: .failure)
            
        case .success where panelEnabled:
            delegate?.requestOpenCollaboratorList()
            
        default:
            break
        }
    }
}

// MARK: - 网络数据请求（文件夹/共享文件夹的请求逻辑）
extension CollaboratorManagerEntryPanel {
    func reloadData(completion: ((ShareViewControllerState) -> Void)? = nil) {
        permissionManager.collaboratorStore.clear()
        DispatchQueue.main.async {
            guard !self.avatarGroupView.hasBeenUpdated else { return }
            self.avatarGroupView.showLoading()
        }
        requestCollaborators(completion: completion)
    }

    /// 协作者详情请求(分为表单、文档、文件夹)
    ///
    /// - Parameter finish: 协作者详情
    private func requestCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        if shareEntity.isFormV1 {
            requestFormCollaborators(completion: completion)
        } else if shareEntity.isBitableSubShare {
            requestBitableCollaborators(completion: completion)
        } else if shareEntity.isFolder {
            requestFolderCollaborators(completion: completion)
        } else if shareEntity.isSyncedBlock {
            requestBlockCollaborators(completion: completion)
        } else {
            requestFileCollaborators(completion: completion)
        }
    }

    /// 文件夹协作者列表请求
    private func requestFolderCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        //如果是共享文件夹，发起网络请求获取协作者
        folderCollaboratorsRequest?.cancel()
        if shareEntity.isFolder {
            if shareEntity.spaceSingleContainer {
                let token = shareEntity.objToken
                permissionManager.requestShareFolderCollaborators(token: token, shouldFetchNextPage: false) { [weak self] (result, error) in
                    guard let self = self else { return }
                    guard error == nil else {
                        DocsLogger.error("collaborator manager entry panel fetch share folder collaborator error", error: error, component: LogComponents.permission)
                        self.requestState = .failure
                        self.reloadTitleStatus()
                        completion?(.error)
                        return
                    }
                    completion?(.fetchData)
                    self.requestState = .success
                    if let totalCollaboratorCount = result?.totalCollaboratorCount {
                        self.totalCollaboratorCount = totalCollaboratorCount
                    }
                    if let collaborators = self.permissionManager.getCollaborators(for: self.shareEntity.objToken, collaboratorSource: .defaultType) {
                        self.collaborators = collaborators
                        self.refreshTitleAndAvatar()
                    }
                    completion?(.setData)
                }
            } else {
                if shareEntity.isOldShareFolder {
                    let spaceID = shareEntity.shareFolderInfo?.spaceID ?? ""
                    if spaceID.isEmpty {
                        spaceAssertionFailure("spaceID 不能为空")
                        DocsLogger.info("spaceID 不能为空")
                    }
                    folderCollaboratorsRequest = PermissionManager.getOldShareFolderCollaboratorsRequest(spaceID: spaceID, complete: { [weak self] (collaborators, error) in
                        guard let self = self else { return }
                        guard error == nil else {
                            DocsLogger.error("collaborator manager entry panel fetch old share folder collaborator error", error: error, component: LogComponents.permission)
                            self.requestState = .failure
                            self.reloadTitleStatus()
                            completion?(.error)
                            return
                        }
                        completion?(.fetchData)
                        self.requestState = .success
                        if let collaborators = collaborators {
                            let augToken = self.permissionManager.augmentedToken(of: self.shareEntity.objToken )
                            self.permissionManager.collaboratorStore.updateCollaborators(for: augToken, collaborators)
                            self.collaborators = collaborators
                            self.refreshTitleAndAvatar()
                        }
                        completion?(.setData)
                    })
                } else if shareEntity.isCommonFolder {
                    //如果是个人文件夹，不用发网络请求，本地构建一个
                    completion?(.fetchData)
                    guard let avatarUrl = User.current.info?.avatarURL else { return }
                    collaborators = [Collaborator]()
                    let defaultPerm: UserPermissionMask = []
                    let selfCollaborator = Collaborator(rawValue: CollaboratorType.user.rawValue,
                                                        userID: "",
                                                        name: "",
                                                        avatarURL: avatarUrl,
                                                        avatarImage: nil,
                                                        userPermissions: defaultPerm.updatePermRoleType(permRoleType: .fullAccess),
                                                        groupDescription: nil)
                    collaborators.append(selfCollaborator)
                    requestState = .success
                    panelEnabled = true
                    reloadAvatarLinks()
                    completion?(.setData)
                }
            }
        } else {
            DocsLogger.info("unknow folder type")
            spaceAssertionFailure("unknow folder type")
        }
    }

    private func refreshTitleAndAvatar(isExternal: Bool? = nil) {
        guard requestState == .success else { return }
        if shareEntity.isFormV1 {
            if let isExternal = isExternal {
                self.panelEnabled = !isExternal && shareEntity.formCanShare
                self.reloadTitleStatus()
                self.reloadAvatarLinks()
            }
        } else if shareEntity.isBitableSubShare {
            if let isExternal = isExternal {
                self.panelEnabled = !isExternal && shareEntity.bitableShareEntity?.isShareReady == true
                self.reloadTitleStatus()
                self.reloadAvatarLinks()
            }
            
        } else if shareEntity.isFolder {
            if shareEntity.spaceSingleContainer {
                panelEnabled = userPermissions?.canShare() ?? false
            } else {
                panelEnabled = shareEntity.shareFolderInfo?.shareRoot ?? false
                //1.0的文件夹，外部协作者不可邀请协作者，也不可以查看协作者，相当于没有分享权限，需要端上做前置处理。
                if panelEnabled, !shareEntity.tenantID.isEmpty,
                    let tenantID = User.current.info?.tenantID, shareEntity.tenantID != tenantID {
                    panelEnabled = false
                }
            }
            reloadTitleStatus()
            //刷新协作者图像
            reloadAvatarLinks()
        } else {
            self.panelEnabled = self.userPermissions?.canShare() ?? false
            self.reloadTitleStatus()

            if self.panelEnabled {
                self.reloadAvatarLinks()
            } else {
                self.loadOwnerAvatarOnly()
            }
        }
    }

    // MARK: 加新协作者类型记得在这里补充 avatar 情形
    private func reloadAvatarLinks() {
        reorderData(&collaborators)
        let totalCount: Int
        if shareEntity.isFolder {
            if shareEntity.spaceSingleContainer {
                totalCount = totalCollaboratorCount
            } else {
                // 旧版共享文件夹没有分页，返回的数据就是全量数据
                totalCount = collaborators.count
            }
        } else {
            totalCount = totalCollaboratorCount
        }
        avatarGroupView.update(collaborators: collaborators, totalCount: totalCount)
        avatarGroupView.isEnabled = panelEnabled
    }

    private func loadOwnerAvatarOnly() {
        if let owner = collaborators.first(where: { $0.isOwner || $0.type == .hostDoc }) {
            let totalCount: Int
            if shareEntity.isFolder {
                if shareEntity.spaceSingleContainer {
                    totalCount = totalCollaboratorCount
                } else {
                    // 旧版共享文件夹没有分页，返回的数据就是全量数据
                    totalCount = collaborators.count
                }
            } else {
                totalCount = totalCollaboratorCount
            }
            avatarGroupView.update(owner: owner, totalCount: totalCount) { [weak self] in
                guard let self = self else { return }
                // 在无权限下，点击owner需要显示profile
                if owner.type == .user {
                    self.delegate?.requestDisplayUserProfile(userId: owner.userID, fileName: nil)
                } else {
                    // 1.0子目录不提示
                    if self.shareEntity.isFolder, !self.shareEntity.spaceSingleContainer, !self.shareEntity.isShareFolderRoot {
                        return
                    }
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_NoPermissionAccessCollaborators, type: .failure)
                }
            }
        } else {
            avatarGroupView.cleanUp()
        }
    }
}

// MARK: - 文档信息请求逻辑
extension CollaboratorManagerEntryPanel {
    /// 文档协作者请求
    func requestFileCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        let objToken = shareEntity.objToken
        let type = shareEntity.type
        permissionManager.fetchCollaborators(token: objToken, type: type.rawValue, shouldFetchNextPage: false, collaboratorSource: .defaultType) { [weak self] (result, error) in
            guard let self = self else { return }
            guard let result = result, error == nil else {
                DocsLogger.error("collaborator manager entry panel fetch collaborator error", error: error, component: LogComponents.permission)
                self.requestState = .failure
                self.panelEnabled = true
                self.reloadTitleStatus()
                completion?(.error)
                return
            }
            completion?(.fetchData)
            self.requestState = .success
            self.collaborators = self.permissionManager.getCollaborators(for: self.shareEntity.objToken, collaboratorSource: .defaultType) ?? []
            self.totalCollaboratorCount = result.totalCollaboratorCount
            self.lastPageLabel = result.pageLabel

            self.refreshTitleAndAvatar()
            completion?(.setData)
            
            if self.shareEntity.wikiV2SingleContainer {
                self.requestFileContainerCollaborators()
                self.requestFileSinglePageCollaborators()
            }
        }
    }

    /// wiki请求container协作者
    func requestFileContainerCollaborators() {
        let objToken = shareEntity.objToken
        let type = shareEntity.type

        permissionManager.fetchCollaborators(token: objToken, type: type.rawValue, shouldFetchNextPage: false, collaboratorSource: .container) { [weak self] (_, _) in
            guard let self = self else { return }
            self.containerPageCollaborators = self.permissionManager.getCollaborators(for: self.shareEntity.objToken, collaboratorSource: .container) ?? []
        }
    }

    /// wiki请求单页面协作者
    func requestFileSinglePageCollaborators() {
        let objToken = shareEntity.objToken
        let type = shareEntity.type

        permissionManager.fetchCollaborators(token: objToken, type: type.rawValue, shouldFetchNextPage: false, collaboratorSource: .singlePage) { [weak self] (_, _) in
            guard let self = self else { return }
            let singlePageCollaborators: [Collaborator] = self.permissionManager.getCollaborators(for: self.shareEntity.objToken,
                                                                                                  collaboratorSource: .singlePage) ?? []
            self.singlePageCollaborators = singlePageCollaborators
        }
    }
}

extension CollaboratorManagerEntryPanel {

    /// 同步块协作者请求
    func requestBlockCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        let objToken = shareEntity.objToken
        let type = shareEntity.type
        permissionManager.fetchBlockCollaborators(token: objToken, type: type.rawValue, shouldFetchNextPage: false) { [weak self] (result, error) in
            guard let self = self else { return }
            guard let result = result, error == nil else {
                DocsLogger.error("collaborator manager entry panel fetch collaborator error", error: error, component: LogComponents.permission)
                self.requestState = .failure
                self.panelEnabled = true
                self.reloadTitleStatus()
                completion?(.error)
                return
            }
            completion?(.fetchData)
            self.requestState = .success
            self.collaborators = self.permissionManager.getCollaborators(for: self.shareEntity.objToken, collaboratorSource: .defaultType) ?? []
            self.totalCollaboratorCount = result.totalCollaboratorCount
            self.lastPageLabel = result.pageLabel

            self.refreshTitleAndAvatar()
            completion?(.setData)
        }
    }
}

// MARK: - 表单协作者请求
extension CollaboratorManagerEntryPanel {

    func requestFormCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        guard let formMeta = shareEntity.formShareFormMeta else {
            completion?(.error)
            spaceAssertionFailure()
            return
        }
        let token = shareEntity.objToken
        let tableID = formMeta.tableId
        let viewID = formMeta.viewId
        
        if let shareToken = shareEntity.formShareFormMeta?.shareToken, !shareToken.isEmpty {
            self.permissionManager.fetchFormCollaborators(token: token, shareToken: shareToken, shouldFetchNextPage: false, lastPageLabel: nil) { [weak self] (result, error) in
                guard let self = self else { return }
                guard let result = result, error == nil else {
                    DocsLogger.error("collaborator manager entry panel fetch collaborator error", error: error, component: LogComponents.permission)
                    self.requestState = .failure
                    self.panelEnabled = true
                    self.reloadTitleStatus()
                    completion?(.error)
                    return
                }
                completion?(.fetchData)
                self.requestState = .success
                self.collaborators = self.permissionManager.getCollaborators(for: shareToken,
                                                                             collaboratorSource: .defaultType) ?? []
                self.totalCollaboratorCount = result.totalCollaboratorCount
                self.lastPageLabel = result.pageLabel
                let isExternal = result.isFileOwnerFromAnotherTenant
                self.refreshTitleAndAvatar(isExternal: isExternal)
                completion?(.setData)
            }
            return
        }

        permissionManager.fetchFormShareMeta(token: token, tableID: tableID, viewId: viewID) { [weak self] meta, _ in
            guard let self = self else { return }
            guard let shareToken = meta?.shareToken, !shareToken.isEmpty else {
                completion?(.error)
                return
            }
            self.permissionManager.fetchFormCollaborators(token: token, shareToken: shareToken, shouldFetchNextPage: false, lastPageLabel: nil) { [weak self] (result, error) in
                guard let self = self else { return }
                guard let result = result, error == nil else {
                    DocsLogger.error("collaborator manager entry panel fetch collaborator error", error: error, component: LogComponents.permission)
                    self.requestState = .failure
                    self.panelEnabled = true
                    self.reloadTitleStatus()
                    completion?(.error)
                    return
                }
                completion?(.fetchData)
                self.requestState = .success
                self.collaborators = self.permissionManager.getCollaborators(for: shareToken,
                                                                             collaboratorSource: .defaultType) ?? []
                self.totalCollaboratorCount = result.totalCollaboratorCount
                self.lastPageLabel = result.pageLabel
                let isExternal = result.isFileOwnerFromAnotherTenant
                self.refreshTitleAndAvatar(isExternal: isExternal)
                completion?(.setData)
            }
        }
    }
    
    func requestBitableCollaborators(completion: ((ShareViewControllerState) -> Void)? = nil) {
        guard let bitableEntity = shareEntity.bitableShareEntity else {
            completion?(.error)
            spaceAssertionFailure()
            DocsLogger.error("bitableShareEntity is nil")
            return
        }
        permissionManager.fetchBitableShareMeta(param: bitableEntity.param) { (result, code) in
            switch result {
            case .success(let meta):
                self.permissionManager.fetchBitableCollaborators(
                    token: bitableEntity.param.baseToken,
                    shareToken: meta.shareToken,
                    shouldFetchNextPage: false
                ) { [weak self] (result, error) in
                    guard let self = self else {
                        completion?(.error)
                        return
                    }
                    guard let result = result, error == nil else {
                        DocsLogger.error("collaborator manager entry panel fetch collaborator error", error: error, component: LogComponents.permission)
                        self.requestState = .failure
                        self.panelEnabled = true
                        self.reloadTitleStatus()
                        completion?(.error)
                        return
                    }
                    completion?(.fetchData)
                    self.requestState = .success
                    self.collaborators = self.permissionManager.getCollaborators(for: meta.shareToken, collaboratorSource: .defaultType) ?? []
                    self.totalCollaboratorCount = result.totalCollaboratorCount
                    self.lastPageLabel = result.pageLabel
                    let isExternal = result.isFileOwnerFromAnotherTenant
                    self.refreshTitleAndAvatar(isExternal: isExternal)
                    completion?(.setData)
                }
            case .failure(let error):
                completion?(.error)
            }
        }
    }
}

extension CollaboratorManagerEntryPanel {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        UDToast.docs.showMessage(text, on: self.window ?? self, msgType: type)
    }
}

// MARK: - 数据排序
extension CollaboratorManagerEntryPanel {
    private func reorderData(_ list: inout [Collaborator]) {
        moveOwnerToFirst(&list)
        if shareEntity.wikiV2SingleContainer {
            moveNewWikiMemberOwnerToFirst(&list)
            moveNewWikiEditorOwnerToFirst(&list)
            moveNewWikiAdminToFirst(&list)
        }
    }
    
    private func moveOwnerToFirst(_ list: inout [Collaborator]) {
        var dstIndex = -1
        for index in 0 ..< list.count where list[index].isOwner {
            dstIndex = index
        }
        if dstIndex >= 0 {
            let data = list[dstIndex]
            list.remove(at: dstIndex)
            list.insert(data, at: 0)
        }
    }
    
    private func moveNewWikiMemberOwnerToFirst(_ list: inout [Collaborator]) {
        var dstIndex = -1
        for index in 0 ..< list.count where list[index].type == .newWikiMember {
            dstIndex = index
        }
        if dstIndex >= 0 {
            let data = list[dstIndex]
            list.remove(at: dstIndex)
            list.insert(data, at: 0)
        }
    }
    
    private func moveNewWikiEditorOwnerToFirst(_ list: inout [Collaborator]) {
        var dstIndex = -1
        for index in 0 ..< list.count where list[index].type == .newWikiEditor {
            dstIndex = index
        }
        if dstIndex >= 0 {
            let data = list[dstIndex]
            list.remove(at: dstIndex)
            list.insert(data, at: 0)
        }
    }
    
    private func moveNewWikiAdminToFirst(_ list: inout [Collaborator]) {
        var dstIndex = -1
        for index in 0 ..< list.count where list[index].type == .newWikiAdmin {
            dstIndex = index
        }
        if dstIndex >= 0 {
            let data = list[dstIndex]
            list.remove(at: dstIndex)
            list.insert(data, at: 0)
        }
    }
}

extension CollaboratorManagerEntryPanel {
    public func updateUserAndPublicPermissions(userPermissions: UserPermissionAbility?,
                                               publicPermissions: PublicPermissionMeta?,
                                               completion: ((ShareViewControllerState) -> Void)?) {
        self.userPermissions = userPermissions
        self.publicPermissions = publicPermissions
        self.refreshTitleAndAvatar()
    }
}
