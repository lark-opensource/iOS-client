//
//  GadgetAPIContext+Gadget.swift
//  TTMicroApp
//
//  Created by baojianjun on 2023/8/14.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter

// 引擎类型：逻辑层/渲染层
public enum GadgetEngineType {
    // 逻辑层
    case worker
    // 渲染层
    case render(page: BDPAppPage)

    case unknown
}

extension GadgetAPIContext {
    
    //是否正在中断
    public var shouldInterruption: Bool {
        return BDPAPIInterruptionManager.shared().shouldInterruption(for: uniqueID)
    }

    // 应用是否活跃
    public var isVCActive: Bool {
        guard let container = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol else {
            assertionFailure("can not get containerModule for app \(uniqueID)")
            Self.logger.error("can not get containerModule for app \(uniqueID)")
            return false
        }
        return container.isVCActiveContext(pluginContext)
    }
    
    // 应用是否在前台
    public var isVCForeground: Bool {
        guard let container = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol else {
            assertionFailure("can not get containerModule for app \(uniqueID)")
            Self.logger.error("can not get containerModule for app \(uniqueID)")
            return false
        }
        return container.isVC(inForgoundContext: pluginContext)
    }
    
    public func fireEventToRender(event: String, sourceID: Int, data: [AnyHashable: Any]?) -> Bool {
        guard let engine = pluginContext.engine else {
            assertionFailure("gadget context engine is nil")
            Self.logger.error("gadget context engine is nil, can not fire event")
            return false
        }
        if let appPage = engine as? BDPAppPage {
            appPage.bdp_fireEvent(event, sourceID: appPage.appPageID, data: data)
        } else {
            Self.logger.error("can not fire event to webview")
            return false
        }
        return true
    }

    public func fireEventToWorker(event: String, sourceID: Int, data: [AnyHashable: Any]?, source: String?) -> Bool {
        guard let engine = pluginContext.engine else {
            assertionFailure("gadget context engine is nil")
            Self.logger.error("gadget context engine is nil, can not fire event")
            return false
        }
        let sourceType: OpenAPIFireEventParams.SourceType = OpenAPIFireEventParams.SourceType.init(rawValue: source ?? "") ?? .none
        if let appPage = engine as? BDPAppPage {
            switch sourceType {
            case .none:
                appPage.publishEvent(event, param: data ?? [:])
                break
            case .webViewComponent:
                if let task = BDPTaskManager.shared().getTaskWith(uniqueID), let taskContext = task.context {
                    taskContext.bdp_fireEvent(event, sourceID: sourceID, data: data)
                } else {
                    Self.logger.error("can not fire event to appService")
                    return false
                }
                break
            default:
                appPage.publishEvent(event, param: data ?? [:])
                break
            }
        } else {
            Self.logger.error("can not fire event to appService")
            return false
        }
        return true
    }
    
    // 引擎类型：逻辑层/渲染层
    public var engineType: GadgetEngineType {
        guard let engine = pluginContext.engine else {
            return .unknown
        }
        if IsGadgetWebView(engine), let page = engine as? BDPAppPage {
            return .render(page: page)
        }
        return .worker
    }

    /*
     worker
     */

    // 加入workers 队列， 设置worker的sourceworker，rootworker
    public func addWorker(workerID: String, data: [AnyHashable: Any] = [:]) -> OPSeperateJSRuntimeProtocol? {
        guard let engineWorkers = pluginContext.engine?.workers, let workers = engineWorkers else {
            Self.logger.error("current engine create worker fail, because workers is nil")
            return nil
        }
        var createWorker: OPSeperateJSRuntimeProtocol?
        if let sourceWorker = workers.sourceWorker as? BDPEngineProtocol & BDPJSBridgeEngineProtocol {
            let interpreters = OpenJSWorkerInterpreters()
            var workerData = data

            workerData["workerName"] = workerID

            if let providerClass = OpenJSWorkerInterpreterManager.shared.getInterpreter(workerName: workerID, interpreterType: .resource) as? NSObject.Type, let resource = providerClass.init() as? OpenJSWorkerResourceProtocol {
                interpreters.resource = resource
            } else {
                Self.logger.warn("worker init, resource can not get, workerName\(workerID)")
            }
            if let providerClass = OpenJSWorkerInterpreterManager.shared.getInterpreter(workerName: workerID,  interpreterType: .netResource) as? NSObject.Type, let resource = providerClass.init() as? OpenJSWorkerNetResourceProtocol {
                interpreters.netResource = resource
            } else {
                Self.logger.warn("worker init, netresource can not get, workerName\(workerID)")

            }
            createWorker = OPRuntimeFactory.shared.seperateJSRuntime(sourceWorker: sourceWorker, data: workerData, interpreters: interpreters)
        }
        if let createWorker = createWorker {
            workers.addWorker(worker: createWorker, workerID: workerID)
            createWorker.sourceWorker = workers.sourceWorker
            createWorker.rootWorker = workers.rootWorker
        }
        return createWorker
    }

    // 终止worker
    public func terminateWorker(workerID: String) {
        guard let engineWorkers = pluginContext.engine?.workers, let workers = engineWorkers else {
            Self.logger.error("current engine terminate worker fail, because workers is nil")
            return
        }
        workers.terminateWorker(workerID: workerID)
    }

    // 获取worker
    public func getWorker(workerID: String) -> OPSeperateJSRuntimeProtocol? {
        guard let engineWorkers = pluginContext.engine?.workers, let workers = engineWorkers else {
            Self.logger.error("current engine terminate worker fail, because workers is nil")
            return nil
        }
        if let worker = workers.getWorker(workerID: workerID) {
            return worker
        } else {
            Self.logger.info("this worker does not exist in the current engine")
        }
        return nil
    }

    // 是否允许创建worker
    public func enableCreateWorker() -> Bool {
        guard let engineWorkers = pluginContext.engine?.workers, let workers = engineWorkers else {
            Self.logger.error("workers is nil")
            return false
        }

        let enable = workers.maxWorkerCount() > workers.workersCount()
        if !enable {
            Self.logger.info("worker count limited")
        }
        return enable
    }
}
