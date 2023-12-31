//
// Created by zoujie.andy on 2022/12/13.
// Affiliated with SKUIKit.
//
// Description:

import Foundation
import SnapKit
import SKResource
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignBadge
import SKFoundation
import UIKit

public enum OperationItemDisableReason: Int {
    case other = 0 //other
    case fg = 1 //FG Close
    case cantRead = 2 // 对部分字段无权限阅读
    case syncFromOtherBase = 3 //从其它数据源同步，不支持操作
    case noPermission = 4
}

public protocol SKOperationItem {
    var identifier: String { get }
    var title: String? { get }
    var titleFont: UIFont? { get }
    var titleAlignment: NSTextAlignment? { get }
    var isEnable: Bool { get }
    var disableReason: OperationItemDisableReason { get }
    var adminLimit: Bool { get }
    var hasSubItem: Bool { get }
    var insertList: [SKOperationItem]? { get }
    var shouldShowRedPoint: Bool { get }
    var shouldShowWarningIcon: Bool { get }
    var shouldShowRedBadge: Bool {get}
    var image: UIImage? { get }
    var imageNoTint: Bool { get }   // 不要自动着色，彩色图标场景使用
    var imageSize: CGSize? { get }
    var customView: UIView? { get }
    var customViewHeight: CGFloat? { get }
    var customViewLayoutCompleted: () -> Void { get }
    var background: (normal: UIColor, highlighted: UIColor)? { get }
    var clickHandler: (() -> Void)? { get }
}

public struct SKOperationBaseItem: SKOperationItem {
    public var identifier: String = ""
    public var title: String?
    public var titleFont: UIFont?
    public var titleAlignment: NSTextAlignment?
    public var isEnable: Bool = true
    public var disableReason: OperationItemDisableReason = .other
    public var adminLimit: Bool = false
    public var hasSubItem: Bool = false
    public var insertList: [SKOperationItem]?
    public var shouldShowRedPoint: Bool = false
    public var shouldShowWarningIcon: Bool = false
    public var shouldShowRedBadge: Bool = false
    public var image: UIImage?
    public var imageNoTint: Bool = false
    public var imageSize: CGSize?
    public var customView: UIView?
    public var customViewHeight: CGFloat?
    public var customViewLayoutCompleted: () -> Void = {}
    public var background: (normal: UIColor, highlighted: UIColor)?
    public var clickHandler: (() -> Void)?
    
    public init() {}
}

public final class SKOperationCell: UICollectionViewCell {

    private enum Const {
        static var textColor: UIColor { UDColor.textTitle }
        static var disableTextColor: UIColor { UDColor.textDisabled }

        static var iconColor: UIColor { UDColor.iconN1 }
        static var disableIconColor: UIColor { UDColor.iconDisabled }

        static var arrowColor: UIColor { UDColor.textPlaceholder }
        static var disableArrowColor: UIColor { UDColor.iconDisabled }

        static var backgroundColor: UIColor { UDColor.bgBodyOverlay }
        static var popoverBackgroundColor: UIColor { UDColor.bgFloatOverlay }
        static var highlightBackgroundColor: UIColor { UDColor.fillPressed }
    }

    override public var isHighlighted: Bool {
        didSet {
            updateContenViewBgColor()
        }
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = Const.backgroundColor
        view.layer.cornerRadius = 8
        return view
    }()
    
    var isInPopover: Bool = false

    var roundingCorners: CACornerMask {
        get {
            containerView.layer.maskedCorners
        }
        set {
            containerView.layer.maskedCorners = newValue
        }
    }

    private var displayIcon: Bool = true
    private var isEnabled: Bool = true
    private var labelLeftConstraintToEdge: Constraint?
    private var labelLeftConstraintToIcon: Constraint?
    private var labelRightConstraintToArrow: Constraint?
    private var labelRightConstraintToEdge: Constraint?
    private var background: (normal: UIColor, highlighted: UIColor)?

    public var buttonIdentifier: String = ""
    let disposeBag = DisposeBag()
    
    private lazy var iconView = UIImageView()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        return label
    }()

    var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private lazy var arrowView = UIImageView()

    lazy var redPoint: SKOperationGuideView = {
        let view = SKOperationGuideView(frame: .zero)
        view.isHidden = false
        return view
    }()

    private let warningIcon = UIImageView().construct { it in
        it.isHidden = true
        it.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 18, height: 18))
    }
    
    private lazy var badgeView : UDBadge = {
        let badge = UDBadge(config: .text)
        return badge
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        containerView.addSubview(iconView)
        containerView.addSubview(label)
        label.addSubview(redPoint)
        containerView.addSubview(arrowView)
        containerView.addSubview(lineView)
        containerView.addSubview(warningIcon)
        containerView.addSubview(badgeView)

        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }

        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            labelLeftConstraintToEdge = make.left.equalToSuperview().offset(16).constraint
            labelLeftConstraintToIcon = make.left.equalTo(iconView.snp.right).offset(12).constraint
            labelRightConstraintToEdge = make.right.equalToSuperview().offset(-16).constraint
            labelRightConstraintToArrow = make.right.lessThanOrEqualTo(warningIcon.snp.left).offset(-12).constraint
        }
        labelLeftConstraintToEdge?.deactivate()
        labelRightConstraintToEdge?.deactivate()

        arrowView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }

        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        redPoint.snp.makeConstraints { (make) in
            make.width.height.equalTo(8)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(16)
        }

        warningIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(0)
            make.centerY.equalToSuperview()
            make.right.equalTo(arrowView.snp.left).offset(-4)
        }
        
        badgeView.snp.makeConstraints { (make) in
            make.right.equalTo(label.snp.right).offset(-10)
            make.centerY.equalTo(label)
        }
        
        updateContenViewBgColor()
        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }
    
    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.containerView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
            case .ended, .cancelled:
                self.updateContenViewBgColor()
            default:
                break
            }
        }).disposed(by: disposeBag)
        containerView.addGestureRecognizer(gesture)
    }

    private func updateContenViewBgColor() {
        guard isEnabled else {
            containerView.backgroundColor = isInPopover ? Const.popoverBackgroundColor : Const.backgroundColor
            return
        }
        if let background = background {
            containerView.backgroundColor = isHighlighted ? background.highlighted : background.normal
        } else {
            containerView.backgroundColor = isHighlighted ?
                Const.highlightBackgroundColor :
                (isInPopover ? Const.popoverBackgroundColor : Const.backgroundColor)
        }
    }

    func updateDisplayIcon(display: Bool) {
        guard displayIcon != display else { return }
        displayIcon = display
        if display {
            iconView.isHidden = false
            labelLeftConstraintToEdge?.deactivate()
            labelLeftConstraintToIcon?.activate()
        } else {
            iconView.isHidden = true
            labelLeftConstraintToEdge?.activate()
            labelLeftConstraintToIcon?.deactivate()
        }
    }

    func configBy(_ info: SKOperationItem) {
        isEnabled = info.isEnable
        background = info.background
        buttonIdentifier = info.identifier
        label.text = info.title
        if let background = background {
            containerView.backgroundColor = isHighlighted ? background.highlighted : background.normal
        } else {
            containerView.backgroundColor = isInPopover ? Const.popoverBackgroundColor : Const.backgroundColor
        }
        arrowView.image = UDIcon.rightOutlined.ud.withTintColor(isEnabled ? Const.arrowColor : Const.disableArrowColor)
        if info.hasSubItem {
            arrowView.isHidden = false
            labelRightConstraintToArrow?.activate()
            labelRightConstraintToEdge?.deactivate()
        } else {
            arrowView.isHidden = true
            labelRightConstraintToArrow?.deactivate()
            labelRightConstraintToEdge?.activate()
        }
        let iconTintColor: UIColor
        if info.adminLimit {
            label.textColor = Const.disableTextColor
            iconTintColor = Const.disableIconColor
        } else {
            label.textColor = isEnabled ? Const.textColor : Const.disableTextColor
            iconTintColor = isEnabled ? Const.iconColor : Const.disableIconColor
        }

        if info.shouldShowWarningIcon {
            warningIcon.isHidden = false
            warningIcon.snp.updateConstraints { (make) in
                make.width.height.equalTo(18)
                make.right.equalTo(arrowView.snp.left).offset(info.hasSubItem ? -4 : 20)
            }
        } else {
            warningIcon.isHidden = true
            warningIcon.snp.updateConstraints { (make) in
                make.width.height.equalTo(0)
                make.right.equalTo(arrowView.snp.left).offset(0)
            }
        }

        iconView.image = info.imageNoTint ? info.image : info.image?.ud.withTintColor(iconTintColor)
        isAccessibilityElement = true
        accessibilityIdentifier = "skuikit.toolkit.\(buttonIdentifier)"
        accessibilityLabel = "skuikit.toolkit.\(buttonIdentifier)"
        contentView.docs.removeAllPointer()
        
        iconView.snp.updateConstraints { (make) in
            make.size.equalTo(info.imageSize ?? CGSize(width: 20, height: 20))
        }
        
        label.font = info.titleFont ?? UIFont.systemFont(ofSize: 16)
        label.textAlignment = info.titleAlignment ?? .left
        if info.titleAlignment == .center {
            // 文本居中对齐则强制不显示 icon
            updateDisplayIcon(display: false)
        }
        
        let attributes = [ NSAttributedString.Key.font: label.font ]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        var leftOffset:CGFloat = 0
        if let title = info.title {
            let size = (title as NSString).boundingRect(with: CGSize(width: bounds.width, height: 100), options: option, attributes: attributes, context: nil).size
            leftOffset = size.width + 10
        }
        badgeView.config.text = info.shouldShowRedBadge == true ? BundleI18n.SKResource.Bitable_Common_NewStatus : ""
        badgeView.snp.remakeConstraints { (make) in
            make.left.equalTo(label.snp.left).offset(leftOffset)
            make.centerY.equalTo(label)
        }
        badgeView.isHidden = !info.shouldShowRedBadge
    }
}

class SKOperationGuideView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 4
        backgroundColor = UIColor.ud.colorfulRed
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
