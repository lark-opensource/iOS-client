import UIKit
import ByteWebImage

let image = UIImage()
let imageSize = image.pxSize // UIImage 可能有 scale，所以需要获取 pxSize 而非 ptSize

let result = ImageUploadChecker.getImageSizeCheckResult(finalImageType: .jpeg, imageSize: imageSize)
