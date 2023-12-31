//
//  WaterMarkService.swift
//  LarkWaterMark
//
//  Created by bytedance on 2021/2/9.
//

import UIKit
import Foundation
import RxSwift

public protocol WaterMarkService: WaterMarkCustomService {
    /// 获取当前明水印隐藏状态
    var imageViewIsHidden: Bool { get }
    /// 获取当图片（暗）水印隐藏状态
    var imageWaterMarkIsHidden: Bool { get }
    /// 获取全局明水印配置
    var globalWaterMarkIsShow: Observable<Bool> { get }
    /// 获取暗明水印配置
    var imageWaterMarkIsShow: Observable<Bool> { get }
    /// 全局水印是否在最前面（与remoteview有关）
    var globalWaterMarkIsFirstView: Observable<(UIWindow, Bool)> { get }
    /// 获取全局水印视图
    var globalWaterMarkView: Observable<UIView> { get }
    /// 获取黑暗模式水印视图
    var darkModeWaterMarkView: Observable<UIView> { get }
    /// 获取聊天水印视图
    func getWaterMarkImageByChatId(_ chatId: String, fillColor: UIColor?) -> Observable<UIView?>
    /// 用户变更时主动调用，通知刷新水印
    func updateUser()
    /// 设置水印配置，不会直接隐藏waterMarkView
    func viewIsHidden(_ isHidden: Bool)
    /// vc 页面共享屏幕及 magic share 区域水印
    func getVCShareZoneWatermarkView() -> Observable<UIView?>
    /// 在window添加视图后上移水印层级到最上层
    func onWaterMarkViewCoveredWithContext(_ context: WaterMarkContext)
}

public protocol WaterMarkCustomService {
    /// 获取屏幕尺寸的全局水印视图监听序列，会根据用户配置更新实时更新水印显隐和水印样式
    var globalCustomWaterMarkView: Observable<UIView> { get }
    
    /// 获取屏幕尺寸的兜底明水印视图监听序列，不会判断用户水印配置，返回用户名+手机号后四位（邮箱）兜底样式的水印
    var defaultObviousWaterMarkView: Observable<UIView> { get }
    
    /// 获取当前后台明水印配置信息，兜底返回默认配置
    var obvoiusWaterMarkConfig: [String: String] { get }
    
    /// 获取自定义尺寸的全局水印视图监听序列，会根据用户配置更新水印内容和水印样式
    /// - Parameter frame: 指定水印视图Frame，若不合法使用屏幕尺寸
    /// - Parameter forceShow: 是否忽略后台的水印显隐配置，true则强制展示水印, 默认为false
    func observeGlobalWaterMarkViewWithFrame(_ frame: CGRect, forceShow: Bool) -> Observable<UIView>
    
    /// 获取自定义尺寸的全局水印视图，使用用户配置的水印内容和样式
    /// - Parameter size: 指定水印视图Frame，若不合法使用屏幕尺寸
    /// - Parameter forceShow: 是否忽略后台的水印显隐配置，true则强制展示水印, 默认为false
    func getGlobalCustomWaterMarkViewWithFrame(_ frame: CGRect, forceShow: Bool) -> UIView
    
    /// 获取自定义Frame的默认水印视图，不会判断用户水印配置，返回用户名+手机号后四位（邮箱）兜底样式的水印
    func getDefaultWaterMarkViewWithFrame(_ frame: CGRect) -> UIView
}
