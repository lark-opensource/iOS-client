//
//  BTStatisticService.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/20.
//

protocol BTStatisticServiceProtocol {
    /*
      对 traceId 添加 extra，会和已有的 extra 进行 merge，会覆盖已有的同名 key
     */
    func addTraceExtra(traceId: String, extra: [String: Any])
    /*
     stop 一个 traceId，会在消费完毕后清除
     - includeChildren: 是否将 children 一并清除
     */
    func stopTrace(traceId: String, includeChildren: Bool)
    /// 清空所有数据，会在消费完毕后清除
    func stopAllTrace()

    /*
     创建一个 normalTrace，可使用 point 进行链路跟踪
     - parentTrace：指定父 traceId
     */
    func createNormalTrace(parentTrace: String?) -> String
    /// 添加 point
    func addNormalPoint(traceId: String, point: BTStatisticNormalPoint)
    /// 添加 consumer, 用于消费 point 进行埋点上报，可重复添加
    func addNormalConsumer(traceId: String, consumer: BTStatisticNormalConsumer)
    /// 移除一个 consumer
    func removeNormalConsumer(traceId: String, consumer: BTStatisticNormalConsumer)

    /// 创建一个 fpsTrace, 可对 FPS 和 dropFrame 进行监控
    func createFPSTrace(parentTrace: String?) -> BTStatisticFPSTrace
    func addFPSConsumer(
        traceId: String,
        consumer: BTStatisticFPSConsumer
    )
    func removeFPSConsumer(traceId: String, consumer: BTStatisticFPSConsumer)

    func removeAllConsumer(traceId: String)

    // 打开 slardar 静态掉帧监测
    func allowedNormalStateDropDetect(isAllowed: Bool)
}
