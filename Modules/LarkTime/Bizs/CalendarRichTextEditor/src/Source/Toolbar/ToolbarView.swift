//
//  ToolbarView.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/8/5.
//

import UIKit
import Foundation

protocol ToolbarViewDelegate: AnyObject {
    func didClickedItem(_ item: ToolbarItem, clickWhenSelected: Bool)
}

final class ToolbarView: UIView {
    weak var delegate: ToolbarViewDelegate?

    var items: [ToolbarItem] = [] {
        didSet {
            toolItemCollectionView?.reloadData()
        }
    }
    private var toolItemCollectionView: UICollectionView?
    private let viewReuseIdentifier = "toolItemCollectionViewCell"
    private let seprateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addItemCollectionView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var _cachedImage: [String: UIImage] = [:]

    private let leftPadding: CGFloat = 14
    private let margin: CGFloat = 22
    private let size: CGFloat = 26
    private let rightPadding: CGFloat = 14

    override func layoutSubviews() {
        super.layoutSubviews()
        toolItemCollectionView?.frame = CGRect(x: 0, y: 0, width: bounds.maxX - seprateLine.frame.maxX, height: bounds.size.height)
        toolItemCollectionView?.collectionViewLayout.invalidateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toolItemCollectionView?.reloadData()
    }

    func addItemCollectionView() {
        let lrMargin: CGFloat = 14
        let itemMargin: CGFloat = 22
        let itemWidth: CGFloat = 22
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = itemMargin
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: lrMargin, bottom: 0, right: lrMargin)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        addSubview(cv)
        cv.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.ud.bgFloat
        cv.showsHorizontalScrollIndicator = false
        cv.register(RTToolItemCellV2.self, forCellWithReuseIdentifier: viewReuseIdentifier)
        toolItemCollectionView = cv
    }
}

extension ToolbarView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let info = items[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewReuseIdentifier, for: indexPath) as? RTToolItemCellV2 else {
            return RTToolItemCellV2()
        }
        cell.icon.image = _loadImage(info.identifier, rawImage: info.image, selected: info.isSelected, enabled: info.isEnable)
        cell.isUserInteractionEnabled = info.isEnable
        return cell
    }

    private func _loadImage(_ identifier: String, rawImage: UIImage?, selected: Bool, enabled: Bool) -> UIImage? {
        let uid = "\(identifier)-\(selected)"
        let targetColor = !enabled ? UIColor.ud.textDisable : (selected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle)
        let image = rawImage?.ud.withTintColor(targetColor)
        _cachedImage[uid] = image
        return image
    }
}

extension ToolbarView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        guard item.isEnable else { return }

        delegate?.didClickedItem(item, clickWhenSelected: item.isSelected)
    }
}

final class RTToolItemCellV2: UICollectionViewCell {

    lazy var icon: UIImageView = {
        let icon = UIImageView()
        return icon
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(self.icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(contentView)
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
