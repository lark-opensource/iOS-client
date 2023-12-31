//
//  SearchDocumentResultCell.swift
//  ByteView
//
//  Created by lvdaqian on 2019/10/17.
//

import Foundation
import RichLabel
import ByteViewNetwork
import UniverseDesignIcon

protocol DocsIconDelegate: AnyObject {
    func getDocsIconImage(with iconInfo: String, url: String, completion: ((UIImage) -> Void)?)
}

extension DocsIconDelegate {
    func getDocsIconImage(with iconInfo: String, url: String, completion: ((UIImage) -> Void)?) {}
}

struct SearchDocumentResultCellModel {
    let icon: UIImage?
    let title: String
    let abstract: String
    let ownerTips: String
    let statusImage: UIImage?
    let status: VcDocs.ShareStatus
    let url: String
    let isSharing: Bool
    let docToken: String
    let docType: VcDocType
    let docSubType: VcDocSubType
    let rank: Int // 本次搜索的索引

    /// 判断可以发起MS能力，非NO_SUPPORT_SHARE或UNKNOWN
    let isMSEnabled: Bool

    /// 文档类型对应的图片URL
    let imageUrl: String

    let iconMeta: String

    /// 是否是“会议相关”区域内的
    let isFileMeetingRelated: Bool

    init(_ model: VcDocs, isSharing: Bool, rank: Int, isFileMeetingRelated: Bool) {
        title = isFileMeetingRelated ?
        !model.docTitle.isEmpty ? model.docTitle : I18n.View_VM_UntitledDocument :
        !model.docTitleHighlight.isEmpty ? model.docTitleHighlight : I18n.View_VM_UntitledDocument
        abstract = model.abstract
        ownerTips = I18n.View_G_OwnerOwnerNameBraces(model.ownerName)
        status = model.status
        url = model.docURL
        icon = model.typeIcon
        docToken = model.docToken
        docType = model.docType
        docSubType = model.docSubType
        iconMeta = model.iconMeta
        isMSEnabled = !(model.status == .noSupportShare || model.status == .unknown)
        let iconAlpha: CGFloat = (isFileMeetingRelated ? true : isMSEnabled) ? 1.0 : 0.5
        self.isSharing = isSharing
        self.rank = rank
        self.isFileMeetingRelated = isFileMeetingRelated
        if isSharing {
            statusImage = UDIcon.getIconByKey(.shareScreenFilled, iconColor: .ud.colorfulGreen.withAlphaComponent(iconAlpha), size: CGSize(width: 20, height: 20))
        } else if .noSharePermission == model.status {
            statusImage = UDIcon.getIconByKey(.lockFilled, iconColor: .ud.iconN3.withAlphaComponent(iconAlpha), size: CGSize(width: 16, height: 16))
        } else {
            statusImage = nil
        }
        imageUrl = model.docLabelURL
    }

}

class SearchDocumentResultCell: UITableViewCell {

    weak var docsIconDelegate: DocsIconDelegate?

    let preMark = "<em>"
    let subMark = "</em>"

    private struct Layout {
        static let horizontalEdgeOffset: CGFloat = 16.0
        static let fileIconSideLength: CGFloat = 40.0
        static let fileIconAndContentSpacing: CGFloat = 12.0
        static let contentVertivalEdgeOffset: CGFloat = 12.0
        static let titleLabelHeight: CGFloat = 22.0
        static let titleAndStatusIconSpacing: CGFloat = 6.0
        static let statusIconSideLength: CGFloat = 20.0
        static let abstractLabelHeight: CGFloat = 20.0 // IG使用的颜色和高度继承自之前的设计
        static let ownerLabelHeight: CGFloat = 20.0
    }

    let fileIconView: UIImageView = UIImageView()
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 0 // 当abstractLabel显示时为2
        return stackView
    }()
    let titleAndStatusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = Layout.titleAndStatusIconSpacing
        return stackView
    }()

    let titleLabel: LKLabel = {
        let label = LKLabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.numberOfLines = 1
        label.backgroundColor = .clear
        let style = NSMutableParagraphStyle()
        style.maximumLineHeight = Layout.titleLabelHeight
        style.minimumLineHeight = Layout.titleLabelHeight
        label.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: [.font: UIFont.systemFont(ofSize: 16),
                                                                                   .paragraphStyle: style,
                                                                                   .foregroundColor: UIColor.ud.textTitle])
        return label
    }()

    let statusView: UIImageView = {
        let imageView = UIImageView()
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()
    let abstractLabel: UILabel = UILabel()
    let ownerLabel: UILabel = UILabel()

    lazy var abstractStyle: [NSAttributedString.Key: Any] = {
        var attr = [NSAttributedString.Key: Any]()
        attr[.foregroundColor] = UIColor.ud.textPlaceholder
        attr[.font] = UIFont.systemFont(ofSize: 14)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = Layout.abstractLabelHeight
        style.maximumLineHeight = Layout.abstractLabelHeight
        style.lineBreakMode = .byTruncatingTail
        attr[.paragraphStyle] = style
        return attr
    }()

    lazy var invalidAbstractStyle: [NSAttributedString.Key: Any] = {
        var attr = [NSAttributedString.Key: Any]()
        attr[.foregroundColor] = UIColor.ud.textDisabled
        attr[.font] = UIFont.systemFont(ofSize: 14)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = Layout.abstractLabelHeight
        style.maximumLineHeight = Layout.abstractLabelHeight
        style.lineBreakMode = .byTruncatingTail
        attr[.paragraphStyle] = style
        return attr
    }()

    lazy var ownerStyle: [NSAttributedString.Key: Any] = {
        var attr = [NSAttributedString.Key: Any]()
        attr[.foregroundColor] = UIColor.ud.textPlaceholder
        attr[.font] = UIFont.systemFont(ofSize: 14)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = Layout.ownerLabelHeight
        style.maximumLineHeight = Layout.ownerLabelHeight
        style.lineBreakMode = .byTruncatingTail
        attr[.paragraphStyle] = style
        return attr
    }()

    lazy var invalidOwnerStyle: [NSAttributedString.Key: Any] = {
        var attr = [NSAttributedString.Key: Any]()
        attr[.foregroundColor] = UIColor.ud.textDisabled
        attr[.font] = UIFont.systemFont(ofSize: 14)
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = Layout.ownerLabelHeight
        style.maximumLineHeight = Layout.ownerLabelHeight
        style.lineBreakMode = .byTruncatingTail
        attr[.paragraphStyle] = style
        return attr
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        autolayoutSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(fileIconView)
        contentView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleAndStatusStackView)
        titleAndStatusStackView.addArrangedSubview(titleLabel)
        titleAndStatusStackView.addArrangedSubview(statusView)
        contentStackView.addArrangedSubview(abstractLabel)
        contentStackView.addArrangedSubview(ownerLabel)

        setSelectedBackgroundColor(UIColor.ud.N900.withAlphaComponent(0.1))
        setBackgroundViewColor(UIColor.ud.bgBody)

        self.backgroundColor = UIColor.ud.bgBody
    }

    private func autolayoutSubviews() {
        fileIconView.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(Layout.horizontalEdgeOffset)
            maker.centerY.equalToSuperview()
            maker.height.width.equalTo(Layout.fileIconSideLength)
        }
        contentStackView.snp.makeConstraints { maker in
            maker.left.equalTo(fileIconView.snp.right).offset(Layout.fileIconAndContentSpacing)
            maker.right.equalToSuperview().inset(Layout.horizontalEdgeOffset)
            maker.top.bottom.equalToSuperview().inset(Layout.contentVertivalEdgeOffset)
        }
        titleAndStatusStackView.snp.makeConstraints { maker in
            maker.height.equalTo(max(Layout.titleLabelHeight, Layout.statusIconSideLength))
        }
        titleLabel.snp.makeConstraints { maker in
            maker.height.equalTo(Layout.titleLabelHeight)
        }
        statusView.snp.makeConstraints { maker in
            maker.width.height.equalTo(Layout.statusIconSideLength)
        }
        abstractLabel.snp.makeConstraints { maker in
            maker.height.equalTo(Layout.abstractLabelHeight)
        }
        ownerLabel.snp.makeConstraints { maker in
            maker.height.equalTo(Layout.ownerLabelHeight)
        }
    }

    func update(_ model: SearchDocumentResultCellModel, account: AccountInfo, isFromMeetingRelated: Bool = false) {
        let isMSEnabled = isFromMeetingRelated ? true : model.isMSEnabled
        isUserInteractionEnabled = isMSEnabled
        if let delegate = docsIconDelegate {
            delegate.getDocsIconImage(with: model.iconMeta, url: model.url) { [weak self] image in
                Util.runInMainThread { [weak self] in
                    self?.fileIconView.image = image
                }
            }
        } else {
            fileIconView.vc.setImage(url: model.imageUrl, accessToken: account.accessToken, placeholder: model.icon)
        }
        fileIconView.alpha = isMSEnabled ? 1.0 : 0.5
        titleLabel.textColor = isMSEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        titleLabel.text = model.title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.attributedText = getColoredTitleText(with: model.title, isEnabled: isMSEnabled)
        abstractLabel.attributedText = getColoredAbstractText(with: model.abstract, isEnabled: isMSEnabled)
        ownerLabel.attributedText = NSAttributedString(string: model.ownerTips, attributes: isMSEnabled ? ownerStyle : invalidOwnerStyle)
        abstractLabel.isHidden = model.abstract.isEmpty
        contentStackView.spacing = model.abstract.isEmpty ? 0 : 2
        if let statusImage = model.statusImage {
            statusView.image = statusImage
            statusView.isHidden = false
        } else {
            statusView.isHidden = true
        }
        layoutIfNeeded()
    }

    /// 设置按压选中状态背景色
    /// - Parameter selectedColor: 按压选中状态背景色
    func setSelectedBackgroundColor(_ selectedColor: UIColor) {
        let selectedBackgroundView = UIView()
        let subView = UIView()
        subView.layer.cornerRadius = 6
        subView.layer.masksToBounds = true
        subView.backgroundColor = selectedColor
        selectedBackgroundView.addSubview(subView)
        subView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
            make.top.bottom.equalToSuperview()
        }
        self.selectedBackgroundView = selectedBackgroundView
    }

    /// 设置背景View颜色
    /// - Parameter backgroundViewColor: 背景View颜色
    func setBackgroundViewColor(_ backgroundViewColor: UIColor) {
        let backgroundView = UIView()
        backgroundView.backgroundColor = backgroundViewColor
        self.backgroundView = backgroundView
    }
}

extension SearchDocumentResultCell {

    func getColoredTitleText(with content: String,
                             fontSize: CGFloat = 16.0,
                             normalColor: UIColor = UIColor.ud.textTitle,
                             specializedColor: UIColor = UIColor.ud.colorfulBlue,
                             disabledColor: UIColor = UIColor.ud.textDisabled,
                             isEnabled: Bool = true) -> NSAttributedString {
        // get highlight keywords and removed html marked
        var keywords = getKeyWordsMarkedByServer(in: content)
        keywords = keywords.map { str -> String in
            let s = str.replacingOccurrences(of: preMark, with: "")
            return s.replacingOccurrences(of: subMark, with: "")
        }
        // remove content html marked
        let removedMarksStr = removeWordsMarked(in: content)
        let attributeStr = NSMutableAttributedString(string: removedMarksStr)
        // set fontSize and normalColor to string
        let allRange = NSRange(location: 0, length: (removedMarksStr as NSString).length)
        attributeStr.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)], range: allRange)
        attributeStr.addAttributes([NSAttributedString.Key.foregroundColor: isEnabled ? normalColor : disabledColor], range: allRange)
        // highlight string
        for keyword in keywords {
            if let range = removedMarksStr.range(of: keyword) {
                let nsRange = removedMarksStr.nsRange(fromRange: range)
                attributeStr.addAttributes([NSAttributedString.Key.foregroundColor: isEnabled ? specializedColor : disabledColor], range: nsRange)
            }
        }
        return attributeStr
    }

    func getColoredAbstractText(with content: String,
                                fontSize: CGFloat = 14.0,
                                normalColor: UIColor = UIColor.ud.textPlaceholder,
                                specializedColor: UIColor = UIColor.ud.colorfulBlue,
                                disabledColor: UIColor = UIColor.ud.textDisabled,
                                isEnabled: Bool = true) -> NSAttributedString {
        getColoredTitleText(with: content, fontSize: fontSize, normalColor: normalColor,
            specializedColor: specializedColor, disabledColor: disabledColor, isEnabled: isEnabled)
    }

    func getKeyWordsMarkedByServer(in content: String) -> [String] {
        var keywordsArray = [String]()
        let keywords = content.matches(for: preMark + "(.*?)" + subMark)
        if !keywords.isEmpty {
            keywordsArray.append(contentsOf: keywords)
        }
        return keywordsArray
    }

    func removeWordsMarked(in content: String) -> String {
        let result = content.replacingOccurrences(of: preMark, with: "").replacingOccurrences(of: subMark, with: "")
        return result
    }

}

private extension String {

    func nsRange(fromRange range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }

    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range) }
        } catch {
            return []
        }
    }

}
