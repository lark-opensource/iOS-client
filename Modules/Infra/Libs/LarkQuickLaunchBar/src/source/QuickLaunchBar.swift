//
//  QuickLaunchBar.swift
//  LarkQuickLaunchBar
//
//  Created by ByteDance on 2023/5/10.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import LarkQuickLaunchInterface

open class QuickLaunchBar: UIView {

    // 业务方代理
    public weak var delegate: QuickLaunchBarDelegate?

    // 业务注入自己的功能item
    private var items: [QuickLaunchBarItem]

    // 是否展示标题
    private var enableTitle: Bool

    private lazy var stackView: UIStackView = {
       let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var skeletonStackView: UIStackView = {
        let stackView = UIStackView()
         stackView.axis = .horizontal
         stackView.distribution = .fillEqually
         stackView.alignment = .fill
         stackView.spacing = 0
         stackView.isHidden = true
         return stackView
     }()

    // 初始化，最终显示的顺序（从左到右）：Items + ExtraItems
    public init(enableTitle: Bool = false,
                items: [QuickLaunchBarItem] = []) {
        self.enableTitle = enableTitle
        self.items = items
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloat
        self.layer.borderWidth = 0.5
        self.ud.setLayerBorderColor(UIColor.ud.lineDividerDefault)
        addSubview(stackView)
        addSubview(skeletonStackView)
        // 按钮并非是剧中对齐的，顶部有额外偏移量
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.trailing.leading.equalToSuperview()
            make.height.equalTo(launchBarHeight-5)
        }
        skeletonStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.trailing.leading.equalToSuperview()
            make.height.equalTo(launchBarHeight-5)
        }
        self.snp.makeConstraints { make in
            make.height.equalTo(launchBarHeight + safeAreaInsets.bottom)
        }
        self.setSkeletonDrawing()
        self.updateLayout()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // init里面safeAreaInsets不能获得正确尺寸，这里再更新下
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if !isBarHidden {
            self.snp.updateConstraints { make in
                make.height.equalTo(launchBarHeight + safeAreaInsets.bottom)
            }
        }
    }

    private func setSkeletonDrawing() {
        let skeletonItem = QuickLaunchBarItem(nomalImage: UIImage())
        for _ in 0 ..< 4 {
            let skeletonView = QuickLaunchBarItemView(item: skeletonItem)
            skeletonStackView.addArrangedSubview(skeletonView)
            skeletonView.itemBtn.layer.cornerRadius = 10
            skeletonView.itemBtn.clipsToBounds = true
            skeletonView.itemBtn.showUDSkeleton()
        }
    }

    private func updateLayout() {
        if !stackView.arrangedSubviews.isEmpty {
            let views = stackView.arrangedSubviews
            views.forEach({ view in
                stackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            })
        }
        // 填充业务自定义items
        for i in 0 ..< items.count {
            let itemView = QuickLaunchBarItemView(config: QuickLaunchBarItemViewConfig(enableTitle: self.enableTitle), item: items[i])
            stackView.addArrangedSubview(itemView)
        }
    }

    // 展示/隐藏骨架图
    public func setSkeletonDrawingHidden(_ isHidden: Bool) {
        self.stackView.isHidden = !isHidden
        self.skeletonStackView.isHidden = isHidden
    }

    // 更新items数据并重新布局
    open func reloadByItems(_ items: [QuickLaunchBarItem]) {
        self.items = items
        self.updateLayout()
    }

    // 更新指定Item, index表示在item当前视图中的位置, 包括items和extraItems
    public func reloadItem(_ item: QuickLaunchBarItem, at index: Int) {
        guard index < stackView.arrangedSubviews.count,
              let view = stackView.arrangedSubviews[index] as? QuickLaunchBarItemView else {
            return
        }
        view.updateItem(item)
    }

    // 获取QuickLaunchBar的高度
    public var launchBarHeight: CGFloat {
        return self.enableTitle ? 62.0 : 43.0
    }

    // 滚动偏移
    private var lastOffsetY: CGFloat = 0.0
    // bar是否已经被隐藏
    private var isBarHidden: Bool = false
    // 滚动隐藏阈值,超过这个阈值才会触发滚动隐藏/展示效果
    static private let offsetThreshold: CGFloat = 10.0
}

// 滚动相关方法
public extension QuickLaunchBar {

    //  容器将要开始滚动
    func containerWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastOffsetY = scrollView.contentOffset.y
    }

    //  容器开始滚动
    func containerDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y - self.lastOffsetY > Self.offsetThreshold && !self.isBarHidden {
            self.hideLaunchBar()
            self.isBarHidden = true
        } else if scrollView.contentOffset.y - self.lastOffsetY < -Self.offsetThreshold && self.isBarHidden  {
            self.showLaunchBar()
            self.isBarHidden = false
        }
    }

    private func showLaunchBar() {
        self.snp.updateConstraints { make in
            make.height.equalTo(self.launchBarHeight + safeAreaInsets.bottom)
        }
        delegate?.quickLaunchBarWillShow()
        UIView.animate(withDuration: 0.25, animations: {
            self.superview?.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.quickLaunchBarDidShow()
        })
    }

    private func hideLaunchBar() {
        self.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        delegate?.quickLaunchBarWillHide()
        UIView.animate(withDuration: 0.25, animations: {
            self.superview?.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.quickLaunchBarDidHide()
        })
    }
}

