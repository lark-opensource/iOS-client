
// swiftlint:disable identifier_name
import Foundation
let SceneAlgorithmModel = "tt_c1_small_v8.0_size0"
let SceneAlgorithmModelExtension = "model"
// swiftlint:enable identifier_name

extension BundleConfig {
    private static let LarkVideoDirectorKAURL = SelfBundle.url(forResource: "LarkVideoDirectorKA", withExtension: "bundle")!
    static let LarkVideoDirectorKABundle = Bundle(url: LarkVideoDirectorKAURL)!
}
