import UIKit
import LarkDocsIcon
import SnapKit
import SwiftyJSON
import Kingfisher
import Foundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation
import LarkContainer

final class AtCell: UICollectionViewCell {

    lazy private var avatarImageView: AvatarImageView = {
        let imageView = AvatarImageView(frame: CGRect.zero)
        return imageView
    }()

    lazy private var displayImage: UIImageView = {
        avatarImageView.imageView.contentMode = .scaleAspectFill
        avatarImageView.imageView.layer.cornerRadius = 40 / 2
        return avatarImageView.imageView
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
        label.accessibilityIdentifier = "subtitle"
        return label
    }()
    lazy private var externalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.ud.B600
        if !UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            label.text = " " + BundleI18n.SKResource.Doc_Widget_External + " "
        }
        label.isHidden = true
        label.layer.backgroundColor = UIColor.ud.B100.cgColor
        label.layer.cornerRadius = 3
        label.accessibilityIdentifier = "externalLabel"
        return label
    }()
    lazy private var notInGroupLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.ud.colorfulBlue
        label.text = " " + BundleI18n.SKResource.Doc_At_NoInGroup + " "
        label.isHidden = true
        label.layer.backgroundColor = UIColor.ud.W50.cgColor
        label.layer.cornerRadius = 3
        label.accessibilityIdentifier = "externalLabel"
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

    var cellData: RecommendData? {
        didSet {
            guard let data = cellData else { return }
            
            if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
                if EnvConfig.CanShowExternalTag.value, let tagValue = data.displayTag?.tagValue, !tagValue.isEmpty {
                    externalLabel.isHidden = false
                    externalLabel.text = " " + tagValue + " "
                } else {
                    externalLabel.isHidden = true
                    externalLabel.text = ""
                }
            } else {
                if !EnvConfig.CanShowExternalTag.value {
                    externalLabel.isHidden = true
                } else {
                    if User.current.info?.isToC == true {
                        externalLabel.isHidden = true
                    } else if data.isCrossTenant || data.isExternal {
                        self.externalLabel.isHidden = false
                        self.externalLabel.text = " " + BundleI18n.SKResource.Doc_Widget_External + " "
                    } else {
                        self.externalLabel.isHidden = true
                    }
                }
            }

            mainTitleLabel.text = data.contentForMainTitle
            subTitleLabel.text = data.contentForSubTitle
            var needUseKeyToDownload = true
            let isNotFileType = (data.type == .chat || data.type == .user)
            if !isNotFileType {
                // 只有是文档类型时，并且FG关闭的时候，才不用key去下载icon
                needUseKeyToDownload = false
            }
            if let iconInfo = data.iconInfo, needUseKeyToDownload {
                displayImage.di.clearDocsImage()
                avatarImageView.set(avatarKey: iconInfo.key,
                                    placeholder: data.defaultImage,
                                    image: nil,
                                    completion: nil)
            } else {
                avatarImageView.cancelImageRequest() // fix: 异步导致数据与UI不匹配
                displayImage.di.setDocsImage(iconInfo: data.iconInfoMeta ?? "",
                                             url: data.url ?? "",
                                             userResolver: Container.shared.getCurrentUserResolver())
            }

            if let imageUrl = data.url, isNotFileType {
                displayImage.kf.setImage(with: URL(string: imageUrl))
            } else {
                avatarImageView.cancelImageRequest()
            }

            let offset = (subTitleLabel.text?.isEmpty ?? true) ? 10 : -1
            mainTitleLabel.snp.updateConstraints { (make) in
                make.top.equalTo(displayImage.snp.top).offset(offset).labeled("顶部和图片对齐")
            }
            
            if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
                externalLabel.snp.updateConstraints { make in
                    make.width.equalTo(externalLabel.sizeThatFits(CGSize(width: 300, height: 100)).width)
                }
            }
            self.notInGroupLabel.isHidden = data.shouldHideNotInGroupInfo
            mainTitleConstrains.forEach { $0.deactivate() }
            mainTitleConstrains.removeAll()
            mainTitleConstrains = getMainTitleConstraints()
            mainTitleConstrains.forEach { $0.activate() }
        }
    }
    private func getMainTitleConstraints() -> [SnapKit.Constraint] {
        var constraints = [SnapKit.Constraint]()
        let toContentViewRightPadding = 24
        let paddingBetween = 4
        if notInGroupLabel.isHidden {
            if externalLabel.isHidden {
                // 只有mainLabel
                constraints.append(contentsOf: mainTitleLabel.snp.prepareConstraints({ (make) in
                    make.right.lessThanOrEqualTo(contentView).offset(-toContentViewRightPadding)
                }))
            } else {
                // mainLabel + 外部租户
                constraints.append(contentsOf: externalLabel.snp.prepareConstraints({ (make) in
                    make.right.lessThanOrEqualTo(contentView).offset(-toContentViewRightPadding)
                }))
                constraints.append(contentsOf: mainTitleLabel.snp.prepareConstraints({ (make) in
                    make.right.lessThanOrEqualTo(externalLabel.snp.left).offset(-paddingBetween)
                }))
            }
        } else {
            // 不在群内，lable显示了
            constraints.append(contentsOf: notInGroupLabel.snp.prepareConstraints({ (make) in
                make.right.lessThanOrEqualTo(contentView).offset(-toContentViewRightPadding)
            }))
            if externalLabel.isHidden {
                // 外部租户。lable隐藏了.  mainLabel + 不在群内
                constraints.append(contentsOf: mainTitleLabel.snp.prepareConstraints({ (make) in
                    make.right.equalTo(notInGroupLabel.snp.left).offset(-paddingBetween)
                }))
            } else {
                // 外部租户，lable显示了。mainLabel + 外部租户 + 不在群内
                constraints.append(contentsOf: externalLabel.snp.prepareConstraints({ (make) in
                    make.right.equalTo(notInGroupLabel.snp.left).offset(-paddingBetween)
                }))
                constraints.append(contentsOf: mainTitleLabel.snp.prepareConstraints({ (make) in
                    make.right.equalTo(externalLabel.snp.left).offset(-paddingBetween)
                }))
            }
        }
        return constraints
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(displayImage)
        contentView.addSubview(mainTitleLabel)
        contentView.addSubview(externalLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(notInGroupLabel)
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
        externalLabel.snp.makeConstraints { (make) in
            make.height.equalTo(14)
            make.centerY.equalTo(mainTitleLabel)
            make.width.equalTo(externalLabel.sizeThatFits(CGSize(width: 300, height: 100)).width)
            make.left.equalTo(mainTitleLabel.snp.right)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        notInGroupLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(mainTitleLabel)
            make.height.equalTo(14)
            make.width.equalTo(notInGroupLabel.sizeThatFits(CGSize(width: 300, height: 100)).width)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(2)
            make.left.equalTo(mainTitleLabel)
            make.height.equalTo(20)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        if cellData?.type == .user || cellData?.type == .chat || cellData?.iconInfo != nil {
            displayImage.clipsToBounds = true
        } else {
            displayImage.clipsToBounds = false
        }
    }

    override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted ? UDColor.bgBody : .clear
        }
    }
}

extension RecommendData {
    public var contentForMainTitle: String {
        return contentToShow
    }
    public var contentForSubTitle: String? {
        switch type {
        case .user, .chat, .group: return department
        case .doc, .folder, .sheet, .bitable, .mindnote, .file, .slides, .wiki, .docx:
            return BundleI18n.SKResource.Doc_List_LastUpdateTime(editTime?.stampDateFormatter ?? "")
        }
    }

    var defaultImage: UIImage? {
        switch type {
        case .user, .chat, .group: return BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        case .doc: return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocColorful)
        case .folder: return nil // 因为找不到"icon_file_round_folder_colorful"了，所以这里返回nil
        case .sheet: return UDIcon.getIconByKeyNoLimitSize(.fileRoundSheetColorful)
        case .bitable: return UDIcon.getIconByKeyNoLimitSize(.fileRoundBitableColorful)
        case .mindnote: return UDIcon.getIconByKeyNoLimitSize(.fileRoundMindnoteColorful)
        case .file: return makeIconForDrive()
        case .slides: return UDIcon.getIconByKeyNoLimitSize(.wikiSlidesCircleColorful)
        case .wiki: return makeIconForWiki()
        case .docx: return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocxColorful)
        }
    }

    var shouldHideNotInGroupInfo: Bool {
        if requestSource == .announcement && hasJoinChat == false && type == .user {
            return false
        }
        return true
    }
    private func makeIconForDrive() -> UIImage? {
        let type = DriveFileType(rawValue: ((content as NSString?)?.pathExtension ?? "").lowercased()) ?? .unknown
        return type.roundImage
    }

    private func makeIconForWiki() -> UIImage? {
        switch subType {
        case .doc:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocColorful)
        case .sheet:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundSheetColorful)
        case .bitable:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundBitableColorful)
        case .mindnote:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundMindnoteColorful)
        case .slides:
            return UDIcon.getIconByKeyNoLimitSize(.wikiSlidesCircleColorful)
        case .file:
            return makeIconForDrive()
        case .docx:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundDocxColorful)
        default:
            return UDIcon.getIconByKeyNoLimitSize(.fileRoundUnknowColorful)
        }
    }
}
