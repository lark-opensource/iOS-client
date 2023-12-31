//
//  FeedPresentProcessorDelegate.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/9.
//

import Foundation

protocol FeedPresentProcessorDelegate: AnyObject {
    /// delegate present对应Type的VC, 并在系统的completion中返回此VC，以供Processor后续管理
    ///
    /// - Parameters:
    ///   - type: present类型
    ///   - source: 事件触发源
    ///   - completion: 完成block
    func showPresent(for type: PresentType,
                     source: PopoverSource?,
                     completion: @escaping (FeedPresentAnimationViewController) -> Void)
}
