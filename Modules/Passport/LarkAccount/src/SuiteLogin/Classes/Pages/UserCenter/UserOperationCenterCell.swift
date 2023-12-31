//
//  UserOperationCenterCell.swift
//  LarkAccount
//
//  Created by bytedance on 2021/6/15.
//

import Foundation
import LKCommonsLogging
import SnapKit

class UserOperationCenterCellData {
    let title: String
    let subtitle: String?
    var iconURL: String?
    var icon: UIImage?
    var tag: String?
    var status: UserExpressiveStatus?
    let buttonInfo: V4ButtonInfo?
    let isValid: Bool

    static let logger = Logger.log(UserOperationCenterCellData.self)

    init(title: String,
         subtitle: String? = nil,
         iconURL: String? = nil,
         icon: UIImage? = nil,
         tag: String? = nil,
         status: UserExpressiveStatus? = nil,
         buttonInfo: V4ButtonInfo? = nil,
         isValid: Bool = true) {
        self.title = title
        self.subtitle = subtitle
        self.iconURL = iconURL
        self.icon = icon
        self.tag = tag
        self.status = status
        self.buttonInfo = buttonInfo
        self.isValid = isValid
    }
}

class UserOperationCenterCell: UITableViewCell, SelectionStyleProtocol {

    static let logger = Logger.log(UserOperationCenterCell.self)
    var data: UserOperationCenterCellData? {
        didSet {
            updateCell()
        }
    }

    lazy var iconView: UIImageView = {
        let iconView = UIImageView(frame: .zero)
        iconView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)
        return iconView
    }()

    lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16)
        lbl.textColor = UIColor.ud.textTitle
        contentView.addSubview(lbl)
        return lbl
    }()

    lazy var subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = UIColor.ud.textCaption
        return lbl
    }()

    let tagLabel: TagInsetLabel = {
        return TagInsetLabel(style: .blue)
    }()

    let actionLabel: InsetLabel = {
        return InsetLabel(style: .blue)
    }()

    lazy var arrowImgView: UIImageView = {
        let imgView = UIImageView()
        let img = BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imgView.image = img
        imgView.frame.size = img.size
        return imgView
    }()
    
    lazy var splitLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineBorderCard
        contentView.addSubview(view)
        return view
    }()

//    func updateSelection(_ selected: Bool) {
//        cardContainer.updateSelection(selected)
//    }
    
    var isLastRow: Bool = false {
        didSet {
            updateSeparator()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none
    }

    private func updateCell() {
        var rightConstraint: SnapKit.ConstraintItem = self.contentView.snp.right
        var leftConstraint: SnapKit.ConstraintItem = self.contentView.snp.left
        
        let isValid = data?.isValid ?? true
        let alpha = isValid ? 1.0 : 0.5
        iconView.alpha = alpha
        titleLabel.alpha = alpha
        subtitleLabel.alpha = alpha
        
        self.setImage(
            urlString: self.data?.iconURL,
            image: self.data?.icon
        )
        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(CL.itemSpace)
            make.width.height.equalTo(Layout.iconImageDiameter)
            make.centerY.equalToSuperview()
        }
        leftConstraint = self.iconView.snp.right
        if isValid {
            contentView.addSubview(self.arrowImgView)
            arrowImgView.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(CL.itemSpace)
                make.width.equalTo(arrowImgView.frame.width)
                make.centerY.equalToSuperview()
                make.size.equalTo(arrowImgView.frame.size)
            }
            rightConstraint = arrowImgView.snp.left
        }

        titleLabel.text = self.data?.title ?? ""
        
        let subtitle: String = self.data?.subtitle ?? ""
        let tag: String = self.data?.tag ?? ""

        if !subtitle.isEmpty || !tag.isEmpty {
            if data?.status == .forbidden, let buttonInfo = self.data?.buttonInfo {
                contentView.addSubview(self.actionLabel)
                actionLabel.snp.makeConstraints { (make) in
                    make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(CL.itemSpace)
                    make.right.equalToSuperview().inset(CL.itemSpace)
                    make.centerY.equalToSuperview()
                }
                rightConstraint = actionLabel.snp.left
                actionLabel.isHidden = false
                actionLabel.text = buttonInfo.text
            }
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalTo(iconView.snp.right).offset(CL.itemSpace).priority(.required)
                make.top.equalTo(iconView.snp.top).priority(.required)
                make.height.equalTo(Layout.titleLabelHeight).priority(.required)
                make.right.lessThanOrEqualTo(rightConstraint).offset(-CL.itemSpace).priority(.required)
            }
            if !subtitle.isEmpty {
                subtitleLabel.text = subtitle
                contentView.addSubview(self.subtitleLabel)
                subtitleLabel.snp.makeConstraints { (make) in
                    make.left.equalTo(titleLabel.snp.left).priority(.required)
                    make.bottom.equalTo(iconView.snp.bottom).priority(.required)
                    make.height.equalTo(Layout.minSubtitleHeight).priority(.required)
                    make.right.lessThanOrEqualTo(rightConstraint).offset(-CL.itemSpace).priority(.required)
                }
                leftConstraint = subtitleLabel.snp.right
            }
            

            let status = self.data?.status
            if !tag.isEmpty {
                contentView.addSubview(self.tagLabel)
                tagLabel.snp.makeConstraints { (make) in
                    make.left.equalTo(leftConstraint).offset(Layout.disableLabelLeft)
                    make.centerY.equalTo(subtitleLabel)
                    make.right.lessThanOrEqualTo(rightConstraint).offset(-CL.itemSpace).priority(.required)
                }
                tagLabel.text = tag
                switch status {
                case .enable:
                    tagLabel.setStyle(.blue)
                case .forbidden:
                    tagLabel.setStyle(.red)
                case .freeze:
                    tagLabel.setStyle(.gray)
                case .unactivated:
                    tagLabel.setStyle(.blue)
                case .unauthorized:
                    tagLabel.setStyle(.gray)
                case .reviewing:
                    tagLabel.setStyle(.purple)
                default:
                    tagLabel.setStyle(.blue)
                }
            } else {
                tagLabel.text = nil
                tagLabel.isHidden = true
            }

        } else {
            self.actionLabel.removeFromSuperview()
            self.subtitleLabel.removeFromSuperview()
            self.tagLabel.removeFromSuperview()
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = .byWordWrapping
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalTo(iconView.snp.right).offset(CL.itemSpace).priority(.required)
                make.centerY.equalToSuperview().priority(.required)
                make.right.lessThanOrEqualTo(rightConstraint).offset(-CL.itemSpace).priority(.required)
            }
            self.subtitleLabel.removeFromSuperview()
        }

        updateSeparator()
    }
    
    private func updateSeparator() {
        if splitLineView.superview != nil {
            splitLineView.snp.removeConstraints()
            splitLineView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(0.5)
                make.left.equalTo(isLastRow ? 0 : iconView.snp.left)
                make.right.equalToSuperview()
            }
        }
    }

    func setImage(urlString: String?, image: UIImage?) {
        if let str = urlString, let url = URL(string: str) {
            self.iconView.kf.setImage(with: url,
                                             placeholder: Resource.V3.default_avatar)
        } else {
            self.iconView.image = image ?? Resource.V3.default_avatar
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelection(_ selected: Bool) {
        self.contentView.backgroundColor = selected ? .cellHighlightBackgroundColor : .cellNormalBackgroundColor
    }
}

extension UserOperationCenterCell {
    struct Layout {
        static let verticalSpace: CGFloat = 12.0
        static let titleLabelHeight: CGFloat = 24.0
        static let minSubtitleHeight: CGFloat = 18.0
        static let iconImageDiameter: CGFloat = 42.0
        static let cellHeight: CGFloat = 68.0
        static let multiIconSpace: CGFloat = 2.0
        static let disableLabelLeft: CGFloat = 4
    }
}
