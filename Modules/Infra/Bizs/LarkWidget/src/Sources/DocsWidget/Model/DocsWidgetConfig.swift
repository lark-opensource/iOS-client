//
//  DocsWidgetConfig.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/15.
//

import Foundation

public struct DocsWidgetConfig: Codable {

    var domain: String
    var useNewPath: Bool
    public var driveDomain: String = ""
    public var appVersion: String?

    public init(domain: String, useNewPath: Bool) {
        self.domain = domain
        self.useNewPath = useNewPath
    }

    private var getRecentListURL: String {
        let path = "space/api/explorer/recent/list/"
        return "https://\(domain)/\(path)"
    }

    private var getPinListURL: String {
        let path = "space/api/explorer\(useNewPath ? "/v2" : "")/pin/list/"
        return "https://\(domain)/\(path)"
    }

    private var getStarListURL: String {
        let path = "space/api/explorer\(useNewPath ? "/v2" : "")/star/list/"
        return "https://\(domain)/\(path)"
    }

    public func getDocsListURL(withType type: DocsListType) -> String {
        switch type {
        case .pin:      return getPinListURL
        case .star:     return getStarListURL
        case .recent:   return getRecentListURL
        }
    }

    public var getDriveApiURL: String {
        let path = "space/api/infra/domains/all"
        return "https://\(domain)/\(path)"
    }

    public var getDocInfoURL: String {
        let path = "space/api/meta/"
        return "https://\(domain)/\(path)"
    }

    public var getDocCoverURL: String {
        let path = "space/api/docx/blocks/record_client_vars"
        return "https://\(domain)/\(path)"
    }

    public func getImageDownloadURL(withImageToken coverToken: String) -> String {
        let path = "space/api/box/stream/download/v2/cover"
        return "https://\(driveDomain)/\(path)/\(coverToken)"
    }

    public static var `default`: DocsWidgetConfig = DocsWidgetConfig(domain: "", useNewPath: false)
}
