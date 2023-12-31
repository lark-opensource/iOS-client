import Foundation

final class FormsConsumer: BTStatisticConsumer, BTStatisticNormalConsumer {
    
    private let eventName: String
    
    private let biz: String
    
    init(eventName: String, biz: String) {
        self.eventName = eventName
        self.biz = biz
    }
    
    func consume(
        trace: BTStatisticBaseTrace,
        logger: BTStatisticLoggerProvider,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        if currentPoint.name == "forms_end" {
            if let firstPoint = allPoint.first(where: { $0.name == "forms_start" }) {
                logger.send(
                    trace: trace,
                    eventName: eventName,
                    params: [
                        "biz": biz,
                        "time": Dictionary(uniqueKeysWithValues: allPoint.map { ($0.name, $0.timestamp) }),
                        "duration": Dictionary(uniqueKeysWithValues: allPoint.map { ($0.name, $0.timestamp - firstPoint.timestamp) }),
                    ]
                )
                return allPoint
            }
        }
        return []
    }
    
    func consumeTempPoint(
        trace: BTStatisticBaseTrace,
        currentPoint: BTStatisticNormalPoint,
        allPoint: [BTStatisticNormalPoint]
    ) -> [BTStatisticNormalPoint] {
        []
    }
    
}
