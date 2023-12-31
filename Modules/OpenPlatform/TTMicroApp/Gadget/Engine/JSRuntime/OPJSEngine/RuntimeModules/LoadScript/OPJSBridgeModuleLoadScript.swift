//
//  OPJSBridgeModuleLoadScript.swift
//  TTMicroApp
//
//  Created by yi on 2022/2/15.
//

import Foundation
import OPJSEngine
import LKCommonsLogging
import OPFoundation

public final class OPJSBridgeModuleLoadScript: NSObject, OPJSLoadScript {
    static let logger = Logger.log(OPJSBridgeModuleLoadScript.self, category: "OPJSEngine")
    @objc weak public var jsRuntime: GeneralJSRuntime?
    
    @objc public func loadScript(relativePath: NSString, requiredModules: NSArray) -> Any? {
        guard let jsRuntime = self.jsRuntime else {
            Self.logger.error("worker loadScript fail, jsRuntime is nil")
            return nil
        }
        jsRuntime.delegate?.bindCurrentThreadTracing?()

        Self.logger.info("loadScript start, relativePath=\(relativePath), app=\(jsRuntime.uniqueID)");

        let common = BDPCommonManager.shared().getCommonWith(jsRuntime.uniqueID)
        if common?.reader == nil {
            Self.logger.error("loadScript failed. common.reader is nil. relativePath:\(relativePath)")
            return nil
        }
        BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_begin", extra: ["file_path": relativePath], uniqueId: jsRuntime.uniqueID)
        //分包场景下需要去指定包内加载对应的JS资源
        var fileReader: BDPPkgFileReader?
        if let isSubpackageEnable = common?.isSubpackageEnable(), isSubpackageEnable {
            fileReader = BDPSubPackageManager.shared().getFileReader(withPagePath: relativePath as String, uniqueID: jsRuntime.uniqueID)
            Self.logger.info("try loadScript in subpackage with relativePath=\(relativePath), and fileReader:\(fileReader) packageName:\(fileReader?.basic().pkgName)");
        }
        if fileReader == nil {
            //如果对应的子页面下有分包js数据，优先取得内容并执行。否则用默认common.reader取到的数据兜底
            fileReader = common?.reader
        }
        // 批量加载JS https://bytedance.feishu.cn/docs/doccnd7fS9t5a1ujvuEkvi5XgQf
        if let fileReader = fileReader, let requiredModules = requiredModules as? [String], requiredModules.count > 0 {
            var datas: [Data]?
            var filePathsError: NSError? = nil
            datas = fileReader.readDatas(withFilePaths: requiredModules, error: &filePathsError)
            var scripts: NSString?
            if let datas = datas {
                // JS 合并
                for data in datas {
                    let script = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
                    scripts = "\(scripts)\(script);" as? NSString // JS 之间增加分号保护
                }
                // 执行合并后的JS
                if let url = NSURL(string: relativePath as String) as? URL, let scripts = scripts as? String {
                    BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_end", extra: ["file_path": relativePath], uniqueId: self.jsRuntime?.uniqueID)
                    BDPTracker.sharedInstance().monitorLoadTimeline(withName: "jsc_eval_js_begin", extra: ["file_path": relativePath], uniqueId: self.jsRuntime?.uniqueID)

                    jsRuntime.evaluateScript(scripts, withSourceURL: url)
                    BDPTracker.sharedInstance().monitorLoadTimeline(withName: "jsc_eval_js_end", extra: ["file_path": relativePath], uniqueId: self.jsRuntime?.uniqueID)
                    Self.logger.info("loadScript finish success, use require index relativePath=\(relativePath)")
                    return nil
                } else {
                    let monitor = OPMonitor(GDMonitorCode.batch_read_script_content_from_file_error)
                    OPJSEngineService.shared.monitor?.bindTracing(monitor: monitor, uniqueID: jsRuntime.uniqueID)
                    monitor.addCategoryValue("file_path", relativePath).addCategoryValue("js_engine_type", self.jsRuntime?.runtimeType.rawValue).setError(filePathsError).flush()

                    Self.logger.warn("loadScript finish failed use require index relativePath=\(relativePath)")
                }
            } else {
                let monitor = OPMonitor(GDMonitorCode.batch_read_script_content_from_file_error)
                OPJSEngineService.shared.monitor?.bindTracing(monitor: monitor, uniqueID: jsRuntime.uniqueID)
                monitor.addCategoryValue("file_path", relativePath).addCategoryValue("js_engine_type", self.jsRuntime?.runtimeType.rawValue).setError(filePathsError).flush()
            }
        }

        if let fileReader = fileReader, let relativePath = relativePath as? String {
            var data: Data?
            do {
                try data = fileReader.readData(withFilePath: relativePath)
                if let data = data  {
                    let script = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
                    if let url = NSURL(string: relativePath as String) as? URL, let script = script as? String {
                        BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_end", extra: ["file_path": relativePath], uniqueId: jsRuntime.uniqueID)
                        BDPTracker.sharedInstance().monitorLoadTimeline(withName: "jsc_eval_js_begin", extra: ["file_path": relativePath], uniqueId: jsRuntime.uniqueID)

                        jsRuntime.evaluateScript(script, withSourceURL: url)
                        BDPTracker.sharedInstance().monitorLoadTimeline(withName: "jsc_eval_js_end", extra: ["file_path": relativePath], uniqueId: jsRuntime.uniqueID)

                        Self.logger.info("loadScript finish success, not use require index relativePath=\(relativePath)")
                    } else {
                        let exParams = ["file_path": relativePath]
                        BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_end", extra: exParams, uniqueId: jsRuntime.uniqueID)
                        let monitor = OPMonitor(GDMonitorCode.read_script_content_from_file_error)
                        OPJSEngineService.shared.monitor?.bindTracing(monitor: monitor, uniqueID: jsRuntime.uniqueID)
                        monitor.addCategoryValue("file_path", relativePath).addCategoryValue("js_engine_type", self.jsRuntime?.runtimeType.rawValue).flush()

                        Self.logger.info("loadScript finish failed, not use require index relativePath=\(relativePath)")
                    }
                }

            } catch let err {
                let exParams = ["file_path": relativePath, "error_msg": err.localizedDescription]
                BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_end", extra: exParams, uniqueId: jsRuntime.uniqueID)

                BDPTracker.sharedInstance().monitorLoadTimeline(withName: "get_file_content_from_ttpkg_end", extra: exParams, uniqueId: jsRuntime.uniqueID)
                let monitor = OPMonitor(GDMonitorCode.read_script_content_from_file_error)
                OPJSEngineService.shared.monitor?.bindTracing(monitor: monitor, uniqueID: jsRuntime.uniqueID)
                monitor.addCategoryValue("file_path", relativePath).addCategoryValue("js_engine_type", self.jsRuntime?.runtimeType.rawValue).setError(err).flush()

                Self.logger.info("loadScript finish failed, not use require index relativePath=\(relativePath), error=\(err)")

            }
        }
        return nil

    }
}
