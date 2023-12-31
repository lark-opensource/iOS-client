//
//  WorkPlaceLongPressMenuView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/7/22.
//

import LarkUIKit
import UIKit
import FigmaKit
import LKCommonsLogging

/// 菜单弹窗的箭头（支持传入frame指定箭头大小和定位）
final class MenuArrow: UIView {
    var fillColor: UIColor = UIColor.ud.bgFloat // 支持外部指定箭头颜色
    private var arrowWidth: CGFloat = 0
    private var arrowHeight: CGFloat = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.arrowWidth = self.frame.width
        self.arrowHeight = self.frame.height
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {    // 画成菱形的原因：箭头有可能朝上/朝下
        if let ctx: CGContext = UIGraphicsGetCurrentContext() {
            ctx.clear(rect)
            ctx.move(to: CGPoint(x: arrowWidth / 2, y: 0))
            ctx.addLine(to: CGPoint(x: arrowWidth, y: arrowHeight / 2))
            ctx.addLine(to: CGPoint(x: arrowWidth / 2, y: arrowHeight))
            ctx.addLine(to: CGPoint(x: 0, y: arrowHeight / 2))
            ctx.closePath()
            ctx.setFillColor(fillColor.cgColor)
            ctx.drawPath(using: .fill)
        }
        super.draw(rect)
    }
}

/// 菜单弹窗的蒙层背景（需要穿透蒙层，展示选中视图）
final class MenuMaskView: UIView {
    /// 要穿透的选中视图的rect
    var maskFrame: TargetItemInfo
    /// 附属装饰视图
    var extraViews: [UIView]
    /// 父视图的rect
    var parentFrame: CGRect
    /// 蒙层颜色
    var fillColor: UIColor = UIColor.ud.bgMask
    init(frame: CGRect, maskFrame: TargetItemInfo, extraViews: [UIView], parentFrame: CGRect) {
        self.maskFrame = maskFrame
        self.parentFrame = parentFrame
        self.extraViews = extraViews
        super.init(frame: frame)
        for view in extraViews {
            addSubview(view)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {    // 抠一个穿透指向目标的洞子（Dig a hole to penetrate the target）
        if let ctx: CGContext = UIGraphicsGetCurrentContext() {
            let targetPath: CGPath
            if maskFrame.useSmoothCorner {
                let path = UIBezierPath.squircle(forRect: maskFrame.maskRect, cornerRadius: maskFrame.maskRedius)
                if path.bounds.origin.equalTo(.zero) {
                    path.apply(
                        CGAffineTransform(
                            translationX: maskFrame.maskRect.origin.x,
                            y: maskFrame.maskRect.origin.y
                        )
                    )
                }
                targetPath = path.cgPath
            } else {
                targetPath = UIBezierPath(roundedRect: maskFrame.maskRect, cornerRadius: maskFrame.maskRedius).cgPath
            }
            ctx.addPath(targetPath)
            ctx.addPath(UIBezierPath(rect: parentFrame).cgPath)
            ctx.setFillColor(fillColor.cgColor)
            ctx.fillPath(using: .evenOdd)
        }
        super.draw(rect)
    }
}

/// 穿透蒙层高亮显示的item信息
struct TargetItemInfo {
    /// 穿透蒙层展示的CGRect
    let maskRect: CGRect
    /// 穿透蒙层展示的圆角值
    let maskRedius: CGFloat
    /// 是否使用扁平化圆角
    let useSmoothCorner: Bool
}

/// 菜单操作选项视图
final class MenuOptionActView: UIView {
    /// 内容边距
    static let edgeSpace: CGFloat = 16
    /// 选项图标大小
    static let imgEdge: CGFloat = 20
    /// 图标和文案的间距
    static let imgTextSpace: CGFloat = 12
    /// 字体
    // swiftlint:disable init_font_with_token
    static let textFont: UIFont = UIFont.systemFont(ofSize: 16)
    // swiftlint:enable init_font_with_token
    /// 菜单可操作选项高度
    static let menuActionHeight: CGFloat = 50.0
    /// 选项图标
    private lazy var imgView = { UIImageView() }()
    /// 选项文案
    private lazy var labelView: UILabel = {
        let label = UILabel()
        label.font = MenuOptionActView.textFont
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    private var disableHighlight = true

    /// 点击事件
    private var tapAction: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTapEvent()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupTapEvent() {
        let tapGestureRcg = UITapGestureRecognizer(target: self, action: #selector(handleTapAction))
        self.addGestureRecognizer(tapGestureRcg)
    }
    @objc
    private func handleTapAction() {
        tapAction?()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard !disableHighlight else {
            return
        }
        backgroundColor = UIColor.ud.fillHover
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard !disableHighlight else {
            return
        }
        backgroundColor = UIColor.clear
    }

    private func setupViews() {
        self.addSubview(imgView)
        self.addSubview(labelView)
        setConstraints()
    }
    private func setConstraints() {
        imgView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: MenuOptionActView.imgEdge, height: MenuOptionActView.imgEdge))
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(MenuOptionActView.edgeSpace)
        }
        labelView.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.left.equalTo(imgView.snp.right).offset(MenuOptionActView.imgTextSpace)
            make.right.lessThanOrEqualToSuperview().offset(-MenuOptionActView.imgTextSpace)
        }
    }
    /// 配置菜单选项的内容
    /// - Parameters:
    ///   - tipImg: 提示图标
    ///   - text: 提示文案
    ///   - isEnable: 是否是可用样式
    func setMenuOption(tipImg: UIImage, text: String, isEnable: Bool) {
        let imgColor = isEnable ? UIColor.ud.iconN2 : UIColor.ud.textDisabled
        let textColor = isEnable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        imgView.image = tipImg.ud.withTintColor(imgColor)
        labelView.text = text
        labelView.textColor = textColor
        disableHighlight = !isEnable
    }
    /// 配置菜单选项的点击事件
    /// - Parameter block: 点击事件
    func setTapEvent(block: @escaping () -> Void) {
        self.tapAction = block
    }
    /// 获取视图非动态部分的横向空间
    static func getSolidHorizontalSpace() -> CGFloat {
        return MenuOptionActView.edgeSpace * 2 + MenuOptionActView.imgEdge + MenuOptionActView.imgTextSpace
    }
}

/// 菜单配置信息
struct MenuConfig {
    /// 是否需要箭头
    var isDisplayArrow: Bool
    /// 菜单展示模式
    var displayMode: MenuDisplayMode
    /// 菜单配置选项
    var options: [MenuOptionSetting]
    /// 菜单底部提示语
    var footerTip: String?
    /// 菜单消失时的回调
    var dismissCallback: (() -> Void)?
}

/// 菜单选项
struct MenuOptionSetting {
    /// 是否是可用样式
    var isEnableStyle: Bool
    /// 选项/提示文案
    var text: String
    /// 选项图标
    var img: UIImage
    /// 选项点击事件
    var block: (() -> Void)
}

/// 菜单展示模式
enum MenuDisplayMode: String {
    /// 右对齐展示，无需展示箭头
    case rightAlign
    /// 瞄准cell中心点展示
    case target
}

/// 菜单视图
final class WorkPlaceLongPressMenuView: UIView {
    static let logger = Logger.log(WorkPlaceLongPressMenuView.self)

    /// 要挂载依赖的父view
    private var parentViewRect: CGRect
    /// 穿透蒙层的高亮目标
    private var targetItemInfo: TargetItemInfo
    /// 附属装饰视图（case：BOT-Tag）
    var extraViews: [UIView]
    /// 菜单设置
    private var menuConfig: MenuConfig
    /// 引导视图主体大小
    private var menuContainerRect: CGRect = .zero
    // MARK: 弹窗菜单样式参数
    /// 菜单宽度
    private var menuWidth: CGFloat = 170
    private let menuMinWidth: CGFloat = 140
    private let menuMaxWidth: CGFloat = 260
    /// 菜单高度
    private var menuHeight: CGFloat = 0
    /// 菜单提示文案项高度
    private var menuTipHeight: CGFloat = 0
    /// 菜单分割线高度
//    private let menuDividerHeight: CGFloat = 0.6
    /// 菜单距离屏幕最小间距
    private let screenSafeSpace: CGFloat = 16.0
    /// 浮窗的圆角半径
    private let menuCornerRadius: CGFloat = 8.0
    /// 菜单选项容器
    private lazy var menuContainer: UIStackView = {
        let container = UIStackView(frame: .zero)
        container.axis = .vertical
        return container
    }()
    /// menu视图
    private lazy var menuView: UIView = {
        let menu = UIView(frame: menuContainerRect)
        menu.backgroundColor = UIColor.ud.bgFloat
        menu.layer.cornerRadius = menuCornerRadius
        menu.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        menu.layer.borderWidth = WPUIConst.BorderW.pt0_5
        return menu
    }()
    // MARK: 弹窗箭头参数
    // 箭头样式相关
    /// 箭头指向目标的纵向间距
    private let arrowMargin: CGFloat = 8
    /// 箭头高度
    private let arrowHeight: CGFloat = 8
    /// 箭头宽度
    private let arrowWidth: CGFloat = 17
    /// 箭头视图
    private lazy var menuArrow: MenuArrow = {
        let arrowUpY = targetItemInfo.maskRect.maxY + arrowMargin
        let arrowDownY = targetItemInfo.maskRect.minY - arrowMargin - arrowHeight * 2
        let rect = CGRect(
            x: self.targetItemInfo.maskRect.midX - arrowWidth / 2,
            y: isArrowTargetUp() ? arrowUpY : arrowDownY,
            width: arrowWidth,
            height: arrowHeight * 2
        )  // 真实的高度其实两个箭头组成菱形的高度
        let arrow = MenuArrow(frame: rect)
        arrow.fillColor = UIColor.ud.bgFloat
        return arrow
    }()
    /// 蒙层背景
    private lazy var backgroundView: MenuMaskView = {
        let background = MenuMaskView(
            frame: .zero,
            maskFrame: targetItemInfo,
            extraViews: extraViews,
            parentFrame: parentViewRect
        )
        background.backgroundColor = .clear
        background.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        background.addGestureRecognizer(tapGestureRecognizer)
        return background
    }()

    init(
        parentViewRect: CGRect,
        mainMaskFrame: TargetItemInfo,
        extraViews: [UIView] = [],
        menuConfig: MenuConfig
    ) {
        // 保存成员变量
        self.parentViewRect = parentViewRect
        self.targetItemInfo = mainMaskFrame
        self.extraViews = extraViews
        self.menuConfig = menuConfig
        super.init(frame: parentViewRect)
        // 计算&加载视图
        generateMenuRect()
        setupViews()
    }
    /// 获取长按菜单内容view
    func getMenuContentView() -> UIView {
        return self.menuContainer
    }
    /// 获取长按菜单内容Size
    func getMenuSize() -> CGSize {
        return CGSize(width: self.menuWidth, height: self.menuHeight)
    }
    /// 生成menu的size，结果保存到成员变量 - menuContainerRect
    private func generateMenuRect() {
        /// 计算menu的高宽
        let menuSize = menuSizeCalculate()
        self.menuHeight = menuSize.height
        self.menuWidth = menuSize.width
        /// 计算menu的origin
        // swiftlint:disable identifier_name
        var x: CGFloat = 0
        var y: CGFloat = 0
        // swiftlint:enable identifier_name
        let maskMidX = targetItemInfo.maskRect.midX
        let maskMaxX = targetItemInfo.maskRect.maxX
        let maskMaxY = targetItemInfo.maskRect.maxY
        let maskMinY = targetItemInfo.maskRect.minY

        switch menuConfig.displayMode {
        case .target:
            let arrowUpY = maskMaxY + arrowHeight + arrowMargin
            let arrowDownY = maskMinY - arrowHeight - arrowMargin - menuHeight
            y = isArrowTargetUp() ? arrowUpY : arrowDownY
            let originX = maskMidX - menuWidth / 2 // 和目标中心对齐
            if originX < screenSafeSpace {  // 屏幕安全边距适配
                x = screenSafeSpace
            } else if originX + menuWidth > (parentViewRect.width - screenSafeSpace) {
                x = parentViewRect.width - screenSafeSpace - menuWidth
            } else {
                x = originX
            }
        case .rightAlign:
            y = isArrowTargetUp() ? maskMaxY + arrowHeight : maskMinY - arrowHeight - menuHeight
            x = maskMaxX - menuWidth  // 和目标右对齐
        }
        menuContainerRect = CGRect(x: x, y: y, width: menuWidth, height: menuHeight)
    }
    /// 布局约束
    private func setupLayout() {
        menuContainer.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(self.menuCornerRadius)
        }
    }
    private func setupViews() {
        addSubview(backgroundView)
        self.isUserInteractionEnabled = true
        backgroundView.frame = parentViewRect
        backgroundView.addSubview(menuView)
        menuView.addSubview(menuContainer)
        setupMenuOptions()
        if menuConfig.isDisplayArrow {
            backgroundView.addSubview(menuArrow)
        }
        setupLayout()
        setNeedsLayout()
    }
    /// 判断menu箭头是否朝上（即menu在target下方展示）
    private func isArrowTargetUp() -> Bool {
        return targetItemInfo.maskRect.centerY < parentViewRect.height / 2
    }

    /// 菜单大小计算
    private func menuSizeCalculate() -> CGSize {
        // 适配最长宽度
        var maxWidth = menuMinWidth
        var itemsHeight: CGFloat = 0
        for option in menuConfig.options {
            let text = option.text
            let optionWidth = getTextSize(
                text: text,
                font: MenuOptionActView.textFont
            ).width + MenuOptionActView.getSolidHorizontalSpace()
            maxWidth = max(maxWidth, optionWidth)
            itemsHeight += MenuOptionActView.menuActionHeight
        }
        // 上下圆角加上安全边距
        itemsHeight += (2 * menuCornerRadius)
        let menuSize = CGSize(width: min(maxWidth, menuMaxWidth), height: itemsHeight)
//        let menuDeviderCount: CGFloat = CGFloat(menuConfig.options.count - 1)
        return CGSize(width: menuSize.width, height: menuSize.height)
//        return CGSize(width: menuSize.width, height: menuSize.height + menuDeviderCount * menuDividerHeight)
    }

    /// 加载菜单选项
    private func setupMenuOptions() {
        var optionSum = 0
        var menuY: CGFloat = 0
        for option in menuConfig.options {  // 可操作的菜单选项
            // 生成可操作选项视图
            let actionOptionView = MenuOptionActView(frame: CGRect(
                x: menuContainer.frame.minX,
                y: menuContainer.frame.minY + menuY,
                width: menuWidth,
                height: MenuOptionActView.menuActionHeight
            ))
            actionOptionView.setMenuOption(tipImg: option.img, text: option.text, isEnable: option.isEnableStyle)
            actionOptionView.setTapEvent { [weak self] in
                option.block()
                self?.dismiss()
            }
            // 将可操作选项视图加入菜单容器
            menuContainer.addArrangedSubview(actionOptionView)
            actionOptionView.addInteraction(type: .hover)
            actionOptionView.snp.makeConstraints { (make) in
                make.height.equalTo(MenuOptionActView.menuActionHeight)
            }
            menuY += MenuOptionActView.menuActionHeight
            optionSum += 1
        }
    }

    @objc
    func dismiss() {
        Self.logger.info("longPress menu dismiss")
        backgroundView.removeFromSuperview()
        self.removeFromSuperview()
        menuConfig.dismissCallback?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 获取文案宽度
    /// - Parameters:
    ///   - text: 文案
    ///   - font: 字体
    private func getTextSize(text: String, font: UIFont) -> CGSize {
        let string: NSString = text as NSString
        return string.size(withAttributes: [.font: font])
    }
}
