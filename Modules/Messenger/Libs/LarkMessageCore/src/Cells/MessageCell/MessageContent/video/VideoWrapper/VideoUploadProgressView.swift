//
//  VideoUploadProgressView.swift
//  Action
//
//  Created by K3 on 2018/8/7.
//

import Foundation
import UIKit

final class VideoUploadProgressView: UIView {
    var uploadProgress: Double = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    var status: VideoViewStatus = .uploading {
        didSet {
            switch status {
            case .pause:
                backgroundView.image = BundleResources.continue_upload
            case .uploading:
                backgroundView.image = BundleResources.video_upload
            default: break
            }
            setNeedsDisplay()
        }
    }

    private let backgroundView: UIImageView

    init() {
        backgroundView = UIImageView()
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        backgroundView.image = BundleResources.video_upload
        backgroundView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        addSubview(backgroundView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }

    override func draw(_ rect: CGRect) {
        self.uploadProgress = min(uploadProgress, 0.99) // 弱网条件下，视频上传完成还要等消息发送成功，故最高只能到99%

        let lineWidth: CGFloat = 2
        let radius: CGFloat = 20
        switch status {
        case .uploading:
            break
        default:
            return
        }

        let pi = CGFloat(Double.pi)
        let start = -pi / 2
        let path = UIBezierPath(arcCenter: CGPoint(x: rect.width / 2, y: rect.height / 2),
                                radius: radius - lineWidth / 2,
                                startAngle: start,
                                endAngle: start + pi * 2 * CGFloat(uploadProgress),
                                clockwise: true)
        path.lineCapStyle = .round
        path.lineWidth = lineWidth
        UIColor.ud.colorfulBlue.setStroke()
        path.stroke()
    }
}
