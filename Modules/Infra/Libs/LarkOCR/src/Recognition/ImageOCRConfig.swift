//
//  ImageOCRConfig.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import UIKit
import Foundation

public struct ImageOCRConfig {
    public var image: UIImage
    public var imageKey: String?
    public var service: ImageOCRService
    public weak var delegate: ImageOCRDelegate?
    public var ocrAnnotationUIConfig: AnnotationUIConfig
    public var extra: [String: Any]

    public init(
        image: UIImage,
        imageKey: String?,
        service: ImageOCRService,
        delegate: ImageOCRDelegate,
        ocrAnnotationUIConfig: AnnotationUIConfig = AnnotationUIConfig(),
        extra: [String: Any] = [:]
    ) {
        self.image = image
        self.imageKey = imageKey
        self.service = service
        self.delegate = delegate
        self.ocrAnnotationUIConfig = ocrAnnotationUIConfig
        self.extra = extra
    }
}
