//
//  OPFileConfig.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/17.
//

import Foundation

/// 渐进式配置解析框架，避免一次解析全量配置耗时太久影响启动速度。
///
/// - 支持懒解析及缓存(lazy var)
/// - 框架层支持预解析(preParsePropeties)
@objcMembers open class OPFileConfig: NSObject {
    
    /// 重写该方法用于递归预加载所有配置，调用 super 该方法可以自动复用加上用父类配置
    open func preParsePropeties(_ appendPropeties: [Any] = []) -> [Any] {
        return appendPropeties
    }
    
    /// Base 路径，不包含文件后缀
    public let basePath: String
    
    /// 对应的 json 配置文件的路径，包含后缀
    public lazy var configJsonPath: String = {
        "\(basePath).json"
    }()
    
    /// 对应的JS文件的路径，包含后缀
    public lazy var jsPath: String = {
        "\(basePath).js"
    }()
    
    public let reader: OPPackageReaderProtocol
    
    public private(set) lazy var configData: [String: Any] = {
        do {
            let data = try reader.syncRead(file: configJsonPath)
            do {
                guard let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    // TODO: JSON类型不正确，输出日志+埋点
                    
                    return [:]
                }
                return result
            } catch {
                // TODO: JSON解析失败，输出日志+埋点
                
            }
        } catch {
            // TODO: 文件读取失败，输出日志+埋点
            
        }
        return [:]
    }()
    
    public init(basePath: String, reader: OPPackageReaderProtocol) {
        self.basePath = basePath
        self.reader = reader
    }
    
    /// 递归预解析所有配置
    public func startPreParse() {
        preParsePropeties().forEach { (property) in
            preParse(config: property)
        }
    }
    
    private func preParse(config: Any) {
        if let config = config as? OPFileConfig {
            config.startPreParse()
        } else if let configs = config as? [Any] {
            configs.forEach { (config) in
                preParse(config: config)
            }
        } else if let configs = config as? [AnyHashable: Any] {
            configs.forEach { (kay, value) in
                preParse(config: value)
            }
        } else {
            // 其他类型，啥也不做
        }
    }
}
