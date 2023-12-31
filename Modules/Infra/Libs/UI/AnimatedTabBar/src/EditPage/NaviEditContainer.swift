//
//  NaviEditContainer.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/8/1.
//

import Foundation
import UIKit
import LarkInteraction
import FigmaKit
import UniverseDesignFont

final class NaviEditContainer: UIView {
    
    // 快捷导航的CollectionView
    lazy var quickCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.bounces = true
        collectionView.clipsToBounds = true
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // 启用拖动功能：
        collectionView.dragInteractionEnabled = true
        collectionView.lu.register(cellWithClass: QuickTabBarItemView.self)
        return collectionView
    }()
    
    // 主导航的CollectionView
    lazy var mainCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.bounces = true
        collectionView.clipsToBounds = true
        collectionView.alwaysBounceVertical = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // 启用拖动功能：
        collectionView.dragInteractionEnabled = true
        collectionView.lu.register(cellWithClass: QuickTabBarItemView.self)
        return collectionView
    }()

    /// 顶部导航栏容器
    lazy var navigationBar: UIView = {
       return UIView()
    }()

    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase//.yellow//UIColor.ud.bgMask
        return view
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear//.green
        return view
    }()
    
    lazy var mainTabBarBackgroundView: UIView = {
        // add custom blur view
        let visualView = VisualBlurView()
        visualView.fillColor = UIColor.ud.bgFloat
        visualView.fillOpacity = 0.85
        visualView.blurRadius = 40
        visualView.frame = self.bounds
        visualView.autoresizingMask = .flexibleWidth
        visualView.layer.masksToBounds = true
        visualView.layer.cornerRadius = 12
        return visualView
    }()

    private lazy var navTitleView: UIView = {
        let label = UILabel()
        label.text = BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationMore
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.title2
        label.textAlignment = .center
        return label
    }()
    /// 取消
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.ud.body2
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Cancel, for: .normal)
        return button
    }()
    /// 完成
    lazy var finishButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryFillDefault
        button.titleLabel?.font = UIFont.ud.body2
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Done, for: .normal)
        return button
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubview()
        setupConstraints()
    }

    private func setupSubview() {
        addSubview(backgroundView)
        addSubview(contentView)
        contentView.addSubview(navigationBar)
        contentView.addSubview(mainTabBarBackgroundView)
        contentView.addSubview(quickCollectionView)
        mainTabBarBackgroundView.addSubview(mainCollectionView)
        navigationBar.addSubview(cancelButton)
        navigationBar.addSubview(finishButton)
        navigationBar.addSubview(navTitleView)
        // 产品说先把取消隐藏，之后大概率会加回来
        cancelButton.isHidden = true
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        navigationBar.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        mainTabBarBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.height.equalTo(Cons.tabBarHeight)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-5)
        }
        mainCollectionView.snp.makeConstraints { (make) in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
        quickCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalTo(mainCollectionView.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        navTitleView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(navTitleView)
            make.height.equalTo(20)
        }
        finishButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-24)
            make.centerY.equalTo(navTitleView)
            make.width.equalTo(56)
            make.height.equalTo(34)
        }
        if #available(iOS 13.4, *) {
            cancelButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
            finishButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
        }
    }
}

// MARK: - Utils
extension NaviEditContainer {
    // 一些布局相关的常量定义在这里，不要在代码中使用魔法数字
    enum Cons {
        /// TabBar 的高度，此高度应与外部 MainTabBar 的高度一致
        static var tabBarHeight: CGFloat { MainTabBar.Layout.stackHeight }
        /// TabBar 从贴底状态到悬浮状态，上升的距离
        static var tabBarRasingOffset: CGFloat { 5 }
    }
}
