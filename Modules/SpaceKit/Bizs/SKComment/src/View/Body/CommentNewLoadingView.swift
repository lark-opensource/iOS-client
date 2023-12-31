//
//  CommentNewLoadingView.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/7/6.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignLoading
import UniverseDesignTheme
import Lottie
import SKUIKit

class CommentNewLoadingView: UIView {
    
    private var spin: UDSpin?
    
    private let iconWH: CGFloat = 14.0
    ///白色渐变背景宽度默认值
    private let backViewWidth: CGFloat = 46.0
    
    /// 发送过程loadingIcon
    private lazy var sendingIndicatorView: LOTAnimationView = {
        return AnimationViews.commentSendLoadingAnimation.construct({
            $0.loopAnimation = true
            $0.autoReverseAnimation = false
            $0.backgroundColor = UIColor.clear
        })
    }()
    
    /// 白色渐变背景layer
    private var backLayer: CAGradientLayer?

    /// 白色渐变view，自动适配暗黑模式
    private lazy var backView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: backViewWidth, height: iconWH)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        it.layer.addSublayer(layer)
        let bgcolor = UIColor.ud.N00 & UIColor.ud.N100
        layer.ud.setColors([
            bgcolor.withAlphaComponent(1.00),
            bgcolor.withAlphaComponent(0.00)
        ])
        layer.locations = [0.4, 1]
        layer.startPoint = CGPoint(x: 0.25, y: 0.5)
        layer.endPoint = CGPoint(x: 0.75, y: 0.5)
        layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: -1, b: 0, c: 0, d: -3.36, tx: 1, ty: 2.26))
        self.backLayer = layer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        
        addSubview(backView)
        addSubview(sendingIndicatorView)
    
        backView.isHidden = true
        backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        sendingIndicatorView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.height.width.lessThanOrEqualTo(iconWH)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        backLayer?.position = self.backView.center
        backLayer?.bounds = self.backView.bounds
    }
    
    ///是否显示白色渐变蒙层
    func showBgMask(_ isShow: Bool) {
        self.backView.isHidden = !isShow
    }
    
    /// 开始转圈
    func startPlay() {
        sendingIndicatorView.play()
    }
    
    /// 停止转圈
    func endStop() {
        sendingIndicatorView.stop()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
