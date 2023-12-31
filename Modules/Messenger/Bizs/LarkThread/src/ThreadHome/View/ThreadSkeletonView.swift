//
//  ThreadSkeletonView.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/9/18.
//

import UIKit
import Foundation
import SkeletonView

struct SkeletonViewConfig {
    static let baseColor = UIColor.ud.N200.withAlphaComponent(0.5)
    static let secondaryColor = UIColor.ud.N200
}

final class SkeletionCell: UITableViewCell {
    let gradient = SkeletonGradient(baseColor: UIColor.ud.N200.withAlphaComponent(0.5),
                                    secondaryColor: UIColor.ud.N200)

    private func addAvatarView() {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        contentView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.leading.top.equalToSuperview().offset(16)
        }
        view.isSkeletonable = true
    }

    private func addBar(leadingOffset: CGFloat, topOffset: CGFloat, width: CGFloat) {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        contentView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.height.equalTo(10)
            make.leading.equalToSuperview().offset(leadingOffset)
            make.top.equalToSuperview().offset(topOffset)
            make.width.equalTo(width)
        }
        view.isSkeletonable = true
    }

    static let identifier = "SkeletionCell"

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isSkeletonable = true
        self.selectionStyle = .none
        initSubView()

        self.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.startSkeletonAnimation()
    }

    func initSubView() {
        addAvatarView()
        addBar(leadingOffset: 64, topOffset: 21, width: 105)
        addBar(leadingOffset: 64, topOffset: 40.5, width: 36)
        addBar(leadingOffset: 16, topOffset: 72, width: 221.5)
        addBar(leadingOffset: 16, topOffset: 98, width: 281)
        addBar(leadingOffset: 16, topOffset: 124, width: 172)

        let seprator = UIView()
        seprator.backgroundColor = UIColor.ud.N100
        contentView.addSubview(seprator)
        seprator.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TopicsSkeletonTableView: UITableView {
    private let gradient = SkeletonGradient(baseColor: SkeletonViewConfig.baseColor,
                                    secondaryColor: SkeletonViewConfig.secondaryColor)

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startLoading() {
        self.showAnimatedGradientSkeleton(usingGradient: self.gradient)
    }

    /// hide self when stop loading
    func stopLoading() {
        self.stopSkeletonAnimation()
        self.isHidden = true
    }

    private func setupUI() {
        self.register(SkeletionCell.self, forCellReuseIdentifier: SkeletionCell.identifier)

        self.isSkeletonable = true
        self.dataSource = self
        self.delegate = self

        self.isSkeletonable = true
        self.separatorStyle = .none
        self.rowHeight = 260
    }
}

extension TopicsSkeletonTableView: SkeletonTableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: SkeletionCell.identifier) ?? SkeletionCell(style: .default, reuseIdentifier: SkeletionCell.identifier)
    }

    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return SkeletionCell.identifier
    }
}
