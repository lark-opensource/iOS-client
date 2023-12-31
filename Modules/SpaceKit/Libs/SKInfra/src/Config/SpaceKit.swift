//  Created by Songwen on 2018/8/17.

import SKFoundation
import SKResource

public final class SpaceKit {
    public static var version: String = {
        if let version = Bundle(for: BundleResources.SKResource.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            DocsLogger.info("CURRENT SPACEKIT VERSION: \(version)")
            return version
        } else {
            DocsLogger.error("CANNOT GET SPACEKIT VERSION")
            return "999.999.999"
        }
    }()
}
