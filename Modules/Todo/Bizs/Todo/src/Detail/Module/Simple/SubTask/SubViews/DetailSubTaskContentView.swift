//
//  DetailSubTaskContentView.swift
//  Todo
//
//  Created by baiyantao on 2022/7/25.
//

import CTFoundation

final class DetailSubTaskContentView: UIView {

    private(set) lazy var tableView = getTableView()
    private(set) lazy var headerView = DetailSubTaskHeaderView()
    private(set) lazy var footerView = DetailSubTaskFooterView()

    init() {
        super.init(frame: .zero)

        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        headerView.frame.size.height = DetailSubTask.headerHeight
        tableView.tableHeaderView = headerView
        footerView.frame.size.height = DetailSubTask.footerItemHeight + DetailSubTask.footerBottomOffset
        tableView.tableFooterView = footerView
        tableView.ctf.register(cellType: DetailSubTaskContentCell.self)
        tableView.separatorStyle = .none
        tableView.clipsToBounds = false
        return tableView
    }
}
