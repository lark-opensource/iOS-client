//
//  Resources.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2021/1/4.
//

import UIKit
import Foundation
import LarkLocalizations
import UniverseDesignEmpty

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: LarkShareContainerBundle, compatibleWith: nil) ?? UIImage()
    }

    private static func localizationsImage(named: String) -> UIImage {
        return LanguageManager.image(named: named, in: LarkShareContainerBundle) ?? UIImage()
    }

    static let container_error = UDEmptyType.loadingFailure.defaultImage()
    static let container_disable = UDEmptyType.noLink.defaultImage()
}
