//
//  FolderRouterServices.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/4/8.
//  


import Foundation

// TODO Navigator
public protocol FolderRouterService {
    func open(resource: SKRouterResource, params: [AnyHashable: Any]?) -> UIViewController?
    func destinationController(for folderToken: String, sourceController: UIViewController, completion: @escaping (UIViewController) -> Void)
    func subordinateRecent(resource: SKRouterResource, params: [AnyHashable: Any]?) -> UIViewController?
}
