//
//  MomentsGridItemView.swift
//  Moment
//
//  Created by liluobin on 2021/1/9.
//

import Foundation
import UIKit
import LKCommonsLogging
import ByteWebImage
import UniverseDesignTheme

final class MomentsGridItemView: UIView {

    static let logger = Logger.log(MomentsGridItemView.self, category: "Module.Moments.MomentsGridItemView")
    var infoProp: ImageInfoProp
    var itemClickCallBack: ((ImageInfoProp) -> Void)?

    lazy var showImageView: SkeletonImageView = {
        let imageView = SkeletonImageView()
        imageView.animateRunLoopMode = .default
        return imageView
    }()

    init(item: ImageInfoProp, itemClickCallBack: ((ImageInfoProp) -> Void)?) {
        self.infoProp = item
        self.itemClickCallBack = itemClickCallBack
        super.init(frame: .zero)
        self.setupView()
        self.setImageActionForItem(item)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.layer.borderWidth = 0.5
        self.layer.ud.setBorderColor(UIColor.ud.N900.withAlphaComponent(0.15))
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(itemClick))
        self.addGestureRecognizer(tap)

        self.addSubview(showImageView)
        showImageView.frame = self.bounds
        showImageView.ud.setMaskView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if showImageView.frame != self.bounds {
            showImageView.frame = self.bounds
        }
    }
    func updateWith(item: ImageInfoProp, itemClickCallBack: ((ImageInfoProp) -> Void)?) {
        self.infoProp = item
        self.itemClickCallBack = itemClickCallBack
        self.setImageActionForItem(item)
    }

    func setImageActionForItem(_ item: ImageInfoProp) {
        item.setImageAction?(self.showImageView, item.index, { [weak self] (_, error) in
            if let error = error {
                Self.logger.error("MomentsGridItemView loadImage error: \(error)")
                self?.showImageView.image = Resources.imageDownloadFailed
                self?.showImageView.contentMode = .center
            } else {
                self?.showImageView.contentMode = .scaleAspectFill
            }
        })
    }

    func toggleAnimation(_ animated: Bool) {
        if animated {
            self.showImageView.autoPlayAnimatedImage = true
            self.showImageView.startAnimating()
        } else {
            self.showImageView.autoPlayAnimatedImage = false
            self.showImageView.stopAnimating()
        }
    }
    func stopAnimationIfNeed() {
        if self.showImageView.isAnimating {
            self.showImageView.autoPlayAnimatedImage = false
            self.showImageView.stopAnimating()
        }
    }
    @objc
    func itemClick() {
        self.itemClickCallBack?(self.infoProp)
    }
}
