//
//  DebugPodInfoForwarding.swift
//  CryptoSwift
//
//  Created by kongkaikai on 2022/11/11.
//

import UIKit
import Foundation
import SwiftUI

public typealias CopyHandler = (String) -> Void

public enum DebugPodInfoForwarding {
    public static func controller(_ copyHandler: CopyHandler?) -> UIViewController {
        if #available(iOS 15.0, *) {
            return UIHostingController(rootView: DebugPodInfoView(copy: copyHandler))
        } else {
            // Fallback on earlier versions
            return DebugPodsInfoViewController()
        }
    }

    public static var buildCommits: String {
        (Bundle.main.infoDictionary?["build_commit_hash"] as? String) ?? "unknown"
    }
}
