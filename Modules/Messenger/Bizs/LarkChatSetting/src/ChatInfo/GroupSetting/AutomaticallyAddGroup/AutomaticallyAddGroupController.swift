//
//  AutomaticallyAddGroupController.swift
//  LarkChatSetting
//
//  Created by Yaoguoguo on 2023/5/23.
//

import Foundation
import FigmaKit
import LarkUIKit
import ServerPB
import UniverseDesignColor
import UniverseDesignFont

final class AutomaticallyAddGroupController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private let table = InsetTableView(frame: .zero)
    private let rules: [ServerPB_Entities_ChatRefDynamicRule]

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(rules: [ServerPB_Entities_ChatRefDynamicRule]) {
        self.rules = rules
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkChatSetting.Lark_GroupSettings_WhoCanAutoJoin_Title

        self.view.addSubview(self.table)
        self.table.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.table.separatorStyle = .none
        self.table.delegate = self
        self.table.dataSource = self
        self.table.showsVerticalScrollIndicator = false
        self.table.rowHeight = UITableView.automaticDimension
        self.table.estimatedRowHeight = 114
        self.table.sectionHeaderHeight = UITableView.automaticDimension
        self.table.sectionFooterHeight = 0
        self.table.lu.register(cellSelf: AutomaticallyAddGroupCell.self)
        self.table.backgroundColor = UIColor.ud.bgFloatBase
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return rules.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < rules.count else { return UITableViewCell() }
        let cell = AutomaticallyAddGroupCell()
        let name = self.rules[indexPath.section].refName
        if rules.count == 1 {
            cell.setRule(order: nil, refName: name)
        } else {
            cell.setRule(order: indexPath.section + 1, refName: name)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let text = BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_EditOnDesktop_Mobile_Text
        let height = text.getHeight(withConstrainedWidth: self.table.frame.width - 16, font: UIFont.systemFont(ofSize: 14))
        return section == 0 ? height : 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.numberOfLines = 0
            label.textColor = UIColor.ud.textPlaceholder
            label.text = BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_EditOnDesktop_Mobile_Text
            return label
        }
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }
}
