//
//  OPWebAppLoader.swift
//  OPWebApp
//
//  Created by Nicholas Tau on 2021/11/8.
//

import Foundation
import OPSDK
import TTMicroApp

extension OPWebAppMeta: AppMetaAdapterProtocol {
    var appMetaAdapter: AppMetaProtocol {
        return OPWebAppMetaAdapter(blockMeta: self)
    }
}

private class OPWebAppMetaAuthData: NSObject, AppMetaAuthProtocol {}

private class OPWebAppBusinessData: NSObject, AppMetaBusinessDataProtocol {}

private class OPWebAppPackageData: NSObject, AppMetaPackageProtocol {
    var urls: [URL]

    var md5: String

    init(urls: [String], md5: String) {
        self.urls = urls.flatMap({ URL(string: $0) })
        self.md5 = md5
    }

}

private class OPWebAppMetaAdapter: AppMetaProtocol {

    var uniqueID: BDPUniqueID

    var version: String

    var name: String

    var iconUrl: String

    var packageData: AppMetaPackageProtocol

    var authData: AppMetaAuthProtocol

    var businessData: AppMetaBusinessDataProtocol

    func toJson() throws -> String {
        return try blockMeta.toJson()
    }

    private let blockMeta: OPWebAppMeta

    init(blockMeta: OPWebAppMeta) {
        self.blockMeta = blockMeta
        self.uniqueID = blockMeta.uniqueID
        self.version = blockMeta.appVersion
        self.name = blockMeta.appName
        self.iconUrl = blockMeta.appIconUrl
        self.packageData = OPWebAppPackageData(urls: blockMeta.packageUrls, md5: blockMeta.md5CheckSum)
        self.authData = OPWebAppMetaAuthData()
        self.businessData = OPWebAppBusinessData()
    }

}

extension BDPPackageUncompressedFileHandle: OPPackageReaderProtocol {
    public func syncRead(file: String) throws -> Data {
        try readData(withFilePath: file)
    }
}

