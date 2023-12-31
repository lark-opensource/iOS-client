//
//  ActionSheet.swift
//  LarkActionSheet
//
//  Created by zhuchao on 2019/4/23.
//

import UIKit
import Foundation
import LarkInteraction
import UniverseDesignColor

/*
 样式类似于系统的ActionSheet, UI针对Lark统一定制
 提供了一些自定义的接口方便定制
 弹出方式调用父类的 present
 */

public final class ActionSheet: UIViewController {

    private let transition = ActionSheetTransition()

    ///点击背景区域dismiss回掉
    public var dismissedByTapOutside: (() -> Void)?

    private var cancelAction: (() -> Void)?

    private var sheetWidth: CGFloat?

    // 底部间距，默认-10
    private var bottomOffset: CGFloat = -10
    /// 初始构造方法
	///
    /// - Parameters:
    ///   - title: 标题, 默认没有标题
    ///   - sheetWidth: 默认width.equalToSuperview().offset(-20)。iPad部分场景需要在formSheet中显示居中定宽的actionSheet，故提供设置方法
    public init(title: String = "", sheetWidth: Float? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = transition
        self.modalPresentationStyle = .custom
        if let sheetWidth = sheetWidth {
            self.sheetWidth = CGFloat(sheetWidth)
        }
        if !title.isEmpty {
            addTitle(title)
        }
    }

	/// 扩展的构造方法，增加参数
	///
	///   - bottomOffset: 底部间距
	public convenience init(title: String = "", sheetWidth: Float? = nil, bottomOffset: CGFloat) {
		self.init(title: title, sheetWidth: sheetWidth)
		self.bottomOffset = bottomOffset
	}

    /// 添加一个item
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - textColor: 标题颜色
    ///   - action: 点击事件
    /// - Returns: item所对应的View, 方便一些非常特殊的case定制
    @discardableResult
    public func addItem(
        title: String,
        textColor: UIColor? = nil,
        icon: UIImage? = nil,
        entirelyCenter: Bool = false,
        action: @escaping () -> Void
    ) -> ItemView {
        let itemView = ItemView(
            title: title,
            icon: icon,
            entirelyCenter: entirelyCenter,
            tapAction: { [weak self] in
                self?.dismiss(animated: true) {
                    action()
                }
            }
        )
        if let color = textColor {
            itemView.label.textColor = color
        }
        addItemView(itemView)
        return itemView
    }

    /// 添加一个自定义的带有事件响应的item, 背景色和高亮会与默认item一致
    ///
    /// - Parameters:
    ///   - itemView: 自定义
    ///   - textColor: 标题颜色
    ///   - isAddLine： 是否添加分割线
    ///   - action: 点击事件
    public func addItemView(_ itemView: UIView, isAddLine: Bool = true, action: @escaping () -> Void) {
        let wrapperItemView = ItemView(title: "", tapAction: { [weak self] in
            self?.dismiss(animated: true) {
                action()
            }
        })
        wrapperItemView.addSubview(itemView)
        itemView.isUserInteractionEnabled = false
        itemView.backgroundColor = .clear
        itemView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addItemView(wrapperItemView, isAddLine: isAddLine)
    }

    /// 添加一个取消item, 文字颜色默认是默认的黑色
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - textColor: 标题颜色
    ///   - action: 点击事件
    /// - Returns: item所对应的View, 方便一些非常特殊的case定制
    @discardableResult
    public func addCancelItem(
        title: String,
        textColor: UIColor? = nil,
        icon: UIImage? = nil,
        entirelyCenter: Bool = false,
        cancelAction: (() -> Void)? = nil
    ) -> ItemView {
        let itemView = ItemView(
            title: title,
            icon: icon,
            entirelyCenter: entirelyCenter,
            tapAction: { [weak self] in
                self?.dismiss(animated: true) {
                    cancelAction?()
                }
            })
        self.cancelAction = cancelAction
        if let color = textColor {
            itemView.label.textColor = color
        }
        itemView.layer.cornerRadius = 8.0
        itemView.clipsToBounds = true
        setUpShadow(of: itemView)
        cancelItem = itemView
        contentView.addArrangedSubview(itemView)
        return itemView
    }

    /// 添加一个红色的取消item
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - textColor: 标题颜色
    ///   - action: 点击事件
    /// - Returns: item所对应的View, 方便一些非常特殊的case定制
    @discardableResult
    public func addRedCancelItem(
        title: String,
        icon: UIImage? = nil,
        cancelAction: (() -> Void)? = nil
    ) -> ItemView {
        let redColor = UIColor.ud.functionDangerContentDefault
        return addCancelItem(
            title: title,
            textColor: redColor,
            icon: icon,
            cancelAction: cancelAction
        )
    }

    /// 添加一个高度定制化的view, 所有行为都由view自行定制
    ///
    /// - Parameters:
    ///   - itemView: 定制化的view
    ///   - isAddLine： 是否添加分割线
    public func addItemView(_ itemView: UIView, isAddLine: Bool = true) {
        if !itemContainerView.arrangedSubviews.isEmpty, isAddLine {
            itemContainerView.addArrangedSubview(Line())
        }
        itemContainerView.addArrangedSubview(itemView)
        relayoutIfNeeded()
    }

    /// 移除所有itemView(有些场景，需要异步修改item。这里可以先移除，再添加回来)
    public func removeAllItemView() {
        let allViews = itemContainerView.arrangedSubviews
        allViews.forEach { (view) in
            itemContainerView.removeArrangedSubview(view)
        }
        relayoutIfNeeded()
    }

    /// 标题的Label, 方便定制化
    public var titleLabel: UILabel? {
        return titleView?.label
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        layoutContentView(contentView, itemContainerView: itemContainerView)
        addTapGesture()
    }

    // private methods

    private let itemContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }()

    private let contentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 10
        return stackView
    }()

    private var layouted: Bool = false

    private var titleView: TitleView?
    private var cancelItem: ItemView?
    private let scrollView: UIScrollView = UIScrollView()

    private func addTitle(_ title: String) {
        self.titleView = TitleView(title: title)
    }

    private func setUpShadow(of view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 9
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    private func layoutContentView(_ view: UIStackView, itemContainerView: UIView) {
        scrollView.backgroundColor = .clear
        scrollView.addSubview(itemContainerView)

        let itemWrapper = UIView()
        itemWrapper.backgroundColor = UIColor.ud.bgBody
        itemWrapper.clipsToBounds = true
        itemWrapper.layer.cornerRadius = 8.0
        itemWrapper.addSubview(scrollView)
        setUpShadow(of: itemWrapper)

        if let titleView = titleView {
            let line = Line()
            titleView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.left.bottom.right.equalTo(titleView)
            }

            itemWrapper.addSubview(titleView)
            titleView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
            }

            scrollView.snp.makeConstraints { (make) in
                make.top.equalTo(titleView.snp.bottom)
                make.bottom.left.right.equalToSuperview()
            }
        } else {
            scrollView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        view.insertArrangedSubview(itemWrapper, at: 0)
        let shouldEnableScroll = self.shouldEnableScroll

        self.view.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(self.bottomOffset)
            if shouldEnableScroll {
                // 滚动的情况，scrollView依据整体高度确定高度
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(minimumTopMargin)
            }
            make.centerX.equalToSuperview()
            if let width = sheetWidth {
                make.width.equalTo(width)
            } else {
                make.width.equalToSuperview().offset(-20)
            }
        }
        itemContainerView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            if !shouldEnableScroll {
                // 不滚动的情况，scrollView依据内容高度确定高度
                make.height.equalToSuperview()
            }
            make.left.right.equalTo(view)
        }
        layouted = true
        isSheetScrollable = shouldEnableScroll
    }

    // 所有选项高度加和
    private var itemsHeight: CGFloat {
        return itemContainerView.arrangedSubviews.reduce(0) { (result, view) in
            return result + view.intrinsicContentSize.height
        }
    }

    private var minimumTopMargin: CGFloat = 64

    // 当前是否可滚动，减少展示后的再次布局次数
    private var isSheetScrollable: Bool = false

    // 计算高度，判断是否需要滚动
    private var shouldEnableScroll: Bool {
        // 总高度 = 文字高度 + 16 + 所有选项高度和 + 10 + 取消按钮高度 + 10
        var totalHeight = itemsHeight + 10
        if let titleView = titleView {
            let labelWidth = sheetWidth ?? UIScreen.main.bounds.width - 40
            var lineCount = 1
            if let text = titleView.label.text, let font = titleView.label.font {
                let textWidth = text.size(withAttributes: [NSAttributedString.Key.font: font]).width
                lineCount = Int(ceil(textWidth / labelWidth))
            }
            totalHeight += CGFloat(lineCount) * titleView.label.font.lineHeight + 16
        }
        if let cancelItem = cancelItem {
            totalHeight += cancelItem.intrinsicContentSize.height + 10
        }
        var safeAreaHeight = UIScreen.main.bounds.height
        if let window = view.window {
            safeAreaHeight -= window.safeAreaInsets.top + window.safeAreaInsets.bottom
        }

        return totalHeight + minimumTopMargin > safeAreaHeight
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        relayoutIfNeeded()
    }

    private func relayoutIfNeeded() {
        guard layouted else { return }
        let shouldEnableScroll = self.shouldEnableScroll
        scrollView.contentSize.height = itemsHeight

        guard shouldEnableScroll != isSheetScrollable else { return }
        // ActionSheet的从需要滚动变为不需要滚动，或从不需要滚动变为需要滚动，重新设置约束
        contentView.snp.remakeConstraints { (make) in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-10)
            if shouldEnableScroll {
                // 滚动的情况，scrollView依据整体高度确定高度
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(minimumTopMargin)
            }
            make.centerX.equalToSuperview()
            if let width = sheetWidth {
                make.width.equalTo(width)
            } else {
                make.width.equalToSuperview().offset(-20)
            }
        }
        itemContainerView.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            if !shouldEnableScroll {
                // 不滚动的情况，scrollView依据内容高度确定高度
                make.height.equalToSuperview()
            }
            make.left.right.equalTo(view)
        }
        isSheetScrollable = shouldEnableScroll
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        if !self.contentView.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true) {
                self.dismissedByTapOutside?()
                self.cancelAction?()
            }
        }
    }

}

private final class TitleView: UIView {
    let label: UILabel = UILabel()
    init(title: String) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 33))
        self.backgroundColor = UIColor.ud.bgBody
        layoutLabel(label, title: title)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutLabel(_ label: UILabel, title: String) {
        //可换行
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.text = title
        label.textColor = UIColor.ud.textPlaceholder
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
}

private final class Line: UIView {
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.lineDividerDefault
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 1.0
        return size
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class ItemView: UIControl {
    public var defaultHeight: CGFloat = 64.0
    public let label: UILabel = UILabel()
    public let iconView: UIImageView = UIImageView()
    private let action: () -> Void
    init(title: String, icon: UIImage? = nil, entirelyCenter: Bool = false, tapAction: @escaping () -> Void) {
        action = tapAction
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 33))
        layoutLabel(label, title: title)
        if let icon = icon {
            layoutIcon(iconView, icon: icon, label: label)
            if entirelyCenter {
                label.snp.updateConstraints { (make) in
                    make.centerX.equalToSuperview().offset((24 + 12) / 2)
                }
            }
        }
        self.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        self.backgroundColor = UIColor.ud.bgBody
        if #available(iOS 13.4, *) {
            addLKInteraction(PointerInteraction(style: PointerStyle(effect: .hover())))
        }
        layoutBgView(bgView)
    }

    @objc
    private func tapped() {
        action()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = defaultHeight
        return size
    }

    private func layoutLabel(_ label: UILabel, title: String) {
        //可换行
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .center
        label.text = title
        label.textColor = UIColor.ud.textTitle
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    private func layoutIcon(_ imageView: UIImageView, icon: UIImage, label: UILabel) {
        //可换行
        imageView.image = icon
        imageView.contentMode = .center
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
            make.left.greaterThanOrEqualToSuperview().offset(10).priority(.required)
            make.right.equalTo(label.snp.left).offset(-12)
        }
    }

    private let bgView = UIView()

    private func layoutBgView(_ bgView: UIView) {
        bgView.isUserInteractionEnabled = false
        self.insertSubview(bgView, at: 0)
        bgView.backgroundColor = UIColor.ud.bgBody
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        bgView.backgroundColor = UIColor.ud.fillHover
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        bgView.backgroundColor = UIColor.ud.bgFloat
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        bgView.backgroundColor = UIColor.ud.bgFloat
    }
}
