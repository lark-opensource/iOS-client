//
//  UDLoadingImageView.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/10/19.
//

import Foundation
import UIKit
import Lottie

public final class UDLoadingImageView: UIView {
    
    private var useInnerResource = false
    private var lottiView: LOTAnimationView
    private var isPlaying: Bool = false

    public var isAnimationPlaying: Bool {
        get {
            return self.lottiView.isAnimationPlaying
        }
    }

    public init(lottieResource: String?) {
        self.lottiView = LOTAnimationView()
        super.init(frame: .zero)
        
        if let path = lottieResource {
            self.lottiView = LOTAnimationView(filePath: path)
        } else if let path = self.lottieResourcePath() {
            self.lottiView = LOTAnimationView(filePath: path)
            useInnerResource = true
        }
        
        addSubview(self.lottiView)
        self.lottiView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.height.equalTo(Layout.designSize)
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(lottieRestart),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        self.lottiView.loopAnimation = true
        self.lottiView.play()
        self.isPlaying = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isHidden: Bool {
        didSet{
            if isHidden {
                self.stop()
            }else{
                self.play()
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.lottiView.loopAnimation = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        self.lottiView.stop()
        self.isPlaying = false
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #available(iOS 13.0, *),
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }
        themeDidChange()
    }
 
    private func themeDidChange() {
        guard useInnerResource else {
            /// 使用内置资源才响应模式主体切换
            return
        }
        lottiView.stop()
        lottiView.removeFromSuperview()
        lottiView = LOTAnimationView(filePath: self.lottieResourcePath() ?? "")
        addSubview(lottiView)
        lottiView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.height.equalTo(Layout.designSize)
        }
        lottiView.loopAnimation = true
        lottiView.play()
    }
    
    private func lottieResourcePath() -> String? {
        var fileSuffix = "lm"
        if #available(iOS 13.0, *) {
            fileSuffix = self.traitCollection.userInterfaceStyle == .dark ? "dm" : "lm"
        }
        let fileName = "data_" + fileSuffix
        let jsonPath = BundleConfig.UniverseDesignLoadingBundle.path(
            forResource: fileName,
            ofType: "json",
            inDirectory: "Lottie/loading_image")
        return jsonPath
    }

    @objc
    private func lottieRestart() {
        guard self.isPlaying else { return }
        guard self.superview != nil else { return }
        guard !self.isHidden && !self.lottiView.isHidden else { return }
        self.lottiView.stop()
        self.lottiView.play()
    }

    @objc
    public func play() {
        guard !self.isHidden && !self.lottiView.isHidden else { return }
        guard !self.lottiView.isAnimationPlaying else { return }
        self.lottiView.play()
        self.isPlaying = true
    }

    @objc
    public func stop() {
        guard self.lottiView.isAnimationPlaying else { return }
        self.lottiView.stop()
        self.isPlaying = false
    }
}

extension UDLoadingImageView {
    enum Layout {
        static let designSize: CGFloat = 124.0
        static let topHeightRatio: CGFloat = 1 / 3
    }
}
