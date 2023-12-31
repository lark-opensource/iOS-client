//
//  PhotoGalleryManager.swift
//  Moment
//
//  Created by llb on 2020/12/31.
//

import Foundation
import UIKit

public final class PhotoInfoItem: NSObject {
    public let image: UIImage
    public let isVideo: Bool
    fileprivate(set) var itemFrame: CGRect = .zero
    fileprivate(set) var itemDeleCallBack: (() -> Void)?
    fileprivate(set) var itemClickCallBack: (() -> Void)?
    fileprivate(set) var isAddItem: Bool = false

    init(image: UIImage, isVideo: Bool) {
        self.image = image
        self.isVideo = isVideo
    }
}

struct PhotoGalleryConfig {
    let columnCount: Int
    let rowSpace: CGFloat
    let columnSpace: CGFloat
    let maxWidth: CGFloat
    let maxImageCount: Int
    let maxVideoCount: Int
    let autoFitSelf: Bool
    let itemCornerRadius: CGFloat?

    weak var superView: UIView?
    init(columnCount: Int = 3,
         rowSpace: CGFloat = 12,
         columnSpace: CGFloat = 12,
         maxImageCount: Int = 9,
         maxVideoCount: Int = 1,
         autoFitSelf: Bool = true,
         itemCornerRadius: CGFloat? = nil,
         maxWidth: CGFloat,
         superView: UIView) {
        self.columnCount = columnCount
        self.rowSpace = rowSpace
        self.columnSpace = columnSpace
        self.autoFitSelf = autoFitSelf
        self.itemCornerRadius = itemCornerRadius
        self.maxImageCount = maxImageCount
        self.maxVideoCount = maxVideoCount
        self.maxWidth = maxWidth
        self.superView = superView
    }
}

public protocol PhotoGalleryManagerDelegate: AnyObject {
    func photoGalleryDidClick(photoItem: PhotoInfoItem)
    func photoGalleryDidClickAddItem()
    func photoGalleryDidRemove(photoItem: PhotoInfoItem)
    func photoGalleryItemCountDidChangeTo(count: Int?)
}

final class PhotoGalleryManager: NSObject {
    /// 初始化items 数组
    var items: [PhotoInfoItem]
    public lazy var photoGalleryView: PhotoGalleryView = {
        return PhotoGalleryView(array: [self.defautAddItem], itemCornerRadius: self.config.itemCornerRadius)
    }()

    private var defautAddItem: PhotoInfoItem = {
        let item = PhotoInfoItem(image: Resources.momentsAdd, isVideo: false)
        item.isAddItem = true
        return item
    }()
    private let config: PhotoGalleryConfig
    weak var delegate: PhotoGalleryManagerDelegate?

    init(config: PhotoGalleryConfig,
         items: [PhotoInfoItem] = []) {
        self.items = items
        self.config = config
        self.items.append(defautAddItem)
        super.init()
        if let view = config.superView {
            view.addSubview(self.photoGalleryView)
        } else {
            assertionFailure("传入的superView = nil 无法正常展示")
        }

        layoutGalleryItemViews()
        self.photoGalleryView.addItems(self.items)
    }

    func addItems(_ addItems: [PhotoInfoItem]) {
        guard self.items.count - 1 >= 0, !addItems.isEmpty, let isVideo = addItems.first?.isVideo else {
            return
        }
        self.items.insert(contentsOf: addItems, at: self.items.count - 1)
        var needUpdateAddItemView = false
        if (!isVideo && self.items.count > self.config.maxImageCount) || (isVideo && self.items.count > self.config.maxVideoCount) {
            self.items.removeLast()
            needUpdateAddItemView = true
        }

        layoutGalleryItemViews()
        photoGalleryView.addItems(addItems)
        if needUpdateAddItemView {
            self.photoGalleryView.addItemView?.isHidden = true
        }
    }

    func removeItem(_ deleItem: PhotoInfoItem) {

        if !self.items.contains(deleItem) {
            return
        }

        self.items.removeAll { (item) -> Bool in
            return item == deleItem
        }
        self.delegate?.photoGalleryDidRemove(photoItem: deleItem)
        if let isAddItem = self.items.last?.isAddItem, !isAddItem {
            self.items.append(self.defautAddItem)
            self.photoGalleryView.addItemView?.isHidden = false
        }
        layoutGalleryItemViews()
        photoGalleryView.deleItem(deleItem)
    }

    func getItemIndex(item: PhotoInfoItem) -> Int? {
        return self.items.firstIndex(of: item)
    }

    private func layoutGalleryItemViews() {
        if self.items.isEmpty {
            self.delegate?.photoGalleryItemCountDidChangeTo(count: self.getCurrentLeftCount())
            self.items.append(self.defautAddItem)
            self.photoGalleryView.addItemView?.isHidden = false
            return
        }
        let width = self.config.maxWidth
        let itemWidth = (width - CGFloat((self.config.columnCount - 1)) * self.config.columnSpace) / CGFloat(self.config.columnCount)
        let itemHeight = itemWidth

        for (index, item) in self.items.enumerated() {
            let x = CGFloat(index % self.config.columnCount) * (itemWidth + self.config.columnSpace)
            let y = CGFloat(index / self.config.columnCount) * (itemHeight + self.config.rowSpace)
            item.itemFrame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
            item.itemDeleCallBack = { [weak self, weak item] in
                guard let item = item else {
                    return
                }
                self?.removeItem(item)
            }
            let isAdd = item.isAddItem
            item.itemClickCallBack = { [weak self, weak item] in
                guard let item = item else {
                    return
                }
                if !isAdd {
                    self?.delegate?.photoGalleryDidClick(photoItem: item)
                } else {
                    self?.delegate?.photoGalleryDidClickAddItem()
                }
            }
        }

        guard let lastItemFrame = self.items.last?.itemFrame else {
            return
        }

        if self.config.autoFitSelf {
            self.photoGalleryView.snp.remakeConstraints { (make) in
                make.top.left.bottom.equalToSuperview()
                make.width.equalTo(self.config.maxWidth)
                make.height.equalTo(lastItemFrame.maxY)
            }
        } else {
            self.photoGalleryView.frame = CGRect(x: 0, y: 0, width: self.config.maxWidth, height: lastItemFrame.maxY)
        }
        self.delegate?.photoGalleryItemCountDidChangeTo(count: self.getCurrentLeftCount())
    }

    func getCurrentLeftCount() -> Int {
        var count = self.items.count
        if let isAddItem = self.items.last?.isAddItem, isAddItem {
            count -= 1
        }
        return count
    }

    func adjustContentToMin() {
        self.photoGalleryView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(0)
        }
    }
}
