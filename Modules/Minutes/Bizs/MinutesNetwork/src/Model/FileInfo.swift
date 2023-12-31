//
//  FileInfo.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public enum FileType: Int, Codable, ModelEnum {
    public static var fallbackValue: FileType = .unknown

    case unkown = -1
    case folder = 0
    case dustbin = 1
    case doc = 2
    case sheet = 3
    case personalFolder = 4
    case sharewithmeFolder = 5
    case shareFolder = 6
    case link = 7
    case bitable = 8
    case demostration = 9
    case mindnote = 10
    case file = 12
    case slide = 15
    case wiki = 16
    case reserve1
    case reserve2
    case reserve3
    case reserve4
    case reserve5
    case unknown = -999
}

public struct FileInfo: Codable {
    public let fid: String
    public let fileIcon: String
    public let fileURL: URL
    public let fileTitle: String
    public let shareName: String?
    public let token: String?

    private enum CodingKeys: String, CodingKey {
        case fid = "fid"
        case fileIcon = "file_icon"
        case fileURL = "file_url"
        case fileTitle = "file_title"
        case shareName = "share_name"
        case token = "token"
    }
}
