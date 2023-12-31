//
//  OPBlockMetaAdapter.swift
//  OPBlock
//
//  Created by lixiaorui on 2020/12/6.
//

import Foundation
import OPSDK
import TTMicroApp

extension OPBlockMeta: AppMetaAdapterProtocol {
    var appMetaAdapter: AppMetaProtocol {
        return OPBlockMetaAdapter(blockMeta: self)
    }
}

private class OPBlockMetaAuthData: NSObject, AppMetaAuthProtocol {}

private class OPBlockBusinessData: NSObject, AppMetaBusinessDataProtocol {}

private class OPBlockPackageData: NSObject, AppMetaPackageProtocol {
    var urls: [URL]

    var md5: String

    init(urls: [String], md5: String) {
        self.urls = urls.flatMap({ URL(string: $0) })
        self.md5 = md5
    }

}

private class OPBlockMetaAdapter: AppMetaProtocol {

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

    private let blockMeta: OPBlockMeta

    init(blockMeta: OPBlockMeta) {
        self.blockMeta = blockMeta
        self.uniqueID = blockMeta.uniqueID
        self.version = blockMeta.appVersion
        self.name = blockMeta.appName
        self.iconUrl = blockMeta.appIconUrl
        self.packageData = OPBlockPackageData(urls: blockMeta.packageUrls, md5: blockMeta.md5CheckSum)
        self.authData = OPBlockMetaAuthData()
        self.businessData = OPBlockBusinessData()
    }

}

extension BDPPackageUncompressedFileHandle: OPPackageReaderProtocol {
    public func syncRead(file: String) throws -> Data {
        try readData(withFilePath: file)
    }
}

