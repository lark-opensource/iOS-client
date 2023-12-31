//
//  FolderAndFileBrowserGridCell.swift
//  LarkFile
//
//  Created by liluobin on 2021/10/19.
//

import Foundation
import UIKit
import SnapKit
import ByteWebImage

class FolderAndFileBrowserGridCell: UICollectionViewCell, FileDislayCellProtocol {
    static var cellReuseID: String {
        return NSStringFromClass(Self.self)
    }
    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byTruncatingMiddle
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var sizeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let imageWarpperView = UIView()
        contentView.addSubview(imageWarpperView)
        imageWarpperView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(sizeLabel)
        imageWarpperView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(24)
            make.height.equalTo(84)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        nameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(imageWarpperView.snp.bottom).offset(8)
        }
        sizeLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        self.contentView.backgroundColor = UIColor.ud.bgBody
    }

    func setContent(props: FolderAndFileBrowserCellPropsProtocol) {
        iconImageView.image = props.image
        nameLabel.text = props.name
        sizeLabel.text = FileDisplayInfoUtil.sizeStringFromSize(props.size)
    }
}
