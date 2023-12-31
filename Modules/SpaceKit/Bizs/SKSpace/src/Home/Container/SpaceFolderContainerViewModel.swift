//
//  SpaceFolderContainerViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/26.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import EENavigator
import LarkContainer

// 负责控制文件夹列表的容器状态
protocol SpaceFolderContainerViewModel {
    typealias StateChange = SpaceFolderContainerController.StateChange
    typealias Action = SpaceFolderContainerController.Action
    typealias TitleState = (title: String, isExternal: Bool, showSecondTag: Bool)
    var stageChanged: Driver<StateChange> { get }
    var titleUpdated: Driver<TitleState> { get }
    var actionSignal: Signal<Action> { get }
    var searchType: DocsSearchFromType { get }
    var moduleForSearch: String { get }
    var organizationTagValue: String { get }
    //业务公参
    var bizParams: SpaceBizParameter { get }

    // 开始处理加载逻辑
    func setup()
    func viewDidAppear()
}

extension SpaceFolderContainerViewModel {
    func viewDidAppear() {}
}

// 普通文件夹的控制逻辑
class SpaceCommonFolderContainerViewModel: SpaceFolderContainerViewModel {
    var organizationTagValue: String {
        return viewModel.folderEntry?.organizationTagValue ?? BundleI18n.SKResource.Doc_Widget_External
    }

    enum InitialState {
        case requirePermission(ownerName: String)
        case requirePassword
        case normal
    }

    private let stageRelay: BehaviorRelay<StateChange>
    var stageChanged: Driver<StateChange> { stageRelay.asDriver() }

    private let titleRelay: BehaviorRelay<TitleState>
    var titleUpdated: Driver<TitleState> {
        titleRelay.asDriver().withLatestFrom(stageChanged) { title, state -> TitleState in
            switch state {
            case .displayContent:
                return title
            default:
                return (title: BundleI18n.SKResource.Doc_Facade_Folder, isExternal: false, showSecondTag: false)
            }
        }
    }

    private let actionInput = PublishRelay<Action>()
    var actionSignal: Signal<Action> { actionInput.asSignal() }

    var searchType: DocsSearchFromType {
        .folder(token: folderToken,
                name: titleRelay.value.title,
                isShareFolder: viewModel.isShareFolder)
    }

    var moduleForSearch: String {
        viewModel.isShareFolder ? "shared_folder" : "folder"
    }

    // 只用于监听无权限、需要密码的场景
    private let viewModel: PermissionRestrictedFolderListViewModel
    private let disposeBag = DisposeBag()

    private let dataManager: SpaceFolderListDataProvider

    private var folderToken: FileListDefine.ObjToken { viewModel.folderToken }
    private var folderType: FolderType { viewModel.folderType }
    private var hasAppearred = false

    var bizParams: SpaceBizParameter

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         title: String,
         viewModel: PermissionRestrictedFolderListViewModel,
         initialState: InitialState,
         dataManager: SpaceFolderListDataProvider = SKDataManager.shared) {
        self.userResolver = userResolver
        self.dataManager = dataManager
        bizParams = SpaceBizParameter(module: viewModel.isShareFolder ? .sharedSubFolder : .personalSubFolder, fileID: viewModel.folderToken, fileType: .folder)
        bizParams.isBlank = viewModel.isBlank

        titleRelay = BehaviorRelay(value: (title: title, isExternal: false, showSecondTag: false))

        self.viewModel = viewModel
        switch initialState {
        case .normal:
            stageRelay = BehaviorRelay<StateChange>(value: .displayContent)
        case let .requirePermission(ownerName):
            stageRelay = BehaviorRelay<StateChange>(value: .displayContent)
            stageRelay.accept(.noPermission(canApply: .allow(ownerName: ownerName), folderType: folderType) { [weak self] (tips, permRole) in
                self?.requestPermission(tips: tips, permRole: permRole)
            })
        case .requirePassword:
            // 闭包里要用 self，但是 stageRelay 需要先初始化，所以这里先初始化再赋值
            stageRelay = BehaviorRelay<StateChange>(value: .displayContent)
            stageRelay.accept(.requirePassword(folderToken: folderToken, folderType: folderType) { [weak self] success in
                self?.handlePasswordResult(success: success)
            })
        }
        
        dataManager.spaceEntry(token: TokenStruct(token: folderToken)) { [weak self] entry in
            guard let self = self else { return }
            if let folder = entry {
                let isExternal = Self.isExternal(folderEntry: folder)
                self.titleRelay.accept((title: title, isExternal: isExternal, showSecondTag: false))
            }
        }
    }

    func setup() {
        viewModel.listStatusChanged.emit(onNext: { [weak self] result in
            self?.update(result: result)
        })
        .disposed(by: disposeBag)
    }
    
    func viewDidAppear() {
        hasAppearred = true
        guard folderType.v2 else { return }
        V2FolderListAPI.reportViewFolder(token: folderToken).subscribe().disposed(by: disposeBag)
    }

    private func handlePasswordResult(success: Bool) {
        guard success else {
            return
        }
        stageRelay.accept(.displayContent)
        viewModel.checkFolderPermission()
        viewModel.notifyPullToRefresh()
    }

    private func requestPermission(tips: String?, permRole: Int) {
        actionInput.accept(.showHUD(.loading))
        viewModel.requestPermission(message: tips ?? "", roleToRequest: permRole)
            .subscribe { [weak self] in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_Facade_SendRequestSuccessfully)))
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                self.handle(requestPermissionError: error)
            }
            .disposed(by: disposeBag)
    }

    private func handle(requestPermissionError error: Error) {
        if DocsNetworkError.error(error, equalTo: .permissionLockDuringUpgrade) {
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast)))
            return
        }
        if DocsNetworkError.error(error, equalTo: .passiveBlock) {
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.LarkCCM_BlockSettings_UnableToRequestPerm_Toast)))
            return
        }

        guard let nsError = error as NSError?, nsError.code == DocsNetworkError.Code.executivesBlock.rawValue else {
            DocsLogger.error("space.folder.common.vm --- request permission failed with error", error: error)
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Permission_SendApplyFailed)))
            return
        }
        let alertController = UIAlertController(title: nil,
                                                message: BundleI18n.SKResource.Doc_Permission_NotApplyPermission,
                                                preferredStyle: .alert)
        let messageAttribute = NSMutableAttributedString(string: BundleI18n.SKResource.Doc_Permission_NotApplyPermission)
        messageAttribute.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0),
                                        NSAttributedString.Key.foregroundColor: UIColor.ud.N1000],
                                       range: NSRange(location: 0, length: messageAttribute.length))
        alertController.setValue(messageAttribute, forKey: "attributedMessage")
        let confirmAction = UIAlertAction(title: BundleI18n.SKResource.Doc_Facade_Confirm,
                                          style: .default,
                                          handler: nil)
        alertController.addAction(confirmAction)
        self.actionInput.accept(.present(viewController: alertController, popoverConfiguration: nil))
    }

    private static func isExternal(folderEntry: SpaceEntry) -> Bool {
        guard EnvConfig.CanShowExternalTag.value else { return false }
        guard User.current.info?.isToNewC == false else { return false }
        return folderEntry.isExternal
    }
}

extension SpaceCommonFolderContainerViewModel {

    func update(result: Result<Void, FolderListError>) {
        if let entry = viewModel.folderEntry, let title = entry.realName {
            let isExternal = Self.isExternal(folderEntry: entry)
            titleRelay.accept((title: title, isExternal: isExternal, showSecondTag: false))
        } else if case .success = result {
            // 新建文件夹后，vm.folderEntry 会延迟设置，这里通过 DataManager 异步重新读一次
            dataManager.spaceEntry(token: TokenStruct(token: folderToken)) { [weak self] entry in
                guard let self = self else { return }
                if let folder = entry, let title = folder.realName {
                    let isExternal = Self.isExternal(folderEntry: folder)
                    self.titleRelay.accept((title: title, isExternal: isExternal, showSecondTag: false))
                }
            }
        }

        guard case let .failure(error) = result else {
            stageRelay.accept(.displayContent)
            return
        }

        switch error {
        case let .noPermission(ownerInfo):
            guard let ownerInfo = ownerInfo,
                  let canApply = ownerInfo["can_apply_perm"].bool,
                  canApply else {
                      stageRelay.accept(.noPermission(canApply: .disallow, folderType: folderType, handler: { (_, _) in }))
                      return
                  }
            let ownerName: String
            let aliasInfo = UserAliasInfo(json: ownerInfo["display_name"])
            if let displayName = aliasInfo.currentLanguageDisplayName {
                ownerName = displayName
            } else if NSLocale.current.isChinese == false,
               let enName = ownerInfo["en_name"].string,
               !enName.isEmpty {
                ownerName = enName
            } else {
                ownerName = ownerInfo["name"].stringValue
            }
            stageRelay.accept(.noPermission(canApply: .allow(ownerName: ownerName), folderType: folderType) { [weak self] (tips, permRole) in
                self?.requestPermission(tips: tips, permRole: permRole)
            })
        case .passwordRequired:
            stageRelay.accept(.requirePassword(folderToken: folderToken, folderType: folderType) { [weak self] success in
                self?.handlePasswordResult(success: success)
            })
        case .folderDeleted:
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.SKResource.Doc_List_FolderDeleted)
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
                self?.actionInput.accept(.exit)
            })
            actionInput.accept(.present(viewController: dialog, popoverConfiguration: nil))
        case let .blockByTNS(info):
            DocsLogger.error("redirect to tns H5 within folder list")
            let action = Action.getHostController { [weak self] hostController in
                guard let self = self else { return }
                var rootController = hostController
                while let parent = rootController.parent, !parent.isKind(of: UINavigationController.self) {
                    rootController = parent
                }
                self.userResolver.navigator.push(info.finalURL,
                                                 from: rootController,
                                                 forcePush: true,
                                                 animated: false) { _, _ in
                    hostController.navigationController?.viewControllers.removeAll { $0 == rootController }
                }
            }
            if hasAppearred {
                actionInput.accept(action)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in
                    self?.actionInput.accept(action)
                }
            }
        }
    }
}

// 无特殊权限控制逻辑的 VM
class SpaceDefaultFolderContainerViewModel: SpaceFolderContainerViewModel {
    var organizationTagValue: String { "" }
    var bizParams: SpaceBizParameter
    var isShareFolder: Bool { return false }

    var isBlank: Bool { false }


    var stageChanged: Driver<StateChange> { .just(.displayContent) }
    var titleUpdated: Driver<TitleState>

    var actionSignal: Signal<Action> { .never() }

    let searchType: DocsSearchFromType
    var moduleForSearch: String

    init(title: String, isExternal: Bool, searchType: DocsSearchFromType, module: String, bizParams: SpaceBizParameter) {
        titleUpdated = .just((title: title, isExternal: isExternal, showSecondTag: false))
        self.searchType = searchType
        moduleForSearch = module
        self.bizParams = bizParams
    }

    func setup() {}

    static var myFolderRoot: SpaceDefaultFolderContainerViewModel {
        SpaceDefaultFolderContainerViewModel(title: BundleI18n.SKResource.Doc_List_My_Folder,
                                             isExternal: false,
                                             searchType: .normal,
                                             module: "personal",
                                             bizParams: SpaceBizParameter(module: .personalFolderRoot))
    }

    static var sharedFolderRoot: SpaceDefaultFolderContainerViewModel {
        let title = SettingConfig.singleContainerEnable ? BundleI18n.SKResource.CreationMobile_ECM_FileMigration_Path_title : BundleI18n.SKResource.Doc_List_Shared_Folder
        return SpaceDefaultFolderContainerViewModel(title: title,
                                             isExternal: false,
                                             searchType: .normal,
                                             module: "shared_folder",
                                             bizParams: SpaceBizParameter(module: .sharedFolderRoot))
    }
    
    static var hiddenFolderRoot: SpaceDefaultFolderContainerViewModel {
        return SpaceDefaultFolderContainerViewModel(title: BundleI18n.SKResource.Doc_List_HiddenFolders,
                                                    isExternal: false,
                                                    searchType: .normal,
                                                    module: "hidden_folder",
                                                    bizParams: SpaceBizParameter(module: .sharedFolderRoot))
    }
    
    static var shareFolderV2Root: SpaceDefaultFolderContainerViewModel {
        return SpaceDefaultFolderContainerViewModel(title: BundleI18n.SKResource.Doc_List_Shared_Folder,
                                                    isExternal: false,
                                                    searchType: .normal,
                                                    module: "shared_folder",
                                                    bizParams: SpaceBizParameter(module: .sharedFolderRoot))
    }
}
