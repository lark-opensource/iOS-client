//
//  CardLifeCycle.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/8.
//

import Foundation

// 卡片生命周期代理(注意是卡片生命周期, 不是 lynx 的生命周期)
public protocol UniversalCardLifeCycleDelegate: AnyObject {
    // 开始执行渲染流程(切入主线程, 准备 loadTemplate)
    func didStartRender(context: UniversalCardContext?)
    // 容器开始准备加载模板 (load_template开始时的回调)
    func didStartLoading(context: UniversalCardContext?)
    // 容器加载模板完毕 (load_template 结束后的回调，可认为完全加载完成)
    func didLoadFinished(context: UniversalCardContext?)
    // 首屏渲染完成 (Lynx 首屏渲染完成)
    func didFinishRender(context: UniversalCardContext?, info: [AnyHashable : Any]?)
    // 执行错误(包含 js 执行错误及渲染错误)
    func didReceiveError(context: UniversalCardContext?, error: UniversalCardError)
    // 收到更新 ContentSize 通知
    func didUpdateContentSize(context: UniversalCardContext?, size: CGSize?)
    // 渲染刷新
    func didFinishUpdate(context: UniversalCardContext?, info: [AnyHashable : Any]?)
}

