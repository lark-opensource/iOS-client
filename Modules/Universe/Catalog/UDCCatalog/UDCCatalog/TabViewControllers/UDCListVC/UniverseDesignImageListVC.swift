//
//  UniverseDeisgnImageListVC.swift
//  UDCCatalog
//
//  Created by 郭怡然 on 2022/9/9.
//  Copyright © 2022 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignImageList
import UniverseDesignAvatar
import UniverseDesignToast
import UniverseDesignColor
import Photos
import PhotosUI

class UniverseDesignImageListVC: UIViewController, UITextFieldDelegate {

    var datasource = [
//        ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .initial),
//        ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .success),
//        ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .inProgress(progressValue: 0)),
//        ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .error(message: nil))
//    ]
        ImageListItem(image: #imageLiteral(resourceName: "ttmoment.jpeg"), status: .success),
        ImageListItem(image: #imageLiteral(resourceName: "flower.jpeg"), status: .error(message: nil)),
        ImageListItem(image: #imageLiteral(resourceName: "ttmoment.jpeg"), status: .inProgress(progressValue: 0)),
        ImageListItem(image: #imageLiteral(resourceName: "flower.jpeg"), status: .success),
        ImageListItem(image: #imageLiteral(resourceName: "sunset.jpeg"), status: .inProgress(progressValue: 0)),
        ImageListItem(image: #imageLiteral(resourceName: "flower.jpeg"), status: .success),
    ]

    var picker: UIViewController?

    lazy var imageList: UDImageList = {
//        let configuration = UDImageList.Configuration.init(maxImageNumber: 9, cameraBackground: .grey, leftRightMargin: 30, interitemSpacing: 10)
//        var imageList = UDImageList(dataSource: self.datasource, configuration: configuration)
        var imageList = UDImageList(dataSource: self.datasource, configuration: .init())
        imageList.onRetryClicked = { [weak self] item in
            guard let self = self else { return }
            UDToast.showTips(with: "reloaded the error image \(item.id)", on: self.view, delay: 1 )
            DispatchQueue.main.async {
                imageList.changeStatus(forItemWith: item.id, to: .inProgress(progressValue: 0))
                self.startProgressing(id: item.id)
            }
        }

        imageList.onImageClicked = { [weak self] item in
            if let self = self {
                if case .inProgress = item.status {
                    DispatchQueue.main.async {
                        UDToast.showTips(with: "uploading the image \(item.id)", on: self.view, delay: 1 )
                        self.startProgressing(id: item.id)
                    }
                } else {
                    UDToast.showTips(with: "clicked the image \(item.id)", on: self.view, delay: 1 )
                }
            }
        }

        imageList.onDeleteClicked = { [weak self] item in
            guard let self = self else { return }
            guard let index = imageList.dataSource.firstIndex(where: { $0.id == item.id }) else { return }
            imageList.deleteItem(item: item)
        }

        imageList.onCameraClicked = { [weak self] in
            if let self = self {
                if #available(iOS 15, *) {
                    var configuration = PHPickerConfiguration(photoLibrary: .shared())
                    // Set the filter type according to the user’s selection.
                    configuration.filter = PHPickerFilter.images
                    // Set the mode to avoid transcoding, if possible, if your app supports arbitrary image/video encodings.
                    configuration.preferredAssetRepresentationMode = .current
                    // Set the selection behavior to respect the user’s selection order.
                    configuration.selection = .default
                    // Set the selection limit to enable multiselection.
                    configuration.selectionLimit = 1
                    // Set the preselected asset identifiers with the identifiers that the app tracks.
                    // configuration.preselectedAssetIdentifiers = selectedAssetIdentifiers
                    let picker = PHPickerViewController(configuration: configuration)
                    picker.delegate = self
                    self.present(picker, animated: true)
                    self.picker = picker
                }
                UDToast.showTips(with: "clicked the camera cell ", on: self.view, delay: 1)
            }
        }
        return imageList
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setComponents()
        setConstraints()
        setAppearance()
    }

    var wrapper: UIView!
    private func setComponents() {
        let wrapper = UIView()
        wrapper.backgroundColor = .clear
        self.wrapper = wrapper
        view.addSubview(wrapper)
        wrapper.addSubview(imageList)
    }

    private func setConstraints() {
        wrapper.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
        }
        imageList.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBody
    }

    @objc private func startProgressing(id: String) {
        var timer: Timer?
        var counter: CGFloat = 0.0
        if timer == nil {
            self.imageList.changeStatus(forItemWith: id, to: .inProgress(progressValue: 0))
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (_) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    counter += 0.02
                    self.imageList.updateProgress(with: id, progressValue: counter)
                    if counter >= 1 {
                        timer?.invalidate()
                        timer = nil
                        self.imageList.changeStatus(forItemWith: id, to: .success)
                    }
                }
            }
        }
    }
}

@available(iOS 14, *)
extension UniverseDesignImageListVC: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        results.first.map { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    guard let image = image, let uiImage = image as? UIImage else { return }
                    DispatchQueue.main.async {
                        self.picker?.dismiss(animated: true)
//                        self.imageList.appendItem(ImageListItem(image: uiImage, status: .inProgress(progressValue: 0)))
                        self.imageList.insertItem(ImageListItem(image: uiImage, status: .inProgress(progressValue: 0)), at: 0)
                    }
                }
            }
        }
    }
}
