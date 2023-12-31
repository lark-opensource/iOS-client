//
//  ShareImagePanel.swift
//  TestCollectionView
//
//  Created by 吴珂 on 2020/4/16.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SKUIKit
import SKCommon
import UniverseDesignColor

protocol ShareImagePanelDelegate: AnyObject {
//    func didSelectSaveImage(_ shareImagePanel: ShareImagePanel)
    func shareImagePanel(_ shareImagePanel: ShareImagePanel, type: ShareAssistType, sourceView: UIView?)
    func checkDownloadPermission() -> Bool
}

class ShareImagePanel: UIView {
    
    private enum Layout {
        static let itemWidth: CGFloat = 64
        static let itemHeight: CGFloat = 84
        static let itemMSpacing: CGFloat = 4
        static let contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        static var topInset: CGFloat {
            (UIApplication.shared.statusBarOrientation.isLandscape && SKDisplay.phone) ? 8 : 24
        }
    }
    
    weak var delegate: ShareImagePanelDelegate?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
        layout.minimumLineSpacing = Layout.itemMSpacing

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UDColor.bgBody
        view.dataSource = self
        view.delegate = self
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        view.contentInset = Layout.contentInset
        view.register(ShareAssistCell.self, forCellWithReuseIdentifier: ShareAssistCell.reuseIdentifier)
        return view
    }()
    
    var dataSource: [ShareAssistItem] = [] {
        didSet {
            refreshSaveImageEnable()
            collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.snp.updateConstraints { (make) in
            make.top.equalToSuperview().inset(Layout.topInset)
        }
    }
    
    func setup() {
        backgroundColor = UDColor.bgBody
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(Layout.topInset)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.itemHeight)
        }
    }
    
    func refreshSaveImageEnable() {
        let canDownload = delegate?.checkDownloadPermission() ?? false
        if !canDownload {
            for data in self.dataSource where data.type == .saveImage {
                data.enable = false
            }
        }
        
        if !canDownload {
            for data in self.dataSource where data.type == .more {
                data.enable = false
            }
        }
    }
}

extension ShareImagePanel: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tempCell = collectionView.dequeueReusableCell(withReuseIdentifier: ShareAssistCell.reuseIdentifier, for: indexPath)
        guard let cell = tempCell as? ShareAssistCell else {
            return tempCell
        }
        
        cell.configure(by: dataSource[indexPath.row])
        cell.containerView.backgroundColor = UDColor.bgBodyOverlay
        return cell
    }
}

extension ShareImagePanel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]
        delegate?.shareImagePanel(self, type: item.type, sourceView: collectionView.cellForItem(at: indexPath))
    }
}
