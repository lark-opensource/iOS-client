//
//  MinutesService.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation

/// Minutes 模块对外提供的接口
public protocol MinutesService: AnyObject {
    var tabURL: URL? { get set }

    /// 打开Minutes
    ///
    /// - Parameters:
    ///   - url: The URL of the minutes
    /// - Returns:
    ///   - Bool: whether the URL is an avalible URL of the minutes
    @discardableResult
    func openMinutes(_ url: URL?) -> AnyObject?

}
