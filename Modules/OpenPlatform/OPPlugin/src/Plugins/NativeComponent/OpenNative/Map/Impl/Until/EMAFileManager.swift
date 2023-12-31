//
//  EMAFileManager.swift
//  EEMicroAppSDK
//
//  Created by 武嘉晟 on 2019/12/26.
//

import Foundation
import OPFoundation
import LKCommonsLogging
import ECOProbe

final class EMAFileManager {
    private static let logger = Logger.oplog(EMAFileManager.self, category: "EMAFileManager")

    static func image(
        with originImageUrl: String,
        engine: BDPJSBridgeEngineProtocol?,
        finish: @escaping(_ image: UIImage?) -> Void
    ) {
        if originImageUrl.isEmpty {
            finish(nil)
            return
        }
        let imageurl = originImageUrl
        logger.info("EMAFileManager get image with url::\(imageurl)")
        if imageurl.hasPrefix("http://") || imageurl.hasPrefix("https://") {
            guard let engine = engine else {
                finish(nil)
                return
            }
            guard let common = BDPCommonManager.shared()?.getCommonWith(engine.uniqueID) else {
                finish(nil)
                return
            }
            if !common.auth.checkURL(imageurl, authType: .download) {
                finish(nil)
                return
            }
            guard let url = URL(string: imageurl) else {
                finish(nil)
                return
            }
            let session = EMANetworkManager.shared().urlSession
            let task = session.dataTask(with: url) { (data, _, error) in
                if error != nil {
                    finish(nil)
                    return
                }
                guard let data = data else {
                    finish(nil)
                    return
                }
                let image = UIImage(data: data)
                finish(image)
            }
            task.resume()
        } else {
            guard let uniqueId = engine?.uniqueID else {
                finish(nil)
                return
            }
            do {
                let file = try FileObject(rawValue: imageurl)
                let fsContext = FileSystem.Context(uniqueId: uniqueId, trace: nil, tag: "EMAFileManager", isAuxiliary: true)
                let data = try FileSystem.readFile(file, context: fsContext)
                let image = UIImage(data: data)
                finish(image)
            } catch let error as FileSystemError {
                logger.error("read file failed, imageurl:\(imageurl)", error: error)
                finish(nil)
            } catch {
                logger.error("read file unknown failed, imageurl:\(imageurl)", error: error)
                finish(nil)
            }
        }
    }

}
