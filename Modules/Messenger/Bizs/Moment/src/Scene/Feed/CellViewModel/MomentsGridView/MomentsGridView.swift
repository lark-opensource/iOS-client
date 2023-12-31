//
//  MomentsGridView.swift
//  Moment
//
//  Created by liluobin on 2021/1/9.
//

import Foundation
import UIKit

typealias ImageViewCompletion = (UIImage?, Error?) -> Void
typealias SetImageAction = ((SkeletonImageView, Int, @escaping ImageViewCompletion) -> Void)?

final class ImageInfoProp {
    let originSize: CGSize
    let setImageAction: SetImageAction
    let imageClick: ((Int, [UIImageView]) -> Void)?
    fileprivate(set) var index: Int = 0
    init(originSize: CGSize,
         setImageAction: SetImageAction,
         imageClick: ((Int, [UIImageView]) -> Void)?) {
        self.originSize = originSize
        self.setImageAction = setImageAction
        self.imageClick = imageClick
    }
}

final class MomentsGridView: UIView {
    var imageList: [ImageInfoProp] = []
    var itemViews: [MomentsGridItemView] = []

    init(imageList: [ImageInfoProp]) {
        super.init(frame: .zero)
        self.imageList = imageList
        setupView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        for (index, item) in imageList.enumerated() {
            item.index = index
            let view = MomentsGridItemView(item: item) { [weak self](prop) in
                guard let self = self else { return }
                prop.imageClick?(index, self.itemViews.map({ $0.showImageView }))
            }
            self.addSubview(view)
            itemViews.append(view)
        }
    }

    func toggleAnimation(_ animated: Bool) {
        if self.itemViews.count == 1 {
            self.itemViews.first?.toggleAnimation(animated)
        } else {
            self.itemViews.forEach { $0.stopAnimationIfNeed() }
        }
    }
    func updateView(imageList: [ImageInfoProp]) {
        self.imageList = imageList
        if imageList.count != self.itemViews.count {
            self.itemViews.forEach { (view) in
                view.removeFromSuperview()
            }
            self.itemViews.removeAll()
            self.setupView()
        } else {
            for (index, item) in imageList.enumerated() {
                item.index = index
                let view = self.itemViews[index]
                view.updateWith(item: item) { [weak self](prop) in
                    guard let self = self else { return }
                    prop.imageClick?(index, self.itemViews.map({ $0.showImageView }))
                }
            }
        }
    }
}
