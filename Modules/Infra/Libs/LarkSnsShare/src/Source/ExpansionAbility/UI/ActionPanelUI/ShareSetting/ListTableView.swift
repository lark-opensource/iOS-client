//
//  SettingAreaView.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/22.
//

import Foundation
import UIKit

final class ListTableView: UIView {
    weak var actionPanel: LarkShareActionPanel?
    var dataSource: [[ShareSettingItem]]
    var onSettingItemClicked: (() -> Void)?
    var updateSettingDataSource: (() -> Void)?

    lazy var tableView: ContentSizedTableView = {
        let table = ContentSizedTableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.isScrollEnabled = true
        table.bounces = false
        table.delegate = self
        table.dataSource = self
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.separatorStyle = .none
        table.register(ListTableCell.self, forCellReuseIdentifier: ListTableCell.identifier)
        return table
    }()

    init(dataSource: [[ShareSettingItem]], actionPanel: LarkShareActionPanel?) {
        self.dataSource = dataSource
        self.actionPanel = actionPanel
        super.init(frame: .zero)
        self.addSubview(tableView)
        self.layer.cornerRadius = ShareCons.panelCornerRadius
        self.clipsToBounds = true

        tableView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(dataSource: [[ShareSettingItem]]) {
        self.dataSource = dataSource
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
    }
}

extension ListTableView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard dataSource.count > section else { return 0 }
        return dataSource[section].count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell: ListTableCell = tableView.dequeueReusableCell(withIdentifier: ListTableCell.identifier,
                                                                   for: indexPath) as? ListTableCell {
            let sectionCount = tableView.numberOfRows(inSection: indexPath.section)
            // 当前分区有多行数据时
            if sectionCount > 1 {
                switch indexPath.row {
                case 0:
                    cell.configure(item: dataSource[indexPath.section][indexPath.row])
                    cell.layer.cornerRadius = ShareCons.panelCornerRadius
                    cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                case sectionCount - 1:
                    cell.configure(item: dataSource[indexPath.section][indexPath.row], isDivideLineHidden: true)
                    cell.layer.cornerRadius = ShareCons.panelCornerRadius
                    cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                default:
                    cell.configure(item: dataSource[indexPath.section][indexPath.row])
                }
            } else {
                cell.configure(item: dataSource[indexPath.section][indexPath.row], isDivideLineHidden: true)
                cell.layer.cornerRadius = ShareCons.panelCornerRadius
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ShareCons.defaultSpacing
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard let handler = self.dataSource[indexPath.section][indexPath.row].handler,
              let panel = self.actionPanel else { return }
        handler(panel)
    }
}

final class ContentSizedTableView: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
