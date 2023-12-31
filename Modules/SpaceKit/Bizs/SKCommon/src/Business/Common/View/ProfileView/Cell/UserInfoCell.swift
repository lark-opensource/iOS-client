//
//  UserInfoCell.swift
//  SKCommon
//
//  Created by GuoXinyi on 2023/1/15.
//

import Foundation
import UIKit
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit
import ByteWebImage
import SKResource

private struct Const {
    static let avatarSize: CGFloat = 40.0
    static let verticalMargin: CGFloat = 18
    static let verticalMarginMin: CGFloat = 8
    static let subVerticalMargin: CGFloat = 3
    
    struct Inset {
        static let left: CGFloat = 16.0
        static let right: CGFloat = 26.0
    }
    
    struct Offset {
        static let titleLeft: CGFloat = 16.0
        static let titleRight: CGFloat = 16.0
    }
}

class UserInfoCell: UITableViewCell {
    
    private let spLine: UIView = {
        let vi = UIView()
        vi.isUserInteractionEnabled = false
        vi.backgroundColor = UDColor.lineDividerDefault
        return vi
    }()
    
    private let avatarView: UIImageView = {
        let vi = UIImageView()
        vi.layer.masksToBounds = true
        vi.layer.cornerRadius = Const.avatarSize * 0.5
        return vi
    }()
    
    private let titleLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body0
        vi.textColor = UDColor.textTitle
        return vi
    }()
    
    private let rightDescLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body2
        vi.textColor = UDColor.textCaption
        return vi
    }()
    
    private let subLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body2
        vi.textColor = UDColor.textCaption
        vi.numberOfLines = 2
        return vi
    }()
    
    private var userInfo: UserInfoData.UserData?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UDColor.bgBody
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            var frame = newValue
            var needUpdate = false
            if frame.size.width != super.frame.size.width {
                needUpdate = true
            }
            super.frame = frame
            if needUpdate {
                updateLayout()
            }
        }
    }
    
    // MARK: - public
    
    static let defaultReuseId = "UserInfoCell"
    
    var avatarAction: ((UserInfoData.UserData) -> Void)?
    
    func showSpLine(_ show: Bool) {
        spLine.isHidden = !show
    }
    
    func update(_ data: UserInfoData.UserData) {
        userInfo = data
        avatarView.bt.setImage(with: URL(string: data.avatarUrl ?? ""), placeholder: nil)
        titleLabel.text = data.userName
        subLabel.text = data.subTitle
        rightDescLabel.text = data.rightDecs
        updateLayout()
    }
    
    // MARK: - private
    
    @objc
    private func avatarTapped(_ sender: UITapGestureRecognizer) {
        guard let user = userInfo else {
            return
        }
        avatarAction?(user)
    }
    
    private func subviewsInit() {
        contentView.addSubview(spLine)
        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subLabel)
        contentView.addSubview(rightDescLabel)
        
        selectionStyle = .none
        contentView.backgroundColor = UDColor.bgBody
        
        rightDescLabel.setContentHuggingPriority(.required, for: .horizontal)
        avatarView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
        avatarView.addGestureRecognizer(tap)
        updateLayout()
    }
    
    private func updateLayout() {
        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(Const.avatarSize)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(Const.Inset.left)
        }
        
        rightDescLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.right.equalToSuperview().inset(Const.Inset.right)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(Const.Offset.titleLeft)
            make.right.equalTo(rightDescLabel.snp.left).offset(Const.Offset.titleRight)
            if subLabel.text?.count ?? 0 == 0 || subLabel.text == nil {
                make.centerY.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
            } else if Int(requiredHeight(self.bounds.width - Const.avatarSize - Const.Inset.left - Const.Offset.titleLeft - Const.Offset.titleRight, culLabel: subLabel) / subLabel.font.lineHeight) > 1 {
                make.top.equalTo(Const.verticalMarginMin)
            } else {
                make.top.equalTo(Const.verticalMargin)
            }
        }
        subLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel)
            make.width.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(Const.subVerticalMargin)
        }
        
        spLine.snp.remakeConstraints { make in
            make.top.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(titleLabel)
        }
    }
    
    /// UILabel根据文字的需要的高度
    private func requiredHeight(_ width: CGFloat, culLabel: UILabel) -> CGFloat {
        let label = UILabel(frame: CGRect(
            x: 0,
            y: 0,
            width: width,
            height: CGFloat.greatestFiniteMagnitude)
        )
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = culLabel.font
        label.text = culLabel.text
        label.attributedText = culLabel.attributedText
        label.sizeToFit()
        return label.frame.height
    }
}

