//
//  DocsNativeEditorManager.swift
//  SKBrowser
//
//  Created by lijuyou on 2021/7/14.
//  


import Foundation
import SKEditor
import SKResource
import SKLynx

public struct DocsNativeEditorManager {

    public static func registerDependency() {

        BlockManager.registerDefaultBlock()
        SheetBlockModule.register()

        ImageHelper.setDownloader(KFImageDownloader.shared)
        registerToolbarHandler()
//        registerBlockMenuHandler()
        SKLynxManager.shared().setup(true)
    }



    private static func registerToolbarHandler() {
        DXToolBarHandlerManager.shared.register(handler: DXTextBlockToolbarHandler.self, for: .text)
        DXToolBarHandlerManager.shared.register(handler: DXHeadingBlockToolbarHandler.self, for: .heading)
        DXToolBarHandlerManager.shared.register(handler: DXBulletBlockToolbarHandler.self, for: .bullet)
    }

    private static func registerBlockMenuHandler() {
        BlockMenuManager.shared.register(handler: TextBlockMenuHandler.self, for: .text)
        BlockMenuManager.shared.register(handler: TextBlockMenuHandler.self, for: .heading)
        BlockMenuManager.shared.register(handler: TextBlockMenuHandler.self, for: .bullet)
        BlockMenuManager.shared.register(handler: BlockMenuHandler.self, for: .image)
        BlockMenuManager.shared.register(handler: TableBlockMenuHandler.self, for: .table)
        BlockMenuManager.shared.register(handler: BlockMenuHandler.self, for: .unknow)
    }
}
