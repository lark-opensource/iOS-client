//
//  LynxLottieElement.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/12.
//  


import Foundation
import Lynx
import UIKit

class LynxLottieView: UIView {
    private var localSrc: String?
    private var lottieView: DocsUDLoadingImageView
    
    override init(frame: CGRect) {
        lottieView = DocsUDLoadingImageView(lottieResource: localSrc)
        super.init(frame: frame)
        addLottieView(lottieView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(localSrc: String) {
        if localSrc != self.localSrc {
            self.localSrc = localSrc
            lottieView.removeFromSuperview()
            addLottieView(DocsUDLoadingImageView(lottieResource: localSrc))
        }
    }
    private func addLottieView(_ lottieView: DocsUDLoadingImageView) {
        self.lottieView = lottieView
        self.addSubview(self.lottieView)
        self.lottieView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

class LynxLottieElement: LynxUI<LynxLottieView> {
    static let name = "ccm-lottie-view"
    override var name: String {
        return Self.name
    }
    
    override func createView() -> LynxLottieView {
        return LynxLottieView()
    }
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["src-local", NSStringFromSelector(#selector(setLocalSrc))]
        ]
    }
    @objc
    func setLocalSrc(value: String, requestReset _: Bool) {
        self.view().update(localSrc: value)
    }
}
