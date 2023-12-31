//
// Created by maozhixiang.lip on 2023/03/13.
//

import Foundation

final class LynxResources {
    private static let lynxBundle = BundleConfig.ByteViewHybridResourcesBundle

    static func loadLynxTemplate(_ path: String) -> Data? {
        guard let templatePath = lynxBundle.path(forResource: "lynx/" + path, ofType: nil) else { return nil }
        // lint:disable:next lark_storage_check
        return try? Data(contentsOf: URL(fileURLWithPath: templatePath))
    }
}
