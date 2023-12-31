//
//  SkeletonViewController.swift
//  UniverseDesignLoadingDev
//
//  Created by Miaoqi Wang on 2020/11/8.
//

import Foundation
import UIKit
import UniverseDesignLoading
import UniverseDesignColor
import SnapKit

private let reusableIdentifier = "SkeletonTableViewController.Cell"

class SkeletonTableViewController: UIViewController {

    let dataSource: [String] = [
        "测试数据",
        "数据源测试数据",
        "这是测试数据数据源测试数据",
        "============",
        "测试数据就是测试数据。那么多问题干嘛"
    ]

    lazy var listTable: UITableView = {
        let tb = UITableView()
        tb.dataSource = self
        tb.separatorStyle = .none
        tb.isSkeletonable = true
        tb.rowHeight = 80
        tb.register(SkeletonListTableViewCell.self, forCellReuseIdentifier: reusableIdentifier)
        return tb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.neutralColor1
        let header = headerView()
        view.addSubview(header)
        view.addSubview(listTable)
        view.isSkeletonable = true

        header.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
        }

        listTable.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(header.snp.bottom)
            make.bottom.equalToSuperview().inset(view.safeAreaInsets.bottom)
        }

        self.listTable.udPrepareSkeleton(completion: { [weak self] (_) in
            self?.view.showUDSkeleton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self?.view.hideUDSkeleton()
            }
        })
    }

    func headerView() -> UIView {
        let header = UIView()
        header.isSkeletonable = true

        let avatarView = UIImageView()
        avatarView.backgroundColor = .black
        avatarView.layer.cornerRadius = 10
        avatarView.isSkeletonable = true
        avatarView.layer.masksToBounds = true
        header.addSubview(avatarView)

        let nameLabel = UILabel()
        nameLabel.textColor = .black
        nameLabel.isSkeletonable = true
        nameLabel.text = " " // 空格告诉Skeleton这里需要显示
        nameLabel.udSkeletonCorner()
        header.addSubview(nameLabel)

        avatarView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(60)
            make.centerX.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(avatarView)
            make.top.equalTo(avatarView.snp.bottom).offset(16)
            make.width.greaterThanOrEqualTo(avatarView.snp.width)
            make.bottom.equalToSuperview()
        }
        return header
    }
}

extension SkeletonTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reusableIdentifier, for: indexPath
        ) as? SkeletonListTableViewCell else {
            return UITableViewCell()
        }

        cell.mainLabel.text = dataSource[indexPath.row]
        cell.subLabel.text = dataSource[indexPath.row]
        cell.avatarView.image = UIImage()

        return cell
    }
}
