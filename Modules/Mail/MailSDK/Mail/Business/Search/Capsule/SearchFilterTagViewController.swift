//
//  SearchFilterTagViewController.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/19.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift

class SearchFilterTagViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    enum Scene {
        case filterLabel
        case filterFolder
    }
    var didSelecteItem: ((MailFilterLabelCellModel?, UIViewController) -> Void)?
    var scene: Scene
    var selectedLabel: MailFilterLabelCellModel?
    var filterLabels = [[MailFilterLabelCellModel]]()
    private var disposeBag = DisposeBag()
    var smartInboxEnable: Bool = false
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.sectionHeaderHeight = 0
        tableView.tableHeaderView = nil
        tableView.allowsMultipleSelection = true
        tableView.registerClass(MailEditLabelCell.self)
        tableView.backgroundColor = ModelViewHelper.listColor()
        return tableView
    }()

    init(scene: SearchFilterTagViewController.Scene, selectedLabel: MailFilterLabelCellModel?) {
        self.scene = scene
        self.selectedLabel = selectedLabel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        smartInboxEnable = Store.settingData.getCachedCurrentSetting()?.smartInboxMode ?? false
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
    
    func setupViews() {
        self.title = scene == .filterFolder ? BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Folder : BundleI18n.MailSDK.Mail_AdvancedSearchFilter_Label
        self.view.backgroundColor = ModelViewHelper.listColor()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()

        view.addSubview(tableView)
        let bottomOffset = Display.bottomSafeAreaHeight == 0 ? 24 : Display.bottomSafeAreaHeight
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomOffset)
        }
    }
    
    func getLabels() {
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
//            self.allLabels = labels
            var filterLabels = [[MailFilterLabelCellModel]]()
            if self.scene == .filterLabel {
                let allLabelModel = MailFilterLabelCellModel(labelId: Mail_LabelId_Unknow, icon: nil, text: BundleI18n.MailSDK.Mail_AdvancedSearchFilter_LabelDefaultOption_AllLabels, badge: 0, fontColor: UIColor.ud.colorfulBlue)
                filterLabels.append([allLabelModel])
                let customLabels = labels.filter { $0.tagType == .label && !$0.isSystem }
                filterLabels.append(customLabels)
                
            } else if self.scene == .filterFolder {
                var allFolderModel = MailFilterLabelCellModel(labelId: Mail_FolderId_Root, icon: nil, text: BundleI18n.MailSDK.Mail_AdvancedSearchFilter_FolderDefaultOption_AllFolders, badge: 0, fontColor: nil)
                allFolderModel.tagType = .folder
                allFolderModel.isSystem = false
                filterLabels.append([allFolderModel])
                if self.smartInboxEnable {
                    let smartLabels = labels.filter { smartInboxLabels.contains($0.labelId) }
                    filterLabels.append(smartLabels)
                    let targetFolder = [Mail_LabelId_Archived, Mail_LabelId_Spam,
                                        Mail_LabelId_Sent, Mail_LabelId_FLAGGED, Mail_LabelId_Trash]
                    let systemLabels = labels.filter { targetFolder.contains($0.labelId) }
                    filterLabels.append(systemLabels)
                } else {
                    let targetFolder = [Mail_LabelId_Inbox, Mail_LabelId_FLAGGED,
                                       Mail_LabelId_Sent, Mail_LabelId_Archived,
                                       Mail_LabelId_Trash, Mail_LabelId_Spam]
                    let systemLabels = labels.filter { !smartInboxLabels.contains($0.labelId) && targetFolder.contains($0.labelId) }
                    filterLabels.append(systemLabels)
                }
                let customFolders = labels.filter { $0.tagType == MailTagType.folder && !$0.isSystem && $0.labelId != Mail_LabelId_Stranger }
                filterLabels.append(customFolders)
            }
            self.filterLabels = filterLabels
            asyncRunInMainThread {
                self.tableView.reloadData()
            }
        }).disposed(by: disposeBag)
   }
    
    
    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < filterLabels.count else { return 0 }
        return filterLabels[section].count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return filterLabels.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section < filterLabels.count - 1 {
            let footer = UIView()
            footer.backgroundColor = UIColor.ud.lineDividerDefault
            return footer
        } else {
            return UIView()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section < filterLabels.count - 1 {
            return 1
        } else {
            return 0.01
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as MailEditLabelCell
        let label = filterLabels[indexPath.section][indexPath.row]
        cell.config(label)
        cell.hiddenOptionButton(true)
        if scene == .filterFolder && label.isSystem {
            cell.labelIcon.tintColor = UIColor.ud.iconN1
        }
        if let selectedID = selectedLabel?.labelId {
            cell.isSelected = (label.labelId == selectedID)
        } else {
            cell.isSelected = indexPath.section == 0 && indexPath.row == 0
        }
        cell.hideSelectIcon = !cell.isSelected
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let label = filterLabels[indexPath.section][indexPath.row]
        didSelectLabel(label: label, indexPath: indexPath)
    }

    private func didSelectLabel(label: MailFilterLabelCellModel, indexPath: IndexPath) {
        selectedLabel = label
        tableView.reloadData()
        let selectedItem = selectedLabel?.labelId == Mail_LabelId_Unknow || selectedLabel?.labelId == Mail_FolderId_Root ? nil : label
        didSelecteItem?(selectedItem, self)
    }
}

