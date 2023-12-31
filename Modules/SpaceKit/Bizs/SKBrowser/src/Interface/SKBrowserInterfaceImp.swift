//
//  SKBrowserInterfaceImp.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/4/13.
//  从SKCommonDependencyImpl拆分迁移

import Foundation
import SpaceInterface
import RxSwift
import RxRelay
import LarkContainer

class SKBrowserInterfaceImp: SKBrowserInterface {
    
    private var userResolver: UserResolver {
        Container.shared.getCurrentUserResolver(compatibleMode: true)
    }
    
    var browsersStackIsEmptyObsevable: BehaviorRelay<Bool> {
        return userResolver.docs.editorManager?.browsersStackisEmpty ?? .init(value: false)
    }
    
    func editorPoolDrainAndPreload() {
        userResolver.docs.editorManager?.drainPoolAndPreload()
    }
    
}
