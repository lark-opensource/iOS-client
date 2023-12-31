//
//  DocPluginForWebImp+Picker.swift
//  CCMMod
//
//  Created by huangzhikai on 2023/10/12.
//

import Foundation
import LarkModel
import SKFoundation
#if MessengerMod
import LarkSearchCore
#endif
import RustPB
import SpaceInterface
import SKCommon
import SKResource

typealias SelectResult = ([(docToken: String, docType: DocsType, url: String)]) -> Void

#if MessengerMod
class DocPluginForWebImpPickDelegate: SearchPickerDelegate {
    
    var selectResult: SelectResult
    public init(selectResult: @escaping SelectResult) {
        self.selectResult = selectResult
    }
    
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard items.first != nil else {
            DocsLogger.error("DocPluginForWebImpPick send doc picker did finish without item")
            self.selectResult([])
            return false
        }
        var selectArr: [(docToken: String, docType: DocsType, url: String)] = []
        for item in items {
            switch item.meta {
            case .doc(let meta):
                guard let docMeta = meta.meta else {
                    break
                }
                selectArr.append((docToken: docMeta.id, docType: DocsType(pbDocsType: docMeta.type), url: docMeta.url))
            case .wiki(let meta):
                guard let wikiMeta = meta.meta else {
                    break
                }
                selectArr.append((docToken: wikiMeta.id, docType: DocsType(pbDocsType: wikiMeta.type), url: wikiMeta.url))
            default:
                break
            }
            
        }
        self.selectResult(selectArr)
        return true
    }
    
}


//picker
extension DocPluginForWebImp {
    func createSelectDocsPickController(selectResult: @escaping SelectResult) -> UIViewController {
        let delegateProxy = DocPluginForWebImpPickDelegate(selectResult: selectResult)
        let controller = SearchPickerNavigationController(resolver: resolver)
        // topView 没有内容，目的是为了强持有 delegateProxy，否则 proxy 会因为没有强引用直接析构
        controller.topView = CCMPickerPlaceHolderTopView(proxy: delegateProxy)
        controller.defaultView = PickerRecommendListView(resolver: self.resolver)
        controller.pickerDelegate = delegateProxy
        
        //配置搜索全部doc文档
        let docConfig = PickerConfig.DocEntityConfig(belongUser: .all,
                                                     belongChat: .all,
                                                     types: [Basic_V1_Doc.TypeEnum.docx, Basic_V1_Doc.TypeEnum.doc],
                                                     folderTokens: [])
        
        
        //配置搜索全部wiki文档
        let wikiConfig =  PickerConfig.WikiEntityConfig(belongUser: .all,
                                                        belongChat: .all,
                                                        types: [Basic_V1_Doc.TypeEnum.docx, Basic_V1_Doc.TypeEnum.doc],
                                                        spaceIds: [])
        
        controller.searchConfig = PickerSearchConfig(entities: [
            docConfig, wikiConfig
        ])
        
        //配置导航栏
        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Select_Title,
                                                              showSure: false,
                                                              canSelectEmptyResult: false)
        //配置搜索栏
        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: false)
        controller.featureConfig = PickerFeatureConfig(scene: .imSelectDocs,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        
        return controller
    }
}
#endif

