//
//  IMMentionSelecedView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import UniverseDesignIcon
import SwiftUI

final class IMMentionSelecdView:UIView {
    let collectionView: UICollectionView
    var unfoldButton = UIButton()
    var items: [IMMentionOptionType] = []
    var didDeleteItemHandler: ((IMMentionOptionType) -> Void)?
   
    init() {
        var collectionViewLayout: UICollectionViewLayout {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 36, height: 36)
            layout.minimumInteritemSpacing = 8
            return layout
        }
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.backgroundColor = UIColor.ud.bgBody
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)  // 8.0
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AvatarCollectionCell.self, forCellWithReuseIdentifier: "AvatarCollectionCell")
        self.addSubview(collectionView)
        
        unfoldButton.setImage(UDIcon.getIconByKey(.rightSmallCcmOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        unfoldButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 18)
        self.addSubview(unfoldButton)
        
        collectionView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(unfoldButton.snp.left)
        }
        unfoldButton.snp.makeConstraints { (make) in
            make.centerY.right.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(40)
        }
    }
    
    func reloadCollect(items: [IMMentionOptionType]) {
        self.items = items
        collectionView.reloadData()
        scrollToLastest(animated: true)
    }
    
    func scrollToLastest(animated: Bool) {
        if items.count > 1 {
            collectionView.scrollToItem(at: IndexPath(item: items.count - 1, section: 0), at: .right, animated: animated)
        }
    }
}


extension IMMentionSelecdView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCollectionCell", for: indexPath)
        let item = items[indexPath.row]
        if let mentionCell = cell as? AvatarCollectionCell {
            if let avatarID = item.avatarID, let avatarKey = item.avatarKey {
                mentionCell.setAvatarBy(by: avatarID,
                                           avatarKey: avatarKey)
            }
            if case .doc(let meta) = item.meta {
                mentionCell.setAvatar(by: meta.image)
            }
            if case .wiki(let meta) = item.meta {
                mentionCell.setAvatar(by: meta.image)
            }
            if item.id == "all" {
                var image = UIImage(named: "atAll", in: BundleConfig.LarkIMMentionBundle, compatibleWith: nil) ?? UIImage()
                mentionCell.setAvatar(by: image)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didDeleteItemHandler?(items[indexPath.row])
    }
    
}

private final class AvatarCollectionCell: UICollectionViewCell {

    private let avatarView = IMMentionAvatarView()
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
