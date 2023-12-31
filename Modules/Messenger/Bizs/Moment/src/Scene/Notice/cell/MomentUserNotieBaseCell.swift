//
//  MomentUserNotieBaseCell.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import EENavigator
import RichLabel
import LarkBizAvatar

class MomentUserNotieBaseCell: BaseTableViewCell {
    let avatarWidth: CGFloat = 48
    var viewModel: MomentsNoticeBaseCellViewModel? {
        didSet {
            updateUI()
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    class func getCellReuseIdentifier() -> String {
        return "MomentUserNotieBaseCell"
    }

    public lazy var avatarView: BizAvatar = {
        let view = BizAvatar()
        view.lu.addTapGestureRecognizer(action: #selector(avatarViewTapped), target: self)
        return view
    }()
    /// 通知不限制标题行数
    public lazy var titleLabel: LKLabel = {
        let fontColor = UIColor.ud.textTitle
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: fontColor,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        let label: LKLabel = LKLabel(frame: .zero).lu.setProps(
            fontSize: 16,
            numberOfLine: 2,
            textColor: fontColor
        )
        label.translatesAutoresizingMaskIntoConstraints = true
        label.autoDetectLinks = false
        label.outOfRangeText = outOfRangeText
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        return label
    }()

    public lazy var contentLabel: LKLabel = {
        let fontColor = UIColor.ud.textTitle
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: fontColor,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        let label: LKLabel = LKLabel(frame: .zero).lu.setProps(
            fontSize: 14,
            numberOfLine: 1,
            textColor: fontColor
        )
        /**
         lu.setProps 内部会关闭 translatesAutoresizingMaskIntoConstraints
         使用frame布局需要为true, 否则无效
         */
        label.translatesAutoresizingMaskIntoConstraints = true
        label.autoDetectLinks = false
        label.outOfRangeText = outOfRangeText
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 1
        return label
    }()

    public lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    public var rightShowView: UIView?

    func setupUI() {
        let rightView = configRightView()
        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(rightView)
        avatarView.snp.makeConstraints { (make) in
            make.left.top.equalTo(16)
            make.width.height.equalTo(avatarWidth)
        }
        titleLabel.text = ""
        contentLabel.text = ""
        timeLabel.text = ""
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.right.equalTo(rightView.snp.left).offset(-8)
            make.top.equalTo(avatarView.snp.top)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.right.equalTo(rightView.snp.left).offset(-8)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(8)
            make.right.equalTo(rightView.snp.left)
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        self.rightShowView = rightView
        layoutRightView(rightView)
    }

    // MARK: - 子类重写
    func configRightView() -> UIView {
        return UIView()
    }

    func layoutRightView(_ view: UIView) {
        view.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(54)
        }
    }

    func updateUI() {
        self.titleLabel.preferredMaxLayoutWidth = self.viewModel?.maxTitleWidth() ?? 0
        self.titleLabel.attributedText = self.viewModel?.title
        self.contentLabel.attributedText = self.viewModel?.content
        self.timeLabel.text = self.viewModel?.time
        self.avatarView.setAvatarByIdentifier(self.viewModel?.user?.userID ?? "",
                                              avatarKey: self.viewModel?.user?.avatarKey ?? "",
                                              scene: .Moments,
                                              avatarViewParams: .init(sizeType: .size(avatarWidth)))
        self.contentLabel.isHidden = !(self.viewModel?.hadContent() ?? true)
        guard let rightShowView else { return }
        if self.contentLabel.isHidden {
            self.timeLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarView.snp.right).offset(8)
                make.right.equalTo(rightShowView.snp.left).offset(-8)
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
                make.bottom.equalToSuperview().offset(-18)
            }
        } else {
            self.timeLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarView.snp.right).offset(8)
                make.right.equalTo(rightShowView.snp.left).offset(-8)
                make.top.equalTo(contentLabel.snp.bottom).offset(8)
                make.bottom.equalToSuperview().offset(-16)
            }
        }
        if let vm = self.viewModel {
            self.updateRightViewWithVM(vm)
        }
    }

    func updateRightViewWithVM(_ vm: MomentsNoticeBaseCellViewModel) {

    }

    @objc
    func avatarViewTapped() {
        self.viewModel?.onAvatarTapped()
    }
}
