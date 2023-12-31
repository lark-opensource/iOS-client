//
//  SCDebugFormViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation
import EENavigator

class SCDebugFormViewController: UIViewController {
    let model: SCDebugFormViewModel
    let heightForHeaderInSection: CGFloat = 35
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.layer.cornerRadius = 5
        tableView.allowsSelection = false
        return tableView
    }()
    
    let resultView: UITextView = {
        let textView = UITextView()
        textView.isSelectable = true
        textView.isEditable = false
        textView.font = .systemFont(ofSize: 14)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 5
        return textView
    }()

    init(model: SCDebugFormViewModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        view.backgroundColor = .white

        view.addSubview(tableView)
        view.addSubview(resultView)

        tableView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(resultView.snp.top).offset(-10)
        }

        resultView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(4)
            $0.bottom.equalTo(view.snp.bottomMargin)
            $0.height.equalTo(200)
        }

        registCellReuseIdentifier()
        tableView.delegate = self
        tableView.dataSource = self
        let submitButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(submitButtonClicked(_:)))
        navigationItem.setRightBarButtonItems([submitButton], animated: true)
    }

    private func registCellReuseIdentifier() {
        tableView.register(SCDebugChoiceBoxViewCell.self, forCellReuseIdentifier: "SCDebugChoiceBoxViewCell")
        tableView.register(SCDebugPasteButtonViewCell.self, forCellReuseIdentifier: "SCDebugPasteButtonViewCell")
        tableView.register(SCDebugSwitchButtonViewCell.self, forCellReuseIdentifier: "SCDebugSwitchButtonViewCell")
        tableView.register(SCDebugCustomizedKeyValueViewCell.self, forCellReuseIdentifier: "SCDebugCustomizedKeyValueViewCell")
        tableView.register(SCDebugCustomizedValueOnlyViewCell.self, forCellReuseIdentifier: "SCDebugCustomizedValueOnlyViewCell")
        tableView.register(SCDebugFormHeaderView.self, forHeaderFooterViewReuseIdentifier: "SCDebugFormHeaderView")
    }

    @objc
    private func submitButtonClicked(_ button: UIButton) {
        model.submit() { [weak self] result in
            DispatchQueue.runOnMainQueue {
                self?.resultView.text = result
            }
        }
    }

    private func addCell(in sectionName: String) {
        guard let sectionModel = model.sectionList[sectionName],
              let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
        let dialog = UIAlertController.generateChoiceDialog(choiceList: sectionModel.addibleFieldType,
                                          getChoiceName: { $0.cellID },
                                          complete: { [weak self] choice in
            sectionModel.insertFieldModel(modelType: choice, at: sectionModel.fieldList.count)
            self?.tableView.reloadData()
        })
        Navigator.shared.present(dialog, from: fromVC)
    }
}

extension SCDebugFormViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        model.sectionList[safeAccess: section]?.fieldList.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = model.sectionList[safeAccess: indexPath.section]
        let cellModelList = section?.fieldList
        let cellModel = cellModelList?[safeAccess: indexPath.row]
        guard let cellModel,
              let cell = tableView.dequeueReusableCell(withIdentifier: cellModel.cellID, for: indexPath) as? SCDebugFieldViewCellProtocol else {
            return UITableViewCell()
        }
        cell.configModel(model: cellModel)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SCDebugFormHeaderView"),
              let headerView = view as? SCDebugFormHeaderView,
              let sectionModel = model.sectionList[safeAccess: section] else {
            return UIView()
        }
        let isSectionEditable = sectionModel.isEidtable
        let sectionName = sectionModel.sectionName
        headerView.updateUI(text: sectionName,
                            isButtonHidden: !isSectionEditable)
        headerView.handleAddButtonClicked = { [weak self] in
            self?.addCell(in: sectionName)
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        model.rowHeight
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        model.sectionList.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        heightForHeaderInSection
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let sectionModel = model.sectionList[safeAccess: indexPath.section]
        let fieldModel = sectionModel?.fieldList[safeAccess: indexPath.row]
        return fieldModel?.isEditable ?? false
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "delete") { action, view, block in
            let sectionModel = self.model.sectionList[safeAccess: indexPath.section]
            sectionModel?.removeFieldModel(at: indexPath.row)
            tableView.reloadData()
            block(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
