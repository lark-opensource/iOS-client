//
//  LocationPickerViewController.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/6.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkLocationPicker
import LarkModel
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import EENavigator
import SnapKit
import UniverseDesignToast
import UniverseDesignDialog
import RustPB

final class LocationPickerViewController: ChooseLocationViewController {
    private static let logger = Logger.log(LocationPickerViewController.self, category: "LarkChat.LocationPickerViewController")

    // 发送回调，第一个String是地图Type，第二个String是选择地址的位置（这两个String都用于打点需求）
    public var sendCallBack: ((LocationContent, UIImage, String, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sendLocationCallBack = { [weak self] (chooseLocation) in
            var placeInfo = RustPB.Basic_V1_Location()
            placeInfo.name = chooseLocation.name
            placeInfo.description_p = chooseLocation.address

            let model = LocationContent(
                latitude: String(format: "%f", chooseLocation.location.latitude),
                longitude: String(format: "%f", chooseLocation.location.longitude),
                zoomLevel: Int32(chooseLocation.zoomLevel),
                vendor: chooseLocation.mapType,
                image: ImageSet(),
                location: placeInfo,
                isInternal: chooseLocation.isInternal
            )
            self?.sendCallBack?(model, chooseLocation.image, chooseLocation.mapType, chooseLocation.selectType)
        }
    }
}
