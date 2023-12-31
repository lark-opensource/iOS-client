//
//  TiledImageController.swift
//  ByteWebImage_Example
//
//  Created by xiongmin on 2021/7/6.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import ByteWebImage

class TiledImageController: UIViewController {
    /// TiledImageView or HugeImageView
    var imageView: UIView!
    var scrollView: UIScrollView!
    var path: String

    init(with path: String, usePreview: Bool) {
        self.path = path
        super.init(nibName: nil, bundle: nil)
        imageView = usePreview ? HugeImageView() : TiledImageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        scrollView = UIScrollView(frame: CGRect(x: 0,
                                                y: 84,
                                                width: view.bounds.width,
                                                height: view.bounds.height - 84))
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        setImage()
        let items = [UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(reset)),
                     UIBarButtonItem(title: "Set", style: .plain, target: self, action: #selector(setImage))]
        navigationItem.rightBarButtonItems = items
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("---vc did appear")
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("---vc did disappear")
    }
    @objc
    func setImage() {
        func layoutViews(imageSize: CGSize) {
            imageView.frame = CGRect(origin: .zero, size: imageSize)
            imageView.frame = layout(size: imageView.frame.size, boundsSize: scrollView.bounds.size)
            scrollView.contentSize = imageSize
            scrollView.minimumZoomScale = view.bounds.width / imageSize.width
            scrollView.maximumZoomScale = 2
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            scrollView.zoomScale = 1
            scrollView.maximumZoomScale = 1
            scrollView.minimumZoomScale = 1
            if let imageView = imageView as? TiledImageView {
                try? imageView.set(with: data)
                layoutViews(imageSize: imageView.imageSize)
                imageView.update(maxScale: scrollView.maximumZoomScale, minScale: scrollView.minimumZoomScale)
            } else if let imageView = imageView as? HugeImageView {
                imageView.setImage(data: data) { result in
                    switch result {
                    case .success:
                        layoutViews(imageSize: imageView.imageSize)
                        imageView.updateTiledView(maxScale: self.scrollView.maximumZoomScale,
                                                  minScale: self.scrollView.minimumZoomScale)
                        print("display success, tiled: \(imageView.usingTile)")
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    @objc
    func reset() {
        if let imageView = imageView as? TiledImageView {
            imageView.reset()
        } else if let imageView = imageView as? HugeImageView {
            imageView.reset()
        }
    }

    func layout(size: CGSize, boundsSize: CGSize) -> CGRect {
        // Center the image as it becomes smaller than the size of the screen
        var frameToCenter = CGRect(origin: .zero, size: size)

        // Horizontally
        if frameToCenter.width < boundsSize.width {
            let newX = floor((boundsSize.width - frameToCenter.width) / CGFloat(2))
            frameToCenter.origin.x = newX
        } else {
            frameToCenter.origin.x = 0
        }

        // Vertically
        if frameToCenter.height < boundsSize.height {
            let newY = floor((boundsSize.height - frameToCenter.height) / CGFloat(2))
            frameToCenter.origin.y = newY
        } else {
            frameToCenter.origin.y = 0
        }

        return frameToCenter
    }
}

extension TiledImageController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.frame = layout(size: imageView.frame.size, boundsSize: scrollView.bounds.size)
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scale < scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
}
