import Photos
import ByteWebImage

let phAsset = PHAsset()

let result = ImageUploadChecker.getAssetCheckResult(asset: PHAsset)

switch result {
case .success:
    print("success")
case .failure(let checkError):
    print(checkError)
}
