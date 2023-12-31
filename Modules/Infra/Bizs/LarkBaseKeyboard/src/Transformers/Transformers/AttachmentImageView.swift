//
//  AttachmentImageView.swift
//  Lark
//
//  Created by lichen on 2018/5/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import ByteWebImage
import EditTextView
import UniverseDesignTheme

public final class AttachmentImageView: ByteImageView, AttachmentPreviewableView {
    public enum State {
        case success
        case progress
        case failed
    }

    public var clickBlock: ((String, State) -> Void)?

    /// conform protocol `AttachmentPreviewableView`
    public lazy var previewImage: () -> UIImage? = { [weak self] in self?.image }

    let disposeBag: DisposeBag = DisposeBag()

    public let key: String
    public var state: State {
        didSet {
            self.updateUIWithState()
        }
    }

    private var iconMask: UIView = {
        let iconMask = UIView()
        iconMask.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
        return iconMask
    }()

    private var failedIcon: UIImageView = {
        let failedIcon = UIImageView()
        failedIcon.image = Resources.failed
        return failedIcon
    }()

    private var uploadingView: UIImageView = {
        let uploadingView = UIImageView()
        uploadingView.image = Resources.loading
        return uploadingView
    }()

    private var clickBtn: UIButton = UIButton(type: .custom)

    public init(key: String, state: State) {
        self.key = key
        self.state = state
        super.init(frame: CGRect.zero)
        self.setupViews()
        self.updateUIWithState()
        self.ud.setMaskView()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.addSubview(self.iconMask)
        self.iconMask.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.clickBtn.addTarget(self, action: #selector(clickImageView), for: .touchUpInside)
        self.addSubview(self.clickBtn)
        self.clickBtn.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.iconMask.addSubview(self.failedIcon)
        self.failedIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        self.iconMask.addSubview(self.uploadingView)
        self.uploadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    func updateUIWithState() {
        switch self.state {
        case .success:
            iconMask.isHidden = true
            self.removeRotateAnimation(view: uploadingView)
            self.isUserInteractionEnabled = false
        case .failed:
            iconMask.isHidden = false
            self.removeRotateAnimation(view: uploadingView)
            failedIcon.isHidden = false
            uploadingView.isHidden = true
            self.isUserInteractionEnabled = true
        case .progress:
            iconMask.isHidden = false
            uploadingView.isHidden = false
            failedIcon.isHidden = true
            self.addRotateAnimation(view: uploadingView)
            self.isUserInteractionEnabled = false
        }
    }

    private func addRotateAnimation(view: UIView, duration: CFTimeInterval = 1) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(CGFloat.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        view.layer.add(rotateAnimation, forKey: "rotateAnimation")
    }

    private func removeRotateAnimation(view: UIView) {
        view.layer.removeAllAnimations()
    }

    // 为了显示效果目前只支持失败状态点击
    @objc
    func clickImageView() {
        self.clickBlock?(self.key, self.state)
    }

    public func updateGifImageBackgroundColorIfNeed(_ gifBackgroundColor: UIColor?) {
        guard let gifBackgroundColor = gifBackgroundColor else { return }
        if self.image?.bt.isAnimatedImage == true {
            self.backgroundColor = gifBackgroundColor
        } else {
            self.backgroundColor = .clear
        }
    }
}
