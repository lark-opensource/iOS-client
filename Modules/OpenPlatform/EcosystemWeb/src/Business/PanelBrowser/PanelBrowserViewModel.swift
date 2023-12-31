//
//  PanelBrowserViewModel.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/9/2.
//

import UIKit
import SwiftyJSON
import LarkRustClient
import RustPB
import Swinject
import RxSwift
import LarkSetting
import LarkStorage
import LKCommonsLogging

class PanelBrowserAppInfo: NSObject {
    /// 网页应用ID
    public var appId: String = ""
    
    /// 网页应用名称
    public var appName: String = ""
    
    /// 网页应用图标地址
    public var appAvatar: String = ""
    
    init(json: JSON) {
        appId = json["cli_id"].stringValue
        appName = json["name"].stringValue
        appAvatar = json["avatar_url"].stringValue
    }
    
    func toJSONString() -> String {
        var json = JSON()
        json["cli_id"].string = appId
        json["name"].string = appName
        json["avatar_url"].string = appAvatar
        return json.rawString() ?? ""
    }
}

protocol PanelBrowserViewModelDelegate: AnyObject {

    func updateAppInfo(appInfo: PanelBrowserAppInfo?)
}

class PanelBrowserViewModel: NSObject {
    
    static let logger = Logger.log(PanelBrowserViewModel.self, category: "PanelBrowserViewModel")

    public var appId: String = ""
    
    private let disposeBag = DisposeBag()
    
    private weak var delegate: PanelBrowserViewModelDelegate?

    private var service: RustService?
    
    private var appInfo: PanelBrowserAppInfo?

    init(appId: String, resolver: Resolver, delegte: PanelBrowserViewModelDelegate? = nil) {
        super.init()
        self.appId = appId
        if let service = try? resolver.resolve(assert: RustService.self) {
            self.service = service
        }
        self.delegate = delegte
        self.fetchInfo()
    }
        
    private lazy var filePath: String = {

        let docDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last?.appendingPathComponent("com.browser.panel", isDirectory: true)
        var isDir: ObjCBool = ObjCBool(false)
        if let docDirPath = docDir?.path, !FileManager.default.fileExists(atPath: docDirPath, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(atPath: docDirPath, withIntermediateDirectories: true)
            } catch {
                Self.logger.error("[PanelBrowser] create docDir failed: \(error.localizedDescription)")
            }
        }
        
        let fileDir = docDir?.appendingPathComponent("\(self.appId ?? "default").info", isDirectory: false)
        if let filePath = fileDir?.path {
            if !FileManager.default.fileExists(atPath: filePath) {
                FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            }
            return filePath
        }
        return ""
    }()
    
    private lazy var uniteStorageReformEnable: Bool = {
        return FeatureGatingManager.shared.featureGatingValue(with: "openplatform.web.ios.unite.storage.reform")// user:global
    }()
    
    private let store : KVStore? = {
        return KVStores.in(space: .global, domain: Domain.biz.microApp).mmkv()
    }()

    private func appInfoCacheKey() -> String{
        return "com.browser.panel." + self.appId
    }
    
    private func fetchInfo() {
    
        var jsonSting: String?
        do {
            if self.uniteStorageReformEnable {
                jsonSting = store?.string(forKey: self.appInfoCacheKey())
            } else {
                jsonSting = try String(contentsOfFile: self.filePath, encoding: .utf8)
            }
            
        } catch {
            Self.logger.error("[PanelBrowser] get app info failed: \(error.localizedDescription)")
        }

        if let jsonStr = jsonSting {
            let json = JSON(parseJSON: jsonStr ?? "")
            let appInfo = PanelBrowserAppInfo(json: json)
            self.updateAppInfo(appInfo)
            self.fetchInfoFromRemote()
        } else {
            self.fetchInfoFromRemote()
        }
    }
    
    func updateAppInfo(_ appInfo: PanelBrowserAppInfo) {
        Self.logger.info("[PanelBrowser] update app info")
        DispatchQueue.main.async {
            self.appInfo = appInfo
            self.delegate?.updateAppInfo(appInfo: appInfo)
        }
    }
    
    private func fetchInfoFromRemote() {

        if self.appId.isEmpty {
            Self.logger.info("[PanelBrowser] fetchInfoFromRemote appId is isEmpty")
            return
        }
        
        var request = RustPB.Openplatform_V1_GetAppDetailRequest()
        request.appID = appId
        service?.sendAsyncRequest(request, transform: { [weak self] (response: RustPB.Openplatform_V1_GetAppDetailResponse) -> Void in
            guard let `self` = self else { return }
            let json = JSON(parseJSON: response.jsonResp)
            let errorCode = json["code"].intValue
            if errorCode == 0 { // 成功
                let appInfo = PanelBrowserAppInfo(json: json["data"])
                self.updateAppInfo(appInfo)
                DispatchQueue.global().async {
                    
                    let jsonString = appInfo.toJSONString()
                    if self.uniteStorageReformEnable {
                        self.store?.set(jsonString, forKey: self.appInfoCacheKey())
                        Self.logger.info("[PanelBrowser] save remote data in mmkv success")
                    } else {
                        if let jsonData = jsonString.data(using: .utf8) {
                            let fileHandle = FileHandle(forWritingAtPath: self.filePath)
                            fileHandle?.write(jsonData)
                            fileHandle?.closeFile()
                            Self.logger.info("[PanelBrowser] save remote data success")
                        } else {
                            Self.logger.info("[PanelBrowser] save remote data failed(jsonData nil)")
                        }
                    }
                    
                }
            } else {
                Self.logger.info("[PanelBrowser] request failed errorCode:\(errorCode)")
            }
        }) .catchError({(error) -> Observable<Void> in
            Self.logger.error("[PanelBrowser] fetch remoteData error: \(error)")
            return .empty()
        }).subscribe()
            .disposed(by: disposeBag)
    }
}
