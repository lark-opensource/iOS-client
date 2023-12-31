//
//  MoreViewV2ManageCell.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/8/30.
//

import UIKit
import UniverseDesignColor
import UniverseDesignBadge

protocol MoreViewManageCellDelegate: AnyObject {
    func didClick(_ item: ItemsProtocol)
}

private extension MoreViewV2ManageCell {
    enum Const {
        static let itemMinWidth: CGFloat = 80
        static let itemHeight: CGFloat = 84
        static let sectionInset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 16, right: 16)
        static let itemSpacing: CGFloat = 8
        static let itemMaxWidth: CGFloat = 112
    }
}

class MoreViewV2ManageCell: UITableViewCell {

    private(set) var items: [ItemsProtocol] = [ItemsProtocol]()
    weak var delegate: MoreViewManageCellDelegate?
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Const.itemSpacing
        layout.sectionInset = Const.sectionInset
        layout.scrollDirection = .horizontal

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MoreViewCollectionCell.self, forCellWithReuseIdentifier: MoreViewCollectionCell.reuseIdentifier)
        return collectionView
    }()

    // 为了及时监听到 contentView 的 sizeChange 事件，更新 collectionView 的布局
    private lazy var containerView: LayoutContentView = {
        let view = LayoutContentView()
        view.backgroundColor = .clear
        view.layoutAction = { [weak self] in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupDefaultValue()
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDefaultValue() {
        accessibilityIdentifier = "MoreViewManageCell"
    }

    private func setupSubviews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func update(items: [ItemsProtocol]) {
        self.items = items
        collectionView.reloadData()
    }

    func reloadData() {
        collectionView.reloadData()
    }
}

extension MoreViewV2ManageCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MoreViewCollectionCell.reuseIdentifier, for: indexPath)
        guard let collectionCell = cell as? MoreViewCollectionCell else {
            assertionFailure("can not find cell")
            return cell
        }
        let data = items[indexPath.item]
        collectionCell.update(isEnabled: data.state != .disable,
                              imageEnableColor: data.iconEnableColor,
                              imageDisableColor: data.iconDisableColor)
        collectionCell.update(title: data.title, image: data.image, needReddot: data.needNewTag)
        return cell
    }
}

extension MoreViewV2ManageCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let data = items[indexPath.item]
        self.delegate?.didClick(data)
    }
}

extension MoreViewV2ManageCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard items.count > 0 else {
            return CGSize(width: collectionView.frame.width - 32, height: Const.itemHeight)
        }
        // 不足3个时，按3个计算宽度
        let layoutItemCount = max(3, items.count)
        let contentWidth = collectionView.frame.width
            - Const.sectionInset.left
            - Const.sectionInset.right
            - CGFloat(layoutItemCount - 1) * Const.itemSpacing
        var itemWidth = max(contentWidth / CGFloat(layoutItemCount), Const.itemMinWidth)
        switch DocsSDK.currentLanguage {
        case .zh_CN, .zh_HK, .zh_TW:
            break
        default:
            itemWidth = Const.itemMaxWidth
        }
        return CGSize(width: itemWidth, height: Const.itemHeight)
    }
}

private class LayoutContentView: UIView {

    var layoutAction: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutAction?()
    }
}
