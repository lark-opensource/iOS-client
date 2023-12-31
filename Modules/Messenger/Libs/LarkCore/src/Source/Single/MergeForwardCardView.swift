//
//  MergeForwardCard.swift
//  LarkCore
//
//  Created by liluobin on 2021/6/15.
//

import Foundation
import UIKit
import SnapKit
import ByteWebImage
import LarkBizAvatar
import UniverseDesignIcon
import UniverseDesignCardHeader

public final class ReplyThreadMergeForwardCardView: MergeForwardCardView {
    public lazy var replyThreadForwardIcon: UIImageView = {
        let imageV = UIImageView()
        imageV.image = Resources.replyInThreadForward
        return imageV
    }()

    override func setupView() {
        super.setupView()
        addSubview(replyThreadForwardIcon)
        replyThreadForwardIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.centerY.equalTo(titleLabel)
        }
        titleLabel.textColor = UDCardHeaderHue.turquoise.textColor
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.snp.remakeConstraints { (make) in
            make.height.greaterThanOrEqualTo(36)
            make.top.equalToSuperview().offset(7)
            make.left.equalTo(replyThreadForwardIcon.snp.right).offset(8)
            make.right.equalToSuperview().offset(-12)
        }
    }
    override func getTitleBgView() -> UIView {
        let header = UDCardHeader(colorHue: UDCardHeaderHue.turquoise, layoutType: .normal)
        return header
    }
    public override func setItem(_ item: MergeForwardCardItem) {
        super.setItem(item)
        if !item.isGroupMember {
            fromLabel.text = ""
            self.iconView.isHidden = true
            self.fromLabel.isHidden = true
            self.lineView.isHidden = true
            self.iconView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            fromLabel.snp.updateConstraints { (make) in
                make.top.equalTo(lineView.snp.bottom).offset(0)
                make.bottom.equalToSuperview().offset(0)
            }
            lineView.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
        } else {
            self.iconView.isHidden = false
            self.fromLabel.isHidden = false
            self.lineView.isHidden = false
            lineView.snp.updateConstraints { (make) in
                make.height.equalTo(1)
            }
            iconView.snp.makeConstraints { (make) in
                make.height.equalTo(16)
            }
            fromLabel.snp.makeConstraints { (make) in
                make.top.equalTo(lineView.snp.bottom).offset(12)
                make.bottom.equalToSuperview().offset(-16)
            }
        }
    }
}

public class MergeForwardCardView: UIView {

    public lazy var iconView: BizAvatar = {
        let view = BizAvatar()
        view.layer.cornerRadius = 8
        view.avatar.clipsToBounds = true
        view.backgroundColor = UIColor.ud.N300
        view.lu.addTapGestureRecognizer(action: #selector(tapFromCard), target: self)
        return view
    }()

     lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        return label
    }()

    lazy var fromLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .left
        label.lu.addTapGestureRecognizer(action: #selector(tapFromCard), target: self)
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.numberOfLines = linesOfContent
        label.textColor = UIColor.ud.N900
        return label
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy private var imageView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.ud.N300
        imageView.autoPlayAnimatedImage = false
        imageView.lu.addTapGestureRecognizer(action: #selector(imageViewClick), target: self)
        return imageView
    }()

    private lazy var noPermissonPreviewView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.isHidden = true
        let iconView = UIImageView()
        view.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        iconView.backgroundColor = UIColor.ud.bgFloatOverlay
        iconView.image = UDIcon.getIconByKey(.banOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconDisabled)
        iconView.contentMode = .center
        return view
    }()

    public var imageViewTap: ((UIImageView) -> Void)?
    let tapHandler: (() -> Void)?

    let linesOfContent: Int

    public init(contentLabelLines: Int = 3, tapHandler: (() -> Void)?) {
        self.linesOfContent = contentLabelLines
        self.tapHandler = tapHandler
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.ud.N300.cgColor
        self.clipsToBounds = true
        let titleBgView = self.getTitleBgView()
        let contentView = UIView()
        addSubview(titleBgView)
        addSubview(titleLabel)
        addSubview(contentView)
        contentView.addSubview(contentLabel)
        contentView.addSubview(imageView)
        imageView.addSubview(noPermissonPreviewView)
        addSubview(lineView)
        addSubview(iconView)
        addSubview(fromLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(36)
            make.top.equalToSuperview().offset(7)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        titleBgView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(1)
            make.right.equalToSuperview().offset(-1)
            make.bottom.equalTo(titleLabel.snp.bottom).offset(7)
        }
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleBgView.snp.bottom).offset(12)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview()
            make.right.equalTo(imageView.snp.left).offset(-16)
            make.bottom.lessThanOrEqualToSuperview()
        }
        imageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-12)
            make.top.equalToSuperview()
            make.width.equalTo(64)
            make.height.equalTo(64)
            make.bottom.lessThanOrEqualToSuperview()
        }
        noPermissonPreviewView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        lineView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(1)
        }
        iconView.snp.makeConstraints { (make) in
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.left.equalToSuperview().offset(12)
            make.centerY.equalTo(fromLabel.snp.centerY)
        }
        fromLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(5)
            make.top.equalTo(lineView.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-16)
            make.right.equalToSuperview().offset(-12)
        }

    }

    public func setItem(_ item: MergeForwardCardItem) {
        contentLabel.text = item.content
        titleLabel.text = item.title
        imageView.bt.setLarkImage(with: .default(key: item.imageKey), placeholder: nil)
        fromLabel.text = item.fromTitle
        iconView.setAvatarByIdentifier(item.fromAvatarEntityId, avatarKey: item.fromAvatarKey, backgroundColorWhenError: UIColor.ud.N300)
        iconView.snp.updateConstraints { (make) in
            make.width.equalTo(item.fromAvatarKey.isEmpty ? 0 : 16)
        }
        imageView.isHidden = item.imageKey.isEmpty
        let width = item.imageKey.isEmpty ? 0 : 64
        imageView.snp.updateConstraints { (make) in
            make.width.equalTo(width)
            make.height.equalTo(width)
        }
        noPermissonPreviewView.isHidden = item.previewPermission.0
        fromLabel.isUserInteractionEnabled = item.isGroupMember
        iconView.isUserInteractionEnabled = item.isGroupMember
    }

    func getTitleBgView() -> UIView {
        let titleBgView = UIView()
        titleBgView.backgroundColor = UIColor.ud.colorfulBlue
        return titleBgView
    }
    @objc
    fileprivate func tapFromCard() {
        self.tapHandler?()
    }

    @objc
    fileprivate func imageViewClick() {
        imageViewTap?(imageView)
    }

}
