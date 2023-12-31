//
//  SpaceHomeViewController+Config.swift
//  SKSpace
//
//  Created by majie.7 on 2023/8/14.
//

import Foundation


public struct SpaceHomeViewControllerConfig {
    
    //首页列表是否支持分页加载
    public let canLoadMore: Bool
    
    public init(canLoadMore: Bool) {
        self.canLoadMore = canLoadMore
    }
    
    public static let `default` = SpaceHomeViewControllerConfig(canLoadMore: true)
    
    // Space新首页
    public static let spaceNewHome = SpaceHomeViewControllerConfig(canLoadMore: true)
}
