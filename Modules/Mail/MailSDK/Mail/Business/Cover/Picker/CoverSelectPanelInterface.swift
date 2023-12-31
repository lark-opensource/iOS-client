//
//  CoverSelectPanelInterface.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import RxSwift
import LarkLocalizations
import CoreGraphics

enum CoverConstants {
    static let officialSectionHeaderIdentifier = "official-cover-multilist-header"
    static let localSectionHeaderIdentifier = "local-cover-multilist-header"
}

typealias SelectCoverInfo = (token: String, type: Int)
typealias OfficialCoverPhotosSeries = [OfficialCoverPhotosSerie]

struct OfficialCoverPhotosSerie: Codable {
    let display: OfficialCoverPhotoDisplayName
    var infos: [OfficialCoverPhotoInfo]
    enum CodingKeys: String, CodingKey {
        case display = "name"
        case infos = "pictures"
    }
}

struct OfficialCoverPhotoDisplayName: Codable {
    let enName: String
    let zhName: String
    let jpName: String
    enum CodingKeys: String, CodingKey {
        case enName = "en-US"
        case zhName = "zh-CN"
        case jpName = "ja-JP"
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

struct OfficialCoverPhotoInfo: Codable {
    let url: String
    let token: String
    var priority: Int32?
    let subjectColorHex: String

    var asMailCover: MailSubjectCover {
        MailSubjectCover(token: token, subjectColorStr: subjectColorHex)
    }
}

extension OfficialCoverPhotoInfo: MailCoverLoadableInfo {}

/// 获取所有官方封面的信息
protocol OfficialCoverPhotosNetWorkAPI {
    func fetchOfficialCoverPhotosTokenWith(_ parmas: [String: Any]) -> Observable<OfficialCoverPhotosSeries>
}

/// 通过 id, token 获取对应封面实体
protocol OfficialCoverPhotoDataAPI {
    var defaultThumbnailSize: CGSize { get }
    func fetchOfficialCoverPhotoDataWith(_ photoInfo: OfficialCoverPhotoInfo,
                                         coverSize: CGSize?,
                                         resumeBag: DisposeBag,
                                         completionHandler: @escaping (UIImage?, Error?, MailImageDownloadType) -> Void)
}

enum OfficialCoverPhotosProviderError: Error, LocalizedError {
    case fetchOfficialPhotosDataError
    case parseOfficialPhotosDataError
    var errorDescription: String? {
        switch self {
        case .fetchOfficialPhotosDataError:
            return "fetchOfficialPhotosDataError"
        case .parseOfficialPhotosDataError:
            return "parseOfficialPhotosDataError"
        }
    }
}

enum CoverPhotoSource: String {
    case gallery //官方图库,自选
    case random //官方图库,随机
    case album //本地相册
    case takePhoto = "take_photo" //相机拍摄
}

enum LocalCoverPhotoAction {
    case album
    case takePhoto
}
