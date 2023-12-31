//
//  MyAIToolsSelecedView.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/23.
//

import UIKit
import Foundation
import UniverseDesignIcon
import LarkMessengerInterface
import ByteWebImage
import LarkModel
import LarkBizAvatar

final class MyAIToolsSelectedView: UIView {

    var items: [MyAIToolInfo] = []
    var didDeleteItemHandler: ((MyAIToolInfo) -> Void)?

    private lazy var collectionView: UICollectionView = {
        var collectionViewLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = CGSize(width: 36, height: 36)
        collectionViewLayout.minimumInteritemSpacing = 8
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AvatarToolCollectionCell.self, forCellWithReuseIdentifier: "AvatarToolCollectionCell")
        return collectionView
    }()

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.ud.bgBody
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        self.addSubview(collectionView)

        collectionView.snp.makeConstraints { (make) in
            make.leading.top.bottom.trailing.equalToSuperview()
        }
    }

    func reloadCollect(items: [MyAIToolInfo]) {
        self.items = items
        collectionView.reloadData()
        scrollToLastest(animated: false)
    }

    func scrollToLastest(animated: Bool) {
        if items.count > 1 {
            collectionView.scrollToItem(at: IndexPath(item: items.count - 1, section: 0), at: .left, animated: animated)
        }
    }
}

extension MyAIToolsSelectedView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarToolCollectionCell", for: indexPath) as? AvatarToolCollectionCell,
                self.items.count > indexPath.row else {
            return UICollectionViewCell()
        }
        cell.setAvatarBy(by: item.toolId, avatarKey: item.toolAvatar)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didDeleteItemHandler?(items[indexPath.row])
    }
}

private final class AvatarToolCollectionCell: UICollectionViewCell {

    private lazy var avatarView: MyAIToolAvatarView = {
        let avatarView = MyAIToolAvatarView()
        return avatarView
    }()
    private let avatarSize: CGFloat = 36

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(avatarView)
        avatarView.setMaskView()
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAvatarBy(by identifier: String, avatarKey: String) {
        avatarView.setAvatarBy(by: identifier, avatarKey: avatarKey)
    }

    func setAvatar(by image: UIImage) {
        avatarView.image = image
    }
}
