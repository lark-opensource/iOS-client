//
//  CropperInterface.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/11/3.
//

import Foundation
import UIKit

/// GridConfigure
public struct GridConfigure {
    /// default config
    public static let `default` = GridConfigure()

    var cornerTouchSize: CGSize = CGSize(width: 60, height: 60)
    var cornerSize: (width: CGFloat, length: CGFloat) = (3, 17)
    var edgeThickNess: (horizontal: CGFloat, vertical: CGFloat) = (60, 60)
}

/// CropperConfigure
public struct CropperConfigure {

    public enum RatioStyle: Equatable {
        case single
        case more
        case custom(CGFloat)
    }

    /// default config
    public static let `default` = CropperConfigure()

    /// grid Config
    public var gridConfig: GridConfigure = .default

    /// squareScale
    public var squareScale: Bool = true

    /// minCropSize
    public var minCropSize: CGSize = CGSize(width: 60, height: 60)

    /// zoomingToFitDelay
    public var zoomingToFitDelay: TimeInterval = 0.5

    /// initialRect
    public var initialRect: CGRect?

    /// more ratio
    public var style: RatioStyle = .single

    /// supportRotate
    public var supportRotate: Bool = true

    /// init
    public init(
        squareScale: Bool = true,
        minCropSize: CGSize = CGSize(width: 60, height: 60),
        zoomingToFitDelay: TimeInterval = 0.5,
        initialRect: CGRect? = nil,
        style: RatioStyle = .single,
        supportRotate: Bool = true
    ) {
        self.squareScale = squareScale
        self.minCropSize = minCropSize
        self.zoomingToFitDelay = zoomingToFitDelay
        self.initialRect = initialRect
        self.style = style
        self.supportRotate = supportRotate
    }
}

/// 新旧CopperVC遵守的协议
public protocol CropViewController: UIViewController {
    /// 埋点事件处理闭包
    var eventBlock: ((ImageEditEvent) -> Void)? { get set }
    /// 完成按钮处理闭包
    var successCallback: ((UIImage, CropViewController, CGRect) -> Void)? { get set }
    /// 返回按钮处理闭包
    var cancelCallback: ((CropViewController) -> Void)? { get set }
}
