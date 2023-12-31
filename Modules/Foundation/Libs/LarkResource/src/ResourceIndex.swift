//
//  IndexModel.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/23.
//

import Foundation
import EEAtomic
import LKCommonsLogging

// lint:disable lark_storage_check - bundle 资源相关，不做存储检查

/// 索引根节点类型
enum IndexRootType: String {
    case keys
}

/// 索引根节点
final class IndexRootNode {
    var type: IndexRootType
    var value: [String: IndexFactorLazyNode]

    init(type: IndexRootType, value: [String: IndexFactorLazyNode]) {
        self.type = type
        self.value = value
    }
}

/// Factor 懒加载节点
/// 在第一次使用的时候才会加载真实索引的数据
final class IndexFactorLazyNode {
    private var once: AtomicOnce = AtomicOnce()
    private var bundle: Bundle
    private var metaData: [AnyObject]?
    private var _node: IndexFactorNode?
    var node: IndexFactorNode? {
        once.once {
            if let meta = metaData {
                _node = ResourceIndexTable.parseFactorNode(meta, bundle)
            }
            metaData = nil
        }
        return _node
    }

    init(metaData: [AnyObject], bundle: Bundle) {
        self.metaData = metaData
        self.bundle = bundle
    }
}

/// 索引子节点
enum IndexFactorNode {
    /// 非叶子节点的子节点
    /// 为某一种 Factor 类型的对象，可以继续向下查找
    case object(IndexFactorObject)
    /// 索引叶子节点
    /// 为具体的索引值
    case value(IndexValue)
}

struct IndexFactorObject {
    enum TypeEnum: String {
        case lproj
        case theme
        case multiply
    }

    var type: TypeEnum
    var value: [String: IndexFactorNode]
}

/// 默认 base factory key
var defaultBaseKey: String = "$base"

public final class ResourceIndexTable: IndexTable {

    static var logger: Log = Logger.log(ResourceIndexTable.self, category: "resource.manager")

    public var name: String
    public var indexFilePath: String

    // bundle 路径
    private var bundlePath: String

    // 通过 path 在初始化的时候懒加载 bundle
    private lazy var bundle: Bundle? = {
        return Bundle(path: bundlePath)
    }()

    private var once: AtomicOnce = AtomicOnce()

    private var _rootNode: IndexRootNode?
    private var rootNode: IndexRootNode? {
        once.once {
            /// 使用 AtomicOnce 控制只加载索引一次
            _rootNode = ResourceIndexTable.parseRootNode(indexFilePath, bundle)
            if _rootNode == nil {
                ResourceIndexTable.logger.error("load index table failed, name \(self.name), path: \(self.indexFilePath)")
            }
        }
        return _rootNode
    }

    public var identifier: String {
        return self.name
    }

    public init?(
        name: String,
        indexFilePath: String,
        bundlePath: String) {
        self.name = name
        self.bundlePath = bundlePath
        self.indexFilePath = indexFilePath
        if !FileManager.default.fileExists(atPath: indexFilePath) {
            return nil
        }
    }

    public func resourceIndex(key: ResourceKey) -> MetaResource? {
        guard let rootNode = self.rootNode else {
            return nil
        }

        guard let node = rootNode.value[key.baseKey.fullKey],
            let factorNode = node.node else {
            return nil
        }
        return findIndex(key: key, in: factorNode)
    }

    private func findIndex(key: ResourceKey, in factorNode: IndexFactorNode) -> MetaResource? {
        switch factorNode {
        case .value(let value):
            return MetaResource(
                key: key,
                index: value)
        case .object(let object):
            let factorKey: String
            switch object.type {
            case .lproj:
                factorKey = key.env.language
            case .theme:
                factorKey = key.env.theme
            case .multiply:
                factorKey = "\(Int(key.env.multiply))"
            }
            guard let node = object.value[factorKey] ?? object.value[defaultBaseKey] else {
                return nil
            }
            return findIndex(key: key, in: node)
        }
    }

    private static func parseRootNode(
        _ indexFilePath: String,
        _ bundle: Bundle?
    ) -> IndexRootNode? {
        guard let bundle = bundle else { return nil }
        var propertyListFormat = PropertyListSerialization.PropertyListFormat.xml
        guard FileManager.default.fileExists(atPath: indexFilePath),
            let data = FileManager.default.contents(atPath: indexFilePath),
            let plistData = try? PropertyListSerialization.propertyList(
                from: data,
                options: .mutableContainersAndLeaves,
                format: &propertyListFormat
            ) as? [String: AnyObject] else {
                return nil
        }
        let rootType = IndexRootType.keys

        guard let value = plistData[rootType.rawValue] as? [String: [AnyObject]] else {
            return nil
        }

        var nodeValue: [String: IndexFactorLazyNode] = [:]
        value.forEach({ (key, item) in
            nodeValue[key] = IndexFactorLazyNode(metaData: item, bundle: bundle)
        })
        return IndexRootNode(type: rootType, value: nodeValue)
    }

    fileprivate static func parseFactorNode(
        _ plistData: [AnyObject],
        _ bundle: Bundle
    ) -> IndexFactorNode? {
        guard
            let type = plistData.first as? String,
            let value = plistData.last else {
                return nil
        }

        if let dic = value as? [String: [AnyObject]],
            let nodeType = IndexFactorObject.TypeEnum(rawValue: type) {
            var nodeValue: [String: IndexFactorNode] = [:]
            dic.forEach({ (key, item) in
                if let object = parseFactorNode(item, bundle) {
                    nodeValue[key] = object
                }
            })

            return .object(IndexFactorObject(type: nodeType, value: nodeValue))

        } else if let valueType = IndexValue.TypeEnum(rawValue: type) {
            if let string = value as? String {
                return .value(IndexValue(type: valueType, value: .string(string), bundle: bundle))
            } else if let data = value as? Data {
                return .value(IndexValue(type: valueType, value: .data(data), bundle: bundle))
            } else if let boolean = value as? Bool {
                return .value(IndexValue(type: valueType, value: .boolean(boolean), bundle: bundle))
            } else if let number = value as? NSNumber {
                return .value(IndexValue(type: valueType, value: .number(number), bundle: bundle))
            }
        }
        assertionFailure("parse factor node failed")
        return nil
    }
}
