//
//  UDImageList.swift
//  UniverseDesignImageList
//
//  Created by 郭怡然 on 2022/9/7.
//
//
import Foundation
import SnapKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignProgressView

public class UDImageList: UIView {
    
    private enum ViewWidthClass {
        case mini
        case small
        case medium
        case large
    }
    
    public enum CameraBackground {
        case grey
        case white
        
        var bgColor: UIColor {
            switch self {
            case .grey:
                return UIColor.ud.bgFiller
            case .white:
                return UIColor.ud.udtokenComponentOutlinedBg
            }
        }
    }
    
    public private(set) var dataSource: [ImageListItem]
    
    public var configuration: Configuration
    
    public var onRetryClicked: ((ImageListItem) -> Void)?
    public var onImageClicked: ((ImageListItem) -> Void)?
    public var onCameraClicked: (() -> Void)?
    public var onDeleteClicked: ((ImageListItem) -> Void)?
    
    private var viewWidthClass: ViewWidthClass {
        switch self.bounds.width {
        case 0..<220:
            return .mini
        case 220..<320:
            return .small
        case 320..<416:
            return .medium
        default:
            return .large
        }
    }
    
    var itemsPerRow: CGFloat {
        switch self.bounds.width {
        case 0..<220:
            return 1
        case 220..<320:
            return 2
        case 320..<416:
            return 3
        default:
            // 公式：itemsPerRow*configuration.defaultItemSize + (itemsPerRow-1)*configuration.interitemSpacing + 2*configuration.leftRightMargin = self.bounds.width
            return (self.bounds.width - 2 * configuration.leftRightMargin + configuration.interitemSpacing) / (configuration.defaultItemSize + configuration.interitemSpacing)
        }
    }
    
    private lazy var currentItemSize: CGFloat = self.configuration.defaultItemSize
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewLeftAlignedLayout()
        layout.sectionInset = .zero
        layout.minimumLineSpacing = configuration.interitemSpacing
        layout.minimumInteritemSpacing = configuration.interitemSpacing
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .clear
        collection.insetsLayoutMarginsFromSafeArea = false
        collection.contentInsetAdjustmentBehavior = .never
        collection.register(ImageListCell.self,
                            forCellWithReuseIdentifier: ImageListCell.reuseIdentifier)
        collection.register(CameraCell.self, forCellWithReuseIdentifier: CameraCell.reuseIdentifier)
        return collection
    }()
    
    public init(dataSource: [ImageListItem], configuration: UDImageList.Configuration) {
        self.dataSource = dataSource
        self.configuration = configuration
        super.init(frame: .zero)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateCollectionViewHeight()
    }
    
    public func reloadItems(at index: Int) {
        guard index >= 0, index < dataSource.count else {
            assertionFailure("index is out of range!")
            return
        }
        collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
    }
    
    public func reloadAllItems() {
        collectionView.reloadData()
    }
    
    public func updateProgress(with id: String, progressValue: CGFloat) {
        guard let index = self.dataSource.firstIndex(where: { $0.id == id }),
              let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImageListCell else { return }
        self.dataSource[index].updateLoading(value: progressValue)
        cell.progressValue = progressValue
    }
    
    public func changeStatus(forItemWith id: String, to status: ImageListItem.Status) {
        guard let index = dataSource.firstIndex(where: { $0.id == id }) else { return }
        dataSource[index].status = status
        reloadItems(at: index)
    }
    
    public func deleteItem(item: ImageListItem) {
        guard let index = dataSource.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        dataSource.remove(at: index)
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        updateCollectionViewHeight()
    }

    public func insertItem(_ item: ImageListItem, at index: Int) {
        guard index >= 0, index <= dataSource.count else {
            assertionFailure("index is out of range!")
            return
        }
        dataSource.insert(item, at: index)
        var indexPaths = [index].map { IndexPath(item: $0, section: 0) }
        collectionView.insertItems(at: indexPaths)
        updateCollectionViewHeight()
    }
    
    public func appendItem(_ item: ImageListItem) {
        insertItem(item, at: dataSource.count)
    }
    
    private func updateCollectionViewHeight() {
        let rows = ceil(CGFloat(collectionView.numberOfItems(inSection: 0)) / itemsPerRow)
        let height = rows * currentItemSize + (rows - 1) * configuration.interitemSpacing
        collectionView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.edges.equalToSuperview()
        }
    }


    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.layoutSubviews()
        reloadAllItems()
        updateCollectionViewHeight()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func openCamera(_ sender: UITapGestureRecognizer){
        onCameraClicked?()
    }
}

// MARK: - UICollectionViewDataSource
extension UDImageList: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ImageListCellDelegate {

    public func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let widthPerItem: CGFloat
        if viewWidthClass == .medium || viewWidthClass == .small {
            let paddingSpace = configuration.interitemSpacing * (itemsPerRow - 1) + 2 * configuration.leftRightMargin
            let availableWidth = self.frame.width - paddingSpace
            widthPerItem = availableWidth / itemsPerRow
        } else {
            widthPerItem = configuration.defaultItemSize
        }
        currentItemSize = widthPerItem
      return CGSize(width: widthPerItem, height: widthPerItem)
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return min(dataSource.count + 1, configuration.maxImageNumber)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == dataSource.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCell.reuseIdentifier, for: indexPath) as? CameraCell ?? CameraCell()
            cell.backgroundColor = configuration.cameraBackground.bgColor
            let tapCameraView = UITapGestureRecognizer(target: self, action: #selector(openCamera(_:)))
            cell.contentView.addGestureRecognizer(tapCameraView)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageListCell.reuseIdentifier, for: indexPath) as? ImageListCell ?? ImageListCell()
            cell.configure(with: dataSource[indexPath.item])
            cell.delegate = self
            return cell
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: configuration.leftRightMargin,
                            bottom: 0,
                            right: configuration.leftRightMargin)
    }
}
