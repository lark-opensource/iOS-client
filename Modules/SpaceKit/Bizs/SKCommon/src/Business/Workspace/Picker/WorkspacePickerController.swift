//
//  WorkspacePickerController.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/5/31.
//

import Foundation
import SKFoundation
import SKResource
import SKUIKit
import SnapKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import EENavigator
import RxSwift
import RxCocoa
import SKInfra
import SpaceInterface
import LarkContainer

public final class WorkspacePickerController: BaseViewController {

    private lazy var searchBar: DocsSearchBar = {
        let bar = DocsSearchBar()
        bar.tapBlock = { [weak self] _ in self?.didClickSearchBar() }
        return bar
    }()

    private lazy var extraSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBodyOverlay
        return view
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.backgroundColor = UDColor.bgBody
        view.rowHeight = 48
        view.register(WorkspacePickerEntranceCell.self,
                      forCellReuseIdentifier: WorkspacePickerEntranceCell.reuseIdentifier)
        view.register(WorkspacePickerEntranceSubHeaderView.self,
                      forCellReuseIdentifier: WorkspacePickerEntranceSubHeaderView.reuseIdentifier)
        view.register(WorkspacePickerRecentCell.self,
                      forCellReuseIdentifier: WorkspacePickerRecentCell.reuseIdentifier)
        view.sectionFooterHeight = 12
        view.register(WorkspacePickerFooterView.self,
                      forHeaderFooterViewReuseIdentifier: WorkspacePickerFooterView.reuseIdentifier)
        view.register(WorkspacePickerRecentHeaderView.self,
                      forHeaderFooterViewReuseIdentifier: WorkspacePickerRecentHeaderView.reuseIdentifier)
        view.separatorStyle = .none
        return view
    }()

    private let recentViewModel: WorkspacePickerRecentViewModel
    private var recentEntries: [WorkspacePickerRecentEntry] = []

    private let config: WorkspacePickerConfig

    private let bag = DisposeBag()

    public init(config: WorkspacePickerConfig) {
        self.config = config
        self.recentViewModel = WorkspacePickerRecentViewModel(config: config)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        navigationBar.title = config.title
        let image = UDIcon.closeSmallOutlined
        let item = SKBarButtonItem(title: BundleI18n.SKResource.Doc_Facade_Cancel,
                                   style: .plain,
                                   target: self,
                                   action: #selector(backBarButtonItemAction))
        item.id = .back
        navigationBar.leadingBarButtonItem = item

        setupRecentList()
    }

    private func setupRecentList() {
        recentViewModel.reload()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] entries in
                guard let self = self else { return }
                // 按 PRD，只取前十个
                self.recentEntries = Array(entries.prefix(10))
                self.tableView.reloadData()
            } onError: { error in
                DocsLogger.error("fetch recent operation failed", error: error)
            }
            .disposed(by: bag)
    }

    private func setupUI() {
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(searchBar.preferedHeight)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func didClickSearchBar() {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let vc = factory.createWikiAndFolderSearchController(config: config)
        Navigator.shared.push(vc, from: self)
    }
}

extension WorkspacePickerController: UITableViewDataSource, UITableViewDelegate {

    // 是否需要一个单独的 extraSection 用于展示 config 里自定义的 entrance
    private var needExtraSection: Bool {
        config.extraEntranceConfig != nil
    }

    private var extraSectionIndex: Int? {
        guard needExtraSection else {
            return nil
        }
        return 0
    }

    private var entranceSectionIndex: Int {
        if needExtraSection {
            return 1
        } else {
            return 0
        }
    }

    private var numberOfEntranceSection: Int {
        config.entrances.count
    }

    private var needRecentSection: Bool {
        !recentEntries.isEmpty
    }

    private var recentSectionIndex: Int {
        if needExtraSection {
            return 2
        } else {
            return 1
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        var count = 1
        if needExtraSection {
            count += 1
        }
        if needRecentSection {
            count += 1
        }
        return count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case extraSectionIndex:
            return 1
        case entranceSectionIndex:
            return numberOfEntranceSection
        case recentSectionIndex:
            return recentEntries.count
        default:
            spaceAssertionFailure("unexpected section index: \(section)")
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case extraSectionIndex:
            return extraEntranceCell(tableView: tableView, indexPath: indexPath)
        case entranceSectionIndex:
            return standardEntranceCell(tableView: tableView, indexPath: indexPath)
        case recentSectionIndex:
            return recentCell(tableView: tableView, indexPath: indexPath)
        default:
            spaceAssertionFailure("unexpected section index: \(indexPath.section)")
            return tableView.dequeueReusableCell(withIdentifier: WorkspacePickerEntranceCell.reuseIdentifier,
                                                 for: indexPath)
        }
    }

    private func extraEntranceCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkspacePickerEntranceCell.reuseIdentifier,
                                                 for: indexPath)
        guard let entranceCell = cell as? WorkspacePickerEntranceCell else {
            spaceAssertionFailure("entrance cell type cast failed")
            return cell
        }
        guard let extraConfig = config.extraEntranceConfig else {
            spaceAssertionFailure("extra entrance config not found")
            return cell
        }
        entranceCell.title = extraConfig.title
        entranceCell.icon = extraConfig.icon
        return entranceCell
    }

    private func standardEntranceCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkspacePickerEntranceCell.reuseIdentifier,
                                                 for: indexPath)
        guard let entranceCell = cell as? WorkspacePickerEntranceCell else {
            spaceAssertionFailure("entrance cell type cast failed")
            return cell
        }
        guard indexPath.row < config.entrances.count else {
            spaceAssertionFailure("entrance index out of bounds")
            return cell
        }
        let entranceType = config.entrances[indexPath.row]
        switch entranceType {
        case .mySpace:
            let title = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_MyFolder_Menu : BundleI18n.SKResource.Doc_List_My_Space
            entranceCell.title = title
            entranceCell.icon = UDIcon.getIconByKeyNoLimitSize(.fileFolderColorful)
        case .sharedSpace:
            if SettingConfig.singleContainerEnable && !LKFeatureGating.newShareSpace {
                entranceCell.title = BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
            } else {
                entranceCell.title = BundleI18n.SKResource.Doc_List_Shared_Space
            }
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                entranceCell.title = BundleI18n.SKResource.LarkCCM_NewCM_SharedFolder_Menu
            }
            entranceCell.icon = UDIcon.getIconByKeyNoLimitSize(.sharedspaceColorful)
        case .wiki:
            let title = BundleI18n.SKResource.Doc_Facade_Wiki
            entranceCell.title = title
            entranceCell.icon = UDIcon.getIconByKeyNoLimitSize(.wikiColorful)
        case .myLibrary:
            let title = BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
            entranceCell.title = title
            entranceCell.icon = UDIcon.getIconByKeyNoLimitSize(.mywikiColorful)
        case .unorganized:
            let title = BundleI18n.SKResource.LarkCCM_NewCM_Unsorted_NavigationMenu
            entranceCell.title = title
            entranceCell.icon = UDIcon.getIconByKeyNoLimitSize(.inboxFilled, iconColor: UDColor.functionInfoContentDefault)
        case .cloudDriverHeader:
            // TODO: 后续MVP新首页全量后，修改为多section的方式展示header
            let cell = tableView.dequeueReusableCell(withIdentifier: WorkspacePickerEntranceSubHeaderView.reuseIdentifier,
                                                     for: indexPath)
            guard let subHeaderCell = cell as? WorkspacePickerEntranceSubHeaderView else {
                spaceAssertionFailure("entrance cell type cast failed")
                return cell
            }
            return subHeaderCell
        }
        return entranceCell
    }

    private func recentCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkspacePickerRecentCell.reuseIdentifier,
                                                 for: indexPath)
        guard let recentCell = cell as? WorkspacePickerRecentCell else {
            spaceAssertionFailure("recent cell type cast failed")
            return cell
        }
        guard indexPath.row < recentEntries.count else {
            spaceAssertionFailure("recent index out of bounds")
            return cell
        }
        let entry = recentEntries[indexPath.row]
        recentCell.update(entry: entry)
        return recentCell
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // 最后一个 section 不需要 footer
        if section >= (tableView.numberOfSections - 1) {
            return nil
        }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: WorkspacePickerFooterView.reuseIdentifier)
        ?? WorkspacePickerFooterView(reuseIdentifier: WorkspacePickerFooterView.reuseIdentifier)
        return view
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // 最后一个 section 不需要 footer
        if section >= (tableView.numberOfSections - 1) {
            return 0
        }
        return 8
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 只有 recentSection 才有 header
        guard section == recentSectionIndex else {
            return nil
        }
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: WorkspacePickerRecentHeaderView.reuseIdentifier)
        ?? WorkspacePickerRecentHeaderView(reuseIdentifier: WorkspacePickerRecentHeaderView.reuseIdentifier)
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // 只有 recentSection 才需要 header
        if section == recentSectionIndex {
            return 44
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case extraSectionIndex:
            didClickExtraEntrance()
        case entranceSectionIndex:
            didClickEntrance(row: indexPath.row)
        case recentSectionIndex:
            didClickRecentEntry(index: indexPath.row)
        default:
            spaceAssertionFailure("unexpected section index: \(indexPath.section)")
            return
        }
    }

    private func didClickEntrance(row: Int) {
        guard row < config.entrances.count else {
            spaceAssertionFailure("entrance row index out of bounds")
            return
        }
        let entranceType = config.entrances[row]
        switch entranceType {
        case .mySpace:
            didClickMySpace()
        case .sharedSpace:
            didClickSharedSpace()
        case .wiki:
            didClickWikiSpace()
        case .myLibrary:
            didClickMyLibrary()
        case .unorganized:
            didClickUnorganized()
        case .cloudDriverHeader:
            return
        }
    }

    private func didClickMySpace() {
        let controller = WorkspacePickerFactory.createMySpacePicker(config: config)
        Navigator.shared.push(controller, from: self)
    }

    private func didClickSharedSpace() {
        let controller = WorkspacePickerFactory.createShareSpacePicker(config: config)
        Navigator.shared.push(controller, from: self)
    }

    private func didClickWikiSpace() {
        let controller = WorkspacePickerFactory.createWikiPicker(config: config)
        Navigator.shared.push(controller, from: self)
    }
    
    private func didClickMyLibrary() {
        guard let spaceId = MyLibrarySpaceIdCache.get() else {
            spaceAssertionFailure("my library item should not show in picker When have not library spaceID cache")
            UDToast().showTips(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: view.window ?? view)
            return
        }
        let spaceName = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? BundleI18n.SKResource.LarkCCM_NewCM_Personal_Title : BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
        let controller = WorkspacePickerFactory.createMyLibraryPicker(spaceID: spaceId,
                                                                      spaceName: spaceName,
                                                                      config: config)
        Navigator.shared.push(controller, from: self)
    }
    
    private func didClickUnorganized() {
        let controller = WorkspacePickerFactory.createUnorganizedPicker(config: config)
        Navigator.shared.push(controller, from: self)
    }

    private func didClickExtraEntrance() {
        guard let extraConfig = config.extraEntranceConfig else {
            spaceAssertionFailure()
            return
        }
        extraConfig.handler(self)
    }

    private func didClickRecentEntry(index: Int) {
        guard index < recentEntries.count else {
            spaceAssertionFailure("recent row index out of bounds")
            return
        }
        let entry = recentEntries[index]
        let controller = WorkspacePickerFactory.createNodePicker(config: config, recentEntry: entry)
        Navigator.shared.push(controller, from: self)
    }
}

// TODO: 实现此协议仅为了创建副本时能正确展示容量管理弹窗，DocsCreateDirector 目前强依赖此类型，待后续优化后去掉此实现
extension WorkspacePickerController: DocsCreateViewControllerRouter {}
