//
//  CardContext.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import ECOProbe
import LarkContainer

public typealias UniversalCardTiming = (
    // 数据初始化时间点, 包含开始点和结束点, 执行在非主线程
    initCard: Date?, setupFinish: Date?,
    // 渲染时间点, 包含 template lynx 渲染时间, 执行在主线程
    renderStart: Date?, loadStart: Date?, loadFinish: Date?, renderFinish: Date?
)

// 卡片上下文的包装器, 用在 Lynx 上下文传递中,
// api 和 extension ui 会使用此类,通过 bridge 或 lynx 透传卡片上下文
public final class UniversalCardLynxBridgeContextWrapper {
    private var semaphore = DispatchSemaphore(value: 1)
    private var _cardContext: UniversalCardContext?
    public var cardContext: UniversalCardContext? {
        set {
            semaphore.wait(); defer { semaphore.signal() }
            _cardContext = newValue
        }
        get {
            semaphore.wait(); defer { semaphore.signal() }
            return _cardContext
        }
    }
    public init() {}
}

// 卡片上下文
public class UniversalCardContext {
    // Context 唯一标识符
    // 目前端上独立维护一个 Context Map, 用于在 扩展组件 和 API 中关联上下文, key 用的这个
    public let key: String
    public let trace: OPTrace
    public private(set) var renderingTrace: OPTrace?

    // 妥协字段, 目前 lynx 自定义组件部分场景需要拿到原始数据, 但是 lynx 没有能挂原始数据的地方, 所以挂 context 上.
    public private(set) var sourceData: UniversalCardData?

    // 卡片挂载的 vc
    public private(set) weak var sourceVC: UIViewController?
    // 卡片模板版本
    public private(set) var cardSDKVersion: String?
    // 卡片的外部依赖
    public let dependency: UniversalCardDependencyProtocol?
    // 外部业务类型, 埋点使用
    public let renderBizType: String?
    // 外部业务类型,
    // 这个字段会编码后传给 lynx, 然后在某些地方带端上. 如果需要传给 lynx 的数据,可以实现 encodeable 方法, 不需要的就不用管
    public let bizContext: Encodable?
    // 卡片交互传递给其他业务方的上下文信息，目前仅用于端通信，传递messageID与chatid
    public let actionContext: Encodable?
    //宿主类型,可能时消息，也可能工作台等
    public let host: String?

    public let deliveryType: String?

    public var timing: UniversalCardTiming = (
        initCard: nil, setupFinish: nil,
        renderStart: nil, loadStart: nil, loadFinish: nil, renderFinish: nil
    )

    public init(
        key: String,
        trace: OPTrace,
        sourceData: UniversalCardData?,
        sourceVC: UIViewController?,
        dependency: UniversalCardDependencyProtocol?,
        renderBizType: String?,
        bizContext: Encodable?,
        actionContext: Encodable? = nil,
        host: String? = nil,
        deliveryType: String? = nil
    ) {
        self.key = key
        self.trace = trace
        self.renderingTrace = trace.subTrace()
        self.sourceData = sourceData
        self.sourceVC = sourceVC
        self.dependency = dependency
        self.bizContext = bizContext
        self.actionContext = actionContext
        self.renderBizType = renderBizType
        self.host = host
        self.deliveryType = deliveryType
    }
    
    public func updateRenderingTrace() {
        renderingTrace = trace.subTrace()
    }


    public func updateSDKVersion(_ version: String?) {
        cardSDKVersion = version
    }
}
