//
//  ChatTabDocSearchCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/4/6.
//

import Foundation
import RustPB
import SnapKit
import LarkUIKit
import LarkCore
import LarkSDKInterface
import LarkTag
import LarkFeatureGating
import LarkAvatar
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import LarkBizTag

final class ChatTabDocSearchCell: UITableViewCell {

    final class InsetHighlightView: UIView {

        private lazy var contentView: UIView = {
            let view = UIView()
            view.backgroundColor = UDColor.fillHover
            view.layer.cornerRadius = 6
            return view
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            setupUI()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }

        private func setupUI() {
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.right.equalToSuperview().inset(6)
            }
        }
    }

    var doc: ChatTabDocSearchModel?

    private let docIcon = UIImageView()

    private var titleLabel: UILabel = UILabel()
    private let detailLabel: UILabel = UILabel()
    private lazy var builder = TagViewBuilder()
    private lazy var tagView = builder.build()
    private var tagConstraint: Constraint?

    private lazy var highlightView = InsetHighlightView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(highlightView)
        highlightView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        highlightView.isHidden = true

        addDocIconImageView(docIcon, left: 46)

        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.textColor = UDColor.textTitle
        self.titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.docIcon.snp.right).offset(12)
            make.right.lessThanOrEqualTo(-20)
            make.top.equalToSuperview().offset(15)
        }
        self.contentView.addSubview(self.detailLabel)
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.detailLabel.textColor = UDColor.textPlaceholder
        self.detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.docIcon.snp.right).offset(12)
            make.right.lessThanOrEqualTo(-20)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(7)
        }

        self.contentView.addSubview(tagView)
        tagView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.titleLabel)
            make.height.equalTo(15)
            self.tagConstraint = make.right.lessThanOrEqualTo(self.contentView).offset(-20).constraint
            make.left.equalTo(self.titleLabel.snp.right).offset(6)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDoc(_ doc: ChatTabDocSearchModel) {
        self.doc = doc
        if let attributedTitle = doc.attributedTitle {
            self.titleLabel.attributedText = attributedTitle
        } else {
            let title = doc.title.isEmpty ? BundleI18n.CCM.Lark_Legacy_DefaultName : doc.title
            var titleAttributed = NSAttributedString(string: title)
            titleAttributed = SearchResult.attributedText(attributedString: titleAttributed,
                                                              withHitTerms: doc.titleHitTerms,
                                                              highlightColor: UDColor.primaryContentDefault)
            let mutTitleAttributed = NSMutableAttributedString(attributedString: titleAttributed)
            mutTitleAttributed.addAttribute(.font,
                                            value: UIFont.systemFont(ofSize: 17),
                                            range: NSRange(location: 0, length: titleAttributed.length))
            self.titleLabel.attributedText = mutTitleAttributed
        }
        self.detailLabel.text = "\(BundleI18n.CCM.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCM.Lark_Legacy_Colon)\(doc.ownerName)"

        var defaultIcon = LarkCoreUtils.docIconColorful(docType: doc.docType, fileName: doc.title)
        if doc.docType == .wiki {
            defaultIcon = LarkCoreUtils.wikiIconColorful(docType: doc.wikiSubType, fileName: doc.title)
        }
        self.docIcon.image = defaultIcon
        addDocIconImageView(docIcon, left: 22.5)
        if doc.relationTag?.tagDataItems.isEmpty == false {
            var dataItems: [TagDataItem] = []
            doc.relationTag?.tagDataItems.forEach({ item in
                let dataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                      tagType: item.respTagType.transform())
                dataItems.append(dataItem)
            })
            builder.update(with: dataItems)
            tagView.isHidden = false
        } else {
            tagView.isHidden = true
        }
        self.tagConstraint?.isActive = !tagView.isHidden
    }

    func update(isHighlight: Bool) {
        highlightView.isHidden = !isHighlight
    }

    private func addDocIconImageView(_ imageView: UIView, left: Float) {
        let iconWidth: CGFloat = 48
        self.contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(iconWidth)
            make.left.equalTo(left)
            make.centerY.equalToSuperview()
        }
    }
}
