//
//  WikiPickerProviderImpl.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/5/31.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import LarkContainer

public final class WikiPickerProviderFactory: WikiPickerProvider {

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func createNodePicker(config: WorkspacePickerConfig) -> UIViewController {
        let controller = WikiWorkSpaceViewController(userResolver: userResolver,
                                                     spaces: [:],
                                                     pickerType: .picker(config: config))
        return controller
    }

    public func createNodePicker(config: WorkspacePickerConfig, recentEntry: WorkspacePickerWikiEntry) -> UIViewController {
        createTreePicker(wikiToken: recentEntry.wikiToken,
                         spaceID: recentEntry.spaceID,
                         spaceName: recentEntry.displayName,
                         config: config)
    }
    
    public func createMyLibraryPicker(spaceID: String, spaceName: String, config: WorkspacePickerConfig) -> UIViewController {
        createTreePicker(wikiToken: nil,
                         spaceID: spaceID,
                         spaceName: spaceName,
                         config: config)
    }

    public func createTreePicker(wikiToken: String?,
                                spaceID: String,
                                spaceName: String,
                                config: WorkspacePickerConfig) -> UIViewController {
        let viewModel = WikiTreeViewModel(wikiToken: wikiToken ?? "",
                                          spaceID: spaceID,
                                          spaceName: spaceName,
                                          config: WikiPickerConfig(config: config))
        let controller = WikiTreeViewController(viewModel: viewModel)
        return controller
    }
}
