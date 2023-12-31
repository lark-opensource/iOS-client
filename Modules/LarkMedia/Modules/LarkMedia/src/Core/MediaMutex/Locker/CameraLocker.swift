//
//  CameraLocker.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/11/15.
//

import Foundation

class CameraLocker: SoloMediaLocker {
    convenience init() {
        self.init(mediaType: .camera)
    }
}
