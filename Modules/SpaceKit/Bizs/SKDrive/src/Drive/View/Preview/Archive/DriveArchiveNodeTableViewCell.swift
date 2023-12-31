//
//  DriveArchiveNodeTableViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/5.
//  

import UIKit
import SnapKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import LarkDocsIcon

class DriveArchiveNodeTableViewCell: UITableViewCell {

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingMiddle
        label.font = UIFont.ct.systemRegular(ofSize: 17)
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var sizeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.ct.systemRegular(ofSize: 14)
        label.textColor = UIColor.ud.N600
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(24)
        }
        contentView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.left.equalTo(nameLabel.snp.left)
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalToSuperview().offset(-24)
        }
    }

    func updateUI(node: DriveArchiveNode) {
        switch node.fileType {
        case .folder:
            guard let folderNode = node as? DriveArchiveFolderNode else {
                assertionFailure("Failed to convert DriveArchiveNode to any sub class")
                DocsLogger.error("Failed to convert DriveArchiveNode to any sub class")
                return
            }
            updateUI(node: folderNode)
        case .regularFile:
            guard let fileNode = node as? DriveArchiveFileNode else {
                assertionFailure("Failed to convert DriveArchiveNode to any sub class")
                DocsLogger.error("Failed to convert DriveArchiveNode to any sub class")
                return
            }
            updateUI(node: fileNode)
        }
    }

    func updateUI(node: DriveArchiveFileNode) {
        nameLabel.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(10)
        }
        nameLabel.text = node.name
        let sizeString = FileSizeHelper.memoryFormat(node.fileSize)
        sizeLabel.text = sizeString
        iconImageView.image = node.driveFileType.roundImage
    }

    func updateUI(node: DriveArchiveFolderNode) {
        nameLabel.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(22)
        }
        nameLabel.text = node.name
        sizeLabel.text = ""
        iconImageView.image = UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 48, height: 48))
    }
}
