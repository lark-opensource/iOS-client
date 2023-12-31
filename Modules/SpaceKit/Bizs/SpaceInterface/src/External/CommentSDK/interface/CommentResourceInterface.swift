//
//  CommentResourceInterface.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/4/23.
//

import Foundation

public protocol CommentResourceInterface {
    var commentJSUrl: URL? { get }

    var commentJSVersion: String? { get }
}
