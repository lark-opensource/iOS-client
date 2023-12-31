//
//  DocComponentSDKImpl.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/18.
//  


import Foundation
import SpaceInterface
import SKFoundation
import SKCommon

public class DocComponentSDKImpl: DocComponentSDK {
    
    public static let shared = DocComponentSDKImpl()
    
    public func create(url: URL, config: DocComponentConfig) -> DocComponentAPI? {
        let docsUrl = fixDocComponentURL(url)
        guard let contentHost = self.createDocComponentHost(docsUrl) else {
            return nil
        }
        let componentApi = DocComponentAPIImpl(url: docsUrl,
                                               config: config)
        let containerVC = DocsContainerViewController(contentHost: contentHost)
        componentApi.containerHost = containerVC
        return componentApi
    }
    
    func createDocComponentHost(_ url: URL) -> DocComponentHost? {
        guard URLValidator.isDocsURL(url) else {
            DocsLogger.error("createDocComponent failed, invalid url:\(url.absoluteString)", component: LogComponents.docComponent)
            return nil
        }
        let (vc, success) = SKRouter.shared.open(with: url)
        guard let componentHost = vc as? DocComponentHost, success else {
            spaceAssertionFailure()
            DocsLogger.error("createDocComponent faild, open failed", component: LogComponents.docComponent)
            return nil
        }
        return componentHost
    }
    
    func fixDocComponentURL(_ url: URL) -> URL {
//        let params = ["from": "doccomponent"]
//        let docsUrl = url.docs.addOrChangeEncodeQuery(parameters: params)
        return url
    }
}
