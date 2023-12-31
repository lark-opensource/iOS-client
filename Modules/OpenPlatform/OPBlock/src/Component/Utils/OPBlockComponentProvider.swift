//
//  OPBlockComponentProvider.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/28.
//

import Foundation
import OPSDK
import OPBlockInterface
import LarkOPInterface
import LarkContainer

// 创建render & worker的工厂协议
protocol OPBlockWorkerRenderFactory {
    // 创建
    static func makeRenderAndWorker(
        userResolver: UserResolver,
        fileReader: OPPackageReaderProtocol,
        context: OPComponentContext
    ) -> (OPRenderProtocol, OPWorkerProtocol)
}

// 创建block web的render及worker
struct OPBlockWebWorkerAndRenderProvider: OPBlockWorkerRenderFactory {
    static func makeRenderAndWorker(
        userResolver: UserResolver,
        fileReader: OPPackageReaderProtocol,
        context: OPComponentContext
    ) -> (OPRenderProtocol, OPWorkerProtocol) {
        let render = OPBlockWebRender(
            userResolver: userResolver,
            fileReader: fileReader,
            context: context
        )
        let worker = OPBlockWebWorker(
            context: context,
            userResolver: userResolver,
            messagePublisher: render.webBrowser
        )
        render.registerWebItem(with: OPBlockComponentWebBrowserItem(render: render, worker: worker))
        return (render, worker)
    }

}

// 创建block dsl的render及worker
// todo: 后续迁移现有blockComponent
//struct OPBlockDSLWorkerAndRenderProvider: OPBlockWorkerRenderFactory {
//
//}

extension BlockComponentUtils {
    
    // block是否要使用web render
    // 策略详见https://bytedance.feishu.cn/docx/doxcn6aEuboLWFkXvmSJv4Yo1Yd?from=space_home_recent&pre_pathname=%2Fdrive%2Fhome%2F
    func shouldUseWebRender(for context: OPContainerContext) throws -> Bool {
        guard let blockMeta = context.meta as? OPBlockMeta,
				let config = context.containerConfig as? OPBlockContainerConfigProtocol else {
            context.trace?.warn("can not convert to blockMeta",
                                additionalData: ["hasMeta": "\(context.meta != nil)",
                                                 "uniqueID": context.uniqueID.fullString])
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail,
                                message: "invalid block meta type \(context.uniqueID)")
        }
		let enableWebRender = blockWebComponentConfig.enableWebRender
		let enableHostwebRender = !blockWebComponentConfig.webRenderHostBlackList.contains(config.host)
        context.trace?.info("web render config",
                            additionalData: ["blockType": blockMeta.extConfig.pkgType.rawValue,
                                             "uniqueID": context.uniqueID.fullString,
                                             "enableWebRender": "\(enableWebRender)",
											 "enableHostwebRender": "\(enableHostwebRender)"])
        switch blockMeta.extConfig.pkgType {
        case .blockDSL:
            return false
        case .offlineWeb:
            let webRenderBlackList = blockWebComponentConfig.webRenderBlockBlackList
            if enableWebRender && enableHostwebRender && !webRenderBlackList.contains(blockMeta.uniqueID.identifier) {
                return true
            } else {
                throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail,
                                    message: "web render unusable for app: \(context.uniqueID)")
            }
        }
    }

    // block是否可以使用某API
    // 策略详见https://bytedance.feishu.cn/docx/doxcn6aEuboLWFkXvmSJv4Yo1Yd?from=space_home_recent&pre_pathname=%2Fdrive%2Fhome%2F
    func usableAPIs(for context: OPContainerContext) -> [String] {
        guard let blockMeta = context.meta as? OPBlockMeta else {
            context.trace?.warn("can not convert to blockMeta",
                                additionalData: ["hasMeta": "\(context.meta != nil)",
                                                 "uniqueID": context.uniqueID.fullString])
            return []
        }
        let host = (context.containerConfig as? OPBlockContainerConfigProtocol)?.host ?? ""
        let commonApis = apiConfig.commonApis
        let hostApis = apiConfig.hostPublicApis[host] ?? []
        let blockTypeApis = apiConfig.blockTypePublicApis[blockMeta.extConfig.pkgType.rawValue] ?? []
        let blockUniqueApis = apiConfig.blockSpecificApis[blockMeta.uniqueID.identifier] ?? []
        let usableApis = Array(Set<String>(commonApis + blockTypeApis + hostApis + blockUniqueApis))
        context.trace?.info("block usable apis count \(usableApis.count)",
                            additionalData: ["uniqueID": context.uniqueID.fullString])
        return usableApis
    }
}
