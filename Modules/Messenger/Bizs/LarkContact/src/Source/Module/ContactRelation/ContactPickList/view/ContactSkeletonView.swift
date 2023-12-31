//
//  ContactSkeletonView.swift
//  LarkContact
//
//  Created by zhenning on 2020/9/12.
//

import UIKit
import Foundation
import SkeletonView

struct ContactSkeletonViewConfig {
    static let baseColor = UIColor.ud.N100
    static let secondaryColor = UIColor.ud.N300.withAlphaComponent(0.7)
}

final class ContactSkeletionCell: UITableViewCell {

    static let identifier = String(describing: self)

    let gradient = SkeletonGradient(baseColor: UIColor.ud.N100,
                                    secondaryColor: UIColor.ud.N300.withAlphaComponent(0.7))

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

    private func addSkeletionBar(leadingOffset: CGFloat, topOffset: CGFloat, width: CGFloat) {
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
        addSkeletionBar(leadingOffset: 76, topOffset: 16, width: 126)
        addSkeletionBar(leadingOffset: 76, topOffset: 40, width: 43)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ContactPickSkeletonTableView: UITableView {
    private let gradient = SkeletonGradient(baseColor: ContactSkeletonViewConfig.baseColor,
                                    secondaryColor: ContactSkeletonViewConfig.secondaryColor)

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
        self.register(ContactSkeletionCell.self, forCellReuseIdentifier: ContactSkeletionCell.identifier)

        self.isSkeletonable = true
        self.dataSource = self
        self.delegate = self
        self.separatorStyle = .none
        self.rowHeight = 68
    }
}

extension ContactPickSkeletonTableView: SkeletonTableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: ContactSkeletionCell.identifier) ?? ContactSkeletionCell(style: .default, reuseIdentifier: ContactSkeletionCell.identifier)
    }

    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return ContactSkeletionCell.identifier
    }
}
