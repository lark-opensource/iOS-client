//
//  BottomMenuBar.swift
//  LarkBusinessModule
//
//  Created by lichen on 2018/3/23.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import FigmaKit

public enum BottomMenuItemType {
    case mergeFoward
    case singleForward
    case messageLink
    case createTodo
    case createWorkItemInMeego
    case mergeFavorite
    case takeAction
    case delete
    // KA菜单，存在一个Type对应多个Item的情况
    case ka
}

public struct BottomMenuItem {
    var name: String
    var image: UIImage
    var type: BottomMenuItemType

    var action: () -> Void

    var enable: Bool = true

    public init(type: BottomMenuItemType,
                name: String,
                image: UIImage,
                action: @escaping () -> Void) {
        self.type = type
        self.name = name
        self.image = image
        self.action = action
    }
}

final class BottomMenuCell: UICollectionViewCell {
    private static let squircleBackgroundSize: CGSize = CGSize(width: 52, height: 52)
    private static let titleLabelTopMargin: CGFloat = 8
    private static let titleLabelMaxWidth: CGFloat = 67

    private static let calculateLabel: UILabel = BottomMenuCell.initLabel()
    private lazy var squircleBackgroundView: SquircleView = {
        let roundView = SquircleView()
        roundView.cornerRadius = 12
        roundView.backgroundColor = UIColor.ud.bgFloat
        return roundView
    }()
    private let imageView = UIImageView()
    private var titleLabel: UILabel = .init()

    private static func initLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.textCaption
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        return label
    }

    static func calculateDisplayHeight(text: String) -> CGFloat {
        calculateLabel.text = text
        let textHeight = calculateLabel.sizeThatFits(CGSize(width: titleLabelMaxWidth, height: CGFloat.greatestFiniteMagnitude)).height
        return squircleBackgroundSize.height + titleLabelTopMargin + textHeight
    }

    var item: BottomMenuItem? {
        didSet {
            self.titleLabel.text = item?.name
            self.imageView.image = item?.image.withRenderingMode(.alwaysTemplate)
            self.alpha = (item?.enable ?? false) ? 1 : 0.3
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                squircleBackgroundView.backgroundColor = UIColor.ud.fillPressed
            } else {
                squircleBackgroundView.backgroundColor = UIColor.ud.bgFloat
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.squircleBackgroundView)
        self.squircleBackgroundView.addSubview(self.imageView)
        self.imageView.tintColor = UIColor.ud.iconN1
        self.imageView.snp.makeConstraints { $0.center.equalToSuperview() }
        self.squircleBackgroundView.snp.makeConstraints { (make) in
            make.centerX.top.equalToSuperview()
            make.size.equalTo(BottomMenuCell.squircleBackgroundSize)
        }

        self.titleLabel = BottomMenuCell.initLabel()
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(squircleBackgroundView.snp.bottom).offset(BottomMenuCell.titleLabelTopMargin)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(BottomMenuCell.titleLabelMaxWidth)
        }
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class BottomMenuBar: UIView {

    public static func barHeight(in view: UIView) -> CGFloat {
        let height = BottomMenuBar.collectionHeight + view.safeAreaInsets.bottom
        return height
    }

    static let collectionHeight: CGFloat = 140
    static let itemSize: CGSize = CGSize(width: 52, height: 62)
    static let itemMinimumLineSpacing: CGFloat = 18

    var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        layout.itemSize = BottomMenuBar.itemSize
        layout.minimumLineSpacing = BottomMenuBar.itemMinimumLineSpacing
        return layout
    }()

    lazy var collection: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.clear
        collection.showsHorizontalScrollIndicator = false
        collection.register(BottomMenuCell.self, forCellWithReuseIdentifier: String(describing: BottomMenuCell.self))
        collection.delegate = self
        collection.dataSource = self
        return collection
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgContentBase.withAlphaComponent(0.9)
        self.addSubview(collection)
        collection.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(BottomMenuBar.collectionHeight)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getItemByType(_ type: BottomMenuItemType) -> UICollectionViewCell? {
        let index = self.items.firstIndex { (item) -> Bool in
            return item.type == type
        }
        guard let cellIndex = index else {
            return nil
        }
        let indexPath = IndexPath(row: cellIndex, section: 0)
        return self.collection.cellForItem(at: indexPath)
    }

    public var items: [BottomMenuItem] = [] {
        didSet {
            self.itemDisplayHeight = 0
            self.items.forEach { (item) in
                let height = BottomMenuCell.calculateDisplayHeight(text: item.name)
                self.itemDisplayHeight = max(self.itemDisplayHeight, height)
            }
            self.updateItemsLayout()
        }
    }

    private var itemDisplayHeight: CGFloat = 0

    private var itemTopInset: CGFloat {
        return (BottomMenuBar.collectionHeight - self.itemDisplayHeight) / 2
    }
    private var itemBottomInset: CGFloat {
        return BottomMenuBar.collectionHeight - itemTopInset - BottomMenuBar.itemSize.height
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updateItemsLayout()
    }

    private func updateItemsLayout() {
        let count = CGFloat(self.items.count)
        let width = self.frame.width
        let itemWidth = BottomMenuBar.itemSize.width
        if self.items.isEmpty || count * itemWidth + 18 * 2 + (count - 1) * BottomMenuBar.itemMinimumLineSpacing > width {
            layout.sectionInset = UIEdgeInsets(top: itemTopInset, left: 18, bottom: itemBottomInset, right: 18)
            layout.minimumLineSpacing = BottomMenuBar.itemMinimumLineSpacing
        } else {
            let space = (width - count * itemWidth) / (count + 1)
            layout.sectionInset = UIEdgeInsets(top: itemTopInset, left: space, bottom: itemBottomInset, right: space)
            layout.minimumLineSpacing = space
        }
        self.collection.reloadData()
    }
}

extension BottomMenuBar: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        let item = self.items[indexPath.row]
        if item.enable {
            item.action()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let item = self.items[indexPath.row]
        return item.enable
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let item = self.items[indexPath.row]
        return item.enable
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < self.items.count else {
            return UICollectionViewCell()
        }
        let item = self.items[indexPath.row]

        let name = String(describing: BottomMenuCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? BottomMenuCell {
            collectionCell.item = item
        }
        return cell
    }
}
