//
//  OPComponent.swift
//  OPSDK
//
//  Created by Limboy on 2020/11/4.
//

import Foundation
import LarkOPInterface
import OPFoundation

/// 这个是专门用于 Template 更新数据用的，通常是一个 Dictionary
@objc
public protocol OPComponentTemplateDataProtocol: NSObjectProtocol {

}

/// 传给 Component 展示的数据类型
/// 用空类型方便特定的 Component 内部去自定义
@objc
public protocol OPComponentDataProtocol: NSObjectProtocol {
    
}

/// Component 的 Error 信息统一在这里定义
public enum OPComponentError: Error {
    case paramError(String)
    case readFileError(String)
}

/// OPComponentContext 会结合 OPContainerContext，同时暴露 Component 特有的属性
@objcMembers
public final class OPComponentContext: NSObject {
    public let containerContext: OPContainerContext

    public let uniqueID: OPAppUniqueID

    public init(context: OPContainerContext) {
        self.containerContext = context
        self.uniqueID = self.containerContext.uniqueID
    }
}

/// OPComponent 的生命周期回调
/// 外部实际均为swift调用，此处@objc需要后续从最原始的协议处改为pure swift协议后再适配
@objc
public protocol OPComponentLifeCycleProtocol: AnyObject {
    /// Component 已经准备开始渲染了，回调一次，第一次页面加载dom ready时回调
    @objc optional func onComponentReady()

    /// Component 渲染过程中出了点问题，回调一次，第一次页面加载失败时回调
    @objc optional func onComponentFail(err: OPError)

    /// Component 高度大小发生变化 （实际等同于render内部真实内容发生变化）height单位为px
    @objc optional func contentHeightDidChange(component: OPComponentProtocol, height: CGFloat)

    /// Component 开始加载页面，可能会多次回调
    @objc optional func onPageStartRender(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol)

    /// Component  页面加载成功，可能会多次回调
    @objc optional func onPageRenderSuccess(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol)

    /// Component 页面加载失败，可能会多次回调
    @objc optional func onPageRenderFail(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol, error: OPError)

    /// Component 页面运行崩溃，可能会多次回调
    @objc optional func onPageRenderCrash(component: OPComponentProtocol, pageInfo: OPRenderPageDataProtocol, error: OPError?)

}

/// 所有特定的 Component 都要实现这个协议
@objc
public protocol OPComponentProtocol: NSObjectProtocol, OPNodeProtocol {

    var context: OPComponentContext { get }
    
    /// bridge 通信协议
    var bridge: OPBridgeProtocol { get }

    /// 通过 fileReader 可以获取特定 Component 依赖的资源
    init(fileReader: OPPackageReaderProtocol, context: OPContainerContext)

    /// 内部会转 data 的类型，如果转换失败会抛出错误
    func render(slot: OPViewRenderSlot, data: OPComponentDataProtocol) throws

    /// 重刷当前page
    func reRender()

    /// 添加生命周期观察者，同一个观察者可以添加多次，内部不做去重处理
    func addLifeCycleListener(listener: OPComponentLifeCycleProtocol)

    /// 内部会转 initData 的类型，如果转换失败会抛出错误
    func update(data: OPComponentTemplateDataProtocol) throws

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 show 事件
    func onShow()

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 hide 事件
    func onHide()

    /// Container 在 destroy 时，告诉 Component 要 destroy 了
    func onDestroy()
    
}

/// Render 生命周期事件的数据类型
/// 用空类型方便特定的 Render 内部去自定义
@objc
public protocol OPRenderPageDataProtocol: NSObjectProtocol {

}

/// render的生命周期回调
public protocol OPRenderLifeCycleProtocol: NSObjectProtocol {

    /// 页面开始渲染
    func onPageStartRender(info: OPRenderPageDataProtocol)

    /// 页面渲染完成
    func onPageSuccess(info: OPRenderPageDataProtocol)

    /// 页面渲染失败
    func onPageError(info: OPRenderPageDataProtocol, error: OPError)

    /// 页面崩溃
    func onPageCrash(info: OPRenderPageDataProtocol, error: OPError?)

    /// 页面height发生变化，用于通知外部进行大小自适应，height单位为px
    func contentHeightDidChange(height: CGFloat)

}

/// 所有特定的 render 都要实现这个协议
public protocol OPRenderProtocol: OPNodeProtocol {

    /// render生命周期，注意实现的时候使用weak
    var delegate: OPRenderLifeCycleProtocol? { get set }

    /// 内部会转 data 的类型，如果转换失败会抛出错误
    func render(slot: OPViewRenderSlot, data: OPComponentDataProtocol) throws

    /// 重新渲染当前页面
    func reRender()

    /// 内部会转 initData 的类型，如果转换失败会抛出错误
    func update(data: OPComponentTemplateDataProtocol) throws

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 show 事件, component 通知 render
    /// render 按需对view进行操作， 如layout等
    func onShow()

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 hide 事件, component 通知 render
    /// render 按需对view进行操作， 如layout等
    func onHide()

    /// Container 在 destroy 时，告诉 Component 要 destroy 了, component 通知 render
    /// render 按需对view进行操作， 如layout等
    func onDestroy()

}

/// 所有特定的 worker 都要实现这个协议
public protocol OPWorkerProtocol: OPNodeProtocol, OPBaseBridgeDelegate {

    /// 标识worker是否准备完成
    var isRuntimeReady: Bool { get }

    /// 接收API调用：一般为js -> native
    func invokeAPI(name: String, params: [AnyHashable: Any]?, extra: [AnyHashable: Any]?, callback: @escaping OPEventCallbackBlock) throws

    /// 触发消息发送: 一般为native -> js
    func publishEvent(name: String, params: [AnyHashable: Any]?, extra: [AnyHashable: Any]?, callback: @escaping OPEventCallbackBlock) throws

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 show 事件, component 通知 worker
    /// worker 按需进行操作， 如开始API调用等
    func onShow()

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 hide 事件, component 通知 worker
    /// worker 按需进行操作， 如pending API调用等
    func onHide()

    /// Container 在 destroy 时，告诉 Component 要 destroy 了, component 通知 worker
    /// worker 按需进行操作， 如清除API队列等
    func onDestroy()

}
