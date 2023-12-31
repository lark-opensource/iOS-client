//
//  ForwardSkeletonTableView.swift
//  LarkMentionDev
//
//  Created by Yuri on 2022/7/8.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignLoading

final class ForwardSkeletonCell: UITableViewCell {
    let avatarView = UIImageView()
    let labelView = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(CGSize(width: 40, height: 40))
            $0.centerY.equalToSuperview()
        }
        labelView.layer.cornerRadius = 8
        labelView.clipsToBounds = true
        contentView.addSubview(labelView)
        labelView.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-27)
            $0.height.equalTo(16)
            $0.centerY.equalToSuperview()
        }
    }
    private var currentWidth: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        if currentWidth == contentView.bounds.width { return }
        currentWidth = contentView.bounds.width
        labelView.layoutIfNeeded()
        labelView.showUDSkeleton()
        avatarView.showUDSkeleton()
    }
}

final class ForwardSkeletonTableView: UIView {
    private var tableView = UITableView(frame: .zero, style: .plain)
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        tableView.isUserInteractionEnabled = false
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.rowHeight = 66
        tableView.register(ForwardSkeletonCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = UIColor.ud.bgBody
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalTo(UIEdgeInsets.zero)
        }
    }
}

extension ForwardSkeletonTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        return cell
    }
}
