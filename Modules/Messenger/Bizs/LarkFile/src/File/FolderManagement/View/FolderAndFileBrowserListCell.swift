//
//  FolderAndFileBrowserTableViewCell.swift
//  LarkFile
//
//  Created by 赵家琛 on 2021/4/9.
//

import UIKit
import Foundation
import LarkListItem
import LarkUIKit
import LarkCore
import LarkExtensions
import LarkBizAvatar
import AvatarComponent

protocol FolderAndFileBrowserCellPropsProtocol {
    var name: String { get } /// 文件/文件夹名
    var image: UIImage? { get }
    var ownerName: String { get } /// 所有者姓名（国际化）
    var size: Int64 { get }
    var createTime: Int64 { get }
    var previewImageKey: String? { get }
    var isVideo: Bool { get }
}

struct FolderAndFileBrowserCellProps: FolderAndFileBrowserCellPropsProtocol {
    let name: String
    var image: UIImage?
    let ownerName: String
    let size: Int64
    let createTime: Int64
    let previewImageKey: String?
    let isVideo: Bool
}
protocol FileDislayCellProtocol: UICollectionViewCell {
    func setContent(props: FolderAndFileBrowserCellPropsProtocol)
}

class FolderAndFileBrowserListCell: UICollectionViewCell, FileDislayCellProtocol {
    static var cellReuseID: String {
        return NSStringFromClass(Self.self)
    }
    let browserInfoView = ListItem()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    func setupView() {
        self.selectedBackgroundView = BaseCellSelectView()
        self.contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(browserInfoView)
        contentView.backgroundColor = UIColor.ud.bgBody
        var config = AvatarComponentUIConfig()
        config.style = .square
        browserInfoView.avatarView.setAvatarUIConfig(config)
        browserInfoView.backgroundColor = UIColor.ud.bgBody
        browserInfoView.additionalIcon.isHidden = true
        browserInfoView.nameTag.isHidden = true
        browserInfoView.bottomSeperator.isHidden = true
        browserInfoView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        browserInfoView.nameLabel.lineBreakMode = .byTruncatingMiddle
        browserInfoView.checkBox.isHidden = true
        browserInfoView.checkBox.subviews.forEach { $0.isHidden = true }
    }

    func setContent(props: FolderAndFileBrowserCellPropsProtocol) {
        browserInfoView.avatarView.image = props.image
        setDescribeInfo(props: props)
    }
    func setDescribeInfo(props: FolderAndFileBrowserCellPropsProtocol) {
        browserInfoView.nameLabel.attributedText = NSAttributedString(string: props.name)
        var subtitle = FileDisplayInfoUtil.sizeStringFromSize(props.size) + " "
        subtitle += props.ownerName + " "
        subtitle += Date.lf.getNiceDateString(TimeInterval(props.createTime))
        browserInfoView.infoLabel.attributedText = NSAttributedString(string: subtitle)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
