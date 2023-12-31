//
//  SelectedCollectionView.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/2/20.
//

import UIKit
import Foundation

public protocol SelectedCollectionItem {
    var id: String { get }
    var avatarKey: String { get }
    var medalKey: String { get }
    var isChatter: Bool { get }
}

public final class SelectedCollectionView: UIView {

    private var animated = true

    var selectItems: [SelectedCollectionItem] = []
    let kSelectedMemberAvatarSpacing: CGFloat = 10.0
    let kSelectedMemberAvatarSize: CGFloat = 30.0
    var didSelectBlock: ((SelectedCollectionItem) -> Void)?

    lazy var selectedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: kSelectedMemberAvatarSize, height: kSelectedMemberAvatarSize)
        layout.minimumInteritemSpacing = kSelectedMemberAvatarSpacing

        let selectedCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        selectedCollectionView.backgroundColor = UIColor.ud.bgBody
        selectedCollectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: kSelectedMemberAvatarSpacing,
            bottom: 0,
            right: kSelectedMemberAvatarSpacing)

        selectedCollectionView.delegate = self
        selectedCollectionView.dataSource = self
        return selectedCollectionView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(selectedCollectionView)
        selectedCollectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        //selectedCollectionView
        let cellName = String(describing: AvatarCollectionViewCell.self)
        selectedCollectionView.register(AvatarCollectionViewCell.self, forCellWithReuseIdentifier: cellName)
        selectedCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "emptyCell")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUI(animated: Bool = true) {
        self.selectedCollectionView.reloadData()
        if !self.selectItems.isEmpty {
            let indexPath = IndexPath(item: self.selectItems.count - 1, section: 0)
            self.selectedCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.selectedCollectionView.layoutIfNeeded()
            })
        }
    }

    public func setSelectedCollectionView(
        selectItems: [SelectedCollectionItem],
        didSelectBlock: ((SelectedCollectionItem) -> Void)?,
        animated: Bool = true
    ) {
        self.didSelectBlock = didSelectBlock
        self.selectItems = selectItems
        self.animated = animated
        self.updateUI(animated: animated)
    }

    public func addSelectItem(selectItem: SelectedCollectionItem) {
        self.selectedCollectionView.performBatchUpdates({ [weak self] in
            guard let self = self else { return }
            self.selectItems.append(selectItem)
            if !selectItems.isEmpty {
                self.selectedCollectionView.insertItems(at: [IndexPath(item: self.selectItems.count - 1, section: 0)])
            }
        }, completion: nil)
    }

    public func addSelectItems(selectItems: [SelectedCollectionItem]) {
        let start = self.selectItems.count
        let indexPaths = (start..<(start + selectItems.count)).map { IndexPath(item: $0, section: 0) }
        self.selectedCollectionView.performBatchUpdates({ [weak self] in
            guard let self = self else { return }
            self.selectItems.append(contentsOf: selectItems)
            self.selectedCollectionView.insertItems(at: indexPaths)
        }, completion: nil)
    }

    public func removeSelectItem(selectItem: SelectedCollectionItem) {
        if let index = self.selectItems.firstIndex(where: { $0.id == selectItem.id }) {
            self.selectedCollectionView.performBatchUpdates({ [weak self] in
                guard let self = self else { return }
                self.selectItems.remove(at: index)
                self.selectedCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }, completion: nil)
        }
    }

    public func removeSelectItems(selectItems: [SelectedCollectionItem]) {
        let indexPaths = selectItems.compactMap { (item) -> IndexPath? in
            if let index = self.selectItems.firstIndex(where: { $0.id == item.id }) {
                return IndexPath(item: index, section: 0)
            }
            return nil
        }.sorted(by: { $0.item > $1.item })

        self.selectedCollectionView.performBatchUpdates({ [weak self] in
            guard let self = self else { return }
            indexPaths.forEach { self.selectItems.remove(at: $0.item) }
            self.selectedCollectionView.deleteItems(at: indexPaths)
        }, completion: nil)
    }

    public func removeSelectAllItems() {
        self.selectItems.removeAll()
        self.updateUI(animated: animated)
    }
}

extension SelectedCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = self.selectItems[indexPath.row]
        self.didSelectBlock?(model)
        self.selectItems.remove(at: indexPath.row)
        self.selectedCollectionView.deleteItems(at: [indexPath])
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectItems.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let name = String(describing: AvatarCollectionViewCell.self)
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
            as? AvatarCollectionViewCell {

            let model = self.selectItems[indexPath.row]
            cell.setContent(model.avatarKey,
                            medalKey: model.medalKey,
                            id: model.id)
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "emptyCell", for: indexPath)
        }
    }
}
