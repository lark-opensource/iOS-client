//
//  CardProtocols.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/13.
//

import Foundation

// MARK: Card View Protocol 卡片渲染引擎的能力
public protocol CardViewProtocol {

    /// 直接从 url 中下载卡片并加载
    /// - Parameter url: 在线template.js url
    func loadTemplate(from url: String)

    /// 从 url 中下载卡片，并附带初始化数据
    /// - Parameters:
    ///   - url: 在线template.js url
    ///   - initData: 初始化数据 json
    func loadTemplate(
        with url: String,
        initData: String?
    )

    /// 加载指定的本地卡片，并附上具有标识性的 url
    /// - Parameters:
    ///   - templateData: 本地template.js
    ///   - url: 具有标识性的 url
    func loadTemplate(
        with templateData: Data,
        url: String
    )

    /// 加载指定的卡片并附带初始化数据和具有标示性的 url
    /// - Parameters:
    ///   - templateData: 本地template.js
    ///   - url: 具有标识性的 url
    ///   - initData: 初始化数据 json
    func loadTemplate(
        with templateData: Data,
        url: String,
        initData: String?
    )

    /// 更新卡片数据
    /// - Parameter data: 需要更新的数据，并且数据不需要预处理,数据格式为json
    func updateCard(with data: String?)

    /// 更新卡片数据
    /// - Parameter data: map结构的数据
    func updateCard(with data: [String: Any]?)

    /// 触发布局
    func triggerLayout()
}

// MARK: Card LifeCycle Protocol
public protocol CardLifeCycleProtocol: AnyObject {

    /// Notify that content has started loading on CardView. This method is called once for each content loading request.
    /// - Parameter view: card view
    func cardViewDidStartLoading(_ view: CardViewProtocol)

    /// Notify that content has been sucessful loaded on CardView. This method is called once for each load content request.
    /// - Parameters:
    ///   - view: card view
    ///   - url: The url of the content
    func cardViewDidFinishLoading(_ view: CardViewProtocol, with url: URL?)

    /// Notify that CardView has been first layout after the content is loaded.
    /// - Parameter view: card view
    func cardViewDidLayoutFirstScreen(_ view: CardViewProtocol)

    /// Notify the JS Runtime is  ready.
    /// - Parameter view: card view
    func cardViewDidConstructJSRuntime(_ view: CardViewProtocol)

    /// Notify that CardView has been updated after updating data on CardView, but the view may not be updated.
    /// - Parameter view: card view
    func cardViewDidUpdateData(_ view: CardViewProtocol)

    /// Notify the intriniscContentSize has changed.
    /// - Parameter view: card view
    func cardViewDidChangeIntrinsicContentSize(_ view: CardViewProtocol, cardContentSize: CGSize)

    /// Notify that content has been sucessful loaded on CardView. This method is called once for each load content request.
    /// - Parameters:
    ///   - view: card view
    ///   - url: The url of the content
    ///   - error: Load failed error message
    func cardViewDidLoadFailed(_ view: CardViewProtocol, with url: String, error: Error?)

    /// Notify that CardView has error happens
    /// - Parameters:
    ///   - view: card view
    ///   - error: error message
    func cardViewDidRecieve(_ view: CardViewProtocol, error: Error?)
    
    /// Notify that CardView has received first load performance data
    /// - Parameters:
    ///   - view: card view
    ///   - perf: performance data
    func cardViewDidReceiveFirstLoadPerf(_ view: CardViewProtocol, perf: [AnyHashable: Any]?)
    
    /// Notify that CardView has received update performance data
    /// - Parameters:
    ///   - view: card view
    ///   - perf: performance data
    func cardViewDidReceiveUpdatePerf(_ view: CardViewProtocol, perf: [AnyHashable: Any]?)
}

/// 提供默认实现，实现protocol func optional
extension CardLifeCycleProtocol {
    /// Notify that content has started loading on CardView. This method is called once for each content loading request.
    /// - Parameter view: card view
    func cardViewDidStartLoading(_ view: CardViewProtocol) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidStartLoading")
    }

    /// Notify that content has been sucessful loaded on CardView. This method is called once for each load content request.
    /// - Parameters:
    ///   - view: card view
    ///   - url: The url of the content
    func cardViewDidLoadFinished(_ view: CardViewProtocol, with url: URL) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidFinishLoading, url:\(url)")
    }

    /// Notify that CardView has been first layout after the content is loaded.
    /// - Parameter view: card view
    func cardViewDidLayoutFirstScreen(_ view: CardViewProtocol) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidLayoutFirstScreen")
    }

    /// Notify the JS Runtime is  ready.
    /// - Parameter view: card view
    func cardViewDidConstructJSRuntime(_ view: CardViewProtocol) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidConstructJSRuntime")
    }

    /// Notify that CardView has been updated after updating data on CardView, but the view may not be updated.
    /// - Parameter view: card view
    func cardViewDidUpdateData(_ view: CardViewProtocol) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidUpdateData")
    }

    /// Notify the intriniscContentSize has changed.
    /// - Parameter view: card view
    func cardViewDidChangeIntrinsicContentSize(_ view: CardViewProtocol, cardContentSize: CGSize) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidChangeIntrinsicContentSize \(cardContentSize)")
    }

    /// Notify that content has been sucessful loaded on CardView. This method is called once for each load content request.
    /// - Parameters:
    ///   - view: card view
    ///   - url: The url of the content
    ///   - error: Load failed error message
    func cardViewDidLoadFailed(_ view: CardViewProtocol, with url: String, error: Error?) {
        BDPLogError(tag: .cardLifeCycle, "default cardViewDidLoadFailed, \(error)")
    }

    /// Notify that CardView has error happens
    /// - Parameters:
    ///   - view: card view
    ///   - error: error message
    func cardViewDidRecieve(_ view: CardViewProtocol, error: Error?) {
        BDPLogError(tag: .cardLifeCycle, "default cardViewDidRecieve")
    }
    
    /// Notify that CardView has received first load performance data
    /// - Parameters:
    ///   - view: card view
    ///   - perf: performance data
    func cardViewDidReceiveFirstLoadPerf(_ view: CardViewProtocol, perf: [AnyHashable: Any]?) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidReceiveFirstLoadPerf")
    }
    
    /// Notify that CardView has received update performance data
    /// - Parameters:
    ///   - view: card view
    ///   - perf: performance data
    func cardViewDidReceiveUpdatePerf(_ view: CardViewProtocol, perf: [AnyHashable: Any]?) {
        BDPLogInfo(tag: .cardLifeCycle, "default cardViewDidReceiveUpdatePerf")
    }
}

// MARK: Card Info Callback Protocol 容器给业务方的回调，可以让业务方监听到卡片的的meta 信息请求结果还有卡片渲染时的外观配置，不仅仅在启动的时候调用，按照新需求更新卡片也需要调用，不保证主线程回调
public protocol CardInfoListenerProtocol: AnyObject {

    /// 获取卡片meta结果回调
    /// - Parameter cardInfo: 卡片的meta信息
    func cardMetaCallback(with cardMeta: CardMeta)

    /// 返回卡片配置信息
    /// - Parameter config: 卡片外观配置数据
    func cardConfigCallback(with configData: Data)

    /// 当在获取卡片信息过程中出现异常时回调：meta获取失败，包下载失败，包安装失败
    /// - Parameter error: 异常
    func cardInfoError(with error: Error)

    /// meta数据是否合法 返回为空代表合法
    /// - Parameter cardMeta: 卡片
    func isMetaVaild(with cardMeta: CardMeta) -> Error?
}

/// 提供默认实现，实现protocol func optional
extension CardInfoListenerProtocol {
    /// 获取卡片meta结果回调
    /// - Parameter cardInfo: 卡片的meta信息
    func cardMetaCallback(with cardMeta: CardMeta) {
        BDPLogInfo(tag: .cardInfoListener, "default cardMetaCallback")
    }

    /// 返回卡片配置信息
    /// - Parameter config: 卡片外观配置数据
    func cardConfigCallback(with configData: Data) {
        BDPLogInfo(tag: .cardInfoListener, "default cardConfigCallback")
    }

    /// 当在获取卡片信息过程中出现异常时回调：meta获取失败，包下载失败，包安装失败
    /// - Parameter error: 异常
    func cardInfoError(with error: Error) {
        BDPLogError(tag: .cardInfoListener, "default cardInfoError, \(error)")
    }
}
