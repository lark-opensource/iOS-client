//
//  IconBuilderManager.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/13.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer

public typealias LIResult = (image: UIImage?, error: Error?)

public struct LarkIconExtend {
    //形状
    public var shape: LarkIconShape = .SQUARE
    public var layer: IconLayer?
    //默认图标
    public var placeHolderImage: UIImage?
    public var foreground: IconForeground?
    
    public init(shape: LarkIconShape = .SQUARE,
                layer: IconLayer? = nil,
                placeHolderImage: UIImage? = nil,
                foreground: IconForeground? = nil) {
        self.shape = shape
        self.layer = layer
        self.placeHolderImage = placeHolderImage
        self.foreground = foreground
    }
}

public class LarkIconManager: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    public var iconExtend: LarkIconExtend = LarkIconExtend(shape: .SQUARE)
    public var iconType: IconType = .none
    public var iconKey: String?
    let circleScale: CGFloat = 0.6 //圆形的按照标准，如果有设置图标的暂时缩小0.6
    let emojiBorderScale: CGFloat = 0.8 // emoji设置边框的，如果有设置图标的暂时缩小0.8
    
    
    //setting
    @ScopedProvider var iconSetting: LarkIconSetting?
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    public func builder(iconType: IconType,
                        iconKey: String?,
                        iconExtend: LarkIconExtend = LarkIconExtend(shape: .SQUARE)) -> Observable<LIResult> {
        
        self.iconKey = iconKey
        self.iconType = iconType
        self.iconExtend = iconExtend
        
        switch self.iconType {
        case .none:
            return .just(self.createDefultIcon())
        case .unicode:
            return .just(self.createEmojiIcon())
        case .image:
            return self.createDownLoadIcon()
        case .word:
            return .just(self.createWordIcon())
        }
    }
    
}
