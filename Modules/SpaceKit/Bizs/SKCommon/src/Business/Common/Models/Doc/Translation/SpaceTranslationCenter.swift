//
//  SpaceTranslationCenter.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/7/15.
//
// swiftlint:disable

import Foundation
import LarkLocalizations
import SpaceInterface

public final class SpaceTranslationCenter {

    public static let standard = SpaceTranslationCenter()

    // 展示逻辑
    public enum DisplayType: Int, Codable {
        case onlyShowOrigin = 1
        case onlyShowTranslation = 2
        case bothShow = 3
        case unKnown = 4
    }

    // 前端传过来的数据结果
    public struct Config: Codable {
        public init(autoTranslate: Bool, displayType: SpaceTranslationCenter.DisplayType, enableCommentTranslate: Bool) {
            self.autoTranslate = autoTranslate
            self.displayType = displayType
            self.enableCommentTranslate = enableCommentTranslate
        }
        
        let autoTranslate: Bool
        let displayType: DisplayType
        let enableCommentTranslate: Bool

        private enum CodingKeys: String, CodingKey {
            case autoTranslate = "enable_auto_translate"
            case displayType = "display_type"
            case enableCommentTranslate = "enable_comment_translate"
        }
    }

    var displayType: DisplayType {
        if let config = config {
            return config.displayType
        } else {
            return .unKnown
        }
    }

    // 前端配置
    public var config: Config?

    enum ConfigCase {
        case autoTranslationAndBothShow // 原文译文对照
        case autoTranslationAndonlyShowTranslation // 只显示译文
        case notAutoTranslation // 关闭自动翻译
        case unKnown // 未知情况
    }

    // 我们自己写的配置
    static var `case`: ConfigCase {
        if let config = standard.config {
            if config.autoTranslate {
                if config.displayType == .bothShow {
                    return .autoTranslationAndBothShow
                } else if config.displayType == .onlyShowTranslation {
                    return .autoTranslationAndonlyShowTranslation
                } else {
                    return .unKnown
                }
            } else {
                return .notAutoTranslation
            }
        } else {
            return .unKnown
        }
    }

    public var enableCommentTranslate: Bool {
        return self.config?.enableCommentTranslate ?? false
    }

   public var commentConfig: CommentTranslateConfig? {
        guard let conf = config else { return nil }
        return CommentTranslateConfig(autoTranslate: conf.autoTranslate,
                                      displayType: .init(rawValue: conf.displayType.rawValue) ?? .unKnown,
                                      enableCommentTranslate: conf.enableCommentTranslate)
    }

    private init() { }
}
