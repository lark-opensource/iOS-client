//
//  WikiFilterPanelViewController.swift
//  SKCommon
//
//  Created by majie.7 on 2022/12/13.
//

import Foundation
import SKUIKit
import SKFoundation
import UniverseDesignColor
import BDXServiceCenter
import BDXBridgeKit
import SKResource


public final class WikiFilterPanelViewController: SKLynxPanelController {
    typealias R = BundleI18n.SKResource
    public var clickHandler: ((String, String?) -> Void)?    //params: type, classId
    private var loadFinish: Bool = false // 加载完成标志位
    
    public init(type: String, classId: String, classFilters: [[String: String]], isIpad: Bool?) {
        var filters: [[String: String]] = []
        var types: [[String: String]] = []
        if UserScopeNoChangeFG.MJ.newWikiHomeFilterEnable {
            filters = [["spaceClassId": "all", "spaceClassName": R.LarkCCM_Wiki_CategoryMgmt_All_Button]]
            filters.append(contentsOf: classFilters)
        }
        if LKFeatureGating.wikiNewWorkspace {
            types = [
                ["spaceTypeId": "all", "spaceTypeName": R.LarkCCM_Wiki_CategoryMgmt_AllSpaces_Title],
                ["spaceTypeId": "team", "spaceTypeName": R.LarkCCM_Wiki_CategoryMgmt_TeamSpaces_Title],
                ["spaceTypeId": "personal", "spaceTypeName": R.LarkCCM_Wiki_CategoryMgmt_PersonalSpaces_Title]]
        }
        let params: [String: Any] = [
            "isIpad": isIpad ?? false,
            "filterDefIdValue": "all",
            "filterValue": ["spaceTypeId": type, "spaceClassId": classId],
            "filterOption": ["spaceTypes": types, "spaceClassifications": filters]]
        super.init(templateRelativePath: "pages/wiki-classification/template.js",
                   initialProperties: params)
        
        self.dismissalStrategy = [.systemSizeClassChanged, .larkSizeClassChanged]
        
        if isIpad == true {
            // ipad上popover样式展示时预设400高度，防止跳变明显
            let initPanelHeight: Double = 400
            self.estimateHeight = initPanelHeight
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func setupBizHandlers(for lynxView: BDXLynxViewProtocol) {
        let methodName = "ccm.notifyWikiSpaceFilterChange"
        let handler: BDXLynxBridgeHandler = { [weak self] (_, _, params, callback) in
            guard let spaceTypeId = params?["spaceTypeId"] as? String,
                  let spaceClassId = params?["spaceClassId"] as? String else {
                DocsLogger.error("wiki.filter.click: lynx params error: params invlid")
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }
            if spaceClassId == "all" {
                self?.clickHandler?(spaceTypeId, nil)
            } else {
                self?.clickHandler?(spaceTypeId, spaceClassId)
            }
            DocsLogger.info("wiki.filter.click --- spaceType: \(spaceTypeId), classId: \(spaceClassId)")
        }
        lynxView.registerHandler(handler, forMethod: methodName)
    }
    
    
    override public func view(_ view: BDXKitViewProtocol, didFinishLoadWithURL url: String?) {
        super.view(view, didFinishLoadWithURL: url)
        self.loadFinish = true
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if loadFinish && !isMyWindowRegularSizeInPad {
            self.dismiss(animated: true)
        }
    }
}
