//
//  BitableAdvancedPermissionsRuleVC.swift
//  Collaborator
//
//  Created by Da Lei on 2018/4/10.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignDialog
import SKInfra

public final class BitableAdvancedPermissionsRuleSectionData {
    var headerTitle: String?
    var models: [BitableAdvancedPermissionsRuleCellData] = []

    init(headerTitle: String?, subCellModels: [BitableAdvancedPermissionsRuleCellData]) {
        self.headerTitle = headerTitle
        self.models = subCellModels
    }
}

public final class BitableAdvancedPermissionsRuleCellData {
    var title: String
    var subTitle: String?
    init(tilte: String, subTitle: String?) {
        self.title = tilte
        self.subTitle = subTitle
    }
}

public final class BitableAdvancedPermissionsRuleVC: BaseViewController {
    private var permStatistics: PermissionStatistics?
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    private var checkLockPermission: DocsRequest<JSON>?
    private var data = [BitableAdvancedPermissionsRuleSectionData]()
    private let disposeBag: DisposeBag = DisposeBag()
    private let rule: BitablePermissionRule

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(BitableAdvancedPermissionsRuleHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: BitableAdvancedPermissionsRuleHeaderView.reuseIdentifier)
        collectionView.register(BitableAdvancedPermissionsRuleCell.self, forCellWithReuseIdentifier: BitableAdvancedPermissionsRuleCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    public init(rule: BitablePermissionRule, permStatistics: PermissionStatistics?) {
        self.rule = rule
        self.permStatistics = permStatistics
        super.init(nibName: nil, bundle: nil)
        initDataSource()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.SKResource.Bitable_AdvancedPermission_Setting
        setupView()
        permStatistics?.reportBitablePremiumPermissionRulesettingView()
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
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        }
    }


    public override func backBarButtonItemAction() {
        permStatistics?.reportPermissionSetClick(click: .back, target: .noneTargetView)
        super.backBarButtonItemAction()
    }
    
    func loading(isBehindNavBar: Bool = false) {
        showLoading(isBehindNavBar: isBehindNavBar, backgroundAlpha: 0.05)
    }

    ///初始化数据 model
    private func initDataSource() {
        var array: [BitableAdvancedPermissionsRuleSectionData] = []
        if rule.ruleType == .defaultEdit {
            let cellModels = [BitableAdvancedPermissionsRuleCellData(tilte: BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultEditPermissionTitle,
                                                                     subTitle: BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultEditPermissionDesc)]
            array.append(BitableAdvancedPermissionsRuleSectionData(headerTitle: nil, subCellModels: cellModels))
        } else if rule.ruleType == .defaultRead {
            let cellModels = [BitableAdvancedPermissionsRuleCellData(tilte: BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultViewPermissionTitle,
                                                                     subTitle: BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultViewPermissionDesc)]
            array.append(BitableAdvancedPermissionsRuleSectionData(headerTitle: nil, subCellModels: cellModels))
        }


        array.append(BitableAdvancedPermissionsRuleSectionData(headerTitle: BundleI18n.SKResource.Bitable_AdvancedPermission_PermissionName,
                                                               subCellModels: [BitableAdvancedPermissionsRuleCellData(tilte: rule.name,
                                                                                                                      subTitle: nil)]))



        let cellModels: [BitableAdvancedPermissionsRuleCellData] = rule.tables.compactMap { table in
            return BitableAdvancedPermissionsRuleCellData(tilte: table.name, subTitle: table.roleDes.keyWord)
        }
        array.append(BitableAdvancedPermissionsRuleSectionData(headerTitle: BundleI18n.SKResource.Bitable_AdvancedPermission_TablePermission, subCellModels: cellModels))
        self.data = array
    }
}

// MARK: - UICollectionViewDelegate/DataSource
extension BitableAdvancedPermissionsRuleVC: UICollectionViewDelegate & UICollectionViewDataSource & UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].models.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableAdvancedPermissionsRuleCell.reuseIdentifier, for: indexPath)
        guard let cell = reusableCell as? BitableAdvancedPermissionsRuleCell else {
            return reusableCell
        }
        let section = indexPath.section
        let row = indexPath.row
        guard section < data.count, row < data[section].models.count else {
            return reusableCell
        }
        let model = data[section].models[row]
        cell.setModel(model)
        let isFirstCell = (row == 0)
        let isLastCell = (row == data[section].models.count - 1)
        cell.updateSplitView(hidden: isLastCell)
        if isFirstCell || isLastCell {
            cell.contentView.layer.cornerRadius = 10
            if isFirstCell && !isLastCell {
                cell.contentView.layer.maskedCorners = .top
            } else if isLastCell && !isFirstCell {
                cell.contentView.layer.maskedCorners = .bottom
            }
            cell.contentView.layer.masksToBounds = true
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.section < data.count, indexPath.row < data[indexPath.section].models.count else { return .zero }
        let height = BitableAdvancedPermissionsRuleCell.height(data[indexPath.section].models[indexPath.row])
        let normalSize = CGSize(width: collectionView.frame.width - 2 * 16, height: height)
        return normalSize
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = indexPath.section
        let reuseHeader = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                          withReuseIdentifier: BitableAdvancedPermissionsRuleHeaderView.reuseIdentifier,
                                                                          for: indexPath)
        guard let header = reuseHeader as? BitableAdvancedPermissionsRuleHeaderView else {
            spaceAssertionFailure("get view fail in PublicPermissionSectionController getUserHeaderView")
            return UICollectionReusableView()
        }
        header.setTitle(data[section].headerTitle)
        return header
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section < data.count else {
            return .zero
        }
        let sectionModel = data[section]
        let height = BitableAdvancedPermissionsRuleHeaderView.sectionHeaderViewHeight(title: sectionModel.headerTitle)
        return CGSize(width: collectionView.frame.width, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        view.layer.zPosition = 0.0
    }
    
}
