//
//  FollowableContentDelegate.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/9.
//  


import Foundation

public protocol FollowableContentDelegate: AnyObject {
    func onContentEvent(_ event: FollowModuleEvent, at mountToken: String?)
}
