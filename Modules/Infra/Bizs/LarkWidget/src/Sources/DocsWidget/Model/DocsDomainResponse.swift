//
//  DocsDomainResponse.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/18.
//

import Foundation

// swiftlint:disable all
public struct DocsDomainResponse: Codable {

    public var code: Int
    public var msg: String
    public var data: DocDomainData
}

public struct DocDomainData: Codable {

    public var drive_api: [String]
    public var nearby_drive_api: [String]?

    public var driveDomain: String? {
        return drive_api.first
    }
}
// swiftlint:enable all
