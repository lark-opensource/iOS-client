// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE
/*
*
*
*  ______ ______ _____        __
* |  ____|  ____|_   _|      / _|
* | |__  | |__    | |  _ __ | |_ _ __ __ _
* |  __| |  __|   | | | '_ \|  _| '__/ _` |
* | |____| |____ _| |_| | | | | | | | (_| |
* |______|______|_____|_| |_|_| |_|  \__,_|
*
*
*/
import UIKit
import Foundation
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkReactionViewBundle, compatibleWith: nil) ?? UIImage()
    }

    static let reactionImage = Resources.image(named: "reactionImage")
    static let reactionOpenEntrance = Resources.image(named: "reaction_open_entrance")
}
