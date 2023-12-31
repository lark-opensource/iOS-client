//
//  RainbowBridge.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/7/1.
//  

import Foundation

/// ⚠️ 小范围试用中, 要使用请先 @陈某豪
public class RainbowBridge {
    // MARK: - typealias
    internal typealias FunctionType = Any
//    public typealias Params = Any

    // MARK: - properties
//    public static let shared = RainbowBridge()

    /// 已经注册的对象
    private var serviceInfos: ThreadSafeDictionary<ServiceKey, ServiceEntry> = ThreadSafeDictionary<ServiceKey, ServiceEntry>()

    /**
     注册服务
     - service: Class/Struct
     - name: a key which enable you register the same Service type
     - factory: function
     */
    public func register<Service>(service: Service.Type,
                                  name: String? = nil,
                                  factory: @escaping (Service) -> Any?) {
        let entry = ServiceEntry(service: service, factory: factory)
        let key = ServiceKey(service, name: name)
        if serviceInfos.value(ofKey: key) != nil {
//            spaceAssertionFailure("RainbowBridge warning: ⚠️ Service 正在被重复注册")
        }
        serviceInfos.updateValue(entry, forKey: key)
    }

    /**
     创建服务
     - service: Class/struct
     - name: a key which enable you register the same Service type
     */
    @discardableResult
    public func call<Service>(_ service: Service,
                              name: String? = nil) -> Any? {
        let key = ServiceKey(type(of: service), name: name)
        guard let entry = serviceInfos.value(ofKey: key) else { return nil }
        if let factory = entry.factory as? (Service) -> Any? {
            return factory(service)
        }
        spaceAssertionFailure("RainbowBridge warning: ⚠️ 没找到对应的服务")
        return nil
    }

}

private extension RainbowBridge {
    private class ServiceKey: Hashable {
        static func == (lhs: RainbowBridge.ServiceKey, rhs: RainbowBridge.ServiceKey) -> Bool {
            return lhs.serviceType == rhs.serviceType
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(serviceType).hashValue)
            hasher.combine(name)
        }
        let serviceType: Any.Type
        let name: String?
        init(_ serviceType: Any.Type, name: String? = nil) {
            self.serviceType = serviceType
            self.name = name
        }
    }

    private struct ServiceEntry {
        let service: Any.Type
        let factory: FunctionType
    }
}
