//
//  GeckoPackageManager+md5.swift
//  SpaceKit
//
//  Created by Webster on 2019/4/19.
//

import SKFoundation
//import IESGeckoKit

extension GeckoPackageManager {

    func logMd5BadCase(result: MD5CheckResult?, channel: String, stage: String) {
        guard let checkResult = result, result?.failReason != .shutdown else {
            return
        }

        let params = ["scm_version": checkResult.version,
                      "stage": stage,
                      "fail_reason": checkResult.failReason.details(),
                      "type": channel,
                      "docapp": SKFoundationConfig.shared.isInDocsApp ? "1" : "0"]
        DocsTracker.log(enumEvent: .md5BadCase, parameters: params)

        let reportTypes: Set<Md5FailedReason> = [.md5SelfFail, .specialFileMd5Failed]
        if reportTypes.contains(checkResult.failReason), !checkResult.pass {
            var errType = "md5_damage"
            switch checkResult.failReason {
            case .md5SelfFail:
                errType = "md5_damage"
            case .specialFileLost:
                errType = "file_not_exist"
            case .specialFileMd5Failed:
                errType = "file_damage"
            default:
                ()
            }
            let params = ["scm_version": checkResult.version,
                          "stage": stage,
                          "type": channel,
                          "error_type": errType,
                          "errorMsg": checkResult.failFilePath]
            DocsTracker.log(enumEvent: .md5FailedCause, parameters: params)
        }

    }
}

extension GeckoPackageManager: GeckoMD5CheckerDataSource {
    func geckoMD5RootPath(in channel: DocsChannelInfo) -> String? {
        guard var dftPath = geckoAgent?.resourceRootFolderPath(identifier: channel.type.identifier()) else { return nil }
        switch channel.type {
        case .webInfo:
            dftPath += "/eesz"
        default:
            ()
        }
        return dftPath
    }

    func targetMD5RootPath(in channel: DocsChannelInfo) -> SKFilePath {
        let zipInfo = OfflineResourceZipInfo.info(by: channel)
        let geckoChannelPath = GeckoPackageManager.Folder.geckoBackupPath(channel: channel.name)
        let versionFileFolder = geckoChannelPath.appendingRelativePath(zipInfo.channelName)
        return versionFileFolder
    }
}

extension GeckoPackageManager: GeckoMD5CheckerDelegate {
    func geckoMD5CheckerRequestClean(checker: GeckoMD5Checker, channel: [DocsChannelInfo]) {
        channel.forEach {
            geckoAgent?.clearCache(for: $0.type.identifier())
        }
    }
}
