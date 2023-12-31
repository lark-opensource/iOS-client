//
//  DriveCardModeTap.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/1/13.
//

import Foundation
import SKFoundation
import SKCommon

// iPad鼠标模式下UITap会将长按识别成单击问题 https://bytedance.feishu.cn/docx/doxcnxFapRFuM38pe2Nuxm0Awih
class DriveCardModeTap: UITapGestureRecognizer {
    private let maxTime: TimeInterval = 0.25
    private let maxDistance: CGFloat = 10
    private var touchBeginTime: TimeInterval = 0.0 // 点击时间
    private var moveDist = 0.0 // 累计移动距离
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        DocsLogger.driveInfo("DriveTapEnterFull -- touchesBegan")
        touchBeginTime = Date().timeIntervalSince1970
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        DocsLogger.driveInfo("DriveTapEnterFull -- touchesMoved")
        guard let touch = touches.first else {
            state = .failed
            return
        }
        let previewLocation = touch.previousLocation(in: view)
        let newPoint = touch.location(in: view)
        let xDist = newPoint.x - previewLocation.x
        let yDist = newPoint.y - previewLocation.y
        let move = sqrt((xDist * xDist) + (yDist * yDist))
        moveDist += move
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        DocsLogger.driveInfo("DriveTapEnterFull -- touchesCancelled")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        let endTime = Date().timeIntervalSince1970
        if endTime - touchBeginTime < maxTime && moveDist < maxDistance {
            self.state = .ended
        } else {
            self.state = .failed
        }
        DocsLogger.driveInfo("DriveTapEnterFull -- touchesEnded time \(endTime - touchBeginTime), moveDist = \(moveDist)")
    }
    
    override func reset() {
        super.reset()
        self.moveDist = 0.0
        self.touchBeginTime = 0.0
    }
}
