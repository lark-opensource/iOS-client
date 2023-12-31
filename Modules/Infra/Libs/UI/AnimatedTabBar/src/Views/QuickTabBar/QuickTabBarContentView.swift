//
//  QuickTabBarContentView.swift
//  AnimatedTabBar
//
//  Created by 夏汝震 on 2021/6/4.
//

import Foundation
import Homeric
import LKCommonsTracker
import FigmaKit
import UniverseDesignEmpty
import UIKit
import LarkContainer

final class QuickTabBarContentView: UIView, UserResolverWrapper {
    public let userResolver: UserResolver

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset = QuickTabBarConfig.Layout.collectionSectionInset
        flowLayout.minimumLineSpacing = QuickTabBarConfig.Layout.itemSpacing
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.backgroundColor = .clear
        collectionView.register(QuickTabBarItemView.self, forCellWithReuseIdentifier: "QuickTabBarItemView")
        return collectionView
    }()

    private lazy var emptyView = QuickTabBarEmptyView()
    internal var dataSource: [AbstractTabBarItem] = []
    internal weak var delegate: QuickTabBarContentViewDelegate?
    private let editEnabled: Bool

    init(frame: CGRect, dataSource: [AbstractTabBarItem], editEnabled: Bool, userResolver: UserResolver) {
        self.dataSource = dataSource
        self.editEnabled = editEnabled
        self.userResolver = userResolver
        super.init(frame: frame)
        self.initSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initSubViews() {
        clipsToBounds = true
        var containerView: UIView
        if UIDevice.current.userInterfaceIdiom == .pad {
            containerView = UIView()
            containerView.backgroundColor = UIColor.ud.bgFloat
        } else {
            let blurView = VisualBlurView()
            blurView.fillColor = UIColor.ud.bgFloat
            blurView.blurRadius = 40.0
            blurView.fillOpacity = 0.85
            containerView = blurView
        }
        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let headerView = UIView()

        let moreLabel = UILabel()
        moreLabel.text = BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationMore
        moreLabel.font = QuickTabBarConfig.Style.editTitleFont
        moreLabel.textColor = QuickTabBarConfig.Style.editTitleColor

        let editButton = UIButton()
        editButton.setTitle(BundleI18n.AnimatedTabBar.Lark_Legacy_Edit, for: .normal)
        editButton.setTitleColor(QuickTabBarConfig.Style.editButtonColor, for: .normal)
        editButton.titleLabel?.font = QuickTabBarConfig.Style.editButtonFont
        editButton.addTarget(self, action: #selector(didTapEditButton(_:)), for: .touchUpInside)
        editButton.isHidden = !editEnabled

        headerView.addSubview(moreLabel)
        headerView.addSubview(editButton)

        moreLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(QuickTabBarConfig.Layout.topViewInset)
            make.centerY.equalToSuperview()
        }

        editButton.snp.makeConstraints { make in
            make.height.equalTo(QuickTabBarConfig.Layout.topViewHeight)
            make.trailing.equalToSuperview().offset(-QuickTabBarConfig.Layout.topViewInset)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(headerView)
        containerView.addSubview(emptyView)
        containerView.addSubview(collectionView)

        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(QuickTabBarConfig.Layout.topViewHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
        }

        emptyView.snp.makeConstraints { (make) in
            make.edges.equalTo(collectionView)
        }
        showOrRemoveEmptyView()
    }

    @objc
    private func didTapEditButton(_ sender: UIButton) {
        self.delegate?.quickTabBarDidTapEditButton(self)
    }

    func showOrRemoveEmptyView() {
        emptyView.isHidden = !dataSource.isEmpty
        if !emptyView.isHidden {
            self.bringSubviewToFront(emptyView)
        }
    }
}

// MARK: - CollectionView DataSource & Delegate
extension QuickTabBarContentView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        delegate?.quickTabBar(self, didSelectItem: dataSource[indexPath.item].tab)
        // 点击事件埋点
        Tracker.post(TeaEvent(Homeric.NAVIGATION, params: [
            "navigation_type": 1,
            "tabkey": dataSource[indexPath.item].title,
            "position": indexPath.item
        ]))
    }
}

extension QuickTabBarContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuickTabBarItemView", for: indexPath)
        guard let itemView = cell as? QuickTabBarItemView else { return UICollectionViewCell() }
        let item = dataSource[indexPath.item]
        itemView.item = item
        itemView.configure(userResolver: userResolver)
        return itemView
    }
}

extension QuickTabBarContentView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return QuickTabBarConfig.Layout.realItemSize(forWidth: collectionView.bounds.width)
    }
}

extension QuickTabBarContentView: QuickTabBarContentViewInterface {
    var maxHeight: CGFloat {
        return QuickTabBarConfig.Layout.maxHeight(for: dataSource.count)
    }

    func updateToProgress(_ progress: CGFloat) {
        layer.cornerRadius = progress * QuickTabBarConfig.Layout.cornerRadius
    }

    func updateData(_ dataSource: [AbstractTabBarItem]) {
        self.dataSource = dataSource
        collectionView.reloadData()
        showOrRemoveEmptyView()
    }

    func reload() {
        self.collectionView.reloadData()
    }
}
