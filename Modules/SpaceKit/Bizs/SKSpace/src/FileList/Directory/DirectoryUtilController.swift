//  Created by weidong fu on 17/1/2018.
// swiftlint:disable file_length type_body_length
// disable-lint: magic number

import Foundation
import UniverseDesignToast
import SwiftyJSON
import SnapKit
import EENavigator
import SKUIKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import RxCocoa
import RxRelay
import RxSwift
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import LarkContainer

struct ShareFolderListRoleTypeModel: Hashable {
    var roleType: Int // 参考CollaboratorRoleType
    var invited: Bool
    var folderToken: String
    init(_ roleType: Int, _ invited: Bool, _ folderToken: String) {
        self.roleType = roleType
        self.invited = invited
        self.folderToken = folderToken
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.roleType)
        hasher.combine(self.invited)
        hasher.combine(self.folderToken)
    }
}

public final class DirectoryUtilContext {
    var action: UtilAction
    //共享空间为nil, 单容器改造前我的空间token有值，单容器改造后我的空间token为""
    var desFile: FolderEntry?
    var desType: DirectoryUtilContextType
    var srcFile: SpaceEntry? {
        switch action {
        case let .addTo(srcFile):
            return srcFile
        case let .addShortCut(srcFile):
            return srcFile
        case let .move(srcFile):
            return srcFile
        case .callback, .searchPicker:
            return nil
        }
    }
    // 操作名字，展示在确认按钮上, 优先级最高，后续都通过此属性配置
    public var actionName: String?

    public let pickerConfig: WorkspacePickerConfig

    // 判断特定文件夹的版本是否符合配置要求
    var ownerTypeChecker: WorkspaceOwnerTypeChecker?

    // 透传我的空间、共享空间入口的取值，但通过搜索跳转场景，会重置为 space
    let targetModule: WorkspacePickerTracker.TargetModule

    public init(action: UtilAction,
                desFile: FolderEntry?,
                desType: DirectoryUtilContextType,
                ownerTypeChecker: WorkspaceOwnerTypeChecker?,
                pickerConfig: WorkspacePickerConfig,
                targetModule: WorkspacePickerTracker.TargetModule) {
        self.action = action
        self.desFile = desFile
        self.desType = desType
        self.ownerTypeChecker = ownerTypeChecker
        self.pickerConfig = pickerConfig
        self.targetModule = targetModule
    }
}

public enum DirectoryUtilContextType: Equatable {
    case mySpace
    case shareSpace
    case subFolder(folderType: FolderType)
}

public final class DirectoryUtilController: BaseViewController, UICollectionViewDataSource,
                                      UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var directLevel = 1
    lazy var cellHeight: CGFloat = 67

    private var inShareRoot = false // 共享文件夹更目录 true,其它false
    private var inMyFolderRoot = false // 我的空间根目录true,其它false
    private var inSubFolder = false //子文件夹
    private var dataModel: FolderPickerDataModel?

    private var fileList: [ListCellViewModel] = []
    private var context: DirectoryUtilContext
    private var createRequest: DocsRequest<String>?
    private var dirContext: DirectoryUtilContext?
    private var nodeList: [String]?
    private var folderListRoleTypeInfo = [ShareFolderListRoleTypeModel]()
    private var showState = [ShareFolderListRoleTypeModel]()
    private var fatherName: String = ""
    private var srcName: String = ""
    private var defaultSortItem = SortItem(isSelected: true, isUp: false, sortType: .updateTime)
    private let disposeBag = DisposeBag()
    private var ownerType: Int
    private var isSingleContainer: Bool {
        switch context.desType {
        case .mySpace, .shareSpace:
            return SettingConfig.singleContainerEnable
        case .subFolder:
            return (ownerType == singleContainerOwnerTypeValue)
        }
    }
    private var canCreateSubNode: Bool = false

    private var loadingView: DocsLoadingViewProtocol?
    public let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.scrollsToTop = true
        cv.backgroundColor = UDColor.bgBody
        cv.alwaysBounceVertical = true
        cv.isScrollEnabled = true

        return cv
    }()

    private lazy var searchBar: DocsSearchBar = {
        let sb = DocsSearchBar()
        sb.tapBlock = { [weak self] _ in self?.onSelectSearch() }
        return sb
    }()

    //添加到，移动到按钮
    private lazy var actionButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.addTarget(self, action: #selector(performAction), for: .touchUpInside)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.docs.addStandardLift()
        return button
    }()

    private lazy var seperator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var btnBackView: UIView = {
        let v = UIView()
        return v
    }()

    private var serverDataState = ServerDataState.loading

    public init(context: DirectoryUtilContext) {
        self.context = context

        self.srcName = context.srcFile?.name ?? ""

        if let desFile = context.desFile {
            ownerType = desFile.ownerType
        } else {
            ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override public func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    /// 点击搜索框事件
    @objc
    private func onSelectSearch() {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let config = context.pickerConfig
        let vc = factory.createFolderSearchController(config: config)
        Navigator.shared.push(vc, from: self)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(ListCell.self, forCellWithReuseIdentifier: ListCell.reuseId)
        collectionView.register(DirectoryPickerEmptyPlaceholderCell.self, forCellWithReuseIdentifier: NSStringFromClass(DirectoryPickerEmptyPlaceholderCell.self))
        configureLayout()
        collectionView.delegate = self
        collectionView.dataSource = self

        setup()
    }

    private func setup() {
        showLoading(usingToast: false)
        fetchOwnerType().observeOn(MainScheduler.instance).subscribe { [weak self] in
            guard let self else { return }
            self.setupDataModel()
            self.configDataModel()
            self.fetchData(usingToast: false)
            if self.inSubFolder || (self.context.desType == .shareSpace && LKFeatureGating.newShareSpace) {
                self.collectionView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
                    self?.fetchMoreFiles()
                }
            }
            self.setupButton()
            self.setupNaviTag()
        } onError: { [weak self] error in
            self?.showFailure()
            DocsLogger.error("fetchOwnerType fail: \(error.localizedDescription)")
        }
        .disposed(by: disposeBag)
    }

    private func fetchOwnerType() -> Completable {
        switch context.desType {
        case .mySpace, .shareSpace:
            return Completable.empty()
        case .subFolder(let folderType):
            guard let objToken = context.desFile?.objToken else {
                spaceAssertionFailure("folder objToken not found when start pick folder")
                return Completable.empty()
            }
            return DocsInfoDetailHelper
                .fetchEntityInfo(objToken: objToken, objType: .folder)
                .flatMap { [weak self] ownerType -> Single<Void> in
                    guard let self else { return Single.just(()) }
                    let newfolderType = FolderType(ownerType: ownerType, shareVersion: nil, isShared: folderType.isShareFolder)
                    self.ownerType = ownerType
                    self.context.desFile?.updateOwnerType(ownerType)
                    self.context.desFile?.updateFolderType(newfolderType)
                    self.context.desType = .subFolder(folderType: newfolderType)
                    DocsLogger.info("fetchOwnerType: \(ownerType)")
                    return Single.just(())
                }.asCompletable()
        }
    }

    private func setupDataModel() {
        let userID: String
        if let currentUserID = User.current.basicInfo?.userID {
            userID = currentUserID
        } else {
            spaceAssertionFailure("Failed to get userID when pick folder")
            userID = ""
        }
        switch context.desType {
        case .mySpace:
            if SettingConfig.singleContainerEnable {
                dataModel = PersonalFileDataModel(userID: userID, usingV2API: true)
            } else {
                dataModel = MyFolderDataModel(userID: userID)
            }
            inMyFolderRoot = true
        case .shareSpace:
            if SettingConfig.singleContainerEnable {
                if LKFeatureGating.newShareSpace {
                    // space2.0 新共享空间，返回共享文件夹列表数据
                    dataModel = ShareFolderDataModel(userID: userID, usingAPI: .newShareFolder)
                } else {
                    dataModel = SharedFileDataModel(userID: userID, usingAPI: .sharedFileV2)
                }
            } else {
                dataModel = ShareFolderDataModel(userID: userID, usingAPI: .shareFolderV1)
            }
            inShareRoot = true
        case .subFolder:
            guard let folder = context.desFile else {
                spaceAssertionFailure("folder entry not found when start pick folder")
                return
            }
            spaceAssert(!folder.objToken.isEmpty, "folder token empty in sub folder picker!")
            if folder.folderType.v2 {
                dataModel = SubFolderDataModelV2(folderToken: folder.objToken,
                                                 isShareFolder: folder.folderType.isShareFolder)
            } else if let spaceID = folder.shareFolderInfo?.spaceID {
                dataModel = SubFolderDataModelV1(folderInfo: .init(token: folder.objToken,
                                                 folderType: .share(spaceID: spaceID,
                                                 isRoot: folder.isShareRoot(),
                                                 ownerID: folder.ownerID)))
            } else {
                dataModel = SubFolderDataModelV1(folderInfo: .init(token: folder.objToken, folderType: .personal))
            }
            inSubFolder = true
        }
    }

    private func configDataModel() {
        guard let dataModel = dataModel else { return }
        dataModel.pickerItemChanged.skip(1).subscribe(onNext: { [weak self] entries in
            self?.didUpdate(entries: entries)
        })
            .disposed(by: disposeBag)
        dataModel.setup()
        dataModel.resetSortFilterForPicker()
    }

    private func setupNaviTag() {
        func _isExternal(folderEntry: SpaceEntry) -> Bool {
            guard EnvConfig.CanShowExternalTag.value else { return false }
            guard User.current.info?.isToNewC == false else { return false }
            return folderEntry.isExternal
        }
        guard case .subFolder = context.desType else {
            DocsLogger.info("is not in subFolder")
            return
        }
        guard let folder = context.desFile else {
            DocsLogger.warning("folder is nil")
            return
        }
        DispatchQueue.main.async {
            let isExternal = _isExternal(folderEntry: folder)
            self.navigationBar.titleView.needDisPlayTag = isExternal
            self.navigationBar.titleView.tagContent = folder.organizationTagValue
            self.navigationBar.titleView.showSecondTag = false
        }
    }

    private func fetchData(usingToast: Bool) {
        showLoading(usingToast: usingToast)
        dataModel?.refresh()
            .subscribe { [weak self] in
                guard let self = self else { return }
                UDToast.removeToast(on: self.view.window ?? self.view)
                self.serverDataState = .synced
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.showFailure()
                DocsLogger.error("picker fetch data failed with error", error: error)
            }
            .disposed(by: disposeBag)
    }

    private func fetchMoreFiles() {
        dataModel?.loadMore()
            .subscribe { [weak self] in
                self?.collectionView.es.stopLoadingMore()
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.collectionView.es.stopLoadingMore()
                if let listError = error as? RecentListDataModel.RecentDataError, listError == .unableToLoadMore { return }
                DocsLogger.error("picker fetch data failed with error", error: error)
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed,
                                    on: self.view.window ?? self.view)
            }
            .disposed(by: disposeBag)
    }

    private func showLoading(usingToast: Bool) {
        serverDataState = .loading
        if usingToast {
            UDToast.showDefaultLoading(on: view.window ?? view)
        } else {
            setLoadingViewShow(true)
        }
    }

    private func showFailure() {
        self.serverDataState = .fetchFailed
        self.setLoadingViewShow(false)
        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed,
                            on: self.view.window ?? self.view)
    }

    private func setLoadingViewShow(_ show: Bool) {
        if show {
            if loadingView == nil, let newLoadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self) {
                let contentView = newLoadingView.displayContent
                view.addSubview(contentView)
                contentView.snp.remakeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(navigationBar.snp.bottom)
                }
                loadingView = newLoadingView
            }
            guard let loadingView = loadingView else {
                return
            }
            view.bringSubviewToFront(loadingView.displayContent)
            loadingView.startAnimation()
        } else {
            guard let loadingView = self.loadingView else { return }
            loadingView.stopAnimation()
        }
    }

    private func canExcuteAction() -> Bool {
        return true
    }

    func resetActionButton(hidden isHidden: Bool) {
        actionButton.setTitle(buttonTitleFor(context), for: .normal)
        let titleColor = canExcuteAction() ? UDColor.primaryOnPrimaryFill : UDColor.primaryOnPrimaryFill.withAlphaComponent(0.3)
        actionButton.setTitleColor(titleColor, for: .normal)

        btnBackView.isHidden = isHidden
        actionButton.isHidden = isHidden

        if isHidden {
            collectionView.snp.remakeConstraints { (make) in
                make.top.equalTo(searchBar.snp.bottom)
                make.bottom.left.right.equalToSuperview()
            }
        } else {
            collectionView.snp.remakeConstraints { (make) in
                make.top.equalTo(searchBar.snp.bottom)
                make.left.right.equalToSuperview()
                make.bottom.equalTo(btnBackView.snp.top)
            }
        }
    }

    private func setupActionButtonForOldNode(isFolder: Bool) {
        var validAction = false
        switch context.action {
        case .addTo, .move:
            validAction = true
        default:
            break
        }
        guard validAction else { return }

        var hiddenAction = true
        switch context.desType {
        case .mySpace:
            if case .move = context.action {
                hiddenAction = !isFolder
            }
        case .subFolder:
            hiddenAction = false
        default:
            break
        }
        resetActionButton(hidden: hiddenAction)
    }

    private func setupActionButtonForNewNode() {
        var validAction = false
        switch context.action {
        case .addShortCut, .move:
            validAction = true
        default:
            break
        }
        guard validAction else { return }

        var hiddenAction = false
        switch context.desType {
        case .shareSpace:
            hiddenAction = true
        default:
            break
        }
        resetActionButton(hidden: hiddenAction)
    }

    private func setupActionButtonForCallBack() {
        guard case .callback = context.action else {
            spaceAssertionFailure()
            return
        }
        switch context.desType {
        case .subFolder, .mySpace:
            resetActionButton(hidden: false)
        default:
            resetActionButton(hidden: true)
        }
    }

    func configureLayout() {
        view.addSubview(collectionView)
        view.addSubview(searchBar)
        view.addSubview(btnBackView)
        btnBackView.addSubview(actionButton)
        btnBackView.addSubview(seperator)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(searchBar.preferedHeight)
        }
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(actionButton.snp.top)
        }
        btnBackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(80.0)
        }
        actionButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.height.equalTo(44.0)
        }
        seperator.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    private func setupButton() {
        if let srcFile = context.srcFile {
            if srcFile.isSingleContainerNode {
                setupActionButtonForNewNode()
            } else {
                setupActionButtonForOldNode(isFolder: srcFile.type == .folder)
            }
        } else {
            setupActionButtonForCallBack()
        }

        setupCreateFolderButton()
    }

    private func buttonTitleFor(_ context: DirectoryUtilContext) -> String? {
        // 产品要求 picker 的按钮文案统一为 “确认”
        return BundleI18n.SKResource.Doc_Wiki_Confirm
    }

    @objc
    func performAction(_ sender: UIButton) {
        guard canExcuteAction() else {
            var tip = BundleI18n.SKResource.Doc_List_AddUnsupport
            switch context.action {
            case .addTo:
                tip = BundleI18n.SKResource.Doc_List_AddUnsupport
            case .addShortCut:
                tip = BundleI18n.SKResource.Doc_List_AddUnsupport
            case .move:
                tip = BundleI18n.SKResource.Doc_List_MoveUnsupport
            default: break
            }
            UDToast.showTips(with: tip, on: view.window ?? view)
            return
        }



        if shouldShowCrossTenantAlertForSingleContainerNode() {
            showCrossTenantAlert()
        } else if shouldShowTransferForSingleContainerNode() {
            showTransferForSingleContainerNode()
        } else if shouldShowCrossTenantAlert {
            showCrossTenantAlert()
        } else {
            handlePerformAction()
        }
    }

    func showCrossTenantAlert() {
        let type = (context.srcFile?.type == .folder) ? BundleI18n.SKResource.Doc_Facade_Folder : BundleI18n.SKResource.Doc_Facade_Document
        let content = BundleI18n.SKResource.CreationMobile_ECM_MovedExternalConfirmDesc(type)
        let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmNotification_Subtitle_Mob
        let dialog = UDDialog()
        if let srcFile = context.srcFile,
           !(srcFile.ownerIsCurrentUser || srcFile.isShortCut) {
            dialog.setContent(text: content, caption: caption)
        } else {
            // owner 或 shortcut 不展示非所有者移动提示
            dialog.setContent(text: content)
        }
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_ECM_MovedExternalConfirmTitle)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.handlePerformAction()
        })
        self.present(dialog, animated: true, completion: nil)
    }

    //是否提示  移动一个文档到外部共享文件夹
    func shouldShowCrossTenantAlertForSingleContainerNode() -> Bool {
        guard case .move = context.action else {
            return false
        }
        if let desFile = context.desFile,
           desFile.isSingleContainerNode,
           desFile.isExternal {
            return true
        }
        return false
    }

    //是否提示 用户从文件夹 1 将内容 A 移动到文件夹 2
    func shouldShowTransferForSingleContainerNode() -> Bool {
        guard case .move = context.action else {
            return false
        }
        if let desFile = context.desFile,
           desFile.isSingleContainerNode,
           desFile.isShareFolder {
            return true
        }

        if let srcFile = context.srcFile,
            srcFile.isSingleContainerNode,
           let parentToken = srcFile.parent,
           let parent = SKDataManager.shared.spaceEntry(token: TokenStruct(token: parentToken, nodeType: 1)),
           let folder = parent as? FolderEntry,
           folder.isShareFolder {
            return true
        }
        return false
    }

    func showTransferForSingleContainerNode() {
        let dialog = UDDialog()
        let title = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirm_Title_Mob
        let content = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmContent_Subtitle_Mob
        let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmNotification_Subtitle_Mob
        
        if let srcfile = context.srcFile, !(srcfile.ownerIsCurrentUser || srcfile.isShortCut) {
            dialog.setContent(text: content, caption: caption)
        } else {
            // owner 或 shortcut 不展示非所有者移动提示
            dialog.setContent(text: content)
        }
        
        dialog.setTitle(text: title)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.handlePerformAction()
        })
        self.present(dialog, animated: true, completion: nil)
    }


    func handlePerformAction() {
        switch context.action {
        case .move: move()
        case .addTo: addTo()
        case .addShortCut: addShortCut()
        case let .callback(completion: completion):
            callback(completion: completion)
        case .searchPicker:
            spaceAssertionFailure("searchPicker should not be used in DirectoryUtilController")
        }
    }

    func callback(completion: DirectoryUtilCallback) {

        if let desFile = context.desFile,
           let tip = context.ownerTypeChecker?(desFile.isSingleContainerNode) {
            UDToast.showTips(with: tip, on: view.window ?? view)
            return
        }

        var folderType = FolderType.v2Common
        var token = ""
        if SettingConfig.singleContainerEnable {
            folderType = .v2Common
        } else {
            folderType = .common
        }
        var isExternal = false
        if let desFile = context.desFile {
            token = desFile.objToken
            folderType = desFile.folderType
            isExternal = desFile.isExternal
        }
        let location = DirectoryUtilLocation(folderToken: token,
                                             folderType: folderType,
                                             isExternal: isExternal,
                                             canCreateSubNode: canCreateSubNode,
                                             contextType: context.desType,
                                             targetModule: context.targetModule)
        completion(location, self)
    }

    func move() {
        guard case .move = context.action, let srcFile = context.srcFile else {
            spaceAssertionFailure()
            return
        }
        let desToken = context.desFile?.objToken ?? ""
        let srcToken = srcFile.nodeToken
        self.setLoadingViewShow(true)

        let handler: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
            self.setLoadingViewShow(false)
            if let error = error {
                self.handle(error: error)
                return
            }
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_Normal_Success,
                                   on: self.view.window ?? self.view)
            self.gotoRoot()
        }

        if srcFile.isSingleContainerNode {
            dataModel?.interactionHelper.moveV2(nodeToken: srcToken, from: srcFile.parent, to: desToken).subscribe {
                handler(nil)
            } onError: { error in
                handler(error)
            }
            .disposed(by: disposeBag)
        } else {
            dataModel?.interactionHelper.move(nodeToken: srcToken, from: srcFile.parent ?? "", to: desToken).subscribe {
                handler(nil)
            } onError: { error in
                handler(error)
            }
            .disposed(by: disposeBag)
        }

    }

    func addShortCut() {
        guard case .addShortCut = context.action, let srcFile = context.srcFile else {
            spaceAssertionFailure()
            return
        }
        var token = context.desFile?.objToken ?? ""
        if case .mySpace = context.desType {
            token = ""
        }
        let srcToken = srcFile.objToken
        let type = srcFile.type
        self.setLoadingViewShow(true)
        dataModel?.interactionHelper.createShortCut(for: SpaceItem(objToken: srcToken, objType: type), in: token)
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_FolderSelectAddSuccess,
                                    on: self.view.window ?? self.view)
                self.gotoRoot()
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                DocsLogger.error("create shortcut error", error: error)
                if let error = error as NSError?, let errorCode = ExplorerErrorCode(rawValue: error.code) {
                    guard error.code == ExplorerErrorCode.moveDontHaveSharePermission.rawValue else {
                        let errorEntity = ErrorEntity(code: errorCode, folderName: error.localizedDescription)
                        UDToast.showFailure(with: errorEntity.wording,
                                            on: self.view.window ?? self.view)
                        return
                    }
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_AddToNoPermission(self.srcName),
                                        on: self.view.window ?? self.view)
                } else if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    UDToast.showFailure(with: message,
                                        on: self.view.window ?? self.view)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry,
                                        on: self.view.window ?? self.view)
                }
            }
            .disposed(by: disposeBag)
    }

    func addTo() {
        guard case .addTo = context.action, let srcFile = context.srcFile else {
            spaceAssertionFailure()
            return
        }
        guard let token = context.desFile?.objToken else { spaceAssertionFailure("missing token"); return }
        let srcToken = srcFile.objToken
        self.setLoadingViewShow(true)
        dataModel?.interactionHelper.add(objToken: srcToken, to: token)
            .subscribe { [weak self] in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_FolderSelectAddSuccess,
                                    on: self.view.window ?? self.view)
                self.gotoRoot()
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.setLoadingViewShow(false)
                DocsLogger.error("add to folder error", error: error)
                if let error = error as NSError?, let errorCode = ExplorerErrorCode(rawValue: error.code) {
                    guard error.code == ExplorerErrorCode.moveDontHaveSharePermission.rawValue else {
                        let errorEntity = ErrorEntity(code: errorCode, folderName: error.localizedDescription)
                        UDToast.showFailure(with: errorEntity.wording,
                                            on: self.view.window ?? self.view)
                        return
                    }
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_AddToNoPermission(self.srcName),
                                        on: self.view.window ?? self.view)
                } else if let docsError = error as? DocsNetworkError,
                          let message = docsError.code.errorMessage {
                    UDToast.showFailure(with: message,
                                        on: self.view.window ?? self.view)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry,
                                        on: self.view.window ?? self.view)
                }
            }
            .disposed(by: disposeBag)
    }

    @objc
    func gotoRoot() {
        self.dismiss(animated: true, completion: nil)
    }

    private func setupCreateFolderButton() {
        //共享文件夹根目录不显示
        //个人文件夹根目录直接显示
        //owner为我的文件夹直接显示
        // owner不为我的文件夹监听一下权限
        if inShareRoot {
            canCreateSubNode = false
            return
        } else if inMyFolderRoot {
            canCreateSubNode = true
            addRightBarButtonItem()
        } else if inSubFolder {
            if let file = context.desFile, file.type == .folder, file.ownerIsCurrentUser { //自己是owner
                canCreateSubNode = true
                addRightBarButtonItem()
            } else { //需要判断权限的情况
                observedEditPerm { [weak self] (canEdit) in
                    guard let self = self else { return }
                    self.canCreateSubNode = canEdit
                    self.addRightBarButtonItem()
                }
            }
        } else {
            spaceAssertionFailure("异常类型")
        }
    }

    private func observedEditPerm(handler: @escaping (Bool) -> Void) {
        dataModel?.addToCurrentFolderEnabled
            .distinctUntilChanged()
            .subscribe(onNext: { (canEdit) in
                handler(canEdit)
        }).disposed(by: disposeBag)
    }

    private func addRightBarButtonItem() {
        let item = SKBarButtonItem(image: UDIcon.creatFolderOutlined,
                                   style: .plain,
                                   target: self,
                                   action: #selector(showCreateFolderView))
        item.id = .addFile
        navigationBar.trailingBarButtonItem = item
    }

    @objc
    private func showCreateFolderView() {
        guard canCreateSubNode else {
            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Wiki_NoPerms_NewFolder_Tooltip, on: view.window ?? view)
            return
        }
        guard let rootViewController = self.navigationController else { return }
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.isAutorotatable = true
        let textField = dialog.addTextField(placeholder: BundleI18n.SKResource.Doc_Facade_InputName)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_CreateFolder)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        let createButton = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Create, dismissCompletion: { [weak dialog] in
            guard let name = dialog?.textField.text, name.isEmpty == false else { return }
            let token = self.context.desFile?.objToken ?? ""
            self.createNewFolder(token: token, type: .folder, ownerType: self.ownerType, name: name)
        })
        dialog.bindInputEventWithConfirmButton(createButton)
        rootViewController.present(dialog, animated: true) {
            textField.becomeFirstResponder()
        }
    }

    private func createNewFolder(token: String, type: DocsType, ownerType: Int, name: String) {
        UDToast.showDefaultLoading(on: view.window ?? view)
        let time = DocsTimeline()
        let folder = token
        self.createRequest?.cancel()
        if isSingleContainer {
            self.createRequest = DocsRequestCenter.createFolderV2(name: name, parent: folder, desc: nil, completion: { [weak self] (token, error) in
                guard let self = self else { return }
                if error != nil {
                    UDToast.removeToast(on: self.view.window ?? self.view)
                    DocsLogger.info("创建文件夹失败", extraInfo: ["错误信息": error as Any])
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed,
                                           on: self.view.window ?? self.view)
                    return
                }
                //骚操作:后端返回创建成功，但exploer接口却拉不到新创建的文件夹。只能延迟一下，再拉
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                    self.fetchData(usingToast: true)
                }
                DocsTracker.createFile(with: folder, typeName: type.name, isSuccess: token != nil, timeline: time)
                FileListStatistics.reportClickAddtoOperation(action: "click_create_folder", file: self.context.srcFile)
            })
        } else {
            self.createRequest = DocsRequestCenter.create(type: type, name: name, in: folder) { [weak self] (token, error) in
                guard let strongSelf = self else { return }
                if error != nil {
                    UDToast.removeToast(on: strongSelf.view.window ?? strongSelf.view)
                    DocsLogger.info("创建文件夹失败", extraInfo: ["错误信息": error as Any])
                    if let docsError = error as? DocsNetworkError,
                       let message = docsError.code.errorMessage {
                        UDToast.showFailure(with: message,
                                            on: strongSelf.view.window ?? strongSelf.view)
                    } else {
                        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed,
                                            on: strongSelf.view.window ?? strongSelf.view)
                    }
                    return
                }
                //骚操作:后端返回创建成功，但exploer接口却拉不到新创建的文件夹。只能延迟一下，再拉
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                    strongSelf.fetchData(usingToast: true)
                }
                DocsTracker.createFile(with: folder, typeName: type.name, isSuccess: token != nil, timeline: time)
                FileListStatistics.reportClickAddtoOperation(action: "click_create_folder", file: strongSelf.context.srcFile)
            }
        }
    }

    private func handle(error: Error) {
        DocsLogger.error("error \(error.localizedDescription)")
        let rawErrorCode = (error as NSError).code
        if let errorCode = ExplorerErrorCode(rawValue: rawErrorCode) {
            guard rawErrorCode == ExplorerErrorCode.moveDontHaveSharePermission.rawValue else {
                let errorEntity = ErrorEntity(code: errorCode, folderName: error.localizedDescription)
                UDToast.showFailure(with: errorEntity.wording,
                                       on: self.view.window ?? self.view)
                return
            }
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_MoveToNoPermission(self.srcName),
                                   on: self.view.window ?? self.view)
        } else if let err = error as? DocsNetworkError,
                  let message = err.code.errorMessage {
            UDToast.showFailure(with: message,
                                   on: self.view.window ?? self.view)
            return
        } else {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry,
                                   on: self.view.window ?? self.view)
        }
        return
    }
    func checkOwnerTypeMatch(file: SpaceEntry, folder: SpaceEntry) -> OwnerTypeMatchType {
        if file.isSingleContainerNode, !folder.isSingleContainerNode {
            return .lower
        }
        if !file.isSingleContainerNode, folder.isSingleContainerNode {
            return .higher
        }
        return .match
    }

    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if serverDataState == .loading {
            return 0
        }
        if fileList.isEmpty {
            return 1
        }
        return fileList.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard !fileList.isEmpty else {
            return emptyPlaceholderCell(indexPath)
        }
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: ListCell.reuseId, for: indexPath)

        guard let cell = cell1 as? ListCell else {
            spaceAssertionFailure("Invalid Cell,Must be ListCell")
            return cell1
        }

        let model = fileList[indexPath.item]
        cell.accessibilityIdentifier = "docs.fileList.cell\(indexPath.item)"
        let file = model.fileEntry

        // TODO: wuwenjian picker 内的检查逻辑需要抽离成 config，做好抽象
        if case .callback = context.action {
            //场景：模板选择
            model.enable = true
            if context.ownerTypeChecker?(file.isSingleContainerNode) != nil {
                // checker 返回了报错信息，需要禁用
                model.enable = false
            }
        } else {
            //场景： 文件夹移动至不能选自己
            var moveToSelf = false
            if let srcFile = context.srcFile, !srcFile.objToken.isEmpty {
                moveToSelf = (file.objToken == srcFile.objToken)
            }

            //场景: 添加至、移动至 新旧类型不能互相添加
            var ownerTypeMatch = false
            if let srcFile = context.srcFile {
                let matchType = checkOwnerTypeMatch(file: srcFile, folder: model.fileEntry)
                if case .match = matchType {
                    ownerTypeMatch = true
                }
            }
            model.enable = (!moveToSelf && ownerTypeMatch)
        }

        cell.apply(model: model)

        cell.backgroundView?.alpha = model.enable ? 1 : 0.3
        cell.contentView.alpha = model.enable ? 1 : 0.3

        //不置灰的情况下，共享文件夹根目录下还需要考虑权限
        if model.enable, inShareRoot == true {
            let enable = false
            cell.backgroundView?.alpha = enable ? 0.3 : 1
            cell.contentView.alpha = enable ? 0.3 : 1
        }

        return cell
    }
    private func emptyPlaceholderCell(_ indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier:
            NSStringFromClass(DirectoryPickerEmptyPlaceholderCell.self),
                                                            for: indexPath) as? DirectoryPickerEmptyPlaceholderCell else { return DirectoryPickerEmptyPlaceholderCell() }
        if inShareRoot {
            cell.config(with: .noShareFolder, title: BundleI18n.SKResource.Doc_List_NoSharedFolder, keyword: nil)
        } else {
            cell.config(with: .noList, title: BundleI18n.SKResource.Doc_List_EmptySubFolder, keyword: nil)
        }
        return cell
    }
    // MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard !fileList.isEmpty else {
            return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
        }
        return CGSize(width: view.frame.width, height: cellHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard !fileList.isEmpty else { return }
        let cellModel = fileList[indexPath.item]

        if let srcFile = context.srcFile {
            // 不允许移动到本身及子级
            guard cellModel.fileEntry.objToken != srcFile.objToken else {
                DocsLogger.info("不允许移动到本身及子级")
                return
            }

            //场景： 新旧类型不能混淆
            let matchType = checkOwnerTypeMatch(file: srcFile, folder: cellModel.fileEntry)
            let tip = matchType.tipWith(action: context.action)

            if case .lower = matchType {
                UDToast.showTips(with: tip, on: view.window ?? view)
                return
            }
            if case .higher = matchType {
                UDToast.showTips(with: tip, on: view.window ?? view)
                return
            }
        } else if case .callback = context.action,
                  let tip = context.ownerTypeChecker?(cellModel.fileEntry.isSingleContainerNode) {
            UDToast.showTips(with: tip, on: view.window ?? view)
            return
        }
        guard let folderEntry = cellModel.fileEntry as? FolderEntry else {
            spaceAssertionFailure("get folder entry failed in folder picker")
            return
        }
        didSelect(folderEntry)
    }

    func didSelect(_ file: FolderEntry) {
        fatherName = file.name
        let dirContext = DirectoryUtilContext(action: context.action,
                                              desFile: file,
                                              desType: .subFolder(folderType: file.folderType),
                                              ownerTypeChecker: context.ownerTypeChecker,
                                              pickerConfig: context.pickerConfig,
                                              targetModule: context.targetModule)
        dirContext.actionName = context.actionName
        let vc = DirectoryHelper.getController(with: dirContext)
        vc.directLevel = directLevel + 1
        if folderListRoleTypeInfo.contains(where: { (item) -> Bool in
            return item.folderToken == file.nodeToken && item.roleType == 1
        }) {
            self.navigationController?.pushViewController(vc, animated: true)//有权限正常跳转
        } else if folderListRoleTypeInfo.contains(where: { (item) -> Bool in
            return item.folderToken == file.nodeToken && item.roleType != 1
        }) {// 没有权限提示
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_DeleteNoPermission,
                                   on: view.window ?? view)
        } else {// 老共享文件夹老逻辑处理
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension DirectoryUtilController: MoveFilesAlertControllerDelegate {
    // MARK: 共享文件夹移动确认请求 FG
    public func moveTo(_ moveFilesAlerController: MoveFilesAlertController) {
        guard case .move = context.action, let srcFile = context.srcFile else {
            spaceAssertionFailure()
            return
        }
        let desToken = context.desFile?.objToken ?? ""
        let srcToken = srcFile.nodeToken

        let handler: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
            self.setLoadingViewShow(false)
            if let error = error {
                self.handle(error: error)
                return
            }
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_Normal_Success,
                                   on: self.view.window ?? self.view)
            self.gotoRoot()
        }

        if srcFile.isSingleContainerNode {
            dataModel?.interactionHelper.moveV2(nodeToken: srcToken, from: srcFile.parent, to: desToken)
                .subscribe {
                    handler(nil)
                } onError: { error in
                    handler(error)
                }
                .disposed(by: disposeBag)
        } else {
            dataModel?.interactionHelper.move(nodeToken: srcToken, from: srcFile.parent ?? "", to: desToken)
                .subscribe {
                    handler(nil)
                } onError: { error in
                    handler(error)
                }
                .disposed(by: disposeBag)
        }
        statisticsForShareFolderManager(inShareRoot: inShareRoot, srcFileToken: srcToken, desFileToken: desToken)
    }
    private func statisticsForShareFolderManager(inShareRoot: Bool, srcFileToken: String, desFileToken: String) {
        let userTenantID = User.current.info?.tenantID
        var param: [String: String] = [:]
        param["module"] = FileListStatistics.Module.home.rawValue
        param["action"] = "create_share_folder"
        param["file_id"] = DocsTracker.encrypt(id: desFileToken)
        param["file_type"] = "share_folder"
        param["file_tenant_id"] = DocsTracker.encrypt(id: userTenantID ?? "")
        if inShareRoot {
            param["parent_folder_id"] = ""
        } else {
            param["parent_folder_id"] = DocsTracker.encrypt(id: srcFileToken)
        }
        param["source"] = "folder_move"
        DocsTracker.log(enumEvent: .shareFolderManager, parameters: param)
    }
}

extension DirectoryUtilController {

    private func didUpdate(entries: [SpaceEntry]) {
        getFolderList(entries: entries) { [weak self] (models) in
            guard let self = self else { return }
            self.fileList = models
            self.collectionView.reloadData()
            if models.isEmpty, self.serverDataState == .loading {
                // keep loading
            } else {
                self.setLoadingViewShow(false)
            }
        }
    }

    private func getFolderList(entries: [SpaceEntry], completion: @escaping ([ListCellViewModel]) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            var list: [SpaceEntry] = entries.filter { entry in
                if entry.type != .folder { return false }
                return !entry.isShortCut
            }
//            list = LocalSortAndFilterUtility.sortList(list, by: self.defaultSortItem.sortType, isUp: self.defaultSortItem.isUp)

            let inFolder = self.context.desFile
            let models = list.map { ListCellViewModel(file: $0, folderFile: inFolder) }
            DispatchQueue.main.async {
                completion(models)
            }
        }
    }
}

extension DirectoryUtilController {

    var shouldShowCrossTenantAlert: Bool {
        //移动、添加至才有,添加快捷方式时文档并没有给文件夹授权，这里不需要提示
        var validAction = false
        switch context.action {
        case .addTo, .move:
            validAction = true
        default:
            break
        }

        guard validAction else {
            return false
        }

        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        // 如果文档没有开启「允许文档被分享到组织外」，不需要弹窗
        if let srcFile = context.srcFile,
           let srcFilePermission = permissionManager.getPublicPermissionMeta(token: srcFile.objToken) {
            if !srcFilePermission.externalAccessEnable {
                return false
            }
        }
        // 小B不显示
        if User.current.info?.isToNewC == true {
            return false
        }
        return isExternal
    }

    var isExternal: Bool {
        return context.desFile?.extra?["is_external"] as? Bool ?? false
    }
}

// TODO: 实现此协议仅为了创建副本时能正确展示容量管理弹窗，DocsCreateDirector 目前强依赖此类型，待后续优化后去掉此实现
extension DirectoryUtilController: DocsCreateViewControllerRouter {}
