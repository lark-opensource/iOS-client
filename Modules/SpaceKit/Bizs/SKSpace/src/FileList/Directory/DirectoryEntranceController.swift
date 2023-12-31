//  Created by Ryan on 2018/8/27.
// disable-lint: magic number

import UIKit
import EENavigator
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import SKInfra
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import SpaceInterface
import LarkContainer

enum OwnerTypeMatchType {
    case match
    case lower //目标版本过低 如:v2类型加入v1文件夹
    case higher //目标版本过高

    func tipWith(action: UtilAction) -> String {
        switch action {
        case .addShortCut:
            //新版文件才有添加快捷方式，仅有添加到旧版文件夹一种异常情况
            return BundleI18n.SKResource.CreationMobile_ECM_UnableShortToast
        case .addTo:
            //旧版文件才有添加快捷方式，仅有添加到新版文件夹一种异常情况
            return BundleI18n.SKResource.CreationMobile_ECM_UnableAddFolderToast
        case .move:
            return (self == .lower) ?  BundleI18n.SKResource.CreationMobile_ECM_UnableMoveDocToast : BundleI18n.SKResource.CreationMobile_ECM_UnableMoveToast
        default:
            return ""
        }
    }
}

class FolderTitleView: UICollectionReusableView {
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UDColor.textCaption
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBase
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self).offset(16)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }
}

public struct DirectoryUtilLocation {
    public let folderToken: String
    public let folderType: FolderType
    public let isExternal: Bool
    public let canCreateSubNode: Bool
    public let contextType: DirectoryUtilContextType
    public let targetModule: WorkspacePickerTracker.TargetModule
}
public typealias DirectoryUtilCallback = (DirectoryUtilLocation, UIViewController) -> Void
public enum UtilAction {
    case addShortCut(srcFile: SpaceEntry)
    case addTo(srcFile: SpaceEntry)
    case move(srcFile: SpaceEntry)
    case searchPicker
    case callback(completion: DirectoryUtilCallback)
}

public final class DirectoryEntranceContext {
    var action: UtilAction
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

    // action 为 callback 时，用于校验文件夹的版本
    var ownerTypeChecker: WorkspaceOwnerTypeChecker?
    let pickerConfig: WorkspacePickerConfig

    public init(action: UtilAction, pickerConfig: WorkspacePickerConfig, ownerTypeChecker: WorkspaceOwnerTypeChecker? = nil) {
        self.action = action
        self.pickerConfig = pickerConfig
        self.ownerTypeChecker = ownerTypeChecker
    }
}

public final class DirectoryEntranceController: BaseViewController,
                                          UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout {
    var context: DirectoryEntranceContext
    private var folders = [ListCellViewModel]()
    private var request: DocsRequest<JSON>?

    private let entranceCount = 2
    private let secCount = 2

    private lazy var searchBar: DocsSearchBar = {
        let sb = DocsSearchBar()
        sb.tapBlock = { [weak self] _ in self?.onSelectSearch() }
        return sb
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false

        collectionView.register(FolderTitleView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "FolderTitleView")
        collectionView.register(CEntranceCell.self, forCellWithReuseIdentifier: "CEntranceCell")
        collectionView.register(ListCell.self, forCellWithReuseIdentifier: "ListCell")

        collectionView.dataSource = self
        collectionView.delegate = self

        return collectionView
    }()
    
    private let userResolver: UserResolver

    public init(userResolver: UserResolver, context: DirectoryEntranceContext) {
        self.userResolver = userResolver
        self.context = context
        super.init(nibName: nil, bundle: nil)

        if SettingConfig.singleContainerEnable {
            requestRecentFoldersV2()
        } else {
            SKDataManager.shared.refreshListData(of: .personalFolder)
            requestRecentFolders()
        }

        if !SettingConfig.singleContainerEnable, SKDataManager.shared.getMyFolder() == nil {
            SKDataManager.shared.refreshListData(of: .personalFolder)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        switch context.action {
        case .addShortCut:
            navigationBar.title = BundleI18n.SKResource.CreationMobile_ECM_ShortcutsTitle
        case .move:
            navigationBar.title = BundleI18n.SKResource.Doc_Facade_MoveTo
        case .addTo, .callback, .searchPicker:
            navigationBar.title = BundleI18n.SKResource.Doc_Facade_AddTo
        }
        let item = SKBarButtonItem(title: BundleI18n.SKResource.Doc_List_Cancel,
                                   style: .plain,
                                   target: self,
                                   action: #selector(backBarButtonItemAction))
        item.foregroundColorMapping = SKBarButton.defaultTitleColorMapping
        item.id = .back
        navigationBar.leadingBarButtonItem = item
        setupUI()
    }

    /// 点击搜索框事件
    @objc
    private func onSelectSearch() {
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let config = context.pickerConfig
        let vc = factory.createFolderSearchController(config: config)
        userResolver.navigator.push(vc, from: self)
        FileListStatistics.reportClickAddtoOperation(action: "click_search_result", file: context.srcFile)
    }

    override public func backBarButtonItemAction() {
        self.dismiss(animated: true, completion: nil)
    }

    override public var canShowBackItem: Bool {
        return false
    }

    private func requestRecentFolders() {
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.recentlyUsedFolders, params: nil)
            .set(method: .GET)
            .start(callbackQueue: .global(), result: { [weak self] (result, error) in
            guard let `self` = self else { return }
            guard error == nil, let result = result else {
                DocsLogger.error("Fail to request recent 3 folders", error: error)
                return
            }
            let resultFolders = DataBuilder.getRecentFolders(from: result)
            self.folders = resultFolders.map { ListCellViewModel(file: $0) }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        })
    }

    private func requestRecentFoldersV2() {
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.recentlyUsedFoldersV2, params: nil)
            .set(method: .GET)
            .start(callbackQueue: .global(), result: { [weak self] (result, error) in
            guard let `self` = self else { return }
            guard error == nil, let result = result else {
                DocsLogger.error("Fail to request recent 3 folders", error: error)
                return
            }
            let resultFolders = DataBuilder.getRecentFolders(from: result)
            self.folders = resultFolders.map { ListCellViewModel(file: $0) }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        })
    }

    func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(searchBar.preferedHeight)
        }
        view.insertSubview(collectionView, belowSubview: searchBar)
        collectionView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(searchBar.snp.bottom)
        }
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
    // MARK: - UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return secCount
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {//第一部分固定显示两个入口，我的空间&共享空间
            return entranceCount
        } else {
            return folders.count
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "CEntranceCell", for: indexPath)
            guard let cell = cell1 as? CEntranceCell else {
                return cell1
            }
            if indexPath.row == 0 {
                cell.titleLabel.text = BundleI18n.SKResource.Doc_List_My_Space
                cell.folderImageView.image = UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
            } else if indexPath.row == 1 {
                cell.titleLabel.text = SettingConfig.singleContainerEnable
                    ? BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
                    : BundleI18n.SKResource.Doc_List_Shared_Space
                cell.folderImageView.image = SettingConfig.singleContainerEnable
                    ? BundleResources.SKResource.Space.DocsType.icon_sharedspace
                    : UDIcon.getIconByKeyNoLimitSize(.fileSharefolderColorful)
                if SettingConfig.singleContainerEnable && LKFeatureGating.newShareSpace {
                    cell.titleLabel.text = BundleI18n.SKResource.Doc_List_Shared_Space
                }
            } else {
                spaceAssertionFailure()
            }
            return cell1
        } else {
            guard !folders.isEmpty else {
                return ListCell()
            }
            let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "ListCell", for: indexPath)
            guard let cell = cell1 as? ListCell else {
                return cell1
            }
            let cellModel = folders[row]
            if let srcFile = context.srcFile {
                let matchType = checkOwnerTypeMatch(file: srcFile, folder: cellModel.fileEntry)
                switch matchType {
                case .match:
                    cellModel.enable = true
                default:
                    cellModel.enable = false
                }
            } else if case .callback = context.action,
                      context.ownerTypeChecker?(cellModel.fileEntry.isSingleContainerNode) != nil {
                cellModel.enable = false
            } else {
                cellModel.enable = true
            }
            cell.apply(model: cellModel)
            cell.backgroundView?.alpha = cellModel.enable ? 1 : 0.3
            cell.contentView.alpha = cellModel.enable ? 1 : 0.3
            return cell
        }

    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 67)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var directoryVC: DirectoryUtilController
        if indexPath.section == 0 {
            if indexPath.row == 1 {
                let context = DirectoryUtilContext(action: self.context.action,
                                                   desFile: nil,
                                                   desType: .shareSpace,
                                                   ownerTypeChecker: context.ownerTypeChecker,
                                                   pickerConfig: context.pickerConfig,
                                                   targetModule: .shared)
                directoryVC = DirectoryHelper.getController(with: context)
                var title = SettingConfig.singleContainerEnable
                    ? BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
                    : BundleI18n.SKResource.Doc_List_Shared_Space
                if SettingConfig.singleContainerEnable && LKFeatureGating.newShareSpace {
                    title = BundleI18n.SKResource.Doc_List_Shared_Space
                }
                directoryVC.navigationBar.title = title
            } else {
                var myFolder: FolderEntry?
                if !SettingConfig.singleContainerEnable {
                    myFolder = SKDataManager.shared.getMyFolder() as? FolderEntry
                }
                let context = DirectoryUtilContext(action: self.context.action,
                                                   desFile: myFolder,
                                                   desType: .mySpace,
                                                   ownerTypeChecker: context.ownerTypeChecker,
                                                   pickerConfig: context.pickerConfig,
                                                   targetModule: .personal)
                directoryVC = DirectoryHelper.getController(with: context)
                directoryVC.navigationBar.title = BundleI18n.SKResource.Doc_List_My_Space
            }
        } else {
            let cellModel = folders[indexPath.row]
            if let srcFile = context.srcFile {
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
            guard let currfolder = folders[indexPath.row].file as? FolderEntry else {
                spaceAssertionFailure("entrance controller select folder failed")
                return
            }
            spaceAssert(!currfolder.objToken.isEmpty, "folder token found empty")
            let tmpContext = DirectoryUtilContext(action: context.action,
                                                  desFile: currfolder,
                                                  desType: .subFolder(folderType: currfolder.folderType),
                                                  ownerTypeChecker: context.ownerTypeChecker,
                                                  pickerConfig: context.pickerConfig,
                                                  targetModule: .space)
            directoryVC = DirectoryHelper.getController(with: tmpContext)
            FileListStatistics.reportClickAddtoOperation(action: "click_recent_folder", file: context.srcFile)
        }

        directoryVC.directLevel += 1
        self.navigationController?.pushViewController(directoryVC, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = indexPath.section
        if section == 1 {
            let titleview = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                              withReuseIdentifier: "FolderTitleView",
                                                                              for: indexPath)
            guard let header = titleview as? FolderTitleView else {
                spaceAssertionFailure("get view fail in DirectoryEntranceController FolderTitleView")
                return UICollectionReusableView()
            }
            header.setTitle(BundleI18n.SKResource.Doc_Facade_RecentlyUsed)
            return header
        } else {
            return UICollectionReusableView()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section == 1 else {
            return CGSize(width: collectionView.frame.width, height: 0)
        }
        return CGSize(width: collectionView.frame.width, height: ((folders.count > 0) ? 44 : 0))
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        view.layer.zPosition = 0.0
    }
}


class CEntranceCell: UICollectionViewCell {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    var folderImageView: UIImageView = {
        let img = UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        let imageView = UIImageView(image: img)
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        contentView.addSubview(folderImageView)
        let iconImageViewWidth: CGFloat = 40
        folderImageView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalTo(self.snp.centerY)
            make.size.equalTo(CGSize(width: iconImageViewWidth, height: iconImageViewWidth))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(folderImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        docs.addStandardHover()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
