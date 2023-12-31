//
//  EventDetailViewStatus.swift
//  Calendar
//
//  Created by Rico on 2021/9/17.
//

import UIKit
import Foundation

enum EventDetailViewStatus: CustomStringConvertible, CustomDebugStringConvertible {

    struct ErrorInfo: CustomStringConvertible, CustomDebugStringConvertible {
        let code: Int
        let tipImage: UIImage?
        let tips: String
        let canRetry: Bool

        var description: String {
            return "code: \(code), tips: \(tips)"
        }

        var debugDescription: String {
            description
        }

    }

    // 初始化状态
    case initial

    // 数据格式化（加载）中
    case reforming

    // 已加载日程数据
    case metaDataLoaded(_ metaData: EventDetailMetaData)

    // 在页面生命周期内，重新加载日程数据
    case refresh(_ metaData: EventDetailMetaData)

    // 日程错误情况
    case error(_ info: ErrorInfo)

    var description: String {
        switch self {
        case .initial: return "initial"
        case .reforming: return "reforming"
        case .metaDataLoaded(let metaData): return "metaDataLoaded: \(metaData.description)"
        case .refresh(let metaData): return "refresh: \(metaData.description)"
        case .error(let errorInfo): return "error: \(errorInfo.description)"
        }
    }

    var debugDescription: String {
        switch self {
        case .initial: return "initial"
        case .reforming: return "reforming"
        case .metaDataLoaded(let metaData): return "metaDataLoaded: \(metaData.debugDescription)"
        case .refresh(let metaData): return "refresh: \(metaData.debugDescription)"
        case .error(let errorInfo): return "error: \(errorInfo.debugDescription)"
        }
    }
}

extension EventDetailViewStatus {

    var shouldShowLoadingView: Bool {
        switch self {
        case .initial, .reforming: return true
        default: return false
        }
    }

    var shouldShowTipsView: Bool {
        switch self {
        case .error: return true
        default: return false
        }
    }

    var errorInfo: (image: UIImage?, tips: String, canRetry: Bool)? {
        guard shouldShowTipsView else {
            return nil
        }
        if case .error(let info) = self {
            return (info.tipImage, info.tips, info.canRetry)
        }
        return nil
    }
}
