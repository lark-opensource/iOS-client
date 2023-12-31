//
//  ImageEditorAssembly.swift
//  LarkImageEditor
//
//  Created by Fan Xia on 2021/3/16.
//

import Foundation
import Swinject
import ServerPB

/// SmartMosaicResponse
public typealias SmartMosaicResponse = ServerPB.ServerPB_Image_understanding_SmartMosaicResponse
typealias Polygon = ServerPB.ServerPB_Image_understanding_Polygon
typealias Point = ServerPB.ServerPB_Image_understanding_Point
typealias ContentType = ServerPB.ServerPB_Image_understanding_Polygon.ContentType

/// ImageEditorDependency
public protocol ImageEditorDependency {
    /// isSmartMosaicEnabled
    func isSmartMosaicEnabled() -> Bool

    /// showBubbleGuide
    func showBubbleGuide(targetRect: CGRect, key: String, message: String)

    /// request
    func requestImageSmartMosaic(pngData: Data,
                                 detectText: Bool,
                                 detectAvatar: Bool,
                                 completionBlock: @escaping (Result<SmartMosaicResponse, Error>) -> Void)
}
