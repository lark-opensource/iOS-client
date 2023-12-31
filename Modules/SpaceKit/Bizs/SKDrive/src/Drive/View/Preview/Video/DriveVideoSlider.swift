//
//  DriveVideoSlider.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/12/17.
//

import UIKit
import LarkAssetsBrowser
import SKFoundation
import SKCommon

class DriveVideoSlider: LKVideoSlider {
    override func createPanGesture() -> UIPanGestureRecognizer {
        return DriveVideoSliderPan(target: self, action: #selector(handlePan(pan:)))
    }
}


class DriveVideoSliderPan: UIPanGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        DocsLogger.driveInfo("DriveVideoSliderPan -- touchesBegan")
        DocsLogger.driveInfo("DriveVideoSliderPan -- cancelWKGestureOnVideoSlider disable")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        DocsLogger.driveInfo("DriveVideoSliderPan -- touchesMoved")
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        DocsLogger.driveInfo("DriveVideoSliderPan -- touchesCancelled")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        DocsLogger.driveInfo("DriveVideoSliderPan -- touchesEnded")
    }
}
