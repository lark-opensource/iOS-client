//
//  DefaultOpenInOtherApp.swift
//  SKDrive
//
//  Created by tanyunpeng on 2023/3/20.
//  


import Foundation
import SKCommon
import UniverseDesignToast

class DefaultOpenInOtherAppDependency: OpenInOtherAppSubModuleDependency {

    func openWith3rdApp(context: OpenInOtherAppContext) {
        DriveRouter.openWith3rdApp(context: context)
    }

    func showFailure(with text: String, on view: UIView) {
        UDToast.showFailure(with: text, on: view)
    }
}
