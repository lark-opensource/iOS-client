//
//  URL+LDExt.swift
//  NewLarkDynamic
//
//  Created by 李论 on 2019/11/1.
//

import UIKit
import LarkFoundation
import LKCommonsLogging
import LarkFeatureGating

private let logger = Logger.oplog(String.self, category: "URL+LDExt")
extension String {
    public func possibleURL() -> URL? {
        do {
            return try URL.forceCreateURL(string: self)
        } catch let error {
            logger.error("conver string: \(self.safeURL()) to url fail with error: \(error)")
            return nil
        }
    }
    
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter) // <1>
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count // <2>

        if zeroDiff == 0 { // <3>
            // Same format, compare normally
            return self.compare(otherVersion, options: .numeric)
        } else {
            let zeros = Array(repeating: "0", count: abs(zeroDiff)) // <4>
            if zeroDiff > 0 {
                otherVersionComponents.append(contentsOf: zeros) // <5>
            } else {
                versionComponents.append(contentsOf: zeros)
            }
            return versionComponents.joined(separator: versionDelimiter)
                .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric) // <6>
        }
    }
}
