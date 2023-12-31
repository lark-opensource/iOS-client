//
//  BanningSettingSelectedController.swift
//  LarkChat
//
//  Created by kkk on 2019/3/14.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LarkCore

typealias OnSureHandler = (_ selecetdItems: [ChatChatterItem], _ removedItems: [ChatChatterItem]) -> Void
final class ChatChatterSelectedDetailController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private var selectedItems: [ChatChatterItem]
    private var removedItems: [ChatChatterItem] = []
    private let saveItem = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Save)
    private let tableView = UITableView(frame: .zero, style: .plain)
    var onSure: OnSureHandler?

    init(selectedItems: [ChatChatterItem]) {
        self.selectedItems = selectedItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 68
        tableView.register(ChatChatterSelectedDetailCell.self,
                           forCellReuseIdentifier: ChatChatterSelectedDetailCell.lu.reuseIdentifier)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        saveItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        saveItem.setBtnColor(color: UIColor.ud.colorfulBlue)
        saveItem.button.addTarget(self, action: #selector(saveTap), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = saveItem

        updateTitle()
    }

    @objc
    private func saveTap() {
        onSure?(selectedItems, removedItems)
        navigationController?.popViewController(animated: true)
    }

    private func updateTitle() {
        self.titleString = BundleI18n.LarkChatSetting.Lark_Legacy_SelectMemberCountTip(selectedItems.count)
    }

    private func removeItem(_ item: ChatChatterItem) {
        selectedItems.removeAll(where: { $0.itemId == item.itemId })
        removedItems.append(item)
        tableView.reloadData()
        updateTitle()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.tableView.reloadData()
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatChatterSelectedDetailCell.lu.reuseIdentifier,
            for: indexPath)

        if let _cell = cell as? ChatChatterSelectedDetailCell, indexPath.row < selectedItems.count {
            _cell.item = selectedItems[indexPath.row]
            _cell.onRemove = { [weak self] (item) in
                guard let item = item else { return }
                self?.removeItem(item)
            }
        }

        return cell
    }
}
