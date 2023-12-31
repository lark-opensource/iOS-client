//
//  TabManagementCollectionCell.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/8/2.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import LarkModel
import LarkCore
import LarkTag
import LarkFeatureGating
import LarkAvatar
import LarkSDKInterface
import UniverseDesignColor
import LarkOpenChat
import UniverseDesignActionPanel
import EENavigator
import LKCommonsLogging
import ByteWebImage

final class TabManagementCollectionCellFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
        attributes.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        return attributes
    }
}

final class TabManagementCollectionCell: UICollectionViewCell {
    static let logger = Logger.log(TabManagementCollectionCell.self, category: "Module.IM.ChatTab")
    static let reuseId: String = "CagegoryEditCell"

    var cellMoreBlock: ((UIView) -> Void)?

    /**（2）doc图标*/
    private let iconImageView = UIImageView()
    /**（3）标题*/
    private var contentLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = UIColor.ud.textTitle
        return contentLabel
    }()
    /**（4）排序图标*/
    private let sortBtn: UIButton = UIButton()
    /**（4）「...」图标*/
    private let moreButton: UIButton = UIButton()
    //  Tab数量
    private lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 16)
        countLabel.textColor = UIColor.ud.textTitle
        return countLabel
    }()
    //  未读小红点
    private lazy var badgeView: UIView = {
        return UIView()
    }()
    // 分割线
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        //（1）背景色
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.masksToBounds = true

        //（2）doc图标
        self.contentView.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(14)
            make.width.equalTo(21)
            make.height.equalTo(21)
            make.centerY.equalToSuperview()
        }
        // 标题
        self.contentView.addSubview(self.contentLabel)
        // 数量
        self.contentView.addSubview(countLabel)
        // 红点
        self.contentView.addSubview(badgeView)
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        badgeView.snp.makeConstraints { make in
            make.left.equalTo(contentLabel.snp.right).offset(2)
            make.width.height.equalTo(6)
            make.top.equalToSuperview().inset(14)
        }

        // 分割线
        self.contentView.addSubview(self.lineView)
        self.lineView.snp.makeConstraints { make in
            make.left.equalTo(self.iconImageView.snp.right).offset(12)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        //（4）排序图标
        self.contentView.addSubview(self.sortBtn)
        self.sortBtn.setImage(Resources.tab_icon_menu_outlined, for: .normal)
        self.sortBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-12)
            make.height.equalToSuperview()
        }
        self.sortBtn.isHidden = true

        //（5）「...」图标
        self.contentView.addSubview(self.moreButton)
        self.moreButton.setImage(Resources.tab_icon_more_outlined.withRenderingMode(.alwaysTemplate), for: .normal)
        self.moreButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-12)
            make.height.equalToSuperview()
        }
        self.moreButton.isHidden = true
        // 添加点击事件
        self.moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = UIColor.ud.bgFloat
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.iconImageView.bt.setLarkImage(with: .default(key: ""))
    }

    @objc
    private func moreButtonTapped(_ sender: UIButton) {
        self.cellMoreBlock?(sender)
    }

    func setTabManagementCellModel(_ chatTabManageItem: ChatTabManageItem, cellEditStatus: ChatTabManagementStatus, enable: Bool) {
        self.contentLabel.text = chatTabManageItem.name
        switch chatTabManageItem.imageResource {
        case .image(let image):
            self.iconImageView.image = image
        case .key(key: let key, config: let config):
            var passThrough: ImagePassThrough?
            if let pbModel = config?.imageSetPassThrough {
                passThrough = ImagePassThrough.transform(passthrough: pbModel)
            }
            self.iconImageView.bt.setLarkImage(with: .default(key: key),
                                               placeholder: config?.placeholder,
                                               passThrough: passThrough) { [weak self] res in
                guard let self = self else { return }
                switch res {
                case .success(let imageResult):
                    guard let image = imageResult.image else { return }
                    if let tintColor = config?.tintColor {
                        self.iconImageView.image = image.ud.withTintColor(tintColor)
                    } else {
                        self.iconImageView.image = image
                    }
                case .failure(let error):
                    Self.logger.error("set image fail", error: error)
                }
            }
        }
        if let countNum = chatTabManageItem.count, countNum != 0 {
            countLabel.isHidden = false
            countLabel.text = "\(countNum)"
            countLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(self.iconImageView.snp.right).offset(12)
                make.centerY.equalToSuperview()
            }
            contentLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(countLabel.snp.right).offset(4)
                make.right.lessThanOrEqualToSuperview().inset(44)
            }
        } else {
            countLabel.isHidden = true
            contentLabel.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(self.iconImageView.snp.right).offset(12)
                make.right.lessThanOrEqualToSuperview().inset(44)
            }
        }
        self.badgeView.badge.removeAllObserver()
        if let badgePath = chatTabManageItem.badgePath {
            self.badgeView.isHidden = false
            badgeView.badge.observe(for: badgePath)
            badgeView.badge.set(size: CGSize(width: 6, height: 6))
            badgeView.badge.set(cornerRadius: 3)
            badgeView.badge.set(offset: CGPoint(x: -3, y: 3))
        } else {
            self.badgeView.isHidden = true
        }
        switch cellEditStatus {
        case .normal:
            self.moreButton.isHidden = !chatTabManageItem.canBeDeleted && !chatTabManageItem.canEdit
            self.moreButton.tintColor = enable ? UIColor.ud.iconN3 : UIColor.ud.iconDisabled
            self.sortBtn.isHidden = true
        case .sorting:
            self.moreButton.isHidden = true
            self.sortBtn.isHidden = !chatTabManageItem.canBeSorted
        }
    }

    func setBottomBorderHidden(_ isHidden: Bool = false) {
        self.lineView.isHidden = isHidden
    }
}

final class TabManagementAddCellCollectionCell: UICollectionViewCell {

    static let reuseId: String = "AddCell"

    private var contentLabel: UILabel = UILabel()

    // 分割线
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        //（1）背景色
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.masksToBounds = true

        //（2）标题
        self.contentView.addSubview(self.contentLabel)
        self.contentLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentLabel.textAlignment = .center
        self.contentLabel.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(22)
            make.centerX.centerY.equalToSuperview()
        }

        // (3) 分割线
        self.contentView.addSubview(self.lineView)
        self.lineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = UIColor.ud.bgFloat
        }
    }

    func setTitle(_ name: String, enable: Bool) {
        self.contentLabel.text = name
        self.contentLabel.textColor = enable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
    }

    func setBottomBorderHidden(_ isHidden: Bool = false) {
        self.lineView.isHidden = isHidden
    }
}
