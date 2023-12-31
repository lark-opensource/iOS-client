//
//  TableViewController.swift
//  LarkTagDev
//
//  Created by Kongkaikai on 2018/12/5.
//

import Foundation
import UIKit
import LarkTag
import SnapKit

class TestTagCell: UITableViewCell {
    let tagView = TagWrapperView()
    var customView: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(tagView)
        tagView.setTags([types[0]])
        tagView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(26)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
         }

        // 方便看到各种Tag
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TestTagCell.self, forCellReuseIdentifier: "reuseIdentifier")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2000
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        if let cell = cell as? TestTagCell {
            let index = indexPath.row % (types.count + 5)
            if index < types.count {
                cell.tagView.isHidden = false
                cell.customView?.isHidden = true

                // 是否自定义排序
                let autoSort: Bool = Bool.random()

                // 随机Tag
                let tag = Tag(
                    title: "\(autoSort)",
                    style: styles.randomElement() ?? .turquoise,
                    type: .customTitleTag)

                // 设置Elements 和 最大显示数量
                cell.tagView.setElements([tag, types[index], types.first!], autoSort: autoSort)
                cell.tagView.maxTagCount = Int.random(in: 1...3)
            } else {
                cell.tagView.isHidden = true
                cell.customView?.removeFromSuperview()

                let tag = LarkTag.Tag(
                    title: "CustomTag: \(indexPath)",
                    image: nil,
                    style: styles.randomElement() ?? .red,
                    type: .customTitleTag)
                let titleTagView = TagWrapperView.titleTagView(for: tag)

                cell.contentView.addSubview(titleTagView)
                cell.customView = titleTagView

                titleTagView.snp.makeConstraints {
                    $0.left.equalToSuperview().offset(26)
                    $0.centerY.equalToSuperview()
                }
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

let types: [TagType] = [
    .external,
    .doNotDisturb,
    .cryptoDoNotDisturb,
    .unregistered,
    .deactivated,
    .isFrozen,
    .onLeave,
    .oncall,
    .crypto,
    .tenantSuperAdmin,
    .tenantAdmin,
    .mainSupervisor,
    .supervisor,
    .groupOwner,
    .groupAdmin,
    .team,
    .allStaff,
    .newVersion,
    .unread,
    .app,
    .robot,
    .thread,
    .read,
    .public,
    .officialOncall,
    .oncallUser,
    .oncallAgent,
    .shareDeactivated,
    .calendarExternalGrey,
    .calendarOrganizer,
    .calendarCreator,
    .calendarNotAttend,
    .calendarOptionalAttend,
    .calendarConflict,
    .calendarConflictInMonth,
    .homeSchool,
    .connect
]

let styles: [Style] = [
    .blue,
    .red,
    .yellow,
    .darkGrey,
    .lightGrey,
    .white,
    .turquoise
]
