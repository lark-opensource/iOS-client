//
//  SearchPinListTableViewCell.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/26.
//

import Foundation
import LarkCore
import LarkModel
import UIKit
import LarkUIKit
import RustPB
import LarkExtensions
import LarkBizAvatar
import LarkSDKInterface

final class SearchPinListTableViewCell: UITableViewCell {
    private let avatarSize: CGFloat = 48.auto()
    private let cellHeight: CGFloat = 67.auto()
    let timeLabel: UILabel
    let avatarView: BizAvatar
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let textWarrperView: UIView
    private(set) var viewModel: SearchPinListCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        avatarView = BizAvatar()
        titleLabel = UILabel()
        subtitleLabel = UILabel()
        textWarrperView = UIView()
        timeLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.ud.bgBody
        self.selectedBackgroundView = BaseCellSelectView()

        titleLabel.font = UIFont.ud.caption1
        titleLabel.textColor = UIColor.ud.textPlaceholder
        subtitleLabel.font = UIFont.ud.body0
        subtitleLabel.textColor = UIColor.ud.textTitle
        timeLabel.font = UIFont.ud.caption1
        timeLabel.textColor = UIColor.ud.textPlaceholder

        let layoutGuide = UILayoutGuide()
        contentView.addLayoutGuide(layoutGuide)
        layoutGuide.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(cellHeight).priority(.high)
        }

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        })

        textWarrperView.backgroundColor = UIColor.clear
        self.contentView.addSubview(textWarrperView)
        textWarrperView.snp.makeConstraints { (make) in
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.centerY.equalTo(avatarView)
            make.right.equalToSuperview().offset(-16)
        }

        textWarrperView.addSubview(titleLabel)
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        textWarrperView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints({ make in
            make.left.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
            make.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        })
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        self.textWarrperView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        })
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.lessThanOrEqualTo(timeLabel.snp.left).offset(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ viewModel: SearchPinListCellViewModel) {
        guard case .message(let meta) = viewModel.result.meta else { return }
        self.viewModel = viewModel
        let searchResult = viewModel.result
        // avatar
        avatarView.setAvatarByIdentifier(viewModel.result.avatarID ?? "", avatarKey: viewModel.result.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        // title
        titleLabel.attributedText = searchResult.title
        subtitleLabel.attributedText = searchResult.summary
        timeLabel.isHidden = false
        timeLabel.text = Date.lf.getNiceDateString(TimeInterval(meta.updateTime))
    }

    private func firstHitAttrTextInfo(attributedText: NSAttributedString, terms: [String]) -> (textWithFirstHitTerm: NSAttributedString, remainText: NSAttributedString)? {
        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
        let text: NSString = mutableAttributedText.string as NSString
        guard let firstTerm = terms.first else { return nil }
        let range = (text as NSString).range(of: firstTerm, options: [.caseInsensitive])
        if range.location == NSNotFound {
            return nil
        }
        let remainTextAtt: NSAttributedString
        let textWithFirstHitTermAtt = mutableAttributedText.attributedSubstring(from: NSRange(location: 0, length: range.location + range.length))
        if range.location > 5 {
            let remainTextMuAtt: NSMutableAttributedString = NSMutableAttributedString(string: "...")
            remainTextMuAtt.append(mutableAttributedText.attributedSubstring(from: NSRange(location: range.location - 5, length: mutableAttributedText.length - (range.location - 5))))
            remainTextAtt = NSAttributedString(attributedString: remainTextMuAtt)
        } else {
            remainTextAtt = textWithFirstHitTermAtt
        }
        return (textWithFirstHitTermAtt, remainTextAtt)
    }

}

extension UILabel {
    var isTruncated: Bool {
        guard let labelText = text else { return false }
        layoutIfNeeded()
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font = font {
            attributes[.font] = font
        }
        let labelTextSize = (labelText as NSString).boundingRect(
            with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil).size
        return labelTextSize.height > bounds.size.height
    }
}
