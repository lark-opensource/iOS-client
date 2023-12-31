//
//  HomeHoverItem.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/7/7.
//

import Foundation


public struct HomeHoverItem {
    public typealias Handler = ((HomeHoverItem, UIView) -> Void)
    
    public let icon: UIImage
    public let hoverBackgroundColor: UIColor
    public let handler: Handler
    
    public init(icon: UIImage,
                hoverBackgroundColor: UIColor,
                handler: @escaping HomeHoverItem.Handler) {
        self.icon = icon
        self.hoverBackgroundColor = hoverBackgroundColor
        self.handler = handler
    }
}
