//
//  ServiceProtocols.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/13.
//  

import SKFoundation
import LarkWebViewContainer
import SpaceInterface

public protocol JSServiceHandler {
    var handleServices: [DocsJSService] { get }
    func handle(params: [String: Any], serviceName: String)
    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?)
}

public extension JSServiceHandler {

    func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        handle(params: params, serviceName: serviceName)
    }
    
    /// 获取Block对应的docsInfo
    func getblockDocsInfo(params: [String: Any]) -> DocsInfo? {
        guard UserScopeNoChangeFG.LJY.enableSyncBlock else {
            return nil //FG关闭时不获取block docsInfo，都走旧逻辑
        }
        let srcObjToken = params[DocsJSParamKeys.srcObjToken] as? String
        let srcObjType = params[DocsJSParamKeys.srcObjType] as? Int
        if let srcObjToken = srcObjToken, let srcObjType = srcObjType {
            return DocsInfo(type: DocsType(rawValue: srcObjType), objToken: srcObjToken)
        }
        return nil
    }
}

// MARK: - 缓存相关
public typealias SKCacheService = NewCacheAPI

// MARK: - 图片缓存相关
public protocol SKImageCacheService {
    func storeImage(_ data: NSCoding?, token: String?, forKey key: String, needSync: Bool)
    func getImage(byKey key: String, token: String?) -> NSCoding?
    func getImage(byKey key: String, token: String?, needSync: Bool) -> NSCoding?
    func mapTokenAndPicKey(token: String?, picKey: String, picType: Int, needSync: Bool, isDrivePic: Bool?)
    func hasImge(forKey key: String, token: String?) -> Bool
    func hasImge(forKey key: String, token: String?, needSync: Bool) -> Bool
    func removePic(forKey key: String, token: String?)
}

public protocol SKExecJSFuncService: AnyObject {

    //js回调接口
    //param: 回传参数，字典类型
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?)
}
// swiftlint:disable class_delegate_protocol
public protocol SKAssertBrowserVCActionDelegate: SKExecJSFuncService {
// swiftlint:enable class_delegate_protocol
    func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController)
}

public protocol SKKeyboardInfoProtocol {
    var height: CGFloat { get }
    var isShow: Bool { get }
    var trigger: String { get }
}

public protocol SKBrowserUIResponder: AnyObject {
    @discardableResult
    func becomeFirst(trigger: String) -> Bool
}
