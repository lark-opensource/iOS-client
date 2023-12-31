//
//  WPActionMenuView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/7/12.
//

import LarkUIKit
import LKCommonsLogging

/// 穿透蒙层高亮显示的item信息
struct WPMaskItemInfo {
    /// 穿透蒙层展示的CGRect
    let maskRect: CGRect
    /// 穿透蒙层展示的圆角值
    let maskRedius: CGFloat
}

enum TitleLayoutType: String {
    /// 标题在内
    case inner
    /// 标题在外
    case outter
    /// 没有标题
    case none
}

/// 菜单配置信息
struct WPMenuConfig {
    /// 字体
    // swiftlint:disable init_font_with_token
    static let textFont: UIFont = UIFont.systemFont(ofSize: 16)
    // swiftlint:enable init_font_with_token
    /// 菜单项固定宽度
    static let MenuSolidWidth: CGFloat = 68
    /// 菜单项固定高度
    static let MenuSolidHeight: CGFloat = 50
    /// 菜单项分割线高度
    static let MenuDividerHeight: CGFloat = 1
    /// 菜单项最大宽度
    static let MenuMaxWidth: CGFloat = 230
    /// 菜单项最小宽度
    static let MenuMinWidth: CGFloat = 140
    /// 菜单可滚动时的上间距
    static let topInset: CGFloat = 8.0
    /// 菜单可滚动时的下间距
    static let bottomInset: CGFloat = 8.0
    /// 菜单配置选项
    var options: [ActionMenuItem]
    /// header类型
    var headerType: TitleLayoutType
    /// 菜单消失时的回调
    var dismissCallback: (() -> Void)?
}

/// 操作菜单视图
final class WPActionMenuView: UIView {
    static let logger = Logger.log(WPActionMenuView.self)

    /// 要挂载依赖的父view
    private var parentViewRect: CGRect
    /// 穿透蒙层的高亮目标
    private var targetItemInfo: WPMaskItemInfo
    /// 操作菜单配置
    private var menuConfig: WPMenuConfig
    /// 菜单视图主体大小
    private var menuContainerRect: CGRect = .zero
    /// 菜单是否向下展示
    private var showMenuInBottom: Bool = true
    /// 是否需要滚动条
    private var isNeedScrollerBar: Bool = false
    /// 是否是pad需要展示
    private var isForPad: Bool
    /// 蒙层背景
    private lazy var backgroundView: WPMenuMaskView = {
        let background = WPMenuMaskView(frame: .zero, maskFrame: targetItemInfo, parentFrame: parentViewRect)
        background.backgroundColor = .clear
        background.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        background.addGestureRecognizer(tapGestureRecognizer)
        return background
    }()
    /// menu视图
    weak var host: ActionMenuHost?
    lazy var menuView: WPMenuContainerView = {
        return WPMenuContainerView(frame: menuContainerRect, dismiss: { [weak self] in
            self?.dismiss()
        })
    }()

    private var menuWidth: CGFloat = 0
    private var menuHeight: CGFloat = 0
    /// 菜单尺寸
    var menuSize: CGSize {
        return CGSize(width: menuWidth, height: menuHeight)
    }

    init(
        parentViewRect: CGRect,
        mainMaskFrame: WPMaskItemInfo,
        menuConfig: WPMenuConfig,
        host: ActionMenuHost,
        isForPad: Bool = false
    ) {
        // 保存成员变量
        self.parentViewRect = parentViewRect
        self.targetItemInfo = mainMaskFrame
        self.menuConfig = menuConfig
        self.host = host
        self.isForPad = isForPad
        super.init(frame: parentViewRect)
        // 计算&加载视图
        generateMenuRect()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 获取蒙层穿透的适配偏移量
    /// - Parameters:
    ///   - cell: BlockCell
    static func getMaskFrameOffsetY(
        cell: UICollectionViewCell,
        collectionView: UICollectionView,
        additionalSpace: CGFloat = 0
    ) -> CGFloat {
        var offsetY: CGFloat = 0
        let originOffsetY = collectionView.contentOffset.y
        /// cell上边缘超出CV可见区域，向下移动，回到屏幕可见区域
        if cell.frame.minY < originOffsetY + additionalSpace {
            offsetY = collectionView.contentOffset.y + additionalSpace - cell.frame.minY
        }
        /// cell下边缘超出，向上移动，回到屏幕可见区域
        if cell.frame.maxY > (collectionView.frame.height - collectionView.contentInset.bottom + originOffsetY) {
            offsetY = collectionView.frame.height - collectionView.contentInset.bottom + originOffsetY - cell.frame.maxY
        }
        /// 适配超长View
        if cell.frame.height > (collectionView.frame.height) {
            offsetY = collectionView.contentOffset.y - cell.frame.minY
        }
        return offsetY
    }

    /// 调整蒙层Rect大小
    /// - Parameter originRect
    static func adjustMaskRect(originRect: CGRect) -> CGRect {
        /// 设计需求：将原来的rect周围加上一圈8padding
        let padding: CGFloat = 8.0
        return CGRect(
            x: originRect.minX - padding,
            y: originRect.minY - padding,
            width: originRect.width + padding * 2 ,
            height: originRect.height + padding * 2
        )
    }

    private func setupViews() {
        if !isForPad {
            addSubview(backgroundView)
            backgroundView.frame = parentViewRect
            addSubview(menuView)
        }
        self.isUserInteractionEnabled = true
        menuView.setData(
            options: menuConfig.options,
            host: host,
            isNeedScrollerBar: isNeedScrollerBar,
            isNeedShadow: !isForPad
        )
    }

    @objc
    func dismiss() {
        Self.logger.info("action menu dismiss")
        backgroundView.removeFromSuperview()
        self.removeFromSuperview()
        menuConfig.dismissCallback?()
    }
}

/// 菜单相关配置
extension WPActionMenuView {
    /// 生成menu的size，结果保存到成员变量 - menuContainerRect
    private func generateMenuRect() {
        /// 计算menu的高宽
        menuHeight = menuHeightCalculate()
        menuWidth = menuWidthCalculate()
        /// 计算menu的origin
        let origin = menuOriginCalculate(width: menuWidth, height: menuHeight)

        menuContainerRect = CGRect(x: origin.x, y: origin.y, width: menuWidth, height: menuHeight)
    }
    /// 计算菜单容器高度
    private func menuHeightCalculate() -> CGFloat {
        let safeMargin: CGFloat = 32.0
        let menuItemHeight = WPMenuConfig.MenuSolidHeight + WPMenuConfig.MenuDividerHeight
        let menuItemNum = CGFloat(menuConfig.options.count)

        let topInset: CGFloat = WPMenuConfig.topInset // 上间距
        let bottomInset: CGFloat = WPMenuConfig.bottomInset  // 下间距
        let halfItemHeight: CGFloat = WPMenuConfig.MenuSolidHeight / 2.0    //  半个选项的高度

        let contentHeight = menuItemNum * menuItemHeight - WPMenuConfig.MenuDividerHeight + topInset + bottomInset

        // 如果向下能展示完整个数，优先向下展示，否则向空间更大的方向展示
        let downAvailableHeight = parentViewRect.maxY - targetItemInfo.maskRect.minY - safeMargin
        if downAvailableHeight > contentHeight && menuItemNum < 8 {
            showMenuInBottom = true
            return contentHeight
        }

        let upAvailableHeight = targetItemInfo.maskRect.minY - parentViewRect.minY - safeMargin
        showMenuInBottom = downAvailableHeight > upAvailableHeight

        let availableHeight = showMenuInBottom ? downAvailableHeight : upAvailableHeight
        // 内容高度与可用高度对比
        if contentHeight < availableHeight && menuItemNum < 8 {
            isNeedScrollerBar = false
            return contentHeight
        } else {
            isNeedScrollerBar = true
            // 设计规则：可用高度 -（露出半个item高度）-（顶部间隔）-（底部间隔）/ 菜单项高度
            let itemNum = (availableHeight - halfItemHeight - topInset - bottomInset) / WPMenuConfig.MenuSolidHeight
            return min(itemNum, 7) * WPMenuConfig.MenuSolidHeight + halfItemHeight + topInset + bottomInset
        }
    }

    /// 计算菜单大小
    private func menuWidthCalculate() -> CGFloat {
        // 适配最长宽度
        var maxWidth = WPMenuConfig.MenuMinWidth
        for option in menuConfig.options {
            let text = option.name
            let optionWidth = getTextSize(
                text: text,
                font: WPMenuConfig.textFont
            ).width + WPMenuConfig.MenuSolidWidth
            maxWidth = max(maxWidth, optionWidth)
        }
        return min(maxWidth, WPMenuConfig.MenuMaxWidth)
    }

    /// 计算菜单原点
    private func menuOriginCalculate(width: CGFloat, height: CGFloat) -> CGPoint {
        let offset = getPointerOffset(type: menuConfig.headerType)
        if showMenuInBottom {
            /// 菜单向下展示
            return CGPoint(
                x: parentViewRect.maxX - offset.x - width,
                y: targetItemInfo.maskRect.minY + offset.y
            )
        } else {
            /// 菜单向上展示
            return CGPoint(
                x: parentViewRect.maxX - offset.x - width,
                y: targetItemInfo.maskRect.minY + offset.y - height
            )
        }
    }

    /// 获取弹窗锚点偏移量
    func getPointerOffset(type: TitleLayoutType) -> CGPoint {
        switch type {
        case.none:
            return CGPoint(x: 24, y: 16)
        case .inner:
            return showMenuInBottom ? CGPoint(x: 30, y: 48) : CGPoint(x: 30, y: 20)
        case .outter:
            return showMenuInBottom ? CGPoint(x: 14, y: 36) : CGPoint(x: 14, y: 8)
        }
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

/// 菜单弹窗的蒙层背景（需要穿透蒙层，展示选中视图）
final class WPMenuMaskView: UIView {
    /// 要穿透的选中视图的rect
    var maskFrame: WPMaskItemInfo
    /// 父视图的rect
    var parentFrame: CGRect
    /// 蒙层颜色
    var fillColor: UIColor = UIColor.ud.bgMask
    init(frame: CGRect, maskFrame: WPMaskItemInfo, parentFrame: CGRect) {
        self.maskFrame = maskFrame
        self.parentFrame = parentFrame
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {    // 抠一个穿透指向目标的洞子（Dig a hole to penetrate the target）
        if let ctx: CGContext = UIGraphicsGetCurrentContext() {
            ctx.addPath(UIBezierPath(roundedRect: maskFrame.maskRect, cornerRadius: maskFrame.maskRedius).cgPath)
            ctx.addPath(UIBezierPath(rect: parentFrame).cgPath)
            ctx.setFillColor(fillColor.cgColor)
            ctx.fillPath(using: .evenOdd)
        }
        super.draw(rect)
    }
}
