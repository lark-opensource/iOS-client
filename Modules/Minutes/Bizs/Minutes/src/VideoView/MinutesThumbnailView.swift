//
//  MinutesThumbnailView.swift
//  Minutes
//
//  Created by chenlehui on 2021/11/19.
//

import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor
import LarkExtensions
import MinutesFoundation
import MinutesNetwork
import UniverseDesignIcon
import Kingfisher
import YYCache
import UniverseDesignShadow

let PreloadCount = 6

class MinutesThumbnailView: UIView {

    enum ShowType {
        case fixed
        case follow
    }

    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 4
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        iv.layer.ud.setShadow(type: .s3Down)
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor.ud.N00.nonDynamic
        l.textAlignment = .center
        return l
    }()

    let thumbnailWidth: CGFloat = 160
    var margin: CGFloat = 16
    var bottomOffset: CGFloat = 0
    var leftOffset: CGFloat = 0
    var rightOffset: CGFloat = 0

    var showType = ShowType.fixed
    var isShowing = false
    var layoutWidth: CGFloat = 300

    var spriteInfo: SpriteInfo?
    var duration: TimeInterval = 0
    var value: CGFloat = 0 {
        willSet {
            isForward = newValue > value
        }
    }
    var isForward = true

    private lazy var imageCache: YYMemoryCache = {
        let cache = YYMemoryCache()
        cache.countLimit = 10
        return cache
    }()

    private lazy var imageDownloader: ImageDownloader = {
        let imageDownloader = ImageDownloader(name: "MinutesImageDownloader")
        imageDownloader.sessionConfiguration = MinutesAPI.sessionConfiguration
        return imageDownloader
    }()

    private var loadingURL: Set<String> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.equalTo(thumbnailWidth)
            make.height.equalTo(90)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(in view: UIView, with type: ShowType, originValue: CGFloat) {
        if isShowing { return }
        value = originValue
        showType = type
        isHidden = true
        updateImage(with: originValue)
        view.addSubview(self)
        switch type {
        case .fixed:
            snp.makeConstraints { make in
                make.top.equalTo(12)
                make.left.equalTo(margin)
            }
        case .follow:
            let centerX = centerX(with: originValue)
            snp.makeConstraints { make in
                make.bottom.equalTo(-bottomOffset)
                make.centerX.equalTo(centerX)
            }
        }
        isShowing = true
    }

    func hide() {
        removeFromSuperview()
        isShowing = false
    }

    func updateLayout(withProcess process: CGFloat, time: String?) {
        guard isShowing else { return }
        value = process
        titleLabel.text = time
        updateImage(with: process)
        if showType == .fixed { return }
        var centerX = centerX(with: process)
        snp.remakeConstraints { make in
            make.bottom.equalTo(-bottomOffset)
            make.centerX.equalTo(centerX)
        }
    }

    private func centerX(with process: CGFloat) -> CGFloat {
        var centerX = (layoutWidth - leftOffset - rightOffset) * process + leftOffset
        if centerX < thumbnailWidth / 2 + margin {
            centerX = thumbnailWidth / 2 + margin
        }
        if centerX > layoutWidth - thumbnailWidth / 2 - margin {
            centerX = layoutWidth - thumbnailWidth / 2 - margin
        }
        return centerX
    }

    private func downloadSpriteImage(with index: Int) {
        guard let info = spriteInfo else { return }
        let count = info.imgUrls.count
        if index < 0 || index >= count { return }
        let urlStr = info.imgUrls[index]
        if imageCache.containsObject(forKey: urlStr) || loadingURL.contains(urlStr) { return }
        guard let url = URL(string: urlStr) else { return }
        loadingURL.insert(urlStr)
        imageDownloader.downloadImage(with: url, options: [.cacheMemoryOnly], progressBlock: nil) { [weak self] res in
            switch res {
            case .success(let img):
                if let key = img.url?.cacheKey {
                    self?.imageCache.setObject(img.image, forKey: key)
                }
            case .failure:
                break
            }
            self?.loadingURL.remove(urlStr)
        }
    }

    private func preloadSpriteImage(with index: Int) {
        for i in 0...PreloadCount {
            if isForward {
                downloadSpriteImage(with: index + i)
            } else {
                downloadSpriteImage(with: index - i)
            }
        }
    }

    private func updateImage(with value: CGFloat) {
        guard let info = spriteInfo, info.imgUrls.count > 0 else { return }
        let currentTime = Int(duration * value)
        // 最后一张缩略图没有就用上一张
        let delta = ((Int(duration) - currentTime) < info.interval && info.isFull == false) ? -1 : 0
        let index = currentTime / (info.interval * info.xLen * info.yLen)
        guard index >= 0, index < info.imgUrls.count else { return }
        preloadSpriteImage(with: index)
        let spriteDuration = info.interval * info.xLen * info.yLen
        var smallIndex = Int((currentTime - spriteDuration * index ) / info.interval) + delta
        if smallIndex < 0 { smallIndex = 0 }
        let y = smallIndex / info.xLen * info.imgHeight
        let x = smallIndex % info.yLen * info.imgWidth
        let rect = CGRect(x: x, y: y, width: info.imgWidth, height: info.imgHeight)
        let key = info.imgUrls[index]
        if let img = imageCache.object(forKey: key) as? UIImage, let little = img.mins.cropping(to: rect) {
            imageView.image = little
            isHidden = false
        } else {
            isHidden = true
        }
    }

}

extension UIImage: MinsCompatible {}
extension MinsWrapper where Base: UIImage {

    func cropping(to rect: CGRect) -> UIImage? {
        var r = rect
        r.origin.x *= base.scale
        r.origin.y *= base.scale
        r.size.width *= base.scale
        r.size.height *= base.scale
        if r.width <= 0 || r.height <= 0 { return nil }
        if let imgRef = base.cgImage?.cropping(to: r) {
            let img = UIImage(cgImage: imgRef, scale: base.scale, orientation: base.imageOrientation)
            return img
        }
        return nil
    }
}
