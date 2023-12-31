//
//  CaptureService.swift
//  EETroubleKiller
//
//  Created by lixiaorui on 2019/5/13.
//

import Foundation
import UIKit
import LKCommonsLogging

public protocol CaptureService: AnyObject {

    func dump()

}

final class CaptureServiceImpl: CaptureService {

    static let logger = Logger.log(TroubleKiller.self, category: "ToubleKiller.Capture")

    func dump() {
        logCapture(.none, tracingId: UUID().uuidString)
    }

    func logCapture(_ type: CaptureType, tracingId: String) {
        assert(Thread.current.isMainThread)
        guard TroubleKiller.config.enable else { return }

        let captureWindows = TroubleKiller.config.checkCaptureWindows()
        let infos = UIApplication.shared.windows
            .filter({ captureWindows.contains($0) })
            .map({ $0.convertToCaptureInfo(in: TroubleKiller.config.treeDepth) })

        TroubleKiller.logger.debug("Capature log for \(type.rawValue) count: \(infos.count)", tag: LogTag.log)
        for (index, info) in infos.enumerated() {
            if let data = try? TroubleKiller.encoder.encode(info),
               let json = String(data: data, encoding: .utf8) {
                TroubleKiller.logger.info("\(tracingId)-\(index) \(type.rawValue) \(json)", tag: LogTag.capture)
                CaptureServiceImpl.logger.info("\(tracingId)-\(index) \(type.rawValue) \(json)", tag: LogTag.capture)
            } else {
                TroubleKiller.logger.error("Capture infos encode failed for index: \(index)", tag: LogTag.log)
            }
        }
        TroubleKiller.logger.debug("Capture end log for \(type.rawValue) count: \(infos.count)", tag: LogTag.log)
    }

}

extension CaptureServiceImpl: CaptureDispatcherDelegate {

    func triggerLog(_ type: CaptureType, tracingId: String) {
        logCapture(type, tracingId: tracingId)
    }

}
