//
//  WikiSpaceDetailTableViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/24.
//  

import UIKit
import QuartzCore
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class WikiSpaceDetailTableViewCell: UITableViewCell {

    private lazy var sectionLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_IntroductionTitle
        label.font = UIFont.ct.systemMedium(ofSize: 16)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.ct.systemRegular(ofSize: 16)
        label.numberOfLines = 0 // 先允许多行，超过4行再折叠
        label.textColor = UDColor.textTitle
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private static let indicatorExpandedHeight: CGFloat = 40
    private static let indicatorCollapseHeight: CGFloat = 12

    private lazy var indicatorView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var indicatorContentView: UIView = {
        let view = UIView()
        view.docs.addStandardHighlight()
        return view
    }()

    private lazy var indicatorLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_ExpandIntroduction
        label.font = UIFont.ct.systemRegular(ofSize: 12)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var indicatorImageView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.downOutlined.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = UIColor.ud.N600 // 这里的颜色可能需要调整
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var bottomSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }()

    var expandCallback: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        expandCallback = nil
    }

    private func setupUI() {
        clipsToBounds = true
        backgroundColor = UDColor.bgBody

        contentView.addSubview(sectionLabel)
        sectionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(22)
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(sectionLabel.snp.bottom).offset(18)
            make.left.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
        }

        contentView.addSubview(bottomSeperatorView)
        bottomSeperatorView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(8)
        }

        contentView.addSubview(indicatorView)
        indicatorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(descriptionLabel.snp.bottom)
            make.bottom.equalTo(bottomSeperatorView.snp.top)
            make.height.equalTo(Self.indicatorExpandedHeight)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickExpandButton))
        indicatorView.addGestureRecognizer(tapGesture)

        indicatorView.addSubview(indicatorContentView)
        indicatorContentView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        indicatorContentView.addSubview(indicatorLabel)
        indicatorLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }

        indicatorContentView.addSubview(indicatorImageView)
        indicatorImageView.snp.makeConstraints { make in
            make.left.equalTo(indicatorLabel.snp.right).offset(4)
            make.width.height.equalTo(16)
            make.right.equalToSuperview()
            make.centerY.equalTo(indicatorLabel)
        }
    }

    private func update(description: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        var attrContent = description
        if description.isEmpty {
            attrContent = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_IntroductionPlaceholder
        }
        let attrString = NSMutableAttributedString(string: attrContent)
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        descriptionLabel.attributedText = attrString
    }

    @objc
    private func didClickExpandButton() {
        expandCallback?()
    }

    private func collapseDescription() {
        indicatorLabel.text = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_ExpandIntroduction
        let rotateTransform = CGAffineTransform(rotationAngle: 0)
        indicatorImageView.layer.setAffineTransform(rotateTransform)
    }

    private func expandDescription() {
        indicatorLabel.text = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_CollapseIntroduction
        let rotateTransform = CGAffineTransform(rotationAngle: .pi)
        indicatorImageView.layer.setAffineTransform(rotateTransform)
    }

    static func preferedHeightFor(cellWidth: CGFloat, isExpanded: Bool, content: String) -> (canExpand: Bool, preferHeight: CGFloat) {
        let extraHeight: CGFloat = 54 /* Top Section Header */ + 18 /* Bottom Seperator */
        let label = UILabel()
        label.font = UIFont.ct.systemRegular(ofSize: 16)
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        var attrContent = content
        if content.isEmpty {
            attrContent = BundleI18n.SKResource.Doc_Wiki_SpaceDetail_IntroductionPlaceholder
        }
        let attrString = NSMutableAttributedString(string: attrContent)
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        label.attributedText = attrString
        var height = label.calculateLabelHeight(textWidth: cellWidth - 36) // label left+right inset
        guard let lineCount = label.lines?.count else {
            // 读不到lineCount，可能是描述为空，展示全文，隐藏展开按钮
            height += indicatorCollapseHeight /* Bottom Button */ + extraHeight
            return (false, height)
        }
        if lineCount <= 4 {
            // 小于4行，展示全文，隐藏展开按钮
            height += indicatorCollapseHeight /* Bottom Button */ + extraHeight
            return (false, height)
        } else if isExpanded {
            // 大于4行，展示全文，显示折叠按钮
            height += indicatorExpandedHeight /* Bottom Button */ + extraHeight
            return (true, height)
        } else {
            // 大于4行，只展示前四行，显示展开按钮
            label.numberOfLines = 4
            height = label.calculateLabelHeight(textWidth: cellWidth - 36)
            height += indicatorExpandedHeight /* Bottom Button */ + extraHeight
            return (true, height)
        }
    }

    func update(description: String, canExpand: Bool, isExpanded: Bool) {
        update(description: description)
        indicatorView.isHidden = !canExpand
        let indicatorHeight: CGFloat = canExpand ? Self.indicatorExpandedHeight : Self.indicatorCollapseHeight
        indicatorView.snp.updateConstraints { make in
            make.height.equalTo(indicatorHeight)
        }
        if isExpanded {
            expandDescription()
        } else {
            collapseDescription()
        }
    }
}
