//
// Created by maozhixiang.lip on 2022/10/19.
//

import Foundation
import ByteViewNetwork

class LynxI18nModule: NSObject, LynxNativeModule {
    typealias Param = LynxNetworkParam

    private var loaders: [LynxI18nLoader]

    private(set) static var name: String = "I18n"
    private(set) static var methodLookup: [String: String] = [
        "load": NSStringFromSelector(#selector(load(keys:)))
    ]

    override required init() {
        self.loaders = [LocalLoader.shared]
        super.init()
    }

    required init(param: Any) {
        if let p = param as? Param {
            self.loaders = [LocalLoader.shared, NetworkLoader(httpClient: p.httpClient)]
        } else {
            self.loaders = [LocalLoader.shared]
        }
        super.init()
    }

    @objc func load(keys: [String]) -> [String: String] {
        for loader in self.loaders {
            let res = loader.load(keys: keys)
            if !res.isEmpty { return res }
        }
        return [:]
    }

    class LocalLoader: LynxI18nLoader {
        static let shared = LocalLoader()
        func load(keys: [String]) -> [String: String] {
            [:] // TODO : load i18n content locally
        }
    }

    class NetworkLoader: LynxI18nLoader {
        let httpClient: HttpClient
        init(httpClient: HttpClient) {
            self.httpClient = httpClient
        }

        func load(keys: [String]) -> [String: String] {
            var contents: [String: String] = [:]
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            httpClient.i18n.get(keys, completion: { result in
                defer { dispatchGroup.leave() }
                guard case let .success(i18nContent) = result else { return }
                contents = i18nContent
            })
            dispatchGroup.wait()
            return contents
        }
    }
}

protocol LynxI18nLoader {
    func load(keys: [String]) -> [String: String]
}
