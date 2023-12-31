//
//  PhotoGalleryItemView.swift
//  Moment
//
//  Created by llb on 2020/12/31.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignTheme

final class PhotoGalleryItemView: UIView {
    let item: PhotoInfoItem
    let cornerRadius: CGFloat?
    lazy var imageView = UIImageView(image: item.image)

    init(item: PhotoInfoItem, cornerRadius: CGFloat?, frame: CGRect) {
        self.item = item
        self.cornerRadius = cornerRadius
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        imageView.ud.setMaskView()
        /// 视频的icon
        let coverView = UIView()
        coverView.layer.cornerRadius = cornerRadius ?? 0
        self.addSubview(coverView)
        coverView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.4)
        coverView.isHidden = !item.isVideo
        coverView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        /// 视频的icon
        let videoIconImageView = UIImageView(image: Resources.iconSendPostVideo)
        self.addSubview(videoIconImageView)
        videoIconImageView.isHidden = !item.isVideo
        videoIconImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 23, height: 24))
        }

        if item.isAddItem {
            imageView.contentMode = .center
        }
        if let radius = cornerRadius {
            imageView.layer.cornerRadius = radius
            imageView.clipsToBounds = true
            imageView.layer.borderWidth = 0.5
            imageView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.15).cgColor
            self.clipsToBounds = false
        }
        let removeView = PhotoRemoveView { [weak self] in
            self?.deleImage()
        }
        self.addSubview(removeView)
        removeView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(4)
            make.top.equalToSuperview().offset(-4)
            make.size.equalTo(PhotoRemoveView.bestSize)
        }
        removeView.setCornerStyle(width: PhotoRemoveView.bestSize.width)
        removeView.isHidden = item.isAddItem

        let tap = UITapGestureRecognizer(target: self, action: #selector(itemClick))
        self.addGestureRecognizer(tap)
        self.layoutIfNeeded()
    }

    func deleImage() {
        item.itemDeleCallBack?()
    }

    @objc
    func itemClick() {
        item.itemClickCallBack?()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                imageView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.15).cgColor
            }
        }
    }
}
