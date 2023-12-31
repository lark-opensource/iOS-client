//
//  FeedCellDataSource.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/20.
//  


import Foundation
import UIKit

struct FeedMessageContent {
    
    /// 显示的富文本
    let text: NSAttributedString?
    
    /// 长按的气泡菜单
    let actions: [FeedContentView.MenuAction]
    
    /// nil不显示图标，play 动画图标， stop 静止图标
    let translateStatus: FeedContentView.TranslateStatus?
}

protocol FeedCellDataSource {
    
    /// 返回图片urlString 以及占位图, 当不支持展示当前消息类型时展示defaultDocsImage
    var avatarResouce: (url: String?, placeholder: UIImage?, defaultDocsImage: UIImage?) { get }
    
    /// 标题文字
    var titleText: String { get }
    
    /// 引文
    var quoteText: String? { get }
    
    /// 返回评论内容，可能异步返回
    func getContentConfig(result: @escaping (FeedMessageContent) -> Void)
    
    /// 返回翻译内容，可能异步返回
    func getTranslateConfig(result: @escaping (FeedMessageContent) -> Void)
    
    /// 返回时间，可能异步返回
    func getTime(time: @escaping (String) -> Void)
    
    /// 是否显示红点
    var showRedDot: Bool { get }
    
    /// 复用标识
    var cellIdentifier: String { get }
    
    /// 消息id
    var messageId: String { get }
    
    /// 内容文本是否可复制到剪贴板
    var contentCanCopy: Bool { get set }
}
