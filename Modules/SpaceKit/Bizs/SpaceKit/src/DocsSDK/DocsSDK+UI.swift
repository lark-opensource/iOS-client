//
//  DocsSDK+UI.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/29.
//  


import Foundation
import SKCommon
import SKSpace
import SKBrowser
import SKFoundation
import SpaceInterface
import LarkContainer
import SKUIKit

// MARK: - UI

extension DocsSDK {
    
    private var vcFactory: SpaceVCFactory? {
        guard let factory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return nil
        }

        return factory
    }

    public func makeSpaceHomeViewController(userResolver: UserResolver, homeType: SpaceHomeType = .spaceTab) -> SpaceHomeViewController? {
        DocsTracker.startRecordTimeConsuming(eventType: .homeTabVCInit, parameters: nil)
        guard let factory = vcFactory else {
            return nil
        }
        let homeViewController = factory.makeSpaceHomeViewController(userResolver: userResolver, homeType: homeType)
        DocsTracker.endRecordTimeConsuming(eventType: .homeTabVCInit, parameters: nil)
        return homeViewController
    }
    
    public func makeSpaceNextHomeViewController(userResolver: UserResolver) -> SpaceHomeViewController? {
        DocsTracker.startRecordTimeConsuming(eventType: .homeTabVCInit, parameters: nil)
        
        guard let factory = vcFactory else {
            return nil
        }
        var homeViewController: SpaceHomeViewController?
        if SKDisplay.pad && UserScopeNoChangeFG.MJ.newIpadSpaceEnable {
            homeViewController = factory.makeSpaceNextHomeIpadViewController(userResolver: userResolver)
        } else {
            homeViewController = factory.makeSpaceNextHomeViewController(userResolver: userResolver)
        }
        DocsTracker.endRecordTimeConsuming(eventType: .homeTabVCInit, parameters: nil)
        return homeViewController
    }

    // 这部分代码需要收敛
    public func createDocs(from: UIViewController?, context: [String: Any]?) {
        guard let fromVC = docsRootVC ?? from else {
            DocsLogger.error("createDocs fail, docsRootVC and fromVC is nil")
            return
        }
        var docsType = DocsType.doc
        if LKFeatureGating.imCreateDocXEnable {
            docsType = .docX
        }
        EditorManager.shared.create(docsType, from: fromVC, isFromLark: true, context: context)
    }
}
