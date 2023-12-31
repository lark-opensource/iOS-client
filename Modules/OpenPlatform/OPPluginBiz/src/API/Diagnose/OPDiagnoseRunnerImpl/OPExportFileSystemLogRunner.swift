//
//  OPExportFileSystemLogRunner.swift
//  EEMicroAppSDK
//
//  Created by Meng on 2021/11/1.
//

import Foundation
import UIKit
import OPPluginManagerAdapter
import ECOProbe
import LKCommonsLogging
import OPSDK

@objcMembers
final class OPExportFileSystemLogRunner: OPDiagnoseBaseRunner {
    private static let logger = Logger.oplog(OPExportFileSystemLogRunner.self)

    public override func exec(with context: OPDiagnoseRunnerContext) {
        Self.logger.info("trigger export file system log runner")

        DispatchQueue.main.async {
            let currentLogFileURL = URL(fileURLWithPath: FileSystemLog.cacheDir)
                .appendingPathComponent(FileSystemLog.currentLogFileName)
                .appendingPathExtension(FileSystemLog.logExtension)
            let activityVC = UIActivityViewController(activityItems: [currentLogFileURL], applicationActivities: nil)
            context.controller?.present(activityVC, animated: true, completion: {
                Self.logger.info("present export file system log")
            })
            context.execCallbackSuccess()
        }
    }
}
