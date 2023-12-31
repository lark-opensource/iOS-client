//
//  WorkspacePickerProvider.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/5/31.
//

import Foundation
import UIKit
import SpaceInterface

public protocol SpaceFolderPickerProvider {

    func createMySpacePicker(config: WorkspacePickerConfig) -> UIViewController

    func createShareSpacePicker(config: WorkspacePickerConfig) -> UIViewController

    func createFolderPicker(config: WorkspacePickerConfig, recentEntry: WorkspacePickerSpaceEntry) -> UIViewController
}


public protocol WikiPickerProvider {

    func createNodePicker(config: WorkspacePickerConfig) -> UIViewController

    func createNodePicker(config: WorkspacePickerConfig, recentEntry: WorkspacePickerWikiEntry) -> UIViewController
    
    func createMyLibraryPicker(spaceID: String, spaceName: String, config: WorkspacePickerConfig) -> UIViewController
    
    func createTreePicker(wikiToken: String?,
                          spaceID: String,
                          spaceName: String,
                          config: WorkspacePickerConfig) -> UIViewController
}
