//
//  InMeetSecuritySelectedViewController.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewUI

protocol InMeetSecuritySelectedViewControllerDelegate: AnyObject {
    func securitySelectedViewControllerDidSave(_ vc: InMeetSecuritySelectedViewController)
}

final class InMeetSecuritySelectedViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 72
        return tableView
    }()

    lazy var barSaveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_M_Save, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        button.setTitleColor(UIColor.ud.primaryPri400, for: .normal)
        button.setTitleColor(UIColor.ud.primaryPri400.withAlphaComponent(0.5), for: .highlighted)
        return button
    }()

    private(set) var deletedItems: [InMeetSecurityPickerItem] = []
    private var selectedItems: [InMeetSecurityPickerItem]
    private let setting: MeetingSettingManager
    private weak var delegate: InMeetSecuritySelectedViewControllerDelegate?

    init(setting: MeetingSettingManager, selectedData: InMeetSecurityPickerSelectedData, delegate: InMeetSecuritySelectedViewControllerDelegate?) {
        self.setting = setting
        self.selectedItems = selectedData.items
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\(I18n.View_M_Selected)\(selectedItems.count)"
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)
        }

        barSaveButton.addTarget(self, action: #selector(didSave(_:)), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: barSaveButton)

        tableView.register(InMeetSecuritySelectedCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = selectedItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? InMeetSecuritySelectedCell {
            cell.config(item, setting: setting)
            cell.deleteAction = { [weak self] _ in
                self?.deleteItem(at: indexPath.row)
            }
        }
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounces = scrollView.contentInset.top < scrollView.contentOffset.y
    }

    @objc private func didSave(_ sender: Any) {
        delegate?.securitySelectedViewControllerDidSave(self)
        self.popOrDismiss(true)
    }

    private func deleteItem(at index: Int) {
        let item = selectedItems.remove(at: index)
        self.deletedItems.append(item)
        self.title = "\(I18n.View_M_Selected)\(selectedItems.count)"
        self.tableView.reloadData()
    }
}
