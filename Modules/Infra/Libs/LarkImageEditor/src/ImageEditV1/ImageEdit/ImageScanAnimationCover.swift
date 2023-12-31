//
//  ImageScanAnimationCover.swift
//  LarkImageEditor
//
//  Created by Fan Xia on 2021/3/29.
//

import UIKit
import Foundation
import SnapKit

final class ImageScanAnimationCover: UIControl {
    private enum Param {
        static let scanAnimationDuration = 5.0
        static let scanLineHWScale = 124.0 / 750
        static let coverBackgroundColorChangeDuration = 0.35
        static let coverInitialBackgroundColor = UIColor.ud.N900.withAlphaComponent(0.0)
        static let coverTargetBackgroundColor = UIColor.ud.N900.withAlphaComponent(0.35)
    }

    private let cancelBlock: (() -> Void)?

    init(cancelBlock: (() -> Void)?) {
        self.cancelBlock = cancelBlock
        super.init(frame: .zero)
        backgroundColor = Param.coverInitialBackgroundColor
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimation() {
        UIView.animate(withDuration: Param.coverBackgroundColorChangeDuration) {
            self.backgroundColor = Param.coverTargetBackgroundColor
        }
        UIView.animate(withDuration: Param.scanAnimationDuration, delay: 0, options: .repeat, animations: {
            self.scanImageView.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.snp.top).offset(self.frame.height + self.scanImageView.frame.height)
            }
            self.scanImageView.superview?.layoutIfNeeded()
        })
    }

    @objc
    func cancelButtonClick() {
        cancelBlock?()
    }

    private func layoutPageSubviews() {
        addSubview(scanImageView)
        addSubview(cancelButton)
        scanImageView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(scanImageView.snp.width).multipliedBy(Param.scanLineHWScale)
            make.bottom.equalTo(self.snp.top).offset(0)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(36)
            make.bottom.equalToSuperview().inset(50)
            make.centerX.equalToSuperview()
        }
        scanImageView.superview?.layoutIfNeeded()
    }

    private lazy var scanImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.image = Resources.edit_scan_animation_line
        return view
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isHidden = (cancelBlock == nil)
        button.setImage(Resources.edit_scan_cancel_icon, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        return button
    }()
}

extension UIView {
    static let imageScanAnimationViewTag = 999_000

    /// startImageScanAnimation
    public func startImageScanAnimation(cancelBlock: (() -> Void)? = nil) {
        stopImageScanAnimation()

        let cover = ImageScanAnimationCover(cancelBlock: cancelBlock)
        cover.tag = UIView.imageScanAnimationViewTag
        addSubview(cover)
        cover.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        layoutIfNeeded()
        cover.startAnimation()
    }

    /// stopImageScanAnimation
    public func stopImageScanAnimation() {
        let cover = viewWithTag(UIView.imageScanAnimationViewTag)
        if let current = cover {
            current.removeFromSuperview()
        }
    }
}
