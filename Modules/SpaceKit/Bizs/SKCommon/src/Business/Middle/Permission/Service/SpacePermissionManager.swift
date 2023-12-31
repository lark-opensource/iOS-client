//
//  SpacePermissionManager.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/18.
//  

import Foundation
import SKInfra

public class SpacePermissionManager {
    public static let share = SpacePermissionManager()

    private init() { }

//    // COPY FROM FEED
//    func canCopy(_ token: String) -> Bool {
//        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
//        // 这里可以信任 permissionManager 缓存，在 UpdateUserPermissionService 设置 UserDefaults 的时候，permissionManager 的缓存也设置过了
//        return permissionManager.getUserPermissions(for: token)?.canCopy() ?? false
//    }
    
    public func canEdit(_ token: String) -> Bool {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        // 这里可以信任 permissionManager 缓存，在 UpdateUserPermissionService 设置 UserDefaults 的时候，permissionManager 的缓存也设置过了
        return permissionManager.getUserPermissions(for: token)?.canEdit() ?? false
    }
}
