//
//  CCMTypeFilterController.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/5/17.
//

import UIKit
import SnapKit
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class CCMTypeFilterController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    private var selections: [CCMTypeFilterOption]
    private var inMultiSelectionMode = false

    private let allOptions: [[CCMTypeFilterOption]]

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.backgroundColor = UDColor.bgBody
        view.allowsMultipleSelection = true
        view.sectionHeaderHeight = 0
        view.sectionFooterHeight = 0
        view.separatorStyle = .none
        view.contentInsetAdjustmentBehavior = .never
        view.register(CCMTypeFilterCell.self, forCellReuseIdentifier: CCMTypeFilterCell.reuseIdentifier)
        view.delegate = self
        view.dataSource = self
        return view
    }()

    private lazy var naviBarButtonItem: SKBarButtonItem = {
        let item = SKBarButtonItem(title: SKResource.BundleI18n.SKResource.Lark_Legacy_MenuMultiSelect,
                                   style: .plain,
                                   target: self,
                                   action: #selector(didClickNaviBarButton))
        item.foregroundColorMapping = SKBarButton.defaultTitleColorMapping
        return item
    }()

    var completion: (([CCMTypeFilterOption]) -> Void)?

    init(selections: [CCMTypeFilterOption], showFolderOption: Bool) {
        self.selections = selections
        if showFolderOption {
            allOptions = [
               CCMTypeFilterOption.allDocumentTypes,
               [.folder]
           ]
        } else {
            allOptions = [CCMTypeFilterOption.allDocumentTypes]
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBody
        navigationBar.title = SKResource.BundleI18n.SKResource.Doc_Search_Type
        navigationBar.trailingBarButtonItem = naviBarButtonItem
        let closeItem = SKBarButtonItem(image: UDIcon.closeSmallOutlined,
                                        style: .plain,
                                        target: self,
                                        action: #selector(close))
        closeItem.id = .close
        navigationBar.leadingBarButtonItem = closeItem
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        // 带选项进入时，自动进多选态并选中
        if !selections.isEmpty {
            switchToMultiSelectionMode()
            selections.forEach { selectedOption in
                guard let indexPath = indexPath(for: selectedOption) else { return }
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }

    @objc
    private func close() {
        dismiss(animated: true)
    }

    @objc
    private func didClickNaviBarButton() {
        if !inMultiSelectionMode {
            switchToMultiSelectionMode()
        } else {
            completion?(selections)
            dismiss(animated: true)
        }
    }

    private func switchToMultiSelectionMode() {
        inMultiSelectionMode = true
        tableView.allowsMultipleSelection = true
        naviBarButtonItem.foregroundColorMapping = SKBarButton.primaryColorMapping
        updateConfirmButton()
        navigationBar.trailingBarButtonItem = naviBarButtonItem
        tableView.visibleCells.forEach { cell in
            guard let typeCell = cell as? CCMTypeFilterCell else { return }
            typeCell.switchToMultiSelectionStyle(animated: true)
        }
    }

    private func updateConfirmButton() {
        if selections.isEmpty {
            naviBarButtonItem.title = SKResource.BundleI18n.SKResource.Doc_Facade_Ok
        } else {
            naviBarButtonItem.title = SKResource.BundleI18n.SKResource.Doc_Facade_Ok + "(\(selections.count))"
        }
        navigationBar.trailingBarButtonItem = naviBarButtonItem
    }

    // 返回 indexPath 对应的 option
    private func option(for indexPath: IndexPath) -> CCMTypeFilterOption? {
        guard indexPath.section < allOptions.count else {
            assertionFailure("section index out of bounds")
            return nil
        }
        let sectionOptions = allOptions[indexPath.section]
        guard indexPath.row < sectionOptions.count else {
            assertionFailure("row index out of bounds")
            return nil
        }
        return sectionOptions[indexPath.row]
    }

    private func indexPath(for option: CCMTypeFilterOption) -> IndexPath? {
        for (section, options) in allOptions.enumerated() {
            if let row = options.firstIndex(of: option) {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let option = option(for: indexPath) else {
            return
        }
        guard inMultiSelectionMode else {
            completion?([option])
            dismiss(animated: true)
            return
        }
        selections.append(option)
        updateConfirmButton()
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let option = option(for: indexPath) else {
            return
        }
        selections.removeAll { $0 == option }
        updateConfirmButton()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        allOptions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < allOptions.count else {
            return 0
        }
        return allOptions[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CCMTypeFilterCell.reuseIdentifier, for: indexPath)
        guard let typeCell = cell as? CCMTypeFilterCell else {
            assertionFailure()
            return cell
        }
        guard let option = option(for: indexPath) else {
            return cell
        }
        typeCell.update(title: option.displayTitle)
        typeCell.update(shouldHideSeparator: false)
        if inMultiSelectionMode {
            typeCell.switchToMultiSelectionStyle(animated: false)
        }
        return typeCell
    }
}
