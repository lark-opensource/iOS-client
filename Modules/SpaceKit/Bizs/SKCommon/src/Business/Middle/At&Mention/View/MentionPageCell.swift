//
//  MentionPageCell.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/26.
//  
import UIKit
import SnapKit
import Kingfisher
import UniverseDesignColor
import SpaceInterface

final class MentionPageCell: UICollectionViewCell {

    lazy private var displayImage: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    lazy private var mainTitleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.N900
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.accessibilityIdentifier = "mainTitle"
        return label
    }()
    lazy private var subTitleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.N500
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.alpha = 0.4
        label.accessibilityIdentifier = "subtitle"
        return label
    }()

    private static let insets = UIEdgeInsets(top: 2, left: 15, bottom: 2, right: 15)
    private static let font = UIFont.systemFont(ofSize: 13)
    static var singleLineHeight: CGFloat {
        return font.lineHeight + insets.top + insets.bottom
    }

    static func textHeight(_ text: String) -> CGFloat {
        // fixed by wangxin.sidney for one line meaure.
        let constrainedSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let attributes = [ NSAttributedString.Key.font: font ]
        let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        let bounds = (text as NSString).boundingRect(with: constrainedSize, options: options, attributes: attributes, context: nil)
        return ceil(bounds.height)
    }

    let separator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor.ud.N300.cgColor
        return layer
    }()

    var mainTitleConstrains = [SnapKit.Constraint]()

    var mentionInfo: MentionInfo? {
        didSet {
            guard let info = mentionInfo else { return }
            mainTitleLabel.text = info.name
            subTitleLabel.text = info.detail
            displayImage.kf.setImage(with: info.icon)
            let offset = (subTitleLabel.text?.isEmpty ?? true) ? 10 : -1
            mainTitleLabel.snp.updateConstraints { (make) in
                make.top.equalTo(displayImage.snp.top).offset(offset).labeled("顶部和图片对齐")
            }
            mainTitleConstrains.forEach { $0.deactivate() }
            mainTitleConstrains.removeAll()
            mainTitleConstrains = getMainTitleConstraints()
            mainTitleConstrains.forEach { $0.activate() }
        }
    }

    private func getMainTitleConstraints() -> [SnapKit.Constraint] {
        var constraints = [SnapKit.Constraint]()
        let toContentViewRightPadding = 24
        constraints.append(contentsOf: mainTitleLabel.snp.prepareConstraints({ (make) in
            make.right.lessThanOrEqualTo(contentView).offset(-toContentViewRightPadding)
        }))
        return constraints
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(displayImage)
        contentView.addSubview(mainTitleLabel)
        contentView.addSubview(subTitleLabel)
        displayImage.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.top.equalTo(contentView).offset(13)
            make.left.equalTo(contentView).offset(16)
        }
        mainTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(displayImage.snp.top).offset(-1).labeled("顶部和图片距离1")
            make.height.equalTo(22).labeled("高度固定22")
            make.left.equalTo(displayImage.snp.right).offset(12).labeled("左边距离图片12")
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(2)
            make.left.equalTo(mainTitleLabel)
            make.height.equalTo(20)
        }
        displayImage.layer.cornerRadius = 40 / 2
        displayImage.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted ? UDColor.bgBody : .clear
        }
    }
}
