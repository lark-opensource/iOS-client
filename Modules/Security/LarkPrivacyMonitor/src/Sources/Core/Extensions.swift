//
//  Extensions.swift
//  LarkPrivacyMonitor-LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2022/11/30.
//

extension Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var LPMBundle: Bundle? = {
        let bundleName = "LarkPrivacyMonitor"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: PrivacyMonitor.self).resourceURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return nil
    }()
}
