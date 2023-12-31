//
//  GroupChatterOrderSelectViewController.swift
//  LarkChatSetting
//
//  Created by Yaoguoguo on 2023/2/23.
//

import Foundation
import LarkUIKit
import FigmaKit
import LarkSettingUI
import SnapKit
import LarkCore
import UniverseDesignColor

class GroupChatterOrderSelectViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    struct SortModel {
        var title: String
        var type: ChatterSortType
    }

    private lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: CGRect.zero)
        tableView.showsVerticalScrollIndicator = false
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 16)))
        tableView.rowHeight = 48
        tableView.register(NormalCell.self, forCellReuseIdentifier: "NormalCell")
        return tableView
    }()

    // 完成按钮
    private lazy var rightItem: UIBarButtonItem = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.B500, for: .normal)
        button.setTitleColor(UIColor.ud.B500, for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkChatSetting.Lark_Legacy_Completed, for: .normal)
        button.addTarget(
            self,
            action: #selector(done),
            for: .touchUpInside
        )
        return UIBarButtonItem(customView: button)
    }()

    private var selectedType: ChatterSortType

    private let models: [SortModel] = [
        SortModel(title: BundleI18n.LarkChatSetting.Lark_IM_GroupMembers_SortByNames_Button, type: .alphabetical),
        SortModel(title: BundleI18n.LarkChatSetting.Lark_IM_GroupMembers_SortByJoinDate_Button, type: .joinTime)
    ]

    var finishCallBack: ((ChatterSortType) -> Void)?

    init(defaultType: ChatterSortType = .joinTime, finishCallBack: ((ChatterSortType) -> Void)? = nil) {
        self.selectedType = defaultType
        super.init(nibName: nil, bundle: nil)
        self.finishCallBack = finishCallBack
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NewChatSettingTracker.groupmemberRankView()
        self.title = BundleI18n.LarkChatSetting.Lark_IM_GroupMembersMobile_SortMembers_Button
        self.addCancelItem()
        navigationItem.rightBarButtonItem = rightItem

        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.models[indexPath.row]
        let accessories: [NormalCellAccessory] = [.checkMark(isShown: model.type == selectedType)]
        let item = NormalCellProp(title: model.title,
                                  accessories: accessories)
        let cell = NormalCell()
        cell.update(item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        didSelect(self.models[indexPath.row].type)
    }

    private func didSelect(_ type: ChatterSortType) {
        self.selectedType = type
        tableView.reloadData()
    }

    @objc
    private func done() {
        NewChatSettingTracker.groupmemberRankViewClick(rankByName: self.selectedType == .alphabetical)
        self.finishCallBack?(self.selectedType)
        self.dismiss(animated: true)
    }
}
