//
//  PreloadStatus.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/1.
//  


import SKFoundation
import SpaceInterface

/// 预加载的状态
///
/// - preloading: 还在预加载
/// - docPreloaded: docs预加载成功了
/// - sheetPreloaded: sheet预加载成功了
public struct PreloadStatus {

    public var preloadedTypes = Set<DocsType>()

    public mutating func addType(_ type: String) {
        if type == "doc" {
            self.preloadedTypes.insert(.doc)
            self.statisticsStage = "doc"
        } else if type == "sheet" {
            self.preloadedTypes.insert(.sheet)
            self.statisticsStage = "sheet"
        } else if type == "mindnote" {
            self.preloadedTypes.insert(.mindnote)
            self.statisticsStage = "mindnote"
        } else if type == "slides" {
            self.preloadedTypes.insert(.slides)
            self.statisticsStage = "slides"
        } else if type == "wiki"{
            self.preloadedTypes.insert(.wiki)
            self.statisticsStage = "wiki"
        } else if type == "file"{
            DocsLogger.info("preloadedTypes is file")
        } else if type == "docx" {
            self.preloadedTypes.insert(.docX)
            self.statisticsStage = "docx"
        } else if type == "bitable" {
            self.preloadedTypes.insert(.bitable)
            self.statisticsStage = "bitable"
        } else if type == "baseAdd" {
            self.preloadedTypes.insert(.baseAdd)
            self.statisticsStage = "baseAdd"
        }
    }

    public var hasLoadSomeThing: Bool {
        return !preloadedTypes.isEmpty
    }

    /// 是否已经预加载好了对应文件的模板
    ///
    /// - Parameter type: 文件类型
    /// - Returns:  yes/no
    public func hasPreload(_ type: DocsType) -> Bool {
        return preloadedTypes.contains(type)
    }
    
    public func hasPreload(_ type: String) -> Bool {
        return preloadedTypes.contains {
            $0.name == type
        }
    }

    public var hasComplete: Bool {
        return preloadedTypes.contains(.mindnote)
    }

    public var statisticsStage: String?

    public init() {
        
    }
}
