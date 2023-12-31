//
//  CoverSelectPanelInterface.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import SKFoundation
import RxSwift
import LarkLocalizations
import SpaceInterface

enum CoverConstants {
    static let officialSectionHeaderIdentifier = "official-cover-multilist-header"
    static let localSectionHeaderIdentifier = "local-cover-multilist-header"
}

public typealias SourceDocumentInfo = (objToken: String, objType: Int)
public typealias SelectCoverInfo = (token: String, type: Int)
public typealias OfficialCoverPhotosSeries = [OfficialCoverPhotosSerie]

public struct OfficialCoverPhotosSerie: Codable {
    let display: OfficialCoverPhotoDisplayName
    var infos: [OfficialCoverPhotoInfo]
    enum CodingKeys: String, CodingKey {
        case display = "series"
        case infos = "candidate_covers"
    }
}

public struct OfficialCoverPhotoDisplayName: Codable {
    let enName: String
    let zhName: String
    let jpName: String
    let seriesId: String
    enum CodingKeys: String, CodingKey {
        case enName = "en"
        case zhName = "zh"
        case jpName = "jp"
        case seriesId = "series_id"
    }

    var displayName: String {
        let larkLauange = LanguageManager.currentLanguage
        
        switch larkLauange {
        case .en_US: return enName
        case .zh_CN: return zhName
        case .ja_JP: return jpName
        default:
            return enName
        }
    }
}

public struct OfficialCoverPhotoInfo: Codable {
    let id: String
    let token: String
    let mimeType: String
    var priority: Int32?
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case token = "token"
        case mimeType = "mime_type"
    }
}

public protocol OfficialCoverPhotosNetWorkAPI {
    func fetchOfficialCoverPhotosTokenWith(_ parmas: [String: Any]) -> Observable<OfficialCoverPhotosSeries>
}

public protocol OfficialCoverPhotoDataAPI {
    func fetchOfficialCoverPhotoDataWith(_ photoInfo: OfficialCoverPhotoInfo,
                                         coverSize: CGSize,
                                         resumeBag: DisposeBag,
                                         completionHandler: @escaping (UIImage?, URLResponse?, Error?) -> Void)
}

enum OfficialCoverPhotosProviderError: Error, LocalizedError {
    case fetchOfficialPhotosDataError
    case parseOfficialPhotosDataError
    public var errorDescription: String? {
        switch self {
        case .fetchOfficialPhotosDataError:
            return "fetchOfficialPhotosDataError"
        case .parseOfficialPhotosDataError:
            return "parseOfficialPhotosDataError"
        }
    }

    public var code: Int {
        switch self {
        case .fetchOfficialPhotosDataError:
            return -1
        case .parseOfficialPhotosDataError:
            return -2
        }
    }
}

enum CoverPhotoSource: String {
    case gallery //官方图库,自选
    case random //官方图库,随机
    case album //本地图库
    case takePhoto = "take_photo" //相册
}

enum LocalCoverPhotoAction {
    case album
    case takePhoto
}
