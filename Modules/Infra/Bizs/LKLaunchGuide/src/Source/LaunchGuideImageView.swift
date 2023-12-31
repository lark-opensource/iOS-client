//
//  LaunchGuideImageView.swift
//  LKLaunchGuide
//
//  Created by Miaoqi Wang on 2020/3/26.
//

import UIKit
import Foundation
import Lottie

typealias LaunchGuideImageView = UIView & LaunchGuideImageViewProtocol

/// Layout 的间距等常量
private enum Layout {
    static let imageSizeWidth: CGFloat = 250.0
}

enum ScrollDirection {
    case left
    case right
}

protocol LaunchGuideImageViewProtocol {
    func playAnimationIfCan()
    func stopAnimationIfCan()
    func playImagesWithAnimation()
    func initImageOffset(direction: ScrollDirection)
    func moveInWithProgress(progress: CGFloat)
    func moveOutWithProgress(progress: CGFloat)
}

/// 单张图片
private final class LaunchGuideImageViewWrapper: UIImageView, LaunchGuideImageViewProtocol {
    func playAnimationIfCan() {}
    func stopAnimationIfCan() {}
    func playImagesWithAnimation() {}
    func initImageOffset(direction: ScrollDirection) {}
    func moveInWithProgress(progress: CGFloat) {}
    func moveOutWithProgress(progress: CGFloat) {}
}

/// 视差效果，有多张图片
private final class LaunchGuideImagesView: UIView, LaunchGuideImageViewProtocol {
    private var imageViews: [UIImageView] = []
    func playAnimationIfCan() {}

    func stopAnimationIfCan() {
        for i in 0...self.imageViews.count - 1 {
            let imageView = self.imageViews[i]
            var rect = imageView.frame
            rect.origin.x = 0
            imageView.frame = rect
        }
    }

    func moveInWithProgress(progress: CGFloat) {
        for i in 0...self.imageViews.count - 1 {
            let imageView = self.imageViews[i]
            var rect = imageView.frame
            var left: CGFloat = 0
            left = Layout.imageSizeWidth * CGFloat(i) * 0.1 * progress
            left = max(left, 0)
            UIView.animate(withDuration: 0.1) {
                rect.origin.x = left
                imageView.frame = rect
            }
        }
    }

    func moveOutWithProgress(progress: CGFloat) {
        for i in 0...self.imageViews.count - 1 {
            let imageView = self.imageViews[i]
            var rect = imageView.frame
            var left = -Layout.imageSizeWidth * CGFloat(i) * 0.1 * progress
            left = min(left, 0)
            UIView.animate(withDuration: 0.1) {
                rect.origin.x = left
                imageView.frame = rect
            }
        }
    }

    func playImagesWithAnimation() {
        for i in 0...self.imageViews.count - 1 {
            let imageView = self.imageViews[i]
            var rect = imageView.frame
            if rect.origin.x == 0 {
                continue
            }
            UIView.animate(withDuration: 0.40) {
                rect.origin.x = 0
                imageView.frame = rect
            }
        }
    }

    func initImageOffset(direction: ScrollDirection) {
        for i in 0...self.imageViews.count - 1 {
            let imageView = self.imageViews[i]
            var rect = imageView.frame
            switch direction {
            case .left:
                rect.origin.x = -Layout.imageSizeWidth * 0.1 * CGFloat(i)
            break
            case .right:
                rect.origin.x = Layout.imageSizeWidth * 0.1 * CGFloat(i)
            break
            default: break
            }
            imageView.frame = rect
        }
    }

    init(images: [UIImage]) {
        super.init(frame: .zero)
        images.forEach { image in
            let imageView = UIImageView(image: image)
            self.addSubview(imageView)
            self.imageViews.append(imageView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LOTAnimationView: LaunchGuideImageViewProtocol {
    func playAnimationIfCan() { play() }
    func stopAnimationIfCan() { stop() }
    func playImagesWithAnimation() {}
    func initImageOffset(direction: ScrollDirection) {}
    func moveInWithProgress(progress: CGFloat) {}
    func moveOutWithProgress(progress: CGFloat) {}
}

extension LaunchGuideViewItem {
    func imageView() -> LaunchGuideImageView {
        switch imageResource {
        case .image(let image):
            return LaunchGuideImageViewWrapper(image: image)
        case .images(let images):
            return LaunchGuideImagesView(images: images)
        case .lottie(let lottie):
            let view = LOTAnimationView(name: lottie.name, bundle: lottie.bundle)
            view.contentMode = .scaleAspectFit
            return view
        }
    }
}
