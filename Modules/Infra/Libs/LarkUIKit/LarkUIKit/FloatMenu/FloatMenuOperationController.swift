//
//  FloatMenuOperationController.swift
//  LarkUIKit
//
//  Created by zhaojiachen on 2023/7/25.
//

import UIKit
import Foundation
import SnapKit
import FigmaKit
import UniverseDesignShadow

public struct FloatMenuItemInfo {
    let icon: UIImage
    let title: String
    let acionFunc: () -> Void

    public init(icon: UIImage, title: String, acionFunc: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.acionFunc = acionFunc
    }
}

public final class FloatMenuOperationController: BaseUIViewController {
    public struct Notification {
        public static let PopOverMenuWillShow: NSNotification.Name = NSNotification.Name("lark.monent.popoverMenu.will.show")
        public static let PopOverMenuDidHide: NSNotification.Name = NSNotification.Name("lark.monent.popoverMenu.did.hide")
    }

    private let backgroundColor: UIColor
    private let bgView: UIView = UIView()
    private let menuView: MenuOperationView
    private let pointView: UIView

    public var animationBegin: (() -> Void)?
    public var animationEnd: (() -> Void)?

    public init(pointView: UIView,
                bgMaskColor: UIColor,
                menuShadowType: UDShadowType?,
                items: [FloatMenuItemInfo]) {
        self.pointView = pointView
        self.backgroundColor = bgMaskColor
        self.menuView = MenuOperationView(menuShadowType: menuShadowType)
        super.init(nibName: nil, bundle: nil)
        self.menuView.setupActionsViews(menuItems: items) { [weak self] (item) in
            self?.hide(completion: item.acionFunc)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(
            name: FloatMenuOperationController.Notification.PopOverMenuWillShow,
            object: self,
            userInfo: nil
        )
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        bgView.isUserInteractionEnabled = true
        view.addSubview(bgView)
        bgView.backgroundColor = self.backgroundColor
        bgView.alpha = 0
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedHandler))
        self.bgView.addGestureRecognizer(tap)

        menuView.frame = originRectOfPointView()
        view.addSubview(menuView)
        menuView.scaleAnimationView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        menuView.alpha = 0
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.animationBegin?()

        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.menuView.frame = self.showRectOfMenuView()
            self.menuView.scaleAnimationView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.menuView.alpha = 1
            self.bgView.alpha = 1
        })
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 转屏时隐藏菜单
        self.hide()
    }

    @objc
    private func tappedHandler() {
        self.hide()
    }

    private func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            self.menuView.frame = self.originRectOfPointView()
            self.menuView.scaleAnimationView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.menuView.alpha = 0
            self.view.layoutIfNeeded()
            self.bgView.alpha = 0
        }, completion: { ( _ ) in
            self.animationEnd?()
            self.dismiss(animated: false, completion: {
                completion?()
                NotificationCenter.default.post(
                    name: FloatMenuOperationController.Notification.PopOverMenuDidHide,
                    object: self,
                    userInfo: nil
                )
            })
        })
    }

    private func originRectOfPointView() -> CGRect {
        guard let superView = pointView.superview else {
            return .zero
        }

        let rect = superView.convert(pointView.frame, to: superView.window)

        return rect
    }

    private func showRectOfMenuView() -> CGRect {
        let naviBarMaxY = CGFloat((Display.iPhoneXSeries ? 44 : 20) + 44)

        guard let superView = pointView.superview else {
            return .zero
        }

        let rect = superView.convert(pointView.frame, to: superView.window)
        var y = rect.minY - menuView.heightOfView
        // 如果覆盖到导航栏 则显示在下方
        if y < naviBarMaxY {
            if rect.maxY < naviBarMaxY {
                y = naviBarMaxY
            } else {
                y = rect.maxY
            }
        }

        let x = rect.maxX - menuView.widthOfView + 4
        return CGRect(x: x, y: y, width: menuView.widthOfView, height: menuView.heightOfView)
    }

}

private final class MenuOperationView: UIView {
    private(set) var heightOfView: CGFloat = 96
    private(set) var widthOfView: CGFloat = 0
    private var menuItems: [FloatMenuItemInfo] = []
    var scaleAnimationView = UIView()
    private var contentView = UIView()

    init(menuShadowType: UDShadowType?) {
        super.init(frame: .zero)

        let viewRadius: CGFloat = 12
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.cornerRadius = viewRadius
        if let menuShadowType = menuShadowType {
            self.layer.ud.setShadow(type: menuShadowType)
        }

        self.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.setupBlurEffectView()
        contentView.layer.cornerRadius = viewRadius
        contentView.clipsToBounds = true
        contentView.addSubview(scaleAnimationView)
        scaleAnimationView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func setupActionsViews(menuItems: [FloatMenuItemInfo], itemClick: ((FloatMenuItemInfo) -> Void)?) {
        self.menuItems = menuItems
        self.heightOfView = OperationItem.heightOfItem * CGFloat(menuItems.count)

        for (index, menuInfo) in self.menuItems.enumerated() {
            let menuItem = OperationItem(info: menuInfo, itemClick: itemClick)
            scaleAnimationView.addSubview(menuItem)
            menuItem.snp.makeConstraints({ (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(OperationItem.heightOfItem)
                make.top.equalToSuperview().offset(OperationItem.heightOfItem * CGFloat(index))
            })

            caluMaxWidth(title: menuInfo.title)
        }
    }

    private func caluMaxWidth(title: String) {
        let titleWidth = NSAttributedString(
            string: title,
            attributes: [
                .font: OperationItem.font
            ]
            ).boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: heightOfView),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).size.width.rounded(.up)

        let width = OperationItem.iconLeading + OperationItem.iconWidth + OperationItem.iconAndTitleSpacing + titleWidth + OperationItem.titleTrailing

        if widthOfView < width {
            widthOfView = width
        }
    }

    private func setupBlurEffectView() {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloatPush
        blurView.blurRadius = 40
        contentView.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class OperationItem: UIView {
    static let font = UIFont.systemFont(ofSize: 16)
    static let heightOfItem: CGFloat = 48
    static let iconLeading: CGFloat = 16
    static let iconWidth: CGFloat = 20
    static let iconAndTitleSpacing: CGFloat = 10
    static let titleTrailing: CGFloat = 20

    private let iconImage: UIImageView = UIImageView()
    private let label: UILabel = UILabel()
    private let button: UIButton = OperationItemButton()

    private let menuInfo: FloatMenuItemInfo
    private let itemClick: ((FloatMenuItemInfo) -> Void)?

    init(info: FloatMenuItemInfo, itemClick: ((FloatMenuItemInfo) -> Void)?) {
        self.menuInfo = info
        self.itemClick = itemClick
        super.init(frame: .zero)

        self.addSubview(iconImage)
        iconImage.image = info.icon.ud.withTintColor(UIColor.ud.iconN1)
        iconImage.contentMode = .scaleAspectFit
        iconImage.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iconImage.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        iconImage.snp.makeConstraints { (make) in
            make.left.equalTo(OperationItem.iconLeading)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: OperationItem.iconWidth, height: OperationItem.iconWidth))
        }

        self.addSubview(label)
        label.text = info.title
        label.font = OperationItem.font
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(iconImage.snp.right).offset(OperationItem.iconAndTitleSpacing)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-OperationItem.titleTrailing)
        }

        self.addSubview(button)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func clickButton() {
        self.itemClick?(menuInfo)
    }
    final class OperationItemButton: UIButton {
        private lazy var highLightView: UIView = {
            let highLightView = UIView()
            highLightView.backgroundColor = UIColor.ud.fillHover
            highLightView.layer.cornerRadius = 6.0
            highLightView.isHidden = true
            addSubview(highLightView)
            highLightView.snp.makeConstraints { (make) in
                make.top.left.equalToSuperview().offset(4)
                make.bottom.right.equalToSuperview().offset(-4)
                make.centerY.equalToSuperview()
            }
            return highLightView
        }()
        override var isHighlighted: Bool {
            didSet {
                highLightView.isHidden = !isHighlighted
            }
        }

    }
}

