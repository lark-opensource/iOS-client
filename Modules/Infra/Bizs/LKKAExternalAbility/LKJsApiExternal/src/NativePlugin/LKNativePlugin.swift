//
//  LKNativePlugin.swift
//  LKNativePlugin
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation
import NativeAppPublicKit

@objcMembers
public class NativeAppApiConfigWrapper: NSObject, NativeAppApiConfigProtocol {
    var delegates: [KANativeAppPluginDelegate] = []
    public func getNativeAppAPIConfigs() -> Data {
        print("KA---Watch: KANativeAppAPIExternal.shared getNativeAppAPIConfigs")
        let temp = delegates.reduce([String](), { artialResult, delegate in
            artialResult + delegate.getPluginApiNames()
        })
        let configs = temp.map {
            KANativeAppAPIConfig(pluginClass: "KANativeAppAPIBasePlugin", apiName: $0 as String)
        }
        print("KA---Watch: KANativeAppAPIExternal.shared configs：\(configs)")
        return (try? PropertyListEncoder().encode(configs)) ?? Data()
    }

    public func getPlugin(pluginClassString: String) -> NativeAppPublicKit.NativeAppBasePlugin {
        let temp = KANativeAppAPIBasePlugin()
        temp.delegates = delegates
        temp.handle()
        return temp
    }

    public func getParams(paramsClassString: String, params: [AnyHashable: Any]) -> NativeAppPublicKit.NativeAppAPIBaseParams? {
        try? KANativeAppAPIBaseParams(with: params)
    }
}

struct KANativeAppAPIConfig: Codable {
    let pluginClass: String
    let apiName: String
}

//@objcMembers
class KANativeAppAPIBaseParams: NativeAppAPIBaseParams {
    var dic: [AnyHashable: Any]?
    public required init(with params: [AnyHashable: Any]) throws {
        dic = params
        try super.init(with: params)
    }
}

//@objcMembers
class KANativeAppAPIBaseResult: NativeAppAPIBaseResult {
    let dic: [String: Any]?
    init(resultType: NativeAppApiResultType, dic: [String: Any]?) {
        self.dic = dic
        super.init(resultType: resultType)
    }
    override func toJSONDict() -> [AnyHashable: Any] {
        dic ?? [:]
    }
}

@objcMembers
class KANativeAppAPIBasePlugin: NativeAppBasePlugin {
    deinit {
        print("KA---Watch: KANativeAppAPIBasePlugin deinit")
    }
    var apiDic: [String: KANativeAppPluginDelegate] = [:]
    var delegates: [KANativeAppPluginDelegate] = []
    override func onPluginContextBind(context: NativeAppPluginContextProtocol?) {
        guard let context else {
            print("KA---Watch: context is nil")
            return
        }
        print("KA---Watch: KANativeAppAPIBasePlugin set context")
        delegates.forEach {
            $0.setContext(context: context)
        }
    }
    func handle() {
        delegates.forEach { delegate in
            delegate.getPluginApiNames().forEach {
                apiDic[$0] = delegate
            }
        }
        apiDic.keys.forEach { api in
            registerAsyncHandler(for: api) { [weak self] params, callback in
                guard let params = params as? KANativeAppAPIBaseParams else {
                    return
                }
                print("KA---Watch: KANativeAppAPIBasePlugin web call params：\(params)")
                let temp = KANativeAppAPIEvent()
                temp.name = api as NSString
                temp.params = params.dic as? [String: Any]
                let delegate = self?.apiDic[api]
                delegate?.handle(event: temp, callback: { isSuccess, dic in
                    print("KA---Watch: KANativeAppAPIBasePlugin web callback isSuccess:\(isSuccess) result：\(dic)")
                    callback(NativeAppAPIBaseResult(resultType: isSuccess ? .success : .fail, data: dic))
                })
            }

        }
    }
}
