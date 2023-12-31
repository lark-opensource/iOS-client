//  Created by weidong fu on 5/2/2018.

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import RxSwift

class NavigationTitleService: BaseJSService {
    private var storedIconKey: String?
    private lazy var docsInfoDetailUpdater: DocsInfoDetailUpdater = DocsInfoDetailHelper.detailUpdater(for: hostDocsInfo)
    private var disposeBag = DisposeBag()
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension NavigationTitleService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.navTitle, .navSetName]
    }

    func handle(params: [String: Any], serviceName: String) {
        if serviceName == DocsJSService.navTitle.rawValue {
            handleSetTitle(params: params, serviceName: serviceName)
        } else if serviceName == DocsJSService.navSetName.rawValue {
            handleSetName(params: params, serviceName: serviceName)
        }
    }

    private func handleSetTitle(params: [String: Any], serviceName: String) {
        guard let title = params["title"] as? String else {
            DocsLogger.info("wrong parameters: no title field")
            return
        }
        let identity = model?.jsEngine.editorIdentity ?? "no identity"
        DocsLogger.info("set title \(DocsTracker.encrypt(id: title)) for \(identity)")
        let canRename = params["canRename"] as? Bool
        var titleInfo = NavigationTitleInfo(title: title)
        titleInfo.subtitle = params["subTitle"] as? String
        titleInfo.docName = params["doc_name"] as? String
        if let filetype = hostDocsInfo?.inherentType, filetype == .docX {
            titleInfo.untitledName = filetype.untitledString
        }
        if let displayTypeInt = params["displayTitleType"] as? Int, let displayType = NavigationTitleInfo.DisplayType(rawValue: displayTypeInt) {
            titleInfo.displayType = displayType
        }

        var iconInfo: IconSelectionInfo?
        if let infoDict = params["icon_info"] as? [String: Any],
            let key = infoDict["key"] as? String,
            let typeNum = infoDict["type"] as? Int,
            let type = SpaceEntry.IconType(rawValue: typeNum),
            let fsUnit = infoDict["fs_unit"] as? String {
            iconInfo = IconSelectionInfo(key: key, type: type.rawValue,
                                         fsUnit: fsUnit, id: -1)
        }

        ui?.displayConfig.setNavigation(titleInfo: titleInfo,
                                        needDisPlayTag: params["need_display_tag"] as? Bool,
                                        tagValue: params["tag_value"] as? String,
                                        iconInfo: iconInfo,
                                        canRename: canRename)
        
        if hostDocsInfo?.inherentType == .sheet, model?.vcFollowDelegate != nil {
            model?.vcFollowDelegate?.follow(onOperate: .vcOperation(value: .onTitleChange(title: title)))
        }
    }

    private func handleSetName(params: [String: Any], serviceName: String) {
        if let infoDict = params["icon_info"] as? [String: Any],
            let key = infoDict["key"] as? String, key != storedIconKey {
            // Notify business sides to update icon info if needed.
            updateDetail()
        }

        if model?.vcFollowDelegate != nil {
            if let newTitle = params["title"] as? String {
                model?.vcFollowDelegate?.follow(onOperate: .vcOperation(value: .onTitleChange(title: newTitle)))
            }
        }
    }
    private func updateDetail() {
        guard let docsInfo = hostDocsInfo else {
            DocsLogger.error("failed to get docsInfo when handle set name event")
            return
        }
        disposeBag = DisposeBag()
        docsInfoDetailUpdater.updateDetail(for: docsInfo).subscribe().disposed(by: disposeBag)
    }
}

extension NavigationTitleService: BrowserViewLifeCycleEvent {
    func browserDidUpdateDocsInfo() {
        storedIconKey = hostDocsInfo?.customIcon?.iconKey
    }
}
