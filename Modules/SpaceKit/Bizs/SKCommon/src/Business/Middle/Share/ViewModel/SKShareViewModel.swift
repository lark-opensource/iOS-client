//
//  SKShareViewModel.swift
//  SKBrowser
//
//  Created by CJ on 2021/4/11.
//
//  swiftlint:disable file_length 

import SKFoundation
import SwiftyJSON
import RxSwift
import SKInfra

enum RequestState {
    case requesting
    case success
    case failure
}

public final class SKShareViewModel {
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var fetchShareBizRequest: DocsRequest<JSON>?
    private var updatePublicPermissionRequest: DocsRequest<JSON>?
    private var unlockPermissionRequest: DocsRequest<Bool>?
    private(set) var userPermissions: UserPermissionAbility?
    private(set) var requestUserPermissionsState: RequestState = .requesting
    private(set) var publicPermissions: PublicPermissionMeta?
    private(set) var shareEntity: SKShareEntity
    private var bizParameter: SpaceBizParameter?
    private(set) var isInVideoConference: Bool
    private let disposeBag = DisposeBag()
    // 单容器版本文件夹用户权限
    public var permStatistics: PermissionStatistics?
    public var noPermission: Bool?
    private(set) var userPermissionRequestInfo: UserPermissionRequestInfo?
    public var isDocVersion: Bool {
        return self.shareEntity.versionInfo != nil
    }
    
    var isNewForm = false
    var isNewFormUser = false
    var formEditable: Bool?

    public init(shareEntity: SKShareEntity,
                bizParameter: SpaceBizParameter? = nil,
                isInVideoConference: Bool = false) {
        self.bizParameter = bizParameter
        self.shareEntity = shareEntity
        self.isInVideoConference = isInVideoConference
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: shareEntity.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: shareEntity.objToken)

        var bitableParameters: BitableParameters?
        if shareEntity.isFormV1 {
            bitableParameters = BitableParameters(bitableType: .app,
                                                  isFullScreen: true,
                                                  bitableId: shareEntity.formShareFormMeta?.token ?? "",
                                                  tableId: shareEntity.formShareFormMeta?.tableId ?? "",
                                                  viewId: shareEntity.formShareFormMeta?.viewId ?? "",
                                                  viewType: .form)
        } else if shareEntity.isFormV2 {
            bitableParameters = BitableParameters(
                bitableType: .app,
                isFullScreen: true,
                bitableId: shareEntity.bitableShareEntity?.param.baseToken ?? "",
                tableId: shareEntity.bitableShareEntity?.param.tableId ?? "",
                viewId: shareEntity.bitableShareEntity?.param.viewId ?? "",
                viewType: .form
            )
        }

        let ccmCommonParameters = CcmCommonParameters(fileId: shareEntity.encryptedObjToken,
                                                      fileType: shareEntity.type.name,
                                                      appForm: isInVideoConference ? "vc" : "none",
                                                      subFileType: shareEntity.fileType,
                                                      module: fromModule(),
                                                      subModule: fromModule(),
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue,
                                                      containerId: bizParameter?.containerID,
                                                      containerType: bizParameter?.containerType,
                                                      bitableParameters: bitableParameters)
        self.permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
    }
    
    private func fromModule() -> String {
        var module = bizParameter?.module.rawValue
        if module == nil || module?.isEmpty == true || module == CcmCommonParameters.Module.unknown.rawValue {
            if shareEntity.isFromWiki {
                module = CcmCommonParameters.Module.wiki.rawValue
            } else {
                switch shareEntity.type {
                case .doc:
                    module = CcmCommonParameters.Module.doc.rawValue
                case .docX:
                    module = CcmCommonParameters.Module.docx.rawValue
                case .sheet:
                    module = CcmCommonParameters.Module.sheet.rawValue
                case .mindnote:
                    module = CcmCommonParameters.Module.mindnote.rawValue
                case .bitable, .bitableSub:
                    module = CcmCommonParameters.Module.bitable.rawValue
                case .slides:
                    module = CcmCommonParameters.Module.slides.rawValue
                case .file:
                    module = CcmCommonParameters.Module.drive.rawValue
                default:
                    module = CcmCommonParameters.Module.unknown.rawValue
                }
            }
        }
        return module ?? CcmCommonParameters.Module.unknown.rawValue
    }
}

extension SKShareViewModel {
//    // 判断分享面板是否要展示表单meta
//    public func showformPanelEntrance() -> Bool {
//        if isDocVersion { return false }
//        return shareEntity.isForm
//    }
    // 判断分享面板是否要展示链接分享入口
    public func showEditLinkSettingEntrance() -> Bool {
        if isDocVersion { return false }
        if shareEntity.onlyShowSocialShareComponent { return false }
        var flag = false
        //文档都展示
        if shareEntity.type.isBizDoc {
            flag = true
        } else {
            if shareEntity.isFolder && shareEntity.spaceSingleContainer {
                flag = publicPermissions?.hasLinkShare ?? true
            } else {
                if shareEntity.isOldShareFolder, shareEntity.isShareFolderRoot {
                    flag = true
                }
            }
        }
        return flag
    }

    // 判断分享面板是否要展示协作者 设置/展示 入口
    public func showCollaboratorsEntrance() -> Bool {
        if isDocVersion { return false }
        if shareEntity.onlyShowSocialShareComponent { return false }
        return true
    }
    
    // 判断分享面板是否要展示权限设置入口
    public func showPermissionSettingEntrance() -> Bool {
        if isDocVersion { return false }
        if shareEntity.onlyShowSocialShareComponent { return false }
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare { return false }
        if shareEntity.isv2Folder {
            return userPermissions?.canManageMeta() ?? true
                || shareEntity.isOwner
        }
        guard shareEntity.type.isBizDoc else {
            return false
        }
        if shareEntity.wikiV2SingleContainer {
            return shareEntity.isOwner ||
                userPermissions?.canManageMeta() ?? true ||
                userPermissions?.canSinglePageManageMeta() ?? true
        }

        let isOwner = shareEntity.isOwner
        let isFullAccess = userPermissions?.canManageMeta() ?? true
        return isOwner || isFullAccess
    }

    public func isPermissionSettingEnabled() -> Bool {
        if shareEntity.type == .sync {
            DocsLogger.info("permission setting disable reason: synced block")
            return false
        }
        return true
    }

    public func isLinkShareEnabled() -> Bool {
        if shareEntity.type == .sync {
            DocsLogger.info("link share disable reason: synced block")
            return false
        }
        return true
    }
}

// MARK: 对外暴露的方法
extension SKShareViewModel {
    // MARK: 获取Form Meta
    public func requestFormShareMeta(completion: ((FormShareMeta?, Error?) -> Void)?) {
        guard shareEntity.isFormV1 else {
            return
        }
        guard let formMeta = shareEntity.formShareFormMeta else {
            spaceAssertionFailure("formMeta is nil")
            return
        }
        
        if let formsShareModel = shareEntity.formsShareModel,
            let shareToken = formsShareModel.shareToken,
            !shareToken.isEmpty {
            let meta = FormShareMeta(
                token: formMeta.token,
                tableId: formMeta.tableId,
                viewId: formMeta.viewId,
                shareType: formMeta.shareType
            )
            meta.updateFlag(true)
            meta.updateShareToken(shareToken)
            self.shareEntity.updateFormMeta(formMeta: meta)
            completion?(meta, nil)
            return
        }
        
        permissionManager.fetchFormShareMeta(token: formMeta.token,
                                             tableID: formMeta.tableId,
                                             viewId: formMeta.viewId,
                                             shareType: formMeta.shareType) { [weak self]  (meta, error) in
            guard let self = self else { return }
            if let shareMeta = meta {
                self.shareEntity.updateFormMeta(formMeta: shareMeta)
            }
            completion?(meta, error)
        }
    }
    
    /// 获取 Bitable Share Meta
    public func requestBitableShareMeta(completion: ((Result<BitableShareMeta, Error>, Int?) -> Void)?) {
        guard let param = shareEntity.bitableShareEntity?.param else {
            spaceAssertionFailure("bitableShareEntity param is nil")
            DocsLogger.error("bitableShareEntity param is nil")
            completion?(.failure(DocsNetworkError.invalidParams), nil)
            return
        }
        permissionManager.fetchBitableShareMeta(param: param) { (result, code) in
            switch result {
            case .success(let meta):
                self.shareEntity.updateBitableShareMeta(meta)
            case .failure(let error):
                break
            }
            completion?(result, code)
        }
    }
    
    // MARK: 获取用户权限和公共权限
    func fetchUserPermissionsAndPublicPermissions(userCompletion: ((Bool) -> Void)?, allCompletion: ((Error?) -> Void)?) {
        let userPermissionsRequest = Completable.create { observer in
            self.fetchUserPermissions { error in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            return Disposables.create()
        }.do(onCompleted: { 
            userCompletion?(true)
        })
        
        let publicPermissionsRequest = Completable.create { observer in
            self.fetchPublicPermissions { _, error in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            return Disposables.create()
        }
        
        Completable.zip(userPermissionsRequest, publicPermissionsRequest).subscribe { [weak self] in
            guard let self = self else { return }
            self.noPermission = false
            let isBitable = self.shareEntity.isFormV1 || self.shareEntity.isBitableSubShare
            if !isBitable, let isOwner = self.publicPermissions?.isOwner {
                self.shareEntity.updateIsOwner(isOwner: isOwner)
            }
            allCompletion?(nil)
        } onError: { error in
            allCompletion?(error)
        }.disposed(by: disposeBag)
        
    }
    
    // MARK: 获取用户权限
    public func fetchUserPermissions(completion: ((Error?) -> Void)?) {
        let tempCompletion: ((Error?) -> Void) = { [weak self] error in
            guard let self = self else { return }
            if self.requestUserPermissionsState == .requesting {
                self.requestUserPermissionsState = error == nil ? .success : .failure
            }
            completion?(error)
        }
        if shareEntity.isFormV1 {
            fetchFormUserPermissions(completion: tempCompletion)
        } else if shareEntity.isBitableSubShare {
            fetchBitableUserPermissions(completion: tempCompletion)
        } else if shareEntity.isFolder {
            fetchShareFolderUserPermissions(completion: tempCompletion)
        } else {
            fetchFileUserPermissions(completion: tempCompletion)
        }
    }
    
    // MARK: 获取公共权限
    public func fetchPublicPermissions(completion: ((Bool, Error?) -> Void)?) {
        if shareEntity.isFolder {
            fetchShareFolderPublicPermissions(completion: completion)
        } else if shareEntity.isFormV1 {
            fetchFormPublicPermissions(completion: completion)
        } else if shareEntity.isBitableSubShare {
            fetchBitablePublicPermissions(completion: completion)
        } else {
            fetchFilePublicPermissions(completion: completion)
        }
    }

    // MARK: 开启/关闭分享表单
    public func updateFormShareMeta(_ flag: Bool, completion: ((Bool) -> Void)?) {
        updateFormMeta(flag, completion: completion)
    }
    
    // MARK: 开启/关闭分享 Bitable
    public func updateBitableShareFlag(_ flag: Bool, completion: ((Error?) -> Void)?) {
        innerUpdateBitableShareFlag(flag, completion: completion)
    }
    
    // MARK: 解锁权限
    public func unlockPermission(completion: ((Bool) -> Void)?) {
        if shareEntity.isFolder {
            unlockShareFolderPermission(completion: completion)
        } else {
            unlockFilePermission(completion: completion)
        }
    }
    
    public func updatePublicPermissions(linkShareEntity: Int, completion: ((Bool, Error?, JSON?) -> Void)?) {
        if shareEntity.isFolder {
            updateShareFolderPublicPermissions(linkShareEntity: linkShareEntity, completion: completion)
        } else {
            updateFilePublicPermissions(linkShareEntity: linkShareEntity, completion: completion)
        }
    }

    public func fetchDocMeta(token: String, type: ShareDocsType, completion: ((ShareBizMeta?, Error?) -> Void)?) {
        fetchShareBizRequest = ShareBizMeta.fetchBizMeta(token: token, type: type, completion: completion)
    }
}

// MARK: Private方法
extension SKShareViewModel {
    // 表单-获取用户权限
    private func fetchFormUserPermissions(completion: ((Error?) -> Void)?) {
        guard let formMeta = shareEntity.formShareFormMeta else {
            spaceAssertionFailure()
            DocsLogger.warning("form meta is nil")
            return
        }
        let token = shareEntity.objToken
        let tableId = formMeta.tableId
        let viewId = formMeta.viewId
        permissionManager.fetchFormUserPermissions(token: token, tableID: tableId, viewId: viewId) { [weak self] mask, error in
            guard let self = self else { return }
            guard let mask = mask else {
                DocsLogger.error("SKShareViewModel fetch form user permission failed", error: error, component: LogComponents.permission)
                completion?(error)
                return
            }
            DocsLogger.info("SKShareViewModel fetch form user permission success", component: LogComponents.permission)
            self.userPermissions = mask
            completion?(nil)
        }
    }
    
    // Bitable-获取用户权限
    private func fetchBitableUserPermissions(completion: ((Error?) -> Void)?) {
        guard let param = shareEntity.bitableShareEntity?.param else {
            spaceAssertionFailure()
            DocsLogger.warning("bitableShareEntity is nil")
            return
        }
        guard !param.isRecordShareV2, !param.isAddRecordShare else {
            // 记录分享二期，分享时候不需要再通过此接口校验用户的分享权限
            completion?(nil)
            return
        }
        permissionManager.fetchBibtaleUserPermissions(
            token: param.baseToken,
            tableID: param.tableId,
            viewId: param.viewId,
            shareType: param.shareType) { [weak self] result, error in
            guard let self = self else {
                return
            }
            guard let result = result else {
                DocsLogger.error("fetch bitable user permission failed", error: error, component: LogComponents.permission)
                let error = error ?? DocsNetworkError.invalidData
                completion?(error)
                return
            }
            DocsLogger.info("fetch bitable user permission success", component: LogComponents.permission)
            self.userPermissions = result
            completion?(nil)
        }
    }

    // 文档-获取用户权限
    private func fetchFileUserPermissions(completion: ((Error?) -> Void)?) {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        permissionManager.fetchUserPermissions(token: token, type: type) { [weak self] info, error in
            guard let self = self else { return }
            guard let info = info else {
                DocsLogger.error("SKShareViewModel fetch file user permission failed", error: error, component: LogComponents.permission)
                completion?(error)
                return
            }
            DocsLogger.info("SKShareViewModel fetch file user permission success", component: LogComponents.permission)
            self.userPermissions = info.mask
            completion?(nil)
        }
    }
    
    // 共享文件夹-获取用户权限
    private func fetchShareFolderUserPermissions(completion: ((Error?) -> Void)?) {
        if shareEntity.spaceSingleContainer {
            let token = shareEntity.objToken
            permissionManager.requestShareFolderUserPermission(token: token, actions: []) { [weak self] (permissions, error) in
                guard let self = self else { return }
                guard let permissions = permissions, error == nil else {
                    DocsLogger.error("SKShareViewModel fetch share folder user permission failed (sc)", error: error, component: LogComponents.permission)
                    completion?(error)
                    return
                }
                DocsLogger.info("SKShareViewModel fetch share folder user permission success (sc)", component: LogComponents.permission)
                self.userPermissions = permissions
                completion?(nil)
            }
        } else {
            let spaceID = shareEntity.spaceID
            // 1.0的个人文件夹是没有spaceID的，就不必请求权限接口了
            if spaceID.isEmpty {
                DocsLogger.info("spaceID is empty")
                completion?(nil)
                return
            }
            permissionManager.getShareFolderUserPermissionRequest(spaceID: spaceID, token: shareEntity.objToken) { [weak self] (permissions, error) in
                guard let self = self else { return }
                guard let permissions = permissions, error == nil else {
                    DocsLogger.error("SKShareViewModel fetch share folder user permission failed", error: error, component: LogComponents.permission)
                    completion?(error)
                    return
                }
                DocsLogger.info("SKShareViewModel fetch share folder user permission success", component: LogComponents.permission)
                self.userPermissions = permissions
                completion?(nil)
            }
        }
    }
    
    // 文档-获取公共权限
    private func fetchFilePublicPermissions(completion: ((Bool, Error?) -> Void)?) {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        permissionManager.fetchPublicPermissions(token: token, type: type) { [weak self] (publicPermissionMeta, error) in
            guard let self = self else { return }
            guard error == nil else {
                DocsLogger.error("SKShareViewModel fetch file public permission failed", error: error, component: LogComponents.permission)
                completion?(false, error)
                return
            }
            DocsLogger.info("SKShareViewModel fetch file public permission success", component: LogComponents.permission)
            self.publicPermissions = publicPermissionMeta
            completion?(true, nil)
        }
    }
    
    // Bitable-获取公共权限
    private func fetchBitablePublicPermissions(completion: ((Bool, Error?) -> Void)?) {
        if shareEntity.bitableShareEntity?.param.isRecordShareV2 == true, shareEntity.bitableShareEntity?.param.isAddRecordShare == true {
            // 新的 Bitable Record 分享无需设置分享范围，没有 PublicPermission 了
            completion?(true, nil)
            return
        }
        if let shareToken = shareEntity.bitableShareEntity?.meta?.shareToken, !shareToken.isEmpty {
            fetchBitablePublicPermissions(baseToken: shareEntity.objToken, shareToken: shareToken, completion: completion)
            return
        }
        requestBitableShareMeta { (result, code) in
            switch result {
            case .success(let meta):
                self.fetchBitablePublicPermissions(baseToken: self.shareEntity.objToken, shareToken: meta.shareToken, completion: completion)
            case .failure(let error):
                completion?(false, error)
            }
        }
    }
    
    private func fetchBitablePublicPermissions(baseToken: String, shareToken: String, completion: ((Bool, Error?) -> Void)?) {
        permissionManager.fetchBitablePublicPermissions(baseToken: baseToken, shareToken: shareToken) { (result, error) in
            guard let result = result else {
                DocsLogger.error("fetch bitable share permission failed", error: error, component: LogComponents.permission)
                let error = error ?? DocsNetworkError.invalidData
                completion?(false, error)
                return
            }
            DocsLogger.info("fetch bitable share permission success", component: LogComponents.permission)
            self.publicPermissions = result
            completion?(true, nil)
        }
    }

    // form-获取公共权限
    private func fetchFormPublicPermissions(completion: ((Bool, Error?) -> Void)?) {
        let token = shareEntity.objToken
        if let shareToken = shareEntity.formShareFormMeta?.shareToken, !shareToken.isEmpty {
            self.shareEntity.updateFormShareURl()
            fetchFormPublicPermissions(baseToken: token, shareToken: shareToken, completion: completion)
        } else {
            requestFormShareMeta { [weak self] meta, error in
                guard let self = self else { return }
                if error == nil, meta?.shareToken.isEmpty == false {
                    self.fetchFormPublicPermissions(completion: completion)
                } else {
                    completion?(false, error)
                }
            }
        }
    }

    private func fetchFormPublicPermissions(baseToken: String, shareToken: String, completion: ((Bool, Error?) -> Void)?) {
        permissionManager.fetchFormPublicPermissions(baseToken: baseToken, shareToken: shareToken) { [weak self] (publicPermissionMeta, error) in
            guard let self = self else { return }
            guard error == nil else {
                DocsLogger.error("SKShareViewModel fetch form public permission failed", error: error, component: LogComponents.permission)
                completion?(false, error)
                return
            }
            DocsLogger.info("SKShareViewModel fetch form public permission success", component: LogComponents.permission)
            self.publicPermissions = publicPermissionMeta
            completion?(true, nil)
        }
    }

    // 共享文件夹-获取公共权限
    private func fetchShareFolderPublicPermissions(completion: ((Bool, Error?) -> Void)?) {
        if shareEntity.spaceSingleContainer {
            let token = shareEntity.objToken
            permissionManager.requestV2FolderPublicPermissions(token: token, type: shareEntity.type.rawValue) { [weak self] (publicPermissionMeta, error) in
                guard let self = self else { return }
                guard error == nil else {
                    DocsLogger.error("SKShareViewModel fetch share folder public permission failed (sc)", error: error, component: LogComponents.permission)
                    completion?(false, error)
                    return
                }
                guard let publicPermissionMeta = publicPermissionMeta else { return }
                DocsLogger.info("SKShareViewModel fetch share folder public permission success (sc)", component: LogComponents.permission)
                self.publicPermissions = publicPermissionMeta
                completion?(true, nil)
            }
        } else {
            let spaceID = shareEntity.spaceID
            if spaceID.isEmpty {
                DocsLogger.info("spaceID is empty")
                completion?(true, nil)
                return
            }
            permissionManager.getOldShareFolderPublicPermissionsRequest(spaceID: spaceID, token: shareEntity.objToken) { [weak self] (shareFolderPermissionMeta, error) in
                guard let self = self else { return }
                guard error == nil else {
                    DocsLogger.error("SKShareViewModel fetch share folder public permission failed", error: error, component: LogComponents.permission)
                    completion?(false, error)
                    return
                }
                DocsLogger.info("SKShareViewModel fetch share folder public permission success", component: LogComponents.permission)
                guard let shareFolderPermissionMeta = shareFolderPermissionMeta else { return }
                self.publicPermissions = shareFolderPermissionMeta
                completion?(true, nil)
            }
        }
    }

    // form 开启/关闭分享表单
    private func updateFormMeta(_ flag: Bool, completion: ((Bool) -> Void)?) {
        guard shareEntity.isFormV1 else {
            return
        }
        guard let formMeta = shareEntity.formShareFormMeta else {
            spaceAssertionFailure("formMeta is nil")
            return
        }
        permissionManager.updateFormShareMeta(token: formMeta.token,
                                              tableID: formMeta.tableId,
                                              viewId: formMeta.viewId,
                                              recordId: nil,
                                              shareType: formMeta.shareType,
                                              flag: flag) { [weak self] (ret, shareToken, _) in
            guard let self = self else { return }
            if ret {
                self.shareEntity.formShareFormMeta?.updateFlag(flag)
                if self.shareEntity.formShareFormMeta?.shareToken.isEmpty == true,
                   let newShareToken = shareToken,
                   newShareToken.isEmpty == false {
                    self.shareEntity.formShareFormMeta?.updateShareToken(newShareToken)
                    self.shareEntity.updateFormShareURl()
                }
            }
            completion?(ret)
        }
    }
    
    // Bitable 开启、关闭分享
    private func innerUpdateBitableShareFlag(_ flag: Bool, completion: ((Error?) -> Void)?) {
        guard let bitableEntity = shareEntity.bitableShareEntity else {
            spaceAssertionFailure()
            DocsLogger.error("bitableShareEntity is nil")
            return
        }
        permissionManager.updateBitableShareFlag(flag, param: bitableEntity.param) { result in
            switch result {
            case .success(let updateToken):
                if let originMeta = bitableEntity.meta {
                    let updateMeta = BitableShareMeta(
                        flag: flag ? .open : .close,
                        objType: originMeta.objType,
                        shareToken: updateToken,
                        shareType: originMeta.shareType,
                        constraintExternal: originMeta.constraintExternal
                    )
                    self.shareEntity.updateBitableShareMeta(updateMeta)
                }
                completion?(nil)
            case .failure(let error):
                completion?(error)
            }
        }
    }
    
    // 文档-解锁
    private func unlockFilePermission(completion: ((Bool) -> Void)?) {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        unlockPermissionRequest = PermissionManager.unlockFile(token: token, type: type) { (success, _) in
            if let success = success, success == true {
                completion?(success)
            } else {
                completion?(false)
            }
        }
    }

    // 共享文件夹-解锁
    private func unlockShareFolderPermission(completion: ((Bool) -> Void)?) {
        let token = shareEntity.objToken
        unlockPermissionRequest = PermissionManager.unlockShareFolder(token: token) { (success, _) in
            if let success = success, success == true {
                completion?(success)
            } else {
                completion?(false)
            }
        }
    }
    
    private func updateShareFolderPublicPermissions(linkShareEntity: Int, completion: ((Bool, Error?, JSON?) -> Void)?) {
        if shareEntity.spaceSingleContainer {
            let token = shareEntity.objToken
            updatePublicPermissionRequest = PermissionManager.updateV2FolderPublicPermissions(
                token: token,
                type: shareEntity.type.rawValue,
                params: ["link_share_entity": linkShareEntity]) { (success, error, json) in
                if let success = success, success == true {
                    completion?(true, nil, json)
                } else {
                    completion?(false, error, json)
                }
            }
        } else {
            let spaceID = shareEntity.spaceID
            /// 文件夹的「所有人可阅读」权限的值为4
            var linkPerm = linkShareEntity
            if linkShareEntity == 3 {
                linkPerm += 1
            }
            let params: [String: Any] = ["space_id": spaceID,
                                         "link_perm": linkPerm]
            updatePublicPermissionRequest = PermissionManager.updateOldShareFolderPublicPermissionRequest(params: params) { (response, error) in
                guard let response = response, let code = response["code"].int else {
                    completion?(false, error, response)
                    return
                }
                guard code == 0 else {
                    completion?(false, error, response)
                    return
                }
                completion?(true, nil, response)
            }
        }
    }
    
    private func updateFilePublicPermissions(linkShareEntity: Int, completion: ((Bool, Error?, JSON?) -> Void)?) {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        let params: [String: Any] = ["type": type,
                                     "token": token,
                                     "link_share_entity": linkShareEntity]
        
        updatePublicPermissionRequest = PermissionManager.updateBizsPublicPermission(type: type, params: params, complete: {  (response, error) in
            guard let code = response?["code"].int else {
                completion?(false, error, response)
                DocsLogger.error("update Bizs public permission")
                return
            }
            guard code == 0 else {
                completion?(false, error, response)
                DocsLogger.error("update Bizs public permission failed, error code is \(code)")
                return
            }
            completion?(true, nil, response)
        })
    }
}
