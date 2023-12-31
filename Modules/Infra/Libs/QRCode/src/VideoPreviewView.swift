//
//  VideoPreviewView.swift
//  QRCode
//
//  Created by jiangxiangrui on 2023/1/4.
//

import UIKit
import Foundation

final class VideoPreviewView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let vw = self.frame.width
        let vh = self.frame.height
        self.layer.sublayers?.forEach { layer in
            layer.frame = CGRect(x: 0, y: 0, width: vw, height: vh)
        }
    }
}
