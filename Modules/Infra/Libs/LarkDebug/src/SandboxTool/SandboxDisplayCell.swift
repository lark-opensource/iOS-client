//
//  SandboxDisplayCell.swift
//  swit_test
//
//  Created by bytedance on 2021/6/29.
//
import Foundation
#if !LARK_NO_DEBUG
import UIKit
import SnapKit
final class SandboxDisplayCell: UITableViewCell {
    static let reuseID = "SandboxDisplayCell"
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let sizeLabel = UILabel()
    var item: SandboxInfoItem? {
        didSet {
            updateUI()
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupView() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(sizeLabel)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        sizeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        sizeLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textAlignment = .left
        sizeLabel.textAlignment = .right
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalTo(sizeLabel.snp.left).offset(-8)
        }
        sizeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    func updateUI() {
        guard let item = self.item else {
            return
        }
        titleLabel.text = item.name
        let size = SandboxFileManager.getFileSizeForPath(item.path)
        sizeLabel.text = SandboxFileManager.getFileSizeDisplayText(size)
        imageView?.image = item.type == .directory ? Resources.debugDic : Resources.debugFile
    }
}
#endif
