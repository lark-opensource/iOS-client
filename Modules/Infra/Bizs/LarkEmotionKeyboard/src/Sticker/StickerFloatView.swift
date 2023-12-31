//
//  StickerFloatView.swift
//  Lark
//
//  Created by lichen on 2017/11/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import ByteWebImage

public enum EmotionFloatViewArrowDirection {
    case center
    case left
    case right
}

public final class StickerFloatView: UIView {
    var sticker: RustPB.Im_V1_Sticker? {
        didSet {
            self.emotionView.image = nil
            if let sticker = sticker {
                let key = sticker.image.origin.key
                self.emotionView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: sticker.stickerSetID),
                                                 trackStart: {
                                                    TrackInfo(scene: .Chat, isOrigin: true, fromType: .sticker)
                                                 })
            }
        }
    }

    private var bubbleView: UIImageView = UIImageView()
    
    public var emotionView: ByteImageView = ByteImageView()

    public lazy var desLabel: UILabel = {
        var desLabel = UILabel()
        desLabel.textColor = UIColor.ud.N600
        desLabel.font = UIFont.systemFont(ofSize: 16)
        desLabel.textAlignment = .center
        return desLabel
    }()

    public func setArrowDirection(direction: EmotionFloatViewArrowDirection, height: CGFloat) {
        switch direction {
        case .left:
            self.drawUIBezierPath(delta: -35, height: height)
        case .right:
            self.drawUIBezierPath(delta: 35, height: height)
        case .center:
            self.drawUIBezierPath(delta: 0, height: height)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        bubbleView.isUserInteractionEnabled = false
        bubbleView.contentMode = .scaleToFill
        self.addSubview(bubbleView)
        bubbleView.snp.makeConstraints({ make in
            make.top.equalTo(6)
            make.width.equalTo(140)
            make.height.equalTo(170)
            make.centerX.equalToSuperview()
        })
        bubbleView.backgroundColor = UIColor.ud.bgFloat
        bubbleView.clipsToBounds = false
        
        emotionView.isUserInteractionEnabled = false
        emotionView.contentMode = .scaleAspectFit
        self.addSubview(emotionView)
        emotionView.snp.makeConstraints({ make in
            make.top.equalTo(18)
            make.height.width.equalTo(116)
            make.centerX.equalToSuperview()
        })
        
        self.addSubview(self.desLabel)
        self.desLabel.snp.makeConstraints { (make) in
            make.top.equalTo(132)
            make.centerX.equalToSuperview()
            make.width.equalTo(emotionView.snp.width)
            make.height.equalTo(24)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 用贝塞尔曲线绘制气泡
    private func drawUIBezierPath(delta: CGFloat, height: CGFloat) {
        let corner: CGFloat = 8
        let bottomMargin: CGFloat = 7.5
        let arrowWidth: CGFloat = 15
        
        let bubbleViewWidth: CGFloat = 140
        let bubbleViewHeight: CGFloat = height + bottomMargin
        
        let arrowPoint : CGPoint = CGPoint(x: bubbleViewWidth / 2 + delta, y: bubbleViewHeight)
        
        let path = UIBezierPath()
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: corner, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: corner), controlPoint: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: bubbleViewHeight - bottomMargin - corner))
        path.addQuadCurve(to: CGPoint(x: corner, y: bubbleViewHeight - bottomMargin), controlPoint: CGPoint(x: 0, y: bubbleViewHeight - bottomMargin))
        path.addLine(to: CGPoint(x: arrowPoint.x - arrowWidth / 2, y: bubbleViewHeight - bottomMargin))
        path.addLine(to: arrowPoint)
        path.addLine(to: CGPoint(x: arrowPoint.x + arrowWidth / 2, y: bubbleViewHeight - bottomMargin))
        path.addLine(to: CGPoint(x: bubbleViewWidth - corner, y: bubbleViewHeight - bottomMargin))
        path.addQuadCurve(to: CGPoint(x: bubbleViewWidth, y: bubbleViewHeight - bottomMargin - corner), controlPoint: CGPoint(x: bubbleViewWidth, y: bubbleViewHeight - bottomMargin))
        path.addLine(to: CGPoint(x: bubbleViewWidth, y: corner))
        path.addQuadCurve(to: CGPoint(x: bubbleViewWidth - corner, y: 0), controlPoint: CGPoint(x: bubbleViewWidth, y: 0))
        path.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = bubbleView.bounds
        shapeLayer.path = path.cgPath
        
        bubbleView.layer.mask = shapeLayer
    }
    
}
