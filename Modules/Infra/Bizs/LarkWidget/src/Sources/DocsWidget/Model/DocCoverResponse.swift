//
//  DocCoverResponse.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/18.
//

import Foundation

// swiftlint:disable all
public struct DocCoverResponse: Codable {

    public var code: Int
    public var msg: String
    public var data: DocCoverData
}

public struct DocCoverData: Codable {
    public var block_map: [String: DocCoverInfo]

    func getCover(_ token: String) -> String? {
        block_map[token]?.data.cover?.token
    }

    func getTitle(_ token: String) -> String? {
        block_map[token]?.data.text?.initialAttributedTexts?.text?["0"]
    }
}

public struct DocCoverInfo: Codable {
    public var data: DocCoverInfoData
}

public struct DocCoverInfoData: Codable {
    public var cover: DocCoverInfoDataCover?
    public var text: DocCoverInfoDataText?
}

public struct DocCoverInfoDataCover: Codable {
    public var token: String
    public var mime_type: String
}

public struct DocCoverInfoDataText: Codable {
    public var initialAttributedTexts: DocCoverInfoDataTextName?
}

public struct DocCoverInfoDataTextName: Codable {
    public var text: [String: String]?
}
// swiftlint:enable all
