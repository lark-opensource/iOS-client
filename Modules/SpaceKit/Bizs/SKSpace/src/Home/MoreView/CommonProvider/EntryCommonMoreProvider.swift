//
//  EntryCommonMoreProvider.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/5/10.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import RxSwift
import RxRelay
import SpaceInterface
import SKInfra

// 实体通用操作逻辑
class EntryCommonMoreProvider {

    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachableUpdated: Observable<Bool> { reachabilityRelay.asObservable() }
    private let secretLabelRelay = BehaviorRelay<SecretLevel?>(value: nil)
    // 允许 wiki 通过其他方式获取后注入
    let fileSizeRelay = BehaviorRelay<Int64?>(value: nil)
    private let retentionLabelRelay = BehaviorRelay<Bool>(value: false)
    // 实体自身权限
    private let permissionService: UserPermissionService
    private let permissionRelay: BehaviorRelay<UserPermissionAbility?>
    private var permissionUpdated: Observable<UserPermissionAbility?> { permissionRelay.asObservable() }
    // 父容器权限
    private let parentPermissionService: UserPermissionService
    private let parentPermissionUpdated: Observable<UserPermissionAbility?>

    private let context: CommonMoreProviderContext
    var entry: SpaceEntry { context.entry }
    // 部分操作依赖文档类型，需要取 Wiki 的真实类型和 token
    lazy var contentMeta: SpaceMeta = {
        if let wikiEntry = entry as? WikiEntry,
           let wikiInfo = wikiEntry.wikiInfo {
            return SpaceMeta(objToken: wikiInfo.objToken, objType: wikiInfo.docsType)
        }
        return SpaceMeta(objToken: entry.objToken, objType: entry.type)
    }()

    private let config: CommonMoreProviderConfig

    weak var handler: SpaceMoreActionHandler?
    var reloadHandler: ((Bool) -> Void)?

    private let disposeBag = DisposeBag()

    init(context: CommonMoreProviderContext,
         config: CommonMoreProviderConfig,
         permissionContext: CommonMoreProviderPermissionContext) {
        self.context = context
        self.config = config
        self.permissionService = permissionContext.permissionService
        self.permissionRelay = permissionContext.permissionRelay
        self.parentPermissionService = permissionContext.parentPermissionService
        self.parentPermissionUpdated = permissionContext.parentPermissionUpdated
        setup()
    }

    // 原则上，不被其他场景（folder、shortcut、wiki等）复用的网络请求都下沉到这里
    // 权限网络请求因为需要被多个 SubProvider 复用，统一在上层处理
    private func setup() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .subscribe(onNext: { [weak self] reachable in
                self?.reachabilityRelay.accept(reachable)
                self?.reloadHandler?(false)
            })
            .disposed(by: disposeBag)

        // 请求密级信息
        SecretLevel.secLabelSingle(token: entry.objToken, type: entry.type)
            .subscribe(onSuccess: { [weak self] level in
                self?.secretLabelRelay.accept(level)
                self?.reloadHandler?(false)
            })
            .disposed(by: disposeBag)
        // Wiki 场景要取真实内容的类型与 token 获取文件大小
        if contentMeta.objType == .file {
            SpaceMoreAPI.fetchFileSize(fileToken: contentMeta.objToken)
                .subscribe(onSuccess: { [weak self] size in
                    self?.fileSizeRelay.accept(size)
                    self?.entry.fileSize = UInt64(size)
                    self?.reloadHandler?(false)
                })
                .disposed(by: disposeBag)
        }

        var infoTypes: Set<SpaceMoreAPI.AggregationInfoType> = [
            .isPined,
            .isStared,
        ]
        if contentMeta.objType.isSupportSubscribe {
            infoTypes.insert(.isSubscribed)
        }

        let itemForAggregationInfo = {
            // 如果是 Wiki shortcut，需要用 Wiki token 拉状态
            if entry.originInWiki, let wikiToken = entry.bizNodeToken {
                return SpaceItem(objToken: wikiToken, objType: .wiki)
            } else {
                return SpaceItem(objToken: entry.objToken, objType: entry.type)
            }
        }()
        SpaceMoreAPI.fetchAggregationInfo(item: itemForAggregationInfo, infoTypes: infoTypes)
            .subscribe(onSuccess: { [weak self] info in
                guard let self = self else { return }
                if let isPined = info.isPined {
                    self.entry.updatePinedStatus(isPined)
                }
                if let isStared = info.isStared {
                    self.entry.updateStaredStatus(isStared)
                }
                if let isSubscribed = info.isSubscribed {
                    self.entry.subscribed = isSubscribed
                }
                self.reloadHandler?(true)
            })
            .disposed(by: disposeBag)

        SpaceMoreAPI.fetchRetentionEnable(token: entry.objToken, docsType: entry.docsType)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] status in
                guard let self = self else { return }
                self.retentionLabelRelay.accept(status)
                self.reloadHandler?(false)
            })
            .disposed(by: disposeBag)
    }
}

extension EntryCommonMoreProvider {
    var share: SpaceMoreItem {
        SpaceMoreItem(type: .share,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !config.forbiddenItems.contains(.share))
        },
                      enableCheckers: {
            NetworkChecker(input: reachableUpdated)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .share, reason: reason, entry: self.entry)
                return
            }
            self.handler?.share(entry: self.entry, sourceView: self.context.sourceView, shareSource: .grid)
        }
    }

    var delete: SpaceMoreItem {
        // type 用 removeFromList 是因为文案不是删除，而是移除
        // 最近列表，离线列表为移除，其他列表是删除
        let itemType: MoreItemType
        switch config.listType {
        case .offline, .recent:
            itemType = .removeFromList
        default:
            itemType = .delete
        }
        return SpaceMoreItem(type: itemType,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !config.forbiddenItems.contains(.delete))
            BizChecker(disableReason: "", staticChecker: config.listType != .shareToMe) // 与我共享列表要隐藏
            if config.listType == .shareFolder {
                // 共享文件夹列表下删除按钮展示，由当前是否是文件夹owner控制
                BizChecker(disableReason: "", staticChecker: entry.ownerIsCurrentUser)
            }
        },
                      enableCheckers: {
            // 离线列表跳过网络判断
            if config.listType != .offline {
                NetworkChecker(input: reachableUpdated)
            }
            // 离线列表、最近列表跳过权限判断
            if config.listType != .recent && config.listType != .offline {
                if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                    UserPermissionServiceChecker(service: permissionService,
                                                 operation: .moveThisNode)
                    if !UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
                        // FG 关要看父节点权限
                        UserPermissionServiceChecker(service: parentPermissionService,
                                                     operation: .moveSubNode)
                    }
                } else {
                    UserPermissionTypeChecker(input: permissionUpdated, permissionType: .beMoved)
                    if !UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
                        // FG 关要看父节点权限
                        V2FolderPermissionChecker(input: parentPermissionUpdated, permissionType: .moveFrom)
                    }
                }
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .delete, reason: reason, entry: self.entry)
                return
            }
            self.handler?.delete(entry: self.entry)
        }
    }
}

// MARK: - 受 allowItems 控制的操作
extension EntryCommonMoreProvider {

    var createShortcut: SpaceMoreItem {
        return SpaceMoreItem(type: .addShortCut,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.addShortCut) ?? true)
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .addShortCut, reason: reason, entry: self.entry)
                return
            }
            self.handler?.addShortCut(for: self.entry)
        }
    }

    var star: SpaceMoreItem {
        let type: MoreItemType = entry.stared ? .unStar : .star
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !config.forbiddenItems.contains(type))
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(type) ?? true)
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleFavorites(for: self.entry)
        }
    }

    var pin: SpaceMoreItem {
        let type: MoreItemType = entry.pined ? .unPin : .pin
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: !config.forbiddenItems.contains(type))
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(type) ?? true)
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleQuickAccess(for: self.entry)
        }
    }

    var manualOffline: SpaceMoreItem {
        let type: MoreItemType = entry.isSetManuOffline ? .cancelManualOffline : .manualOffline
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            if contentMeta.objType == .file {
                BizChecker(disableReason: "", staticChecker: DriveFeatureGate.driveEnabled)
            }
            BizChecker(disableReason: "", staticChecker: entry.canSetManualOffline)
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.manualOffline) ?? true)
        },
                             enableCheckers: {}) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleManualOffline(for: self.entry)
        }
    }

    var sensitivtyLabel: SpaceMoreItem {
        var title = ""
        let style = entry.moreViewItemRightStyle
        switch style {
        case .normal:
            title = entry.secureLabelName ?? ""
        case .fail:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_GetInfoFailed
        case .notSet:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Unspecified
        case .none:
            title = ""
        @unknown default:
            title = ""
        }

        return SpaceMoreItem(type: .sensitivtyLabel, style: .rightLabel(title: title)) {
            NetworkChecker(input: reachableUpdated)
            BizChecker(disableReason: "", staticChecker: LKFeatureGating.sensitivtyLabelEnable)
            if !UserScopeNoChangeFG.TYP.permissionSecretDetail {
                if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                    UserPermissionServiceChecker(service: permissionService,
                                                 operation: .modifySecretLabel)
                } else {
                    UserPermissionTypeChecker(input: permissionUpdated, permissionType: .modifySecretLevel)
                }
            }
            BizChecker(disableReason: "", staticChecker: entry.canSetSecLabel == .yes)
            BizChecker(disableReason: "", staticChecker: entry.typeSupportSecurityLevel == true)
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.sensitivtyLabel) ?? true)
            SecretLevelChecker(input: secretLabelRelay.asObservable())
        } enableCheckers: {

        } handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .sensitivtyLabel, reason: reason, entry: self.entry)
                return
            }
            self.handler?.openSensitivtyLabelSetting(entry: self.entry, level: self.secretLabelRelay.value)
        }
    }

    var importToOnlineDocument: SpaceMoreItem {
        // wiki 不支持转在线文档，所以这里暂时用原始的 type
        let (canImport, _) = ImportToOnlineFile.getImportInfo(fileType: entry.type, fileSubtype: entry.fileType)
        let type = MoreItemType.importAsDocs(entry.fileType)
        return SpaceMoreItem(type: type,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: canImport)
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(type) ?? true)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .importToOnlineDocument)
                .custom(reason: BundleI18n.SKResource.Doc_Facade_ImportFailedNoImportPermission)
            }
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            BizChecker(disableReason: BundleI18n.SKResource.Drive_Drive_ImportFailedSupport, staticChecker: ImportToOnlineFile.featureEnabled)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .importToOnlineDocument)
                .custom(reason: BundleI18n.SKResource.Doc_Facade_ImportFailedNoImportPermission)
            } else {
                SecurityPolicyChecker(permissionType: .createCopy, docsType: contentMeta.objType, token: contentMeta.objToken)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .export)
                    .custom(reason: BundleI18n.SKResource.Doc_Facade_ImportFailedNoImportPermission)
            }
            DriveFileSizeChecker(input: fileSizeRelay.asObservable(), sizeLimit: ImportToOnlineFile.importSizeLimit)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Docs_import_failed_TooLarge(String(ImportToOnlineFile.importSizeLimit / 1024 / 1024)))
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: type, reason: reason, entry: self.entry)
                return
            }
            self.handler?.importAsDocs(for: self.entry)
        }
    }

    var moveTo: SpaceMoreItem {
        let isSupport: Bool = config.listType.hasMoveToAction

        var shouldCheckSameTenantWithOwner: Bool = !entry.isSameTenantWithOwner
        if UserScopeNoChangeFG.ZYP.spaceMoveToEnable {
            // 移动到入口补齐的FG开启时，与 Android 统一，无需判断文档Owner是否与当前用户同租户
            shouldCheckSameTenantWithOwner = false
        }
        // 跨租户或不支持申请移动文件夹时，要判断权限
        let needCheckPermission = (shouldCheckSameTenantWithOwner)
        || (entry.type == .folder && !UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled)

        return SpaceMoreItem(type: .moveTo,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: isSupport)
            BizChecker(disableReason: "", staticChecker: !config.forbiddenItems.contains(.moveTo))
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.moveTo) ?? true)
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if needCheckPermission {
                if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                    UserPermissionServiceChecker(service: permissionService,
                                                 operation: .moveThisNode)
                    .custom(reason: BundleI18n.SKResource.Doc_List_MakeMoveForbidden(entry.type.i18Name))
                    UserPermissionServiceChecker(service: parentPermissionService,
                                                 operation: .moveSubNode)
                } else {
                    UserPermissionTypeChecker(input: permissionUpdated, permissionType: .beMoved)
                        .custom(reason: BundleI18n.SKResource.Doc_List_MakeMoveForbidden(entry.type.i18Name))
                    V2FolderPermissionChecker(input: parentPermissionUpdated, permissionType: .moveFrom)
                }
            }
            if entry.type != .wiki {
                BizChecker(disableReason: BundleI18n.SKResource.LarkCCM_CM_MoveDoc_Error_Toast,
                           staticChecker: entry.contentExistInSpace)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .moveTo, reason: reason, entry: self.entry)
                return
            }
            self.handler?.moveTo(for: self.entry)
        }
    }

    // drive 下载
    var saveToLocal: SpaceMoreItem {
        return SpaceMoreItem(type: .saveToLocal,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: contentMeta.objType == .file)
            BizChecker(disableReason: "", staticChecker: DriveFeatureGate.driveEnabled)
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.saveToLocal) ?? true)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .saveFileToLocal)
                .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            }
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            DriveFileSizeChecker(input: fileSizeRelay.asObservable(), sizeLimit: nil)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .saveFileToLocal)
                .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            } else {
                SecurityPolicyChecker(permissionType: .download, docsType: contentMeta.objType, token: contentMeta.objToken)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .preview)
                    .custom(reason: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .export)
                    .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .saveToLocal, reason: reason, entry: self.entry)
                return
            }
            self.handler?.saveToLocal(for: self.entry, originName: nil)
        }
    }

    var openWithOtherApp: SpaceMoreItem {
        return SpaceMoreItem(type: .openWithOtherApp,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: contentMeta.objType == .file)
            BizChecker(disableReason: "", staticChecker: DriveFeatureGate.driveEnabled)
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.openWithOtherApp) ?? true)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                // TODO: FG 下线后合并下 hiddenChecker 和 enableChecker
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .openWithOtherApp)
                .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            }
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .openWithOtherApp)
                .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            } else {
                SecurityPolicyChecker(permissionType: .openWithOtherApp, docsType: contentMeta.objType, token: contentMeta.objToken)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .preview)
                    .custom(reason: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .export)
                    .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .openWithOtherApp, reason: reason, entry: self.entry)
                return
            }
            self.handler?.openWithOtherApp(for: self.entry,
                                           originName: nil,
                                           sourceView: self.context.sourceView)
        }
    }

    var copyLink: SpaceMoreItem {
        SpaceMoreItem(type: .copyLink,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.copyLink) ?? true)
            BizChecker(disableReason: "", staticChecker: UserScopeNoChangeFG.PLF.shareChannelDisable == false)
        },
                      enableCheckers: {}) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .copyLink, reason: reason, entry: self.entry)
                return
            }
            self.handler?.copyLink(for: self.entry)
        }
    }

    var copyFile: SpaceMoreItem {
        SpaceMoreItem(type: .copyFile,
                      hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: contentMeta.objType.isSupportCopy)
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.copyFile) ?? true)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .createCopy)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplate_NoCopyPerm_Toast_Mob)
            }
        },
                      enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .createCopy)
                .custom(reason: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplate_NoCopyPerm_Toast_Mob)
            } else {
                // CAC 应该用 Wiki 内容的 token + type
                SecurityPolicyChecker(permissionType: .createCopy, docsType: contentMeta.objType, token: contentMeta.objToken)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .duplicate)
                    .custom(reason: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplate_NoCopyPerm_Toast_Mob)
            }
            if contentMeta.objType == .file {
                DriveFileSizeChecker(input: fileSizeRelay.asObservable(), sizeLimit: nil)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .copyFile, reason: reason, entry: self.entry)
                return
            }
            self.handler?.copyFile(for: self.entry, fileSize: self.fileSizeRelay.value)
        }
    }

    var subscribe: SpaceMoreItem {
        let type = contentMeta.objType
        return SpaceMoreItem(type: .subscribe,
                             style: .mSwitch(isOn: entry.subscribed, needLoading: true),
                             hiddenCheckers: {
            BizChecker(disableReason: "") {
                if type == .doc || type == .docX || type == .sheet { return true }
                return false
            }
            if !entry.isSameTenantWithOwner {
                if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                    UserPermissionServiceChecker(service: permissionService,
                                                 operation: .edit)
                } else {
                    UserPermissionTypeChecker(input: permissionUpdated, permissionType: .edit)
                }
            }

            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.subscribe) ?? true)
        },
                             enableCheckers: {}) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .subscribe, reason: reason, entry: self.entry)
                return
            }
            self.handler?.toggleSubscribe(for: self.entry) { [weak self] _ in
                guard let self else { return }
                // 订阅状态更新需要刷新下switch的状态
                self.reloadHandler?(true)
            }
        }
    }
    // 文档类导出到本地
    var exportToLocal: SpaceMoreItem {
        let type = contentMeta.objType
        return SpaceMoreItem(type: .exportDocument,
                             hiddenCheckers: {
            if type == .docX {
                BizChecker(disableReason: "", staticChecker: LKFeatureGating.docxExportEnabled)
            } else {
                BizChecker(disableReason: "", staticChecker: type.isSupportExport)
            }

            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.exportDocument) ?? true)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .export)
                .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            }
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .export)
                .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            } else {
                SecurityPolicyChecker(permissionType: .export, docsType: contentMeta.objType, token: contentMeta.objToken)
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .export)
                    .custom(reason: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .exportDocument, reason: reason, entry: self.entry)
                return
            }
            let canEdit: Bool
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                canEdit = self.permissionService.validate(operation: .edit, bizDomain: .ccm).allow
            } else {
                canEdit = self.permissionRelay.value?.canEdit() ?? false
            }
            self.handler?.exportDocument(for: self.entry,
                                         haveEditPermission: canEdit,
                                         sourceView: self.context.sourceView)
        }
    }

    var retention: SpaceMoreItem {
        return SpaceMoreItem(type: .retention,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: LKFeatureGating.retentionEnable)
            RxBizChecker(disableReason: "", input: retentionLabelRelay.asObservable())
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.retention) ?? true)
        }, enableCheckers: {
            NetworkChecker(input: reachableUpdated)
        }, handler: { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .retention, reason: reason, entry: self.entry)
                return
            }
            self.handler?.retentionHandle(entry: self.entry)
        })
    }

    var rename: SpaceMoreItem {
        SpaceMoreItem(type: .rename,
                      hiddenCheckers: {},
                      enableCheckers: {
            NetworkChecker(input: reachableUpdated)
            if UserScopeNoChangeFG.WWJ.permissionSDKEnabledInMore {
                UserPermissionServiceChecker(service: permissionService,
                                             operation: .edit)
                    .custom(reason: BundleI18n.SKResource.Doc_Facade_MoreRenameTips(entry.type.i18Name))
            } else {
                UserPermissionTypeChecker(input: permissionUpdated, permissionType: .edit)
                    .custom(reason: BundleI18n.SKResource.Doc_Facade_MoreRenameTips(entry.type.i18Name))
            }
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .rename, reason: reason, entry: self.entry)
                return
            }
            self.handler?.rename(entry: self.entry)
        }
    }

    // MARK: - Legacy V1
    var addTo: SpaceMoreItem {
        return SpaceMoreItem(type: .addTo,
                             hiddenCheckers: {
            BizChecker(disableReason: "", staticChecker: config.allowItems?.contains(.addTo) ?? true)
        },
                             enableCheckers: {
            NetworkChecker(input: reachableUpdated)
        }) { [weak self] _, forbiddenReason in
            guard let self else { return }
            if let reason = forbiddenReason {
                self.handler?.handle(disabledAction: .addTo, reason: reason, entry: self.entry)
                return
            }
            self.handler?.addToFolder(for: self.entry)
        }
    }
}
