//
//  MailDriveAPI.swift
//  MailNetwork
//
//  Created by weidong fu on 1/1/2018.
//

import Foundation

struct MailDriveAPI {
    static let driveAPIBasePATH = "/space/api/box/stream"
    static let driveAPIFileDownload = "/space/api/box/stream/download/all/"
    static let driveAPIChangeToken = "/space/api/box/file/multi_copy/"
    static let driveAPIPermissionPath = "/space/api/suite/permission/public.v4/"
    static let driveAPIStateAction = "/space/api/suite/permission/document/actions/state/"

    static func getDriveURL(provider: ConfigurationProxy?) -> String {
        let url = "https://" + (provider?.getDomainSetting(key: .docsDrive).first ?? "")
        MailLogger.info("mail get docsURL \(url)")
        return url
    }

    static func getDriveAPI(provider: ConfigurationProxy?) -> String {
        let url = "https://" + (provider?.getDomainSetting(key: .docsApi).first ?? "")
        MailLogger.info("mail get docsAPI \(url)")
        return url
    }

    static func getDriveAPIBaseUrl(provider: ConfigurationProxy?) -> String {
        return MailDriveAPI.getDriveURL(provider: provider) + MailDriveAPI.driveAPIBasePATH
    }

    static func getChangeTokenUrl(provider: ConfigurationProxy?) -> String {
        return MailDriveAPI.getDriveAPI(provider: provider) + MailDriveAPI.driveAPIChangeToken
    }
    static func driveFetchPermissionURL(provider: ConfigurationProxy?,
                                        token: String,
                                        type: Int) -> String {
        return MailDriveAPI.getDriveAPI(provider: provider)
                + MailDriveAPI.driveAPIPermissionPath
                + "?token=\(token)"
                + "&type=\(type)"
    }
    static func driveFetchStateActionURL(provider: ConfigurationProxy?) -> String {
        return MailDriveAPI.getDriveAPI(provider: provider) + MailDriveAPI.driveAPIStateAction
    }

    static func driveFileDownloadURL(fileToken: String, mountPoint: String, mountNodeToken: String, provider: ConfigurationProxy?) -> String {
        return MailDriveAPI.getDriveURL(provider: provider)
                + MailDriveAPI.driveAPIFileDownload
                + "\(fileToken)?"
                + "mount_node_token=\(mountNodeToken)"
                + "&mount_point=\(mountPoint)"
    }
}
