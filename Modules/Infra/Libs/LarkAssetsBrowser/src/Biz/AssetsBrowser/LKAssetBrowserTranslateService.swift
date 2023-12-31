//
//  LKAssetBrowserTranslateService.swift
//  LarkUIKit
//
//  Created by shizhengyu on 2020/3/25.
//
import UIKit
import Foundation
import LarkUIKit

public struct AssetTranslationAbility {
    public let canTranslate: Bool
    public let srcLanguage: [String]

    public init(canTranslate: Bool = false, srcLanguage: [String] = []) {
        self.canTranslate = canTranslate
        self.srcLanguage = srcLanguage
    }
}

public protocol LKAssetBrowserTranslateService {
    func detectTranslationAbilityIfNeeded(assets: [LKDisplayAsset], completion: @escaping (Bool) -> Void)
    func assetTranslationAbility(assetKey: String) -> AssetTranslationAbility?
    func mainLanguage() -> String?
    func translateAsset(asset: LKDisplayAsset,
                        languageConflictSideEffect: (() -> Void)?,
                        completion: @escaping (LKDisplayAsset?, Error?) -> Void)
    func cancelCurrentTranslate()
}

// 翻译样式
extension UIView {
    static let imageTranslateAnimationViewTag = 909_000

    /// startImageScanAnimation
    func startImageTranslateAnimation(cancelBlock: (() -> Void)? = nil) {
        stopImageScanAnimation()

        let cover = ImageTranslateAnimationCover(cancelBlock: cancelBlock)
        cover.tag = UIView.imageTranslateAnimationViewTag
        addSubview(cover)
        cover.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        layoutIfNeeded()
        cover.startAnimation()
    }

    /// stopImageScanAnimation
    public func stopImageTranslateAnimation() {
        let cover = viewWithTag(UIView.imageTranslateAnimationViewTag)
        if let current = cover {
            current.removeFromSuperview()
        }
    }
}

class ImageTranslateAnimationCover: UIControl {

    private let cancelBlock: (() -> Void)?
    private let scanningImgLayer = CALayer()
    private let scanningAnimation = CABasicAnimation()
    private var scanningRect: CGRect = .zero

    init(cancelBlock: (() -> Void)?) {
        self.cancelBlock = cancelBlock
        super.init(frame: .zero)
        backgroundColor = UIColor.clear
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        self.addScanAnimation(rect: self.bounds)
    }

    private func addScanAnimation(rect: CGRect) {
        guard scanningRect != rect else {
            return
        }
        let image = Resources.scanning
        scanningRect = rect
        scanningImgLayer.isHidden = false
        scanningImgLayer.removeAllAnimations()
        scanningImgLayer.contents = image.cgImage
        scanningImgLayer.isHidden = false
        scanningImgLayer.frame = CGRect(x: (rect.width - image.size.width) / 2, y: -image.size.height, width: image.size.width, height: image.size.height)
        scanningAnimation.keyPath = "position.y"
        scanningAnimation.toValue = rect.height - image.size.height
        scanningAnimation.duration = 2
        scanningAnimation.repeatCount = Float.infinity
        scanningAnimation.isRemovedOnCompletion = false
        scanningImgLayer.add(scanningAnimation, forKey: "ScanAnimation")
    }

    func stopAnimation() {
        scanningImgLayer.removeAllAnimations()
        scanningImgLayer.isHidden = true
        scanningRect = .zero
    }

    @objc
    func cancelButtonClick() {
        cancelBlock?()
    }

    private func layoutPageSubviews() {
        self.layer.addSublayer(self.scanningImgLayer)
        self.scanningImgLayer.isHidden = true

        addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.width.height.equalTo(34)
            make.left.equalTo(20)
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(28)
        }
    }

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = (cancelBlock == nil)
        button.setImage(Resources.close_icon, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        return button
    }()

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds != self.scanningRect,
           !scanningImgLayer.isHidden {
            self.addScanAnimation(rect: self.bounds)
        }
    }
}
