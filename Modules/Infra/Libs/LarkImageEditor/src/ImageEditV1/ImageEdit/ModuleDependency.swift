//
//  ModuleDependency.swift
//  LarkImageEditor
//
//  Created by Fan Xia on 2021/3/16.
//

import Foundation
import LarkSetting
import LarkGuide
import LarkRustClient
import ServerPB
import LarkContainer
import RxSwift
import LarkGuideUI

typealias SmartMosaicRequest = ServerPB.ServerPB_Image_understanding_SmartMosaicRequest
typealias ImageInfo = ServerPB.ServerPB_Image_understanding_ImageInfo

final class ModuleDependency {
    static var dependency: ImageEditorDependency? = ImageEditorDependencyImpl()
}

final class ImageEditorDependencyImpl: ImageEditorDependency {
    init() {}

    func isSmartMosaicEnabled() -> Bool {
        false
    }

    func showBubbleGuide(targetRect: CGRect, key: String, message: String) {
        // smart mosaic 功能下线
    }

    func requestImageSmartMosaic(pngData: Data, detectText: Bool, detectAvatar: Bool, completionBlock: @escaping (Result<SmartMosaicResponse, Error>) -> Void) {
        // smart mosaic 功能下线
    }
}
