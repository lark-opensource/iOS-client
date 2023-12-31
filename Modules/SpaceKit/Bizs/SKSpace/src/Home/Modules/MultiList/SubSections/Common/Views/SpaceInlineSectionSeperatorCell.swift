//
//  SpaceInlineSectionSeperatorCell.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/30.
//

import Foundation
import SnapKit
import UniverseDesignColor

class SpaceInlineSectionSeperatorCell: UICollectionViewCell {
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    fileprivate func setupUI() {
        contentView.backgroundColor = UIColor.ud.N100
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
    }

    func update(title: String) {
        titleLabel.text = title
    }
}

class SpaceInlineSectionSeperatorGridCell: SpaceInlineSectionSeperatorCell {
    private lazy var actualContentView = UIView()

    override func setupUI() {
        contentView.addSubview(actualContentView)
        actualContentView.backgroundColor = UIColor.ud.N100
        actualContentView.snp.makeConstraints { make in
            // 参考 SpaceRecentListSection 的 grid section insets
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(-16)
            make.right.equalToSuperview().inset(-16)
        }
        actualContentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
    }
}
