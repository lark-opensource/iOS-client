//
//  DrivePreviewPushMocker.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import UIKit
@testable import SpaceKit

class DrivePreviewPushMocker: DrivePreviewGetPushService {
    weak var delegate: DrivePreviewGetPushHandlerDelegate?

    func pushResult(_ data: DrivePreviewGetPushData) {
        delegate?.previewGetPushHandlerDidRecevied(data: data)
    }
}
