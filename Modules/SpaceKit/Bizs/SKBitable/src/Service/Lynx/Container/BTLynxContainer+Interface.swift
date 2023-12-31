//
//  BTLynxContainer+Interface.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import EEAtomic

public extension BTLynxContainer {

    //context的数据封装
    struct ContextData {
        let bizContext: [AnyHashable: Any]

        public init(bizContext: [AnyHashable: Any]) {
            self.bizContext = bizContext
        }
    }
    //container的数据封装
    struct ContainerData {
        public var contextData: ContextData
        public var config: Config

        public init(
            contextData: ContextData,
            config: Config
        ) {
            self.contextData = contextData
            self.config = config
        }
        
        // 改成 encodable
        func toDict() -> [String: Any] {
            return [
                "config": config.dictionary ?? [:],
                "contextData": contextData.bizContext
            ]
        }
    }
    
    struct Config: Encodable {
        var perferWidth: CGFloat
        var perferHeight: CGFloat?
        var maxHeight: CGFloat?
        public init(
            perferWidth: CGFloat,
            perferHeight: CGFloat? = nil,
            maxHeight: CGFloat? = nil
        ) {
            self.perferWidth = perferWidth
            self.perferHeight = perferHeight
            self.maxHeight = maxHeight
        }
        
        var dictionary: [String: AnyHashable]? {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(self) else { return nil }
            return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: AnyHashable] }
        }
    }
    

    static func create(_ containerData: BTLynxContainer.ContainerData, lifeCycleClient: BTLynxContainerLifeCycle? = nil) -> BTLynxContainer {
        return BTLynxContainer(
            containerData: containerData,
            lifeCycleClient: lifeCycleClient
        )
    }
    
}
