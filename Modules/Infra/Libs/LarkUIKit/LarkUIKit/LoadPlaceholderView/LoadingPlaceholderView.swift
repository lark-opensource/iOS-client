//
//  LoadingView.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import UniverseDesignTheme
import UniverseDesignLoading

open class LoadingPlaceholderView: UIView {
    public var text: String = "" {
        didSet {
            label.text = self.text
        }
    }

    open var image: UIImage? {
        return nil
    }

    open override var frame: CGRect {
        didSet {
            if container.superview != nil {
                /// 调整边距，jira：https://jira.bytedance.com/browse/SUITE-60649
                container.snp.remakeConstraints { (make) in
                    make.centerX.left.right.equalToSuperview()
                    make.top.equalToSuperview().offset(frame.height / 3)
                }
            }
        }
    }

    open override var bounds: CGRect {
        didSet {
            if container.superview != nil {
                /// 调整边距，jira：https://jira.bytedance.com/browse/SUITE-60649
                container.snp.remakeConstraints { (make) in
                    make.centerX.left.right.equalToSuperview()
                    make.top.equalToSuperview().offset(bounds.height / 3)
                }
            }
        }
    }

    public let container = UIView()
    public let logo = UIImageView()
    public let label = UILabel()
    public var animationView = UDLoadingImageView(lottieResource: nil)

    private var isLoadingView: Bool {
        return self.image == nil
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgBody

        self.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(bounds.height / 3)
        }

        // logo
        logo.image = image
        container.addSubview(logo)
        logo.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 125, height: 125))
        }

        container.addSubview(animationView)
        animationView.snp.makeConstraints { (make ) in
            make.edges.equalTo(logo)
        }

        if isLoadingView {
            logo.isHidden = true
            animationView.isHidden = false
        } else {
            logo.isHidden = false
            animationView.isHidden = true
        }

        // 文案
        label.text = self.text
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        container.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(44)
            make.top.equalTo(logo.snp.bottom).offset(11)
            make.bottom.equalToSuperview()
        }
    }

   open override var isHidden: Bool {
        didSet {
            if isHidden {
                self.stop()
            } else {
                self.play()
            }
        }
    }

    private func play() {
        if isLoadingView {
            self.animationView.play()
        }
    }

    private func stop() {
        if isLoadingView {
            self.animationView.stop()
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.stop()
    }
}
