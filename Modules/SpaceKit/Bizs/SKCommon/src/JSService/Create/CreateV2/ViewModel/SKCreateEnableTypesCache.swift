//
//  DocsCreateViewMaker.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/8/26.
//  

import LarkReleaseConfig
import SKFoundation
import SpaceInterface

final class SKCreateEnableTypesCacheImpl: SKCreateEnableTypesCache {
    var createEnableTypes: [DocsType] = []

    func updateCreateEnableTypes() {
        // ⚠️添加了新的因子记得加判断
        let needBitable = isEnableBitable()
        let needMindnote = isEnableMindnote()
        let needFolder = isEnableCreateFolder()
        let needDocX = isEnableDocX()
        /// 模板创建文档时用于过滤可用的模板
        createEnableTypes.removeAll()

        // ⚠️添加了新的因子记得加判断
        // 开始判断哪些 item 要显示
        addTypeToCreateItem(type: .doc)
        addTypeToCreateItem(type: .sheet)
        if needBitable { addTypeToCreateItem(type: .bitable) }
        if needMindnote { addTypeToCreateItem(type: .mindnote) }
        if needDocX { addTypeToCreateItem(type: .docX) }
        if needFolder { addTypeToCreateItem(type: .folder) }
        // Drive
        // 上传多媒体
        addTypeToCreateItem(type: .mediaFile)
        // 上传文件
        addTypeToCreateItem(type: .file)

    }
    private func addTypeToCreateItem(type: DocsType) {
        createEnableTypes.append(type)
    }

    private func isEnableMindnote() -> Bool {
        return DocsType.mindnoteEnabled
    }

    private func isEnableCreateFolder() -> Bool {
        return DocsConfigManager.isShowFolder
    }

    private func isEnableDocX() -> Bool {
        #if DEBUG
        return true
        #endif

        return DocsType.docX.enabledByFeatureGating
    }
    
    private func isEnableBitable() -> Bool {
        return DocsType.enableDocTypeDependOnFeatureGating(type: .bitable)
    }
}
