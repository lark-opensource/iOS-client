//
//  LikeUserCell.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/4.
//

import Foundation
import SnapKit
import Kingfisher
import SKResource
import SKUIKit
import UniverseDesignColor
import SKFoundation

protocol LikeUserCellDelegate: AnyObject {
    func didReceiveTapEventAtProfileView(_ cell: LikeUserCell)
}

class LikeUserCell: UITableViewCell {
    weak var clickDelegate: LikeUserCellDelegate?
    var model: LikeUserInfo?
    private let imageViewWidth: CGFloat = 48
    lazy fileprivate var displayImage: UIImageView = {
        let imageView = SKAvatar(configuration: .init(backgroundColor: .clear,
                                               style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.cornerRadius = imageViewWidth / 2.0
        imageView.layer.masksToBounds = true
        imageView.image = BundleResources.SKResource.Common.Other.group_default
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapEvent(sender:)))
        tapGesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()

    lazy fileprivate var nameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    lazy var externalLabel: SKNavigationBarTitle.ExternalLabel = {
        let l = SKNavigationBarTitle.ExternalLabel()
        l.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return l
    }()

    lazy fileprivate var timestampLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UDColor.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textAlignment = .right
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    lazy fileprivate var seperatorLine: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UDColor.lineBorderCard
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(displayImage)
        contentView.addSubview(nameLabel)
        contentView.addSubview(externalLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(seperatorLine)
        let lPadding: CGFloat = 76
        let rPadding: CGFloat = 16
        let externalLabelWidth: CGFloat = 40
        displayImage.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: imageViewWidth, height: imageViewWidth))
            make.centerY.equalTo(self)
            make.left.equalTo(16)
        }

        timestampLabel.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualToSuperview().dividedBy(3.0)
            make.height.equalTo(28)
            make.centerY.equalTo(self)
            make.right.equalTo(-rPadding)
        }

        externalLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel.snp.centerY)
            make.left.equalTo(nameLabel.snp.right).offset(6)
            make.right.lessThanOrEqualTo(timestampLabel.snp.left).offset(-8)
            make.width.greaterThanOrEqualTo(externalLabelWidth)
            make.height.equalTo(15)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.right.equalTo(externalLabel.snp.left).offset(-6)
            make.centerY.equalTo(self)
            make.left.equalTo(lPadding)
        }
        
        //设置优先显示名字，标签进行压缩，但标签最小宽度是40
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        externalLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        seperatorLine.snp.makeConstraints { (make) in
            make.left.equalTo(76)
            make.bottom.equalToSuperview().offset(-0.5)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configBy(info: LikeUserInfo) {
        model = info
        if let url = URL(string: info.avatarURL) {
            let image = BundleResources.SKResource.Common.Other.group_default
            self.displayImage.kf.setImage(with: ImageResource(downloadURL: url), placeholder: image)
        }

        if let interval = info.updateTimestamp {
            self.timestampLabel.text = interval.stampDateFormatter
        }

        if let likeName = info.displayName {
            self.nameLabel.text = likeName
        }
        
        //后端接口无法做兜底，如果displayTag为空，需要走到旧逻辑
        if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled, let displayTag = model?.displayTag  {
            if EnvConfig.CanShowExternalTag.value,
                let displayName = displayTag.displayName,
                !displayName.isEmpty {
                self.externalLabel.isHidden = false
                self.externalLabel.text = displayName
            } else {
                self.externalLabel.isHidden = true
                self.externalLabel.text = ""
            }
        } else {
            if !EnvConfig.CanShowExternalTag.value ||
                model?.tenantId == User.current.info?.tenantID {
                self.externalLabel.isHidden = true
                self.externalLabel.text = ""
            } else {
                self.externalLabel.isHidden = false
                self.externalLabel.text = BundleI18n.SKResource.Doc_Widget_External
            }
        }
    }
}

extension LikeUserCell {
    @objc
    func didReceiveTapEvent(sender: UITapGestureRecognizer) {
        self.clickDelegate?.didReceiveTapEventAtProfileView(self)
    }
}
