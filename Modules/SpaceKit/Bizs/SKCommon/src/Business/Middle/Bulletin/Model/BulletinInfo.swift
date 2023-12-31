//
//  BulletinInfo.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/11.
//

import SKFoundation

public struct BulletinInfo {
    public var id: String
    public var content: [String: String] = [:]
    public var startTime: Int
    public var endTime: Int
    public var products: [String]
    ///verison用来判断在哪个版本展示，后台没有传version表示所有版本都展示，
    ///0～10000代表默认值，版本号大于0小于10000都展示
    public var version: [String: String] = [:]

    public init(id: String, content: [String: String], startTime: Int, endTime: Int, products: [String], version: [String: String] = ["start": "0", "end": "10000"]) {
        self.id = id
        self.content = content
        self.startTime = startTime
        self.endTime = endTime
        self.products = products
        self.version = version
    }

    var description: String {
        return "BulletinInfo description: id: \(id), content: \(content.description), startTime: \(startTime), endTime: \(endTime), products: \(products.description), version: \(version.description) "
    }

    public init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
            let startTime = dict["start_time"] as? Int,
            let endTime = dict["end_time"] as? Int,
            let contentRaw = dict["content"] as? Data,
            let productsRaw = dict["products"] as? Data,
            let versionRaw = dict["version"] as? Data else { return nil }
        do {
            let decoder = DocsBulletinManager.decoder
            let content = try decoder.decode([String: String].self, from: contentRaw)
            let products = try decoder.decode([String].self, from: productsRaw)
            let version = try decoder.decode([String: String].self, from: versionRaw)
            self.id = id
            self.content = content
            self.startTime = startTime
            self.endTime = endTime
            self.products = products
            self.version = version
        } catch {
            DocsLogger.debug("BulletinInfo decode failed", error: error)
            return nil
        }
    }
}
