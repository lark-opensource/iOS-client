//
//  SyncStatusView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/11/11.
//

import UIKit
import SnapKit

// 为了复用同步状态，抽离出同步状态相关代码
public final class SyncStatusView: UIView {
    public var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    private let imageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func startRotation() {
        DispatchQueue.main.async { [weak self] in
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = 0
            animation.toValue = CGFloat(Double.pi * 2)
            animation.duration = 1.0
            animation.repeatCount = Float.infinity
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            self?.imageView.layer.add(animation, forKey: "RotationForeverAnimation")
        }
    }

    public func stopRotation() {
        imageView.layer.removeAnimation(forKey: "RotationForeverAnimation")
    }
}
