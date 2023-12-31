//
//  DocsFollowAPI.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/2.
//  


import Foundation
import SpaceInterface

public struct DocsVCFollowState: FollowState {
    public let rawJson: String

    public init(rawJson: String) {
        self.rawJson = rawJson
    }

    public func toJSONString() -> String {
        return rawJson
    }
}
