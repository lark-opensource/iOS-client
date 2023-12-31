//
//  VoteUserCell.swift
//  SKCommon
//
//  Created by zhysan on 2022/9/14.
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
    
    struct Inset {
        static let left: CGFloat = 16.0
        static let right: CGFloat = 26.0
    }
    
    struct Offset {
        static let titleLeft: CGFloat = 16.0
        static let titleRight: CGFloat = 16.0
    }
}

class VoteUserCell: UITableViewCell {
    
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
    
    private let dateLabel: UILabel = {
        let vi = UILabel()
        vi.font = UDFont.body2
        vi.textColor = UDColor.textCaption
        return vi
    }()
    
    private var user: DocVote.VoteMember?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - public
    
    static let defaultReuseId = "VoteUserCell"
    
    var avatarAction: ((DocVote.VoteMember) -> Void)?
    
    func showSpLine(_ show: Bool) {
        spLine.isHidden = !show
    }
    
    func update(_ data: DocVote.VoteMember) {
        user = data
        let placeholder = BundleResources.SKResource.Common.Other.group_default
        avatarView.bt.setImage(with: URL(string: data.avatarUrl ?? ""), placeholder: placeholder)
        titleLabel.text = data.userName ?? ""
        dateLabel.text = data.voteTime?.stampDateFormatter ?? ""
    }
    
    // MARK: - private
    
    @objc
    private func avatarTapped(_ sender: UITapGestureRecognizer) {
        guard let user = user else {
            return
        }
        avatarAction?(user)
    }
    
    private func subviewsInit() {
        contentView.addSubview(spLine)
        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        
        selectionStyle = .none
        contentView.backgroundColor = UDColor.bgBody
        
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        avatarView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(avatarTapped(_:)))
        avatarView.addGestureRecognizer(tap)
        
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(Const.avatarSize)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(Const.Inset.left)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(Const.Offset.titleLeft)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.right.equalToSuperview().inset(Const.Inset.right)
            make.left.equalTo(titleLabel.snp.right).offset(Const.Offset.titleRight)
        }
        
        spLine.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(titleLabel)
        }
    }
}
