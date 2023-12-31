import UIKit

@objcMembers
public final class EditorPickImage: NSObject {
    public let image: UIImage
    let data: Data?

    public init(image: UIImage, data: Data? = nil) {
        self.image = image
        self.data = data
    }
}
