//
//  WikiJSEventHandler.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/10/15.
//

import Foundation

public enum WikiJSEvent {
    case setWikiInfo
    case titleChanged
    case setWikiTreeEnable
    case permissionChanged
}
public protocol WikiJSEventHandler: AnyObject {
    func handle(event: WikiJSEvent, params: [String: Any])
}
