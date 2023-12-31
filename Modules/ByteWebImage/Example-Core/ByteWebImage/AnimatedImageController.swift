//
//  AnimatedImageController.swift
//  ByteWebImage_Example
//
//  Created by xiongmin on 2021/4/16.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import ByteWebImage

class AnimatedImageController: UIViewController, AnimatedViewDelegate {

    var imageView: ByteImageView!
    var url: URL?

    var forceStartIndex: Int = 0
    var forceStartFrame: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.imageView = ByteImageView()
        self.imageView.frame = CGRect(x: 0,
                                      y: 150,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.width * 0.75)
        self.view.addSubview(self.imageView)

        self.imageView.animatedDelegate = self
        self.imageView.forceStartIndex = forceStartIndex
        self.imageView.forceStartFrame = forceStartFrame
        self.imageView.autoPlayAnimatedImage = false
        let callbacks = ImageRequestCallbacks(decrypt: nil, progress: nil, completion: { [weak self] (_) in
            self?.imageView.play()
        })
        self.imageView.bt.setImage(self.url, callbacks: callbacks)

        let right = UIBarButtonItem(title: "Resize", style: .plain, target: self, action: #selector(reload))
        self.navigationItem.setRightBarButton(right, animated: true)
    }
    var resizeTimes: Int = 0
    @objc
    func reload() {
        resizeTimes += 1
        self.imageView.removeFromSuperview()
        self.imageView = ByteImageView()
        self.imageView.frame = CGRect(x: 0,
                                      y: 150,
                                      width: UIScreen.main.bounds.width,
                                      height: UIScreen.main.bounds.width * 0.75)
        self.view.addSubview(self.imageView)

        self.imageView.animatedDelegate = self
        self.imageView.forceStartIndex = forceStartIndex
        self.imageView.forceStartFrame = forceStartFrame
        self.imageView.autoPlayAnimatedImage = false
        let callbacks = ImageRequestCallbacks(decrypt: nil, progress: nil, completion: { [weak self] (_) in
            guard let self = self else { return }
            self.imageView.play()
            self.imageView.frame = CGRect(x: 0,
                                          y: 140,
                                           width: UIScreen.main.bounds.width - CGFloat(self.resizeTimes * 10),
                                           height: UIScreen.main.bounds.width * 0.75 - CGFloat(self.resizeTimes * 10))
        })
        self.imageView.bt.setImage(self.url, callbacks: callbacks)
    }

    func animatedImageViewCurrentFrameIndex(_ imageView: ByteWebImage.ByteImageView, image: UIImage, index: Int) {
        self.forceStartFrame = image
        self.forceStartIndex = index
    }

    func animatedImageView(_ imageView: ByteImageView, didPlayAnimationLoops count: UInt) {
    }

    func animatedImageViewDidFinishAnimating(_ imageView: ByteImageView) {
    }

    func animatedImageViewReadyToPlay(_ imageView: ByteImageView) {
    }

    func animatedImageViewHasPlayedFirstFrame(_ imageView: ByteImageView) {
    }

    func animatedImageViewCompleted(_ imageView: ByteImageView) {
    }
}
