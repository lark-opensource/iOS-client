//
//  BorderOperationCorePanel.swift
//  SKBrowser
//
//  Created by 吴珂 on 2020/8/13.
//


import Foundation
import UIKit
import SKUIKit
import SKResource
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon

enum BorderType: String {
    case noborder
    case fullborder
    case outerborder
    case innerborder
    case leftborder
    case rightborder
    case topborder
    case bottomborder
    case wrongBorder //兜底

    var selectedImage: UIImage? {
        let image: UIImage
        switch self {
        case .fullborder:
            image = UDIcon.bordersOutlined
        case .noborder:
            image = UDIcon.noBordersOutlined
        case .outerborder:
            image = UDIcon.outerBordersOutlined
        case .innerborder:
            image = UDIcon.innerBordersOutlined
        case .leftborder:
            image = UDIcon.leftBordersOutlined
        case .rightborder:
            image = UDIcon.rightBordersOutlined
        case .topborder:
            image = UDIcon.upBordersOutlined
        case .bottomborder:
            image = UDIcon.downBordersOutlined
        case .wrongBorder:
            image = UDIcon.bordersOutlined
        }
        return image.ud.withTintColor(UDColor.primaryContentDefault)
    }
    
    var normalImage: UIImage? {
        let image: UIImage
        switch self {
        case .fullborder:
            image = UDIcon.bordersOutlined
        case .noborder:
            image = UDIcon.noBordersOutlined
        case .outerborder:
            image = UDIcon.outerBordersOutlined
        case .innerborder:
            image = UDIcon.innerBordersOutlined
        case .leftborder:
            image = UDIcon.leftBordersOutlined
        case .rightborder:
            image = UDIcon.rightBordersOutlined
        case .topborder:
            image = UDIcon.upBordersOutlined
        case .bottomborder:
            image = UDIcon.downBordersOutlined
        case .wrongBorder:
            image = UDIcon.bordersOutlined
        }
        return image.ud.withTintColor(UDColor.iconN1)
    }
}

protocol BorderOperationCorePanelDelegate: AnyObject {
    func didSelectBorder(_ borderType: BorderType)
}

class BorderOperationCorePanel: UIView {
    enum Const {
        static let itemHeight: CGFloat = 48
        static let itemSpacing: CGFloat = 1
        static let margin: CGFloat = 16
        static let preferredHeight = itemHeight * 2 + itemSpacing + margin * 2
        static let defaultUnselectIndexPath = IndexPath(row: -1, section: 0)
    }
    
    static let preferredHeight: CGFloat = Const.preferredHeight
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout().construct { (it) in
            it.minimumLineSpacing = 0
            it.minimumInteritemSpacing = 0
            it.sectionInset = .zero
            it.scrollDirection = .vertical
        }
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(BorderCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    let cellReuseIdentifier = "BorderCell"
    
    var dataSource: [String] = ["noborder", "fullborder", "outerborder", "innerborder", "leftborder", "rightborder", "topborder", "bottomborder"]
    
    var lastHitIndexPath: IndexPath = Const.defaultUnselectIndexPath
    
    var didSelect: Bool {
        return lastHitIndexPath != Const.defaultUnselectIndexPath
    }
    
    var currentBorderType: String {
        return borderType(indexPath: lastHitIndexPath).rawValue
    }
    
    weak var delegate: BorderOperationCorePanelDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBody
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview().inset(Const.margin)
        }
    }
    
    func reset() {
        lastHitIndexPath = Const.defaultUnselectIndexPath
        collectionView.reloadData()
    }
    
    func update(dataSource: [String]) {
        if self.dataSource.count == dataSource.count {
            self.dataSource = dataSource
            let visibleIndexPath = collectionView.indexPathsForVisibleItems
            for indexPath in visibleIndexPath {
                if let cell = collectionView.cellForItem(at: indexPath) as? BorderCell {
                    updateCell(cell: cell, indexPath: indexPath)
                }
            }
        } else {
            self.dataSource = dataSource
            collectionView.reloadData()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func borderType(indexPath: IndexPath) -> BorderType {
        let borderString = dataSource[indexPath.row]
        if let borderType = BorderType(rawValue: borderString) {
            return borderType
        }
        
        return BorderType.wrongBorder
    }
    
    func select(type: BorderType) {
        if let index = dataSource.firstIndex(of: type.rawValue) {
            lastHitIndexPath = IndexPath(row: index, section: 0)
            collectionView.reloadData()
        }
    }

    //iPad转屏时刷新页面布局
    public func refreshViewLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension BorderOperationCorePanel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        lastHitIndexPath = indexPath
        delegate?.didSelectBorder(borderType(indexPath: indexPath))
        collectionView.reloadData()
    }
}

extension BorderOperationCorePanel: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        updateCell(cell: cell as? BorderCell, indexPath: indexPath)
        return cell
    }
    
    func updateCell(cell: BorderCell?, indexPath: IndexPath) {
        cell?.borderType = borderType(indexPath: indexPath)
        cell?.customIsSelected = lastHitIndexPath == indexPath
    }
}

extension BorderOperationCorePanel: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (collectionView.bounds.size.width - 3 * Const.itemSpacing) / 4
        return CGSize(width: itemWidth, height: Const.itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Const.itemSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Const.itemSpacing
    }
}

class BorderCell: UICollectionViewCell {
    
    let imageView = UIImageView().construct { (it) in
        it.contentMode = .scaleAspectFit
    }

    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.center.equalToSuperview()
        }
        guard SKDisplay.pad else { return }
        let hoverView = UIView()
        contentView.addSubview(hoverView)
        hoverView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        hoverView.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
    }
    
    var borderType: BorderType? {
        didSet {
            imageView.image = borderType?.normalImage?.ud.withTintColor(UDColor.iconN1)
            imageView.highlightedImage = borderType?.selectedImage?.ud.withTintColor(UDColor.colorfulBlue)
        }
    }
    
    var customIsSelected: Bool = false {
        didSet {
            contentView.backgroundColor = customIsSelected ? UDColor.fillActive : UDColor.bgBodyOverlay
            // 同时设置会出现highlightedImage异常的问题
            if customIsSelected {
                imageView.image = nil
            } else {
                imageView.highlightedImage = nil
            }
            imageView.isHighlighted = customIsSelected
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
