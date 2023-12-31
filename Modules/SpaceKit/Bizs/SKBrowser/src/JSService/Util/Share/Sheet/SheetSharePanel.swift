//
//  SheetSharePanel.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/10/22.
//


import Foundation
import UIKit
import SnapKit
import SKCommon
import SKUIKit
import UniverseDesignColor

protocol SheetSharePanelDelegate: AnyObject {
//    func didSelectSaveImage(_ shareImagePanel: ShareImagePanel)
    func sharePanel(_ sharePanel: SheetSharePanel, didClickType type: ShareAssistType)
    func checkDownloadPermission() -> Bool
}

class SheetSharePanel: UIView {
    
    enum Const {
        static let preferredHeight: CGFloat = 114
    }

    private enum Layout {
        static let itemWidth: CGFloat = 64
        static let itemHeight: CGFloat = 84
        static let itemMSpacing: CGFloat = 4
        static let contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    weak var delegate: SheetSharePanelDelegate?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
        layout.minimumLineSpacing = Layout.itemMSpacing

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
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
    
//    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        
        backgroundColor = .clear
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.itemHeight)
        }
        
//        layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
//        layer.shadowOffset = CGSize(width: 5, height: -10)
//        layer.shadowOpacity = 1
//        layer.shadowRadius = 10
    }
    
    func refreshSaveImageEnable() {
        let canDownload = delegate?.checkDownloadPermission() ?? false
        if !canDownload {
            for data in self.dataSource where (data.type == .saveImage || data.type == .more) {
                data.enable = false
            }
        }
    }
}

extension SheetSharePanel: UICollectionViewDataSource {
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

extension SheetSharePanel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]
        delegate?.sharePanel(self, didClickType: item.type)
    }
}
