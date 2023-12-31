//
//  UserPermissionCache.swift
//  SpaceInterface
//
//  Created by peilongfei on 2023/10/16.
//  


import Foundation

public protocol UserPermissionCache {

    associatedtype UserPermission: Codable

    func set(userPermission: UserPermission, token: String)

    func userPermission(for token: String) -> UserPermission?
}
