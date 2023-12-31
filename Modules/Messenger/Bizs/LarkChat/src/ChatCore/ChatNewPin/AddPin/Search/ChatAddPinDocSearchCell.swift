//
//  ChatAddPinDocSearchCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/6.
//

import Foundation
import RustPB
import LarkUIKit
import SnapKit
import LarkCore
import LarkSDKInterface
import LarkTag
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import LarkBizTag
import LarkDocsIcon
import LarkContainer

final class ChatAddPinDocSearchCell: UITableViewCell {

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
                make.top.bottom.equalToSuperview().inset(6)
                make.left.right.equalToSuperview().inset(6)
            }
        }
    }

    private var doc: ChatAddPinDocSearchModel?
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
        backgroundColor = UIColor.ud.bgBody
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

    func setDoc(_ doc: ChatAddPinDocSearchModel) {
        self.doc = doc
        if let attributedTitle = doc.attributedTitle {
            self.titleLabel.attributedText = attributedTitle
        } else {
            let title = doc.title
            var titleAttributed = NSAttributedString(string: title)
            titleAttributed = SearchResult.attributedText(attributedString: titleAttributed,
                                                              withHitTerms: doc.titleHitTerms,
                                                              highlightColor: UDColor.primaryPri500)
            let mutTitleAttributed = NSMutableAttributedString(attributedString: titleAttributed)
            mutTitleAttributed.addAttribute(.font,
                                            value: UIFont.systemFont(ofSize: 17),
                                            range: NSRange(location: 0, length: titleAttributed.length))
            self.titleLabel.attributedText = mutTitleAttributed
        }
        self.detailLabel.text = "\(BundleI18n.CCM.Lark_Legacy_SendDocDocOwner)\(BundleI18n.CCM.Lark_Legacy_Colon)\(doc.ownerName)"

        let docType: RustPB.Basic_V1_Doc.TypeEnum
        if doc.docType == .wiki {
            docType = doc.wikiSubType
        } else {
            docType = doc.docType
        }
        let defaultIcon = LarkCoreUtils.docIconColorful(docType: docType, fileName: doc.title)
        addDocIconImageView(docIcon, left: 22.5)

        self.docIcon.di.clearDocsImage()
        if !doc.iconInfo.isEmpty {
            let containerInfo = ContainerInfo(isShortCut: doc.docType == .shortcut, defaultCustomIcon: defaultIcon)
            self.docIcon.di.setDocsImage(iconInfo: doc.iconInfo, url: doc.url, shape: .SQUARE, container: containerInfo, userResolver: doc.userResolver)
        } else {
            self.docIcon.image = defaultIcon
        }

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

struct ChatAddPinDocSearchModel {
    var id: String
    var title: String
    // Search Broker V2 自带高亮 优先使用这个
    var attributedTitle: NSAttributedString?
    var ownerID: String
    var ownerName: String
    var updateTime: Int64
    var url: String
    var docType: RustPB.Basic_V1_Doc.TypeEnum
    var titleHitTerms: [String]
    var isCrossTenant: Bool
    // wiki 真正类型
    var wikiSubType: RustPB.Basic_V1_Doc.TypeEnum
    var relationTag: Basic_V1_TagData?
    let iconInfo: String
    let userResolver: UserResolver

   init(id: String,
        title: String,
        attributedTitle: NSAttributedString?,
        ownerID: String,
        ownerName: String,
        url: String,
        docType: RustPB.Basic_V1_Doc.TypeEnum,
        updateTime: Int64,
        titleHitTerms: [String],
        isCrossTenant: Bool,
        wikiSubType: RustPB.Basic_V1_Doc.TypeEnum,
        relationTag: Basic_V1_TagData? = nil,
        iconInfo: String,
        userResolver: UserResolver) {
       self.id = id
       self.title = title.isEmpty ? BundleI18n.CCM.Lark_Legacy_DefaultName : title
       self.relationTag = relationTag
       self.attributedTitle = attributedTitle
       self.ownerID = ownerID
       self.ownerName = ownerName
       self.url = url
       self.docType = docType
       self.updateTime = updateTime
       self.titleHitTerms = titleHitTerms
       self.isCrossTenant = isCrossTenant
       self.wikiSubType = wikiSubType
       self.iconInfo = iconInfo
       self.userResolver = userResolver
   }
}

final class ChatAddPinDocStatusSearchCell: UITableViewCell {
    private var titleLabel: UILabel = UILabel()
    private var loadingView = UDLoading.presetSpin(loadingText: BundleI18n.LarkChat.Lark_Legacy_LoadingLoading, textDistribution: .horizonal)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textColor = UIColor.ud.textPlaceholder
        self.titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(16)
        }

        self.contentView.addSubview(self.loadingView)
        self.loadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func set(searchResult: ChatAddPinSearchViewModel.SearchStatus, showLoading: Bool) {
        if case .normal = searchResult {
            self.titleLabel.text = BundleI18n.CCM.Lark_Legacy_AllResultLoaded
        } else {
            self.titleLabel.text = BundleI18n.CCM.Lark_Legacy_SendDocLoading
        }

        if showLoading {
            self.loadingView.isHidden = false
            self.titleLabel.isHidden = true
            self.backgroundColor = UIColor.clear
        } else {
            self.loadingView.isHidden = true
            self.titleLabel.isHidden = false
            self.backgroundColor = UIColor.ud.bgBody
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
