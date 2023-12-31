//
//  WikiTreeViewModel.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/23.
//

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKResource
import SKFoundation
import SKWorkspace
import SpaceInterface

// Wiki Picker ViewModel
class WikiTreeViewModel {

    var selectedNode: WikiTreeNodeMeta? {
        return treeViewModel.selectedNode
    }
    var isSelectedValidNode: Bool {
        guard let selectedToken = treeViewModel.selectedWikiToken else {
            return false
        }
        return selectedToken != treeViewModel.disabledToken
    }

    private let wikiToken: String
    let spaceID: String
    let spaceName: String

    private let bag = DisposeBag()

    let config: WikiPickerConfig
    var tracker: WorkspacePickerTracker { config.tracker }
    var displayTittle: String {
        if MyLibrarySpaceIdCache.isMyLibrary(spaceID)  {
            return BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
        }
        return treeViewModel.spaceInfo?.displayTitle ?? spaceName
    }

    let treeViewModel: WikiPickerTreeViewModel

    init(wikiToken: String,
         spaceID: String,
         spaceName: String,
         config: WikiPickerConfig) {
        self.wikiToken = wikiToken
        self.spaceID = spaceID
        self.spaceName = spaceName
        self.config = config
        treeViewModel = WikiPickerTreeViewModel(spaceID: spaceID,
                                                wikiToken: wikiToken.isEmpty ? nil : wikiToken,
                                                disabledToken: config.disabledWikiToken)
    }

    func initailTreeData() {
        treeViewModel.setup()
    }

    func updateTreeData(_ wikiToken: String) {
        // 避免从搜索结果中选择被禁止选中的节点
        guard wikiToken != treeViewModel.disabledToken else { return }
        treeViewModel.focusNode(wikiToken: wikiToken)
    }
}
