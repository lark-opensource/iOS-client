// 
// Created by duanxiaochen.7 on 2020/3/29.
// Affiliated with DocsSDK.
// 
// Description:

import SKFoundation
import SKUIKit
import SKBrowser
import SKCommon
import SKResource
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor

public struct BTCapsuleUIConfiguration: Equatable {
    public struct AvatarConfiguration: Equatable {
        let avatarLeft: CGFloat
        let avatarSize: CGFloat
    }
    
    //行距
    public let rowSpacing: CGFloat
    //列距
    public let colSpacing: CGFloat
    //固定行高
    public let lineHeight: CGFloat
    //内边距
    public let textInsets: UIEdgeInsets
    //字体
    public let font: UIFont
    //背景
    public let backgroundColor: UIColor
    
    public let avatarConfig: AvatarConfiguration?

    public static let zero = BTCapsuleUIConfiguration(rowSpacing: 0, colSpacing: 0, lineHeight: 0, textInsets: .zero, font: .systemFont(ofSize: 14))

    public init(rowSpacing: CGFloat, colSpacing: CGFloat, lineHeight: CGFloat, textInsets: UIEdgeInsets, font: UIFont, backgroundColor: UIColor = UDColor.fillTag, avatarConfig: AvatarConfiguration? = nil) {
        self.rowSpacing = rowSpacing
        self.colSpacing = colSpacing
        self.lineHeight = lineHeight
        self.textInsets = textInsets
        self.font = font
        self.backgroundColor = backgroundColor
        self.avatarConfig = avatarConfig
    }
}

public protocol BTCapsuleCellDelegate: AnyObject {
    func btCapsuleCell(_ cell: BTCapsuleCell, didSingleTapTextContentof model: BTCapsuleModel)
    
    func btCapsuleCell(_ cell: BTCapsuleCell, didDoubleTapTextContentof model: BTCapsuleModel)
    
    
    func btCapsuleCell(_ cell: BTCapsuleCell, shouleApplyAction action: BTTextViewMenuAction) -> Bool
}


public class BTCapsuleCell: UICollectionViewCell {
    
    weak var delegate: BTCapsuleCellDelegate?
    
    var model: BTCapsuleModel?
    
    var config: BTCapsuleUIConfiguration? = nil
    
    lazy var contentTextView: BTTextView = {
        let textView = BTTextView()
        textView.textContainer.maximumNumberOfLines = 1
        textView.isEditable = false
        textView.textAlignment = .center
        textView.btDelegate = self
        textView.textContainer.lineBreakMode = .byTruncatingTail
        return textView
    }()
    
    lazy var _contentTextView: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        if UserScopeNoChangeFG.XM.nativeCardViewEnable {
            contentView.addSubview(_contentTextView)
        } else {
            contentView.addSubview(contentTextView)
        }
    }

    public func setupCell(_ selectModel: BTCapsuleModel, maxLength: CGFloat, layoutConfig: BTCapsuleUIConfiguration) {
        self.model = selectModel
        self.config = layoutConfig
        setupContentTextView(selectModel.text,
                             textColor: UIColor.docs.rgb(selectModel.color.textColor),
                             backgroudColor: UIColor.docs.rgb(selectModel.color.color),
                             maxLength: maxLength,
                             layoutConfig: layoutConfig)
    }
    
    func setupContentTextView(_ text: String,
                              textColor: UIColor,
                              backgroudColor: UIColor,
                              maxLength: CGFloat,
                              layoutConfig: BTCapsuleUIConfiguration) {
        let capsuleHeight = layoutConfig.lineHeight
        contentView.layer.cornerRadius = capsuleHeight / 2
        contentView.backgroundColor = backgroudColor
        if UserScopeNoChangeFG.XM.nativeCardViewEnable {
            _contentTextView.textColor = textColor
            _contentTextView.font = layoutConfig.font
            _contentTextView.text = text
        } else {
            contentTextView.textColor = textColor
            contentTextView.font = layoutConfig.font
            contentTextView.text = text
        }
        let labelWidth = ceil(_contentTextView.intrinsicContentSize.width)
        let insets = layoutConfig.textInsets
        if UserScopeNoChangeFG.XM.nativeCardViewEnable {
            _contentTextView.snp.makeConstraints { make in
                make.left.greaterThanOrEqualToSuperview().inset(insets.left)
                make.right.lessThanOrEqualToSuperview().inset(insets.right)
    //            make.width.equalTo(labelWidth)
                make.centerY.equalToSuperview()
            }
        } else {
            contentTextView.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(insets.left)
                make.right.equalToSuperview().inset(insets.right)
                make.width.equalTo(labelWidth)
                make.centerY.equalToSuperview()
            }
        }
        contentView.heightAnchor.constraint(equalToConstant: layoutConfig.lineHeight).isActive = true
        let equalConstraint = contentView.widthAnchor.constraint(equalToConstant: insets.left + labelWidth + insets.right)
        equalConstraint.priority = .required - 1
        equalConstraint.isActive = true
        contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: layoutConfig.lineHeight).isActive = true
        contentView.widthAnchor.constraint(lessThanOrEqualToConstant: maxLength).isActive = true
    }
}

extension BTCapsuleCell: BTSingleContainerItemProtocol {
    func itemWidth() -> CGFloat {
        guard let layoutConfig = config else { return 0 }
        BTCollectionViewWaterfallHelper.label.font = layoutConfig.font
        BTCollectionViewWaterfallHelper.label.text = model?.text
        let labelWidth = ceil(BTCollectionViewWaterfallHelper.label.intrinsicContentSize.width)
        let calcuWidth = layoutConfig.textInsets.left +
        labelWidth +
        layoutConfig.textInsets.right
        let minWidth = layoutConfig.lineHeight
        return max(calcuWidth, minWidth)
    }
}

extension BTCapsuleCell: BTTextViewDelegate {
    func btTextViewDidScroll(toBounce: Bool) {}
    
    func btTextView(_ textView: BTTextView, didDoubleTapped sender: UITapGestureRecognizer) {
        guard let model = self.model else {
            return
        }
        delegate?.btCapsuleCell(self, didDoubleTapTextContentof: model)
    }
    
    func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        guard let model = self.model else {
            return
        }
        delegate?.btCapsuleCell(self, didSingleTapTextContentof: model)
    }
    
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool {
        return delegate?.btCapsuleCell(self, shouleApplyAction: action) ?? false
    }
}

public final class BTCapsuleCellWithAvatar: BTCapsuleCell {

    let avatarView: UIImageView = {
        let avatarView = SKAvatar(configuration: .init(style: .circle, contentMode: .scaleAspectFit))
        return avatarView
    }()

    public override func setupUI() {
        if UserScopeNoChangeFG.XM.nativeCardViewEnable {
            contentView.addSubview(_contentTextView)
        } else {
            contentView.addSubview(contentTextView)
        }
        contentView.addSubview(avatarView)

        avatarView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview().inset(4)
            $0.width.height.equalTo(20)
        }
    }

    override public func setupCell(_ selectModel: BTCapsuleModel, maxLength: CGFloat, layoutConfig: BTCapsuleUIConfiguration) {
        self.model = selectModel
        self.config = layoutConfig
        let capsuleHeight = layoutConfig.lineHeight
        avatarView.kf.setImage(with: URL(string: selectModel.avatarUrl),
                               placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        avatarView.layer.cornerRadius = (capsuleHeight - 8) / 2
        avatarView.snp.updateConstraints {
            $0.width.height.equalTo(capsuleHeight - 8)
        }
        if let config = layoutConfig.avatarConfig {
            avatarView.layer.cornerRadius = config.avatarSize * 0.5
            avatarView.snp.remakeConstraints { make in
                make.width.height.equalTo(config.avatarSize)
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().inset(config.avatarLeft)
            }
        }
        avatarView.clipsToBounds = true
        let text: String
        switch DocsSDK.currentLanguage {
        case .en_US:
            text = selectModel.enName
        default:
            text = selectModel.text
        }
        setupContentTextView(text,
                             textColor: UDColor.textTitle,
                             backgroudColor: layoutConfig.backgroundColor,
                             maxLength: maxLength,
                             layoutConfig: layoutConfig)
    }
}
