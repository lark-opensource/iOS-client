//
//  OPDynamicComponentLoader.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2022/05/25.
//

import Foundation
import OPSDK
import TTMicroApp

extension OPDynamicComponentMeta: AppMetaAdapterProtocol {
    var appMetaAdapter: AppMetaProtocol {
        return OPDynamicComponentMetaAdapter(meta: self)
    }
}

private class OPDynamicComponentMetaAuthData: NSObject, AppMetaAuthProtocol {}

private class OPDynamicComponentBusinessData: NSObject, AppMetaBusinessDataProtocol {}

private class OPDynamicComponentPackageData: NSObject, AppMetaPackageProtocol {
    var urls: [URL]

    var md5: String

    init(urls: [String], md5: String) {
        self.urls = urls.compactMap({ URL(string: $0) })
        self.md5 = md5
    }

}

private class OPDynamicComponentMetaAdapter: AppMetaProtocol {

    var uniqueID: BDPUniqueID

    var version: String

    var name: String

    var iconUrl: String

    var packageData: AppMetaPackageProtocol

    var authData: AppMetaAuthProtocol

    var businessData: AppMetaBusinessDataProtocol

    func toJson() throws -> String {
        return try meta.toJson()
    }

    private let meta: OPDynamicComponentMeta

    init(meta: OPDynamicComponentMeta) {
        self.meta = meta
        self.uniqueID = meta.uniqueID
        self.version = meta.appVersion
        self.name = meta.appName
        self.iconUrl = meta.appIconUrl
        self.packageData = OPDynamicComponentPackageData(urls: meta.packageUrls, md5: meta.md5CheckSum)
        self.authData = OPDynamicComponentMetaAuthData()
        self.businessData = OPDynamicComponentBusinessData()
    }

}

extension BDPPackageUncompressedFileHandle: OPPackageReaderProtocol {
    public func syncRead(file: String) throws -> Data {
        try readData(withFilePath: file)
    }
}

