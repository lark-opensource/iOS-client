//
//  VersionContainerViewModel.swift
//  SKBrowser
//
//  Created by Guoxinyi on 2022/9/6.
//

import Foundation
import UIKit
import SKFoundation
import SKUIKit
import SKResource
import RxSwift
import RxCocoa
import SwiftyJSON
import SKCommon
import SpaceInterface
import LarkContainer

public enum VersionContainerState {
    case prepare    // 请求versionToken
    case failed(error: VersionErrorCode)
    case success(versionInfo: (String, String, String))
}

public final class VersionContainerViewModel: NSObject {
    public var versionURL: URL
    public var params: [AnyHashable: Any]?
    public let docType: DocsType?
    public var parentToken: String?
    public var versionToken: String?
    public var version: String?
    
    var sourcenToken: String {
        DocsUrlUtil.getFileToken(from: versionURL) ??  ""
    }
    
    public var bindState: ((VersionContainerState) -> Void)?
    
    public let userResolver: UserResolver
    
    public init(url: URL, params: [AnyHashable: Any]?, userResolver: UserResolver, addInner: Bool = true) {
        self.userResolver = userResolver
        if addInner {
            self.versionURL = url.docs.addQuery(parameters: [URLValidator.versionParam: "1"])
        } else {
            self.versionURL = url
        }
        
        self.params = params
        self.docType = DocsType(url: self.versionURL)
        self.parentToken = DocsUrlUtil.getFileToken(from: url)
    }
    
    public func loadVersionInfo() {
        self.bindState?(.prepare)
        DocsVersionManager.shared.getVersionTokenForUrl(self.versionURL) { [weak self] (vToken, vValue, _, errCode) in
            guard let `self` = self else { return }
            guard let versionToken = vToken, let version = vValue, let sourceToken = self.parentToken else {
                if errCode == VersionErrorCode.versionNotPermission.rawValue ||
                   errCode == VersionErrorCode.versionEditionIdForbidden.rawValue ||
                   errCode == VersionErrorCode.versionEditionIdLengthErr.rawValue {
                    self.versionToken = vToken
                    self.version = vValue
                    self.bindState?(.success(versionInfo: (self.parentToken ?? "", "", "")))
                } else {
                    self.bindState?(.failed(error: VersionErrorCode(rawValue: errCode) ?? .undefine))
                }
                return
            }
            self.versionToken = vToken
            self.version = vValue
            self.bindState?(.success(versionInfo: (sourceToken, versionToken, version)))
        }
    }
    
    public var urlForSuspendable: String {
        if var components = URLComponents(string: self.versionURL.absoluteString) {
            components.query = nil // 移除所有参数
            if let finalUrl = components.string {
                if let vurl = URL(string: finalUrl), let version = self.version { // 版本需要增加参数
                    return vurl.docs.addQuery(parameters: ["edition_id": version]).absoluteString
                }
                return finalUrl
            }
        }
        return self.versionURL.absoluteString
    }
}
