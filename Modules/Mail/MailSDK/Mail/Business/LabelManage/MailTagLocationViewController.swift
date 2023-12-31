//
//  MailTagLocationViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/17.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import Homeric

protocol MailTagLocationDelegate: AnyObject {
    func updateTagLocation(_ model: MailFilterLabelCellModel, userOrderIndex: Int64?)
}

class MailTagLocationViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    enum Scene {
        case label
        case folder
    }

    /// 当前所属的ID
    let fromLabel: MailFilterLabelCellModel?
    let defaultParentId: String?

    var didMoveLabelCallback: (() -> Void)?
    private var disposeBag = DisposeBag()
    private var filterThreadLabels: [MailFilterLabelCellModel] = []
//    private var allLabels: [MailFilterLabelCellModel] = []
    private var selectedLabel: MailFilterLabelCellModel?
    private var newLabelID: String?
    private let accountContext: MailAccountContext
    var scene: Scene = .label
    weak var delegate: MailTagLocationDelegate?
    var folderTree: FolderTree?
    var disableFolder: [MailFilterLabelCellModel] = []

    override var navigationBarTintColor: UIColor {
        return ModelViewHelper.navColor()
    }

    init(fromLabel: MailFilterLabelCellModel?, defaultParentId: String?, accountContext: MailAccountContext) {
        self.fromLabel = fromLabel
        self.defaultParentId = defaultParentId
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        getLabels()

        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(_):
                    self?.getLabels()
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }

    @objc
    func confirmHandler() {
        if let selectedLabel = selectedLabel {
            moveToLabel(selectedLabel)
        } else {
            navigator?.pop(from: self)
        }
    }

    func reloadData() {
        asyncRunInMainThread {
            self.tableView.reloadData()
        }
    }

    func setupViews() {
        var tagTpye: MailTagType = .label
        if scene == .label {
            tagTpye = .label
        } else {
            tagTpye = .folder
        }
        title = BundleI18n.MailSDK.__Mail_Folder_TabNamePlaceMobile.toTagName(tagTpye)
        self.view.backgroundColor = ModelViewHelper.listColor()
        updateNavAppearanceIfNeeded()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Display.bottomSafeAreaHeight)
        }
    }

    func getLabels() {
        MailDataSource.shared.getLabelsFromDB()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (labels) in
                guard let `self` = self else { return }
                var filterLabels = [MailFilterLabelCellModel]()
                if self.scene == .label {
                    filterLabels = labels.filter {
                        if $0.tagType == .folder {
                            return false
                        }
                        if let fromLabel = self.fromLabel, $0.labelId == fromLabel.labelId {
                            return false
                        }
                        if !$0.isSystem || self.targetSystemLabels.contains($0.labelId) {
                            return true
                        }
                        return false
                    }
                } else {
                    if FeatureManager.enableSystemFolder() {
                        filterLabels = labels.filter {
                            if $0.tagType == .folder || ($0.isSystem && managableSystemFolders.contains($0.labelId)) {
                                return true
                            }
                            return false
                        }
                    } else {
                        filterLabels = labels.filter {
                            if $0.tagType == .label {
                                return false
                            }
                            return true
                        }
                    }
                }

                self.folderTree = FolderTree.build(filterLabels)

                if self.scene == .folder {
                    var folder: [MailFilterLabelCellModel] = []
                    if FeatureManager.enableSystemFolder() {
                        var (system, other) = filterLabels.genSortedSystemAndOther()
                        self.disableFolder = self.folderTree?.findChilds(self.fromLabel?.labelId ?? "") ?? []
                        var myFolder = MailFilterLabelCellModel(labelId: Mail_FolderId_Root, badge: 0)
                        myFolder.text = BundleI18n.MailSDK.Mail_Folder_MyFoldersMobile
                        myFolder.tagType = .folder
                        other.insert(myFolder, at: 0)
                        system.append(contentsOf: other)
                        folder = system
                    } else {
                        folder = filterLabels
                        self.disableFolder = self.folderTree?.findChilds(self.fromLabel?.labelId ?? "") ?? []
                        var myFolder = MailFilterLabelCellModel(labelId: Mail_FolderId_Root, badge: 0)
                        myFolder.text = BundleI18n.MailSDK.Mail_Folder_MyFoldersMobile
                        myFolder.tagType = .folder
                        folder.insert(myFolder, at: 0)
                    }
                    filterLabels = folder
                } else {
                    var myLabel = MailFilterLabelCellModel(labelId: "", badge: 0)
                    myLabel.text = BundleI18n.MailSDK.Mail_Label_MyLabels
                    myLabel.tagType = .label
                    filterLabels.insert(myLabel, at: 0)
                }
                self.filterThreadLabels = filterLabels
                self.reloadData()
                self.newLabelID = nil
        }).disposed(by: disposeBag)
   }

    lazy var targetSystemLabels: [String] = {
        return [] // [Mail_LabelId_Inbox]
    }()

    private func moveToLabel(_ label: MailFilterLabelCellModel) {
        disposeBag = DisposeBag()
        if scene == .label {
            setConfirmBtnEnable(false)
            if let selectedLabel = selectedLabel {
                delegate?.updateTagLocation(selectedLabel, userOrderIndex: nil)
                navigator?.pop(from: self)
            }
        } else {
            setConfirmBtnEnable(false)
            if let selectedLabel = selectedLabel {
                let didChangeParent = (selectedLabel.labelId != fromLabel?.parentID ?? Mail_FolderId_Root)
                delegate?.updateTagLocation(selectedLabel, userOrderIndex: didChangeParent ? nil: selectedLabel.userOrderedIndex)
                navigator?.pop(from: self)
            }
        }
    }

    private func setConfirmBtnEnable(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.registerClass(MailEditLabelCell.self)
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.bounds = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 15)
        tableView.backgroundColor = ModelViewHelper.listColor()
        return tableView
    }()

    // MARK: - TableView Datasource & Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterThreadLabels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as MailEditLabelCell
        let label = filterThreadLabels[indexPath.row]
        if (label.isSystem || (self.folderTree?.checkRootParentIsSystem(labelId: label.labelId) ?? false)) && FeatureManager.enableSystemFolder()
            && scene == .folder {
            cell.defaultPadding = 16
        } else {
            cell.defaultPadding = 32
        }
        cell.hiddenOptionButton(true)
        cell.hiddenIcon = label.labelId == Mail_FolderId_Root
        cell.config(label)
        if label.isSystem {
            cell.labelIcon.tintColor = UIColor.ud.iconN1
        }
        cell.setDisable(disableFolder.contains(label))
        var shouldSelected = false
        if let from = fromLabel {
            shouldSelected = from.parentID == label.labelId
        } else {
            shouldSelected = indexPath.row == 0 // 新建默认第一个
        }
        if let parentId = defaultParentId {
            shouldSelected = parentId == label.labelId
        }
        // 为了退出一瞬间的点击态同步
        if let selected = selectedLabel {
            shouldSelected = selected.labelId == label.labelId
        }
        cell.isSelected = shouldSelected
        cell.hideSelectIcon = !shouldSelected
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let label = filterThreadLabels[indexPath.row]
        if disableFolder.contains(label) { // 无法选择当前及子级文件夹
            return
        }
        if scene == .folder { // 暂时只限制文件夹
            var fromFolderDepth: Int = 0
            if let fromeTagID = fromLabel?.labelId {
                fromFolderDepth = folderTree?.findMaxDepth(fromeTagID) ?? 1
            } else {
                fromFolderDepth = 1
            }
            var maxLayersCount = 5
            if let setting = ProviderManager.default.commonSettingProvider,
               let maxCountString = setting.originalSettingValue(configName: .mailFolderLayerMaxCountKey),
               let maxCount = Int(maxCountString) {
                maxLayersCount = maxCount
            }
            let selectedFolderDepth: Int = folderTree?.getDepth(label.labelId) ?? 1
            if fromFolderDepth + selectedFolderDepth > maxLayersCount {
                MailLogger.debug("[mail_folder] fromFolderDepth: \(fromFolderDepth) selectedFolderDepth: \(selectedFolderDepth)")
                MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_AddSubFolder_MaximumFolder_Toast(num: maxLayersCount),
                                        on: self.view,
                                        event: ToastErrorEvent(event: .folder_maximumfivelayersmobile))
                return
            }
        }
        selectedLabel = label
        setConfirmBtnEnable(true)
        tableView.reloadData()
        confirmHandler()
    }

}
