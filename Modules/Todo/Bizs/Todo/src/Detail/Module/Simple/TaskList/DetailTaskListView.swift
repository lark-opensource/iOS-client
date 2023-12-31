//
//  DetailTaskListView.swift
//  Todo
//
//  Created by wangwanxin on 2022/12/23.
//

import CTFoundation
import UIKit
import UniverseDesignIcon

final class DetailTaskListView: BasicCellLikeView {

    var contentHeight: CGFloat = 48.0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    static var footerHeight: CGFloat = 36.0
    static var headerHeight: CGFloat = 6.0

    private(set) lazy var emptyView = getEmptyView()
    private(set) lazy var tableView = getTableView()
    private(set) lazy var addView = getAddView()
    private(set) lazy var spaceView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let image = UDIcon.getIconByKey(
            .tasklistOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 20, height: 20)
        )
        icon = .customImage(image.ud.withTintColor(UIColor.ud.iconN3))
        iconAlignment = .centerVertically
        content = .customView(emptyView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: contentHeight)
    }

    private func getEmptyView() -> DetailEmptyView {
        let view = DetailEmptyView()
        view.text = I18N.Todo_AddTaskListInTaskDetails_Placeholder
        return view
    }

    private func getTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = spaceView
        tableView.tableFooterView = addView
        tableView.ctf.register(cellType: DetailTaskListContentCell.self)
        tableView.ctf.register(footerViewType: DetailTaskListContentFooterView.self)
        tableView.separatorStyle = .none
        tableView.clipsToBounds = false
        return tableView
    }

    private func getAddView() -> DetailAddView {
        let view = DetailAddView()
        view.text = I18N.Todo_AddTaskListInTaskDetails_Placeholder
        return view
    }

}
