import Foundation

final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkShareExtensionBundle, compatibleWith: nil) ?? UIImage()
    }

    static let send_to_myself = Resources.image(named: "send_to_myself")
    static let send_to_qun = Resources.image(named: "send_to_qun")
    static let send_to_toutiaoquan = Resources.image(named: "send_to_toutiaoquan")
    static let unknownFile = Resources.image(named: "unknownFile")
    static let videoBeginPlay = Resources.image(named: "video_begin_play")
}
