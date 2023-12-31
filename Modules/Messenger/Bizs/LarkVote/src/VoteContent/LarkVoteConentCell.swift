//
//  LarkVoteContentCell.swift
//  LarkVote
//
//  Created by bytedance on 2022/4/12.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import ByteWebImage
import UniverseDesignCheckBox
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignProgressView
import UniverseDesignIcon

public struct AvatarInfo {
    public var avatarKey: String = ""
    public var userId: String = ""
    public init(avatarKey: String, userId: String) {
        self.avatarKey = avatarKey
        self.userId = userId
    }
}

public final class LarkVoteContentCellProps {
    public var identifier: Int = -1
    public var isSelected: Bool = false
    public var isMutilSelect: Bool = false
    public var showResult: Bool = false
    public var itemTitle: String = ""
    public var itemResultText: String = ""
    public var itemPercentNum: CGFloat = 0.0
    public var itemCntNum: Int = 0
    public var avatarKeyList: [AvatarInfo] = []
    public var avatarViewClickBlock: ((Int) -> Void)?
    public init() {}
    public init(_ props: LarkVoteContentCellProps) {
        self.identifier = props.identifier
        self.isSelected = props.isSelected
        self.isMutilSelect = props.isMutilSelect
        self.showResult = props.showResult
        self.itemTitle = props.itemTitle
        self.itemResultText = props.itemResultText
        self.itemPercentNum = props.itemPercentNum
        self.itemCntNum = props.itemCntNum
        self.avatarKeyList = props.avatarKeyList
        self.avatarViewClickBlock = props.avatarViewClickBlock
    }
}

public final class LarkVoteContentCell: UITableViewCell {

    private enum Cons {
        static var verticalSpacing: CGFloat = 4
        static var horizontalPadding: CGFloat = 12
        static var bottomPadding: CGFloat = 16
        static var progressHeight: CGFloat = 4
        static var checkBoxSize: CGFloat = 20
        static var titleToCheckBoxSpacing: CGFloat = 8
        static var resultLabelHeight: CGFloat = 18
        static var avatarToProgressSpacing: CGFloat = 8
        static var avatarSize: CGFloat = 24
        static var avatarSpacing: CGFloat = 7
        static var titleFont: UIFont { return UIFont.ud.body2 }
        static var resultTextFont: UIFont { return UIFont.ud.caption3 }
        static var selectedTextColor: UIColor = UIColor.ud.primaryContentDefault
        static var normalTextColor: UIColor = UIColor.ud.textTitle
    }
    private var oldProps: LarkVoteContentCellProps = LarkVoteContentCellProps()
    private var newProps: LarkVoteContentCellProps = LarkVoteContentCellProps()
    private var avatarViewList: [UIImageView] = []
    private var maxAvatarCnt: Int = 0
    private var cellWidth: CGFloat = 0.0

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var checkBox: LarkVoteCheckBox = LarkVoteCheckBox(frame: CGRect(x: Cons.horizontalPadding, y: 0, width: Cons.checkBoxSize, height: Cons.checkBoxSize))

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Cons.normalTextColor
        label.font = Cons.titleFont
        label.numberOfLines = 0
        label.backgroundColor = .clear
        return label
    }()

    private lazy var itemResultLabel: UILabel = {
        let label = UILabel()
        label.textColor = Cons.normalTextColor
        label.font = Cons.resultTextFont
        label.numberOfLines = 1
        label.backgroundColor = .clear
        return label
    }()

    private lazy var progressView: LarkVoteProgressView = LarkVoteProgressView()

    private lazy var avatarContainer: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(avatarStackViewDidClick))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var itemCntLabel: UILabel = {
        let label = UILabel()
        label.layer.cornerRadius = Cons.avatarSize / 2
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.backgroundColor = UIColor.ud.N100
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.ud.caption3
        label.numberOfLines = 1
        return label
    }()

    public override func layoutSubviews() {
        super.layoutSubviews()
        let count = Int((self.frame.size.width - 2 * Cons.horizontalPadding) / (Cons.avatarSize + Cons.avatarSpacing)) - 1
        if count != self.maxAvatarCnt {
            self.maxAvatarCnt = count
            updateAvatarStackView()
        }
    }

    private func setupUI() {
        self.clipsToBounds = false
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgFloat
        checkBox.isUserInteractionEnabled = false
        self.contentView.addSubview(checkBox)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(itemResultLabel)
        self.contentView.addSubview(progressView)
        self.contentView.addSubview(avatarContainer)
    }

    private func updateAvatarStackView() {
        let defaultAvatar = BundleResources.LarkVote.default_avatar
        // 均匀分布
        var itemSpacing = Cons.avatarSpacing
        if self.maxAvatarCnt > 0 {
            itemSpacing = (self.cellWidth - 2 * Cons.horizontalPadding - CGFloat(self.maxAvatarCnt + 1) * Cons.avatarSize) / CGFloat(self.maxAvatarCnt)
        }
        for (index, newAvatarInfo) in newProps.avatarKeyList.enumerated() {
            let itemX = (Cons.avatarSize + itemSpacing) * CGFloat(index)
            if index >= self.maxAvatarCnt {
                itemCntLabel.isHidden = false
                itemCntLabel.text = newProps.itemCntNum > 99 ? "..." : "+\(newProps.itemCntNum - self.maxAvatarCnt)"
                itemCntLabel.frame = CGRect(x: itemX, y: 0, width: Cons.avatarSize, height: Cons.avatarSize)
                avatarContainer.addSubview(itemCntLabel)
                return
            }
            if index < self.avatarViewList.count {
                let imageView = self.avatarViewList[index]
                imageView.isHidden = false
                imageView.frame = CGRect(x: itemX, y: 0, width: Cons.avatarSize, height: Cons.avatarSize)
                if index < oldProps.avatarKeyList.count {
                    let oldAvatarInfo = oldProps.avatarKeyList[index]
                    if oldAvatarInfo.userId != newAvatarInfo.userId {
                        imageView.bt.setLarkImage(with: .avatar(key: newAvatarInfo.avatarKey, entityID: newAvatarInfo.userId), placeholder: defaultAvatar)
                    }
                } else {
                    let imageView = self.avatarViewList[index]
                    imageView.isHidden = false
                    imageView.bt.setLarkImage(with: .avatar(key: newAvatarInfo.avatarKey, entityID: newAvatarInfo.userId), placeholder: defaultAvatar)
                }
            } else {
                let imageView = UIImageView(frame: CGRect(x: itemX, y: 0, width: Cons.avatarSize, height: Cons.avatarSize))
                imageView.layer.cornerRadius = Cons.avatarSize / 2.0
                imageView.clipsToBounds = true
                avatarContainer.addSubview(imageView)
                avatarViewList.append(imageView)
                imageView.isHidden = false
                imageView.bt.setLarkImage(with: .avatar(key: newAvatarInfo.avatarKey, entityID: newAvatarInfo.userId), placeholder: defaultAvatar)
            }
        }
        if newProps.avatarKeyList.count < avatarViewList.count {
            for index in newProps.avatarKeyList.count ..< avatarViewList.count {
                avatarViewList[index].isHidden = true
            }
        }
        itemCntLabel.isHidden = true
    }

    // 更新UI
    public func updateItem(_ props: LarkVoteContentCellProps, cellWidth: CGFloat) {
        oldProps = newProps
        newProps = LarkVoteContentCellProps(props)
        self.cellWidth = cellWidth
        // 设置TitleLabel frame
        var titleLabelX = Cons.horizontalPadding
        if !newProps.showResult {
            titleLabelX += (Cons.checkBoxSize + Cons.titleToCheckBoxSpacing)
        }
        let titleLabelW = self.cellWidth - titleLabelX - Cons.horizontalPadding
        var titleLabelH = titleLabel.frame.height
        if oldProps.itemTitle != newProps.itemTitle {
            titleLabelH = LarkVoteUtils.calculateLabelSize(text: newProps.itemTitle, font: Cons.titleFont, size: CGSize(width: titleLabelW, height: CGFloat.greatestFiniteMagnitude)).height
        }
        titleLabel.frame = CGRect(x: titleLabelX, y: 2, width: titleLabelW, height: titleLabelH)

        if newProps.showResult {
            // update type/avatar frame
            let commonX = Cons.horizontalPadding
            let commonWidth = self.cellWidth - 2 * Cons.horizontalPadding
            let itemResultLabelY = titleLabel.frame.maxY + Cons.verticalSpacing
            itemResultLabel.frame = CGRect(x: commonX, y: itemResultLabelY, width: commonWidth, height: Cons.resultLabelHeight)
            let progressViewY = itemResultLabel.frame.maxY + Cons.verticalSpacing
            progressView.frame = CGRect(x: commonX, y: progressViewY, width: commonWidth, height: Cons.progressHeight)
            let avatarContainerY = progressView.frame.maxY + Cons.avatarToProgressSpacing
            let avatarContainerW = self.cellWidth - 2 * Cons.horizontalPadding
            avatarContainer.frame = CGRect(x: Cons.horizontalPadding, y: avatarContainerY, width: avatarContainerW, height: Cons.avatarSize)
            // update type/avatar data
            itemResultLabel.text = newProps.itemResultText
            itemResultLabel.textColor = newProps.isSelected ? Cons.selectedTextColor : Cons.normalTextColor
            progressView.progress = newProps.itemPercentNum
            self.maxAvatarCnt = Int((self.cellWidth - 2 * Cons.horizontalPadding) / (Cons.avatarSize + Cons.avatarSpacing)) - 1
            updateAvatarStackView()
        }

        checkBox.isMutilSelect = newProps.isMutilSelect
        checkBox.isSelected = newProps.isSelected
        checkBox.isHidden = newProps.showResult
        titleLabel.text = newProps.itemTitle
        titleLabel.textColor = newProps.isSelected ? Cons.selectedTextColor : Cons.normalTextColor
        itemResultLabel.isHidden = !newProps.showResult
        progressView.isHidden = !newProps.showResult
        avatarContainer.isHidden = !newProps.showResult || newProps.avatarKeyList.isEmpty
    }

    @objc
    private func avatarStackViewDidClick() {
        if let block = newProps.avatarViewClickBlock {
            self.avatarContainer.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak self] in
                self?.avatarContainer.isUserInteractionEnabled = true
            }
            block(newProps.identifier)
        }
    }

    // 计算cell高度
    public static func calculateCellHeight(cellProps: LarkVoteContentCellProps, cellWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 0.0
        var labelSize = CGSize(width: cellWidth - 2 * Cons.horizontalPadding, height: CGFloat.greatestFiniteMagnitude)
        // titleLabel高度
        if !cellProps.showResult {
            // 投票前后Titlelabel宽度要变化
            let titleWidth = labelSize.width - Cons.checkBoxSize - Cons.titleToCheckBoxSpacing
            labelSize = CGSize(width: titleWidth, height: labelSize.height)
        }
        let titleLabelHeight = LarkVoteUtils.calculateLabelSize(text: cellProps.itemTitle, font: Cons.titleFont, size: labelSize).height

        height += cellProps.showResult ? titleLabelHeight : max(titleLabelHeight + 2, Cons.checkBoxSize)

        if !cellProps.showResult {
            return height + Cons.bottomPadding
        }
        // resultLabel高度 + progressView高度
        if !cellProps.itemResultText.isEmpty {
            let resultLabelHeight = Cons.resultLabelHeight
            height += (Cons.verticalSpacing * 2 + resultLabelHeight + Cons.progressHeight)
        }
        // avatarView高度
        if !cellProps.avatarKeyList.isEmpty {
            height += (Cons.avatarToProgressSpacing + Cons.avatarSize)
        }
        return height + Cons.bottomPadding
    }
}

final class LarkVoteProgressView: UIView {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(progressView)
        progressView.frame = CGRect(x: 0, y: 0, width: 0, height: self.frame.height)
        progressView.layer.cornerRadius = self.frame.height / 2.0
        progressView.backgroundColor = UIColor.ud.primaryContentDefault
        self.backgroundColor = UIColor.ud.lineBorderCard
        self.layer.cornerRadius = self.frame.height / 2.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var progressView: UIView = UIView()

    override var frame: CGRect {
        didSet {
            if !oldValue.equalTo(frame) {
                progressView.frame = CGRect(x: 0, y: 0, width: frame.width * progress, height: frame.height)
                self.progressView.layer.cornerRadius = self.frame.height / 2.0
                self.layer.cornerRadius = self.frame.height / 2.0
            }
        }
    }

    public var progress: CGFloat = 0.0 {
        didSet {
            if oldValue != progress {
                self.progressView.frame.size.width = progress * self.frame.width
            }
        }
    }
}

final class LarkVoteCheckBox: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(centerIconView)
        centerIconView.isHidden = true
        centerIconView.image = singleImage
        centerIconView.center = self.center
        let padding = self.frame.width * (1 - iconSizeFactor) / 2
        let size = self.frame.width * iconSizeFactor
        centerIconView.frame = CGRect(x: padding, y: padding, width: size, height: size)
        centerIconView.layer.cornerRadius = size / 2
        centerIconView.clipsToBounds = true
        centerIconView.backgroundColor = .clear
        self.layer.ud.setBorderColor(UIColor.ud.N500)
        self.layer.borderWidth = 1.5
        self.backgroundColor = .clear
        self.layer.cornerRadius = self.frame.width / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private let iconSizeFactor = 0.4
    private lazy var centerIconView: UIImageView = UIImageView()
    private lazy var singleImage: UIImage = UIImage.ud.fromPureColor(UIColor.ud.primaryOnPrimaryFill)
    private lazy var mutipleImage: UIImage = UDIcon.getIconByKey(.checkOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 18, height: 18))

    override var frame: CGRect {
        didSet {
            if !oldValue.equalTo(frame) {
                if isMutilSelect {
                    centerIconView.frame = self.bounds
                } else {
                    let padding = self.frame.width * (1 - iconSizeFactor) / 2
                    let size = self.frame.width * iconSizeFactor
                    centerIconView.frame = CGRect(x: padding, y: padding, width: size, height: size)
                    centerIconView.layer.cornerRadius = size / 2
                }
                self.layer.cornerRadius = self.frame.width / 2
            }
        }
    }

    public var isMutilSelect: Bool = false {
        didSet {
            if oldValue != isMutilSelect {
                if isMutilSelect {
                    centerIconView.frame = self.bounds
                } else {
                    let padding = self.frame.width * (1 - iconSizeFactor) / 2
                    let size = self.frame.width * iconSizeFactor
                    centerIconView.frame = CGRect(x: padding, y: padding, width: size, height: size)
                    centerIconView.layer.cornerRadius = size / 2
                }
                centerIconView.image = isMutilSelect ? mutipleImage : singleImage
            }
        }
    }

    public var isSelected: Bool = false {
        didSet {
            if oldValue != isSelected {
                centerIconView.isHidden = !isSelected
                self.layer.borderWidth = isSelected ? 0.0 : 1.5
                self.backgroundColor = isSelected ? UIColor.ud.primaryContentDefault : .clear
            }
        }
    }
}
