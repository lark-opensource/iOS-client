//
//  NaviRecommandContainer.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/11/03.
//

import Foundation
import UIKit
import LarkInteraction
import FigmaKit

final class NaviRecommandContainer: UIView {

    // 推荐内容的CollectionView
    lazy var collectionView: UICollectionView = {
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
        collectionView.lu.register(cellWithClass: NaviRecommandCell.self)
        collectionView.lu.register(supplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: RecommandHeaderTitleView.self)
        return collectionView
    }()

    /// 顶部导航栏容器
    lazy var navigationBar: UIView = {
       return UIView()
    }()

    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody//.yellow//UIColor.ud.bgMask
        return view
    }()

    lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear//.green
        return view
    }()

    private lazy var navTitleView: UIView = {
        let label = UILabel()
        label.text = BundleI18n.AnimatedTabBar.Lark_Legacy_SelectTip
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    /// 取消
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Cancel, for: .normal)
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
        contentView.addSubview(collectionView)
        navigationBar.addSubview(cancelButton)
        navigationBar.addSubview(navTitleView)
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
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        navTitleView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(navTitleView)
            make.height.equalTo(20)
        }
        if #available(iOS 13.4, *) {
            cancelButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
        }
    }
}

// MARK: - Utils
extension NaviRecommandContainer {
    // 一些布局相关的常量定义在这里，不要在代码中使用魔法数字
    enum Cons {
        /// TabBar 的高度，此高度应与外部 MainTabBar 的高度一致
        static var tabBarHeight: CGFloat { MainTabBar.Layout.stackHeight }
        /// TabBar 从贴底状态到悬浮状态，上升的距离
        static var tabBarRasingOffset: CGFloat { 5 }
    }
}
