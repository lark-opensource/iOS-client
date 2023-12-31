//
//  SendDocCell.swift
//  Lark
//
//  Created by lichen on 2018/7/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import LarkUIKit
import LarkModel

#if MessengerMod
import LarkCore
import LarkSDKInterface
#endif

import LarkTag
import LarkFeatureGating
import LarkAvatar
import UniverseDesignColor
import LarkBizTag
import SKCommon
import SKFoundation

class SendDocStatusCell: UITableViewCell {
    private var titleLabel: UILabel = UILabel()

    var searchResult: SendDocViewModel.SearchStatus = .noload {
        didSet {
            switch searchResult {
            case .nomore:
                self.titleLabel.text = BundleI18n.CCMMod.Lark_Legacy_AllResultLoaded
            default:
                self.titleLabel.text = BundleI18n.CCMMod.Lark_Legacy_SendDocLoading
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textColor = UDColor.textPlaceholder
        self.titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct Layout {
    static let itemHeight: CGFloat       = 68.0
    static let leftPadding: CGFloat      = 106.0
    static let rightPadding: CGFloat     = 20.0
    static let tagPadding: CGFloat       = 10.0
    static let stackViewSpace: CGFloat   = 6.0
    static let defaultViewWidth: CGFloat = 320.0
}

class SendDocCell: UITableViewCell {

    var doc: SendDocModel?

    private let checkBox = LKCheckbox(boxType: .multiple)
    private let docIcon = UIImageView()
    private let docIconV2 = AvatarImageView()
    private let labelIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.borderWidth = 1.5
        imageView.layer.masksToBounds = true
        imageView.layer.ud.setBorderColor(UIColor.ud.N00)

        return imageView
    }()
    
    private let titleView: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 6
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var highlightView = InsetHighlightView()
    
    private lazy var builder = TagViewBuilder()
    private lazy var tagView = builder.build()
    private var tagConstraint: Constraint?
    
    var contentWidth: CGFloat {
        let titleWidth = titleLabel.systemLayoutSizeFitting(.zero).width
        let leftPadding = Layout.leftPadding
        let rightPadding = Layout.rightPadding
        var contentWidth = leftPadding + titleWidth + rightPadding
        
        if !tagView.isHidden {
            contentWidth += tagView.systemLayoutSizeFitting(.zero).width
        }
        return contentWidth
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(highlightView)
        
        highlightView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        highlightView.isHidden = true
        
        contentView.addSubview(checkBox)
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
        }


        let labelIconWidth: CGFloat = 48
        contentView.addSubview(labelIcon)
        labelIcon.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(labelIconWidth)
        }
        labelIcon.layer.cornerRadius = labelIconWidth / 2.0
        
        contentView.addSubview(titleView)
        if UserScopeNoChangeFG.MJ.imSendDocSwipeEnable {
            titleView.snp.makeConstraints { make in
                make.left.equalTo(labelIcon.snp.right).offset(12)
                make.top.equalToSuperview().offset(9)
            }
        } else {
            titleView.setContentCompressionResistancePriority(.required - 10, for: .horizontal)
            titleView.snp.makeConstraints { make in
                make.left.equalTo(labelIcon.snp.right).offset(12)
                make.right.lessThanOrEqualToSuperview().offset(-8)
                make.top.equalToSuperview().offset(9)
            }
        }
        
        titleView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleView)
            make.top.equalTo(titleView.snp.bottom).offset(4)
        }
        
        titleView.addArrangedSubview(tagView)
        tagView.setContentCompressionResistancePriority(.required, for: .horizontal)
        tagView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
        }
    }

    func setDoc(_ doc: SendDocModel, selected: Bool) {
        #if MessengerMod
        self.doc = doc
        if let attributedTitle = doc.attributedTitle {
            self.titleLabel.attributedText = attributedTitle
        } else {
            let title = doc.title.isEmpty ? BundleI18n.CCMMod.Lark_Legacy_DefaultName : doc.title
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
        self.detailLabel.text = "\(BundleI18n.CCMMod.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCMMod.Lark_Legacy_Colon)\(doc.ownerName)"

        var defaultIcon = LarkCoreUtils.docIcon(docType: doc.docType, fileName: doc.title)
        if doc.docType == .wiki {
            defaultIcon = LarkCoreUtils.docIcon(docType: doc.wikiSubType, fileName: doc.title)
        }
        labelIcon.image = defaultIcon

        if doc.sendDocModelCanSelectType == .optionalType {
            //cell可以选择
            self.checkBox.isHidden = false
            self.checkBox.isSelected = selected
        } else if doc.sendDocModelCanSelectType == .notOptionalType {
            //cell被点击跳转
            self.checkBox.isHidden = true
            self.titleView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(22)
            }
        }
        var dataItems: [TagDataItem] = []
        if doc.relationTag?.tagDataItems.isEmpty == false, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            doc.relationTag?.tagDataItems.forEach({ item in
                let dataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                      tagType: item.respTagType.transform())
                dataItems.append(dataItem)
            })
            builder.update(with: dataItems)
            tagView.isHidden = false
        } else if doc.searchRelationTag?.tagDataItems.isEmpty == false, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            doc.searchRelationTag?.tagDataItems.forEach({ item in
                let dataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                      tagType: item.respTagType.transform())
                dataItems.append(dataItem)
            })
            builder.update(with: dataItems)
            tagView.isHidden = false
        } else {
            if doc.isCrossTenant {
                let dataItem = LarkBizTag.TagDataItem(tagType: .external)
                dataItems.append(dataItem)
                builder.update(with: dataItems)
                tagView.isHidden = false
            } else {
                tagView.isHidden = true
            }
        }
        #endif
    }

    func update(enable: Bool) {
        contentView.alpha = enable ? 1.0 : 0.3
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
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = iconWidth / 2.0
    }
}

private class InsetHighlightView: UIView {

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
