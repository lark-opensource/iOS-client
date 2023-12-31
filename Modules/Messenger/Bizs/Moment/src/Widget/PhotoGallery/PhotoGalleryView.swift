//
//  PhotoGalleryView.swift
//  Moment
//
//  Created by llb on 2020/12/31.
//

import Foundation
import UIKit

final class PhotoGalleryView: UIView {
    var addItemView: PhotoGalleryItemView?
    var itemViews: [PhotoGalleryItemView] = []
    let itemCornerRadius: CGFloat?

    init(array: [PhotoInfoItem], itemCornerRadius: CGFloat?) {
        self.itemCornerRadius = itemCornerRadius
        super.init(frame: .zero)
        setupItemViewWithItems(array)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupItemViewWithItems(_ items: [PhotoInfoItem]) {
        for item in items {
            let itemView = PhotoGalleryItemView(item: item, cornerRadius: self.itemCornerRadius, frame: item.itemFrame)
            self.addSubview(itemView)
            self.itemViews.append(itemView)
            if item.isAddItem {
                self.addItemView = itemView
            }
        }
    }

    func addItems(_ items: [PhotoInfoItem]) {
        for item in items {
            let itemView = PhotoGalleryItemView(item: item, cornerRadius: self.itemCornerRadius, frame: item.itemFrame)
            self.addSubview(itemView)
            self.itemViews.append(itemView)
        }
        if let addItemView = self.addItemView {
            self.updateItemViewFrame(view: addItemView, toFrame: addItemView.item.itemFrame, animation: false)
        }
    }

    func updateItemViewFrame(view: PhotoGalleryItemView, toFrame: CGRect, animation: Bool) {
        guard view.frame != toFrame else {
            return
        }
        if animation {
            UIView.animate(withDuration: 0.25) {
                view.frame = toFrame
            }
        } else {
            view.frame = toFrame
        }
    }

    func deleItem(_ item: PhotoInfoItem) {
        self.itemViews.removeAll { (itemView) -> Bool in
            if itemView.item == item {
                itemView.removeFromSuperview()
                return true
            }
            return false
        }
        self.itemViews.forEach { [weak self] (itemView) in
            self?.updateItemViewFrame(view: itemView, toFrame: itemView.item.itemFrame, animation: true)
        }
    }

    func removeAllItem() {
        self.itemViews.forEach { (itemView) in
            itemView.removeFromSuperview()
        }
        self.itemViews.removeAll()
    }

}
