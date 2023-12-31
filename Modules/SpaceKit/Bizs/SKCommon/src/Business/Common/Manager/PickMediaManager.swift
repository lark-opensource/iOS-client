//
// Created by duanxiaochen.7 on 2020/12/7.
// Affiliated with SKBrowser.
//
// Description:
//


import LarkUIKit
import Photos
import SKResource
import LarkAssetsBrowser
import EENavigator

public protocol SKPickMediaDelegate: AnyObject {
    func didFinishPickingMedia(params: [String: Any])
}

public final class SKPickMediaManager: AssetPickerSuiteViewDelegate {

    weak var delegate: SKPickMediaDelegate?

    public var suiteView: AssetPickerSuiteView

    public init(delegate: SKPickMediaDelegate, assetType: PhotoPickerAssetType, cameraType: CameraType, rootVC: UIViewController?) {
        self.delegate = delegate
        suiteView = AssetPickerSuiteView(assetType: assetType, cameraType: cameraType, sendButtonTitle: BundleI18n.SKResource.Doc_Facade_Upload, presentVC: rootVC)
        suiteView.delegate = self
        suiteView.isAccessibilityElement = true
        suiteView.accessibilityLabel = "spacekit.photoPicker"
        suiteView.accessibilityIdentifier = "spacekit.photoPicker"
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        let assets = result.selectedAssets
        let orignal = result.isOriginal
        let params = [SKPickContent.pickContent: SKPickContent.asset(assets: assets, original: orignal)]
        DispatchQueue.main.async {
            self.delegate?.didFinishPickingMedia(params: params)
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        let params = [SKPickContent.pickContent: SKPickContent.takePhoto(photo: photo)]
        DispatchQueue.main.async {
            self.delegate?.didFinishPickingMedia(params: params)
        }
    }

    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        let params = [SKPickContent.pickContent: SKPickContent.takeVideo(videoUrl: url)]
        DispatchQueue.main.async {
            self.delegate?.didFinishPickingMedia(params: params)
        }
    }
}
