//
//  MomentsHashTagListView.swift
//  Moment
//
//  Created by liluobin on 2021/6/23.
//

import Foundation
import UIKit
import SnapKit
import LarkContainer

protocol MomentsHashTagListViewDelegate: AnyObject {
    func didSelectedItem(_ item: String)
}

final class HashTagListHeader: UIView {
    init() {
        super.init(frame: .zero)
        setupview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupview() {
        backgroundColor = UIColor.ud.bgBody
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.text = BundleI18n.Moment.Lark_Community_RecentTitle
        addSubview(label)
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(lineView)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview()
        }
        lineView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }
}

final class MomentsHashTagListView: UIView, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    weak var delegate: MomentsHashTagListViewDelegate?
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.separatorStyle = .none
        table.register(HashTagCell.self, forCellReuseIdentifier: HashTagCell.cellId)
        return table
    }()
    var hasHeader = false

    lazy var viewModel: HashTagListViewModel = {
        return HashTagListViewModel(userResolver: self.userResolver) { [weak self] (_) in
            self?.tableView.reloadData()
        }
    }()
    lazy var headerView: HashTagListHeader = {
        return HashTagListHeader()
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupView() {
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        viewModel.refreshFirstRow = { [weak self] (hasHeader) in
            guard let self = self else {
                return
            }
            if self.hasHeader != hasHeader {
                self.tableView.reloadData()
            } else {
                self.tableView.reloadRows(at: [IndexPath(item: 0, section: 0)], with: .none)
            }
            self.hasHeader = hasHeader
            lineView.isHidden = hasHeader
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.hashTagItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HashTagCell.cellId, for: indexPath)
        if let hashtagCell = cell as? HashTagCell {
            hashtagCell.item = viewModel.hashTagItems[indexPath.row]
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
              indexPath.row < viewModel.hashTagItems.count else { return }
        let item = viewModel.hashTagItems[indexPath.row]
        delegate?.didSelectedItem(item.content)
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return hasHeader ? headerView : nil
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return hasHeader ? 40 : 0
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < viewModel.hashTagItems.count else {
            return 56
        }
        let item = viewModel.hashTagItems[indexPath.row]
        return (item.isUserCreate && item.content.isEmpty) ? 0 : 56
    }
}
