//
//  DocPluginForWebImp.swift
//  CCMMod
//
//  Created by huangzhikai on 2023/10/10.
//

import Foundation
import LarkContainer
import LarkOPInterface
import UniverseDesignIcon
import LarkUIKit
import LarkQuickLaunchInterface
import UniverseDesignToast
import UniverseDesignActionPanel
import SKResource
import SKFoundation
import SKCommon
import EENavigator
import LarkNavigator
import LarkNavigation
import LarkSplitViewController
import RxSwift
import UniverseDesignBadge
import SKInfra
import LarkSecurityAudit

public class DocPluginForWebImp: DocPluginForWebProtocol {
    let resolver: UserResolver
    
    private weak var vc: UIViewController?
    private var quickItem: QuickLaunchBarItem?
    private let disposeBag = DisposeBag()
    //当前网页应用url
    private var webUrl: String = ""
    private var completion: ((BusinessBarItemsForWeb) -> Void)?
    private var urlMetaId: Int?
    
    //关联的文档
    private var referenceModel: AssociateAppModel.ReferencesModel?
    
    public init(_ resolver: UserResolver) {
        self.resolver = resolver
    }
    
    public func createBarItems(for url: URL, on vc: UIViewController, with completion: @escaping (BusinessBarItemsForWeb) -> Void) {
        
        self.vc = vc
        
        //请求是否有关联文档
        DocPluginForWebService.checkReferenceExist(appUrl: url.absoluteString) { [weak self] result, error  in
            guard error == nil else {
                DocsLogger.error("checkReferenceExist error: \(String(describing: error))", component: LogComponents.associateApp)
                completion(BusinessBarItemsForWeb(url: url, navigationBarItem: nil, launchBarItem: nil, extraMap: nil))
                return
            }
            
            guard result.visible else {
                DocsLogger.info("checkReferenceExist visible is false", component: LogComponents.associateApp)
                completion(BusinessBarItemsForWeb(url: url, navigationBarItem: nil, launchBarItem: nil, extraMap: nil))
                return
            }
            
            guard let self else {
                return
            }
            
            //记录web url
            self.webUrl = url.absoluteString
            self.referenceModel = nil
            self.urlMetaId = result.urlMetaId
            
            if result.referenceExist {
                //存在查询已关联的文档
                self.checkAppReference(for: url, with: completion)
            } else {
                //不存在关联文档
                self.createDocsBarItems(with: completion)
                AssociateAppTracker.reportShowTypeTrackerEvent(showType: .addDocs,
                                                               referenceModel: self.referenceModel,
                                                               webUrl: URL(string: self.webUrl),
                                                               urlId: self.urlMetaId)
            }
            
        }
    }
    
    func checkAppReference(for url: URL, with completion: @escaping (BusinessBarItemsForWeb) -> Void) {
        
        DocPluginForWebService.appReference(appUrl: url.absoluteString) { [weak self] model, error in
            guard let self else {
                return
            }
            guard error == nil else {
                completion(BusinessBarItemsForWeb(url: url, navigationBarItem: nil, launchBarItem: nil, extraMap: nil))
                return
            }
            
            guard let references = model?.references, references.count > 0 else {
                completion(BusinessBarItemsForWeb(url: url, navigationBarItem: nil, launchBarItem: nil, extraMap: nil))
                return
            }
            
            //暂时只取第一篇关联的文档
            self.referenceModel = references.first
            self.urlMetaId = model?.urlMetaId
            self.createDocsBarItems(with: completion)
            AssociateAppTracker.reportShowTypeTrackerEvent(showType: .viewDocs,
                                                           referenceModel: self.referenceModel,
                                                           webUrl: url,
                                                           urlId: self.urlMetaId)
        }
    }
    
    // 创建doc文档按钮
    private func createDocsBarItems(with completion: @escaping (BusinessBarItemsForWeb) -> Void) {
        self.completion = completion
        self.resetDocsBarItems()
        //增加监听是否操作关联文档
        NotificationCenter.default.rx.notification(Notification.Name.Docs.deleteAssociateApp)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                guard let object = notification.object,
                      let deleteUrl = object as? String else {
                    DocsLogger.error("deleteAssociateApp notify error", component: LogComponents.associateApp)
                    return
                }
                
                //清除缓存的关联文档记录
                if self.webUrl == deleteUrl {
                    DocsLogger.info("deleteAssociateApp notify, delete url:\(deleteUrl)", component: LogComponents.associateApp)
                    self.referenceModel = nil
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func resetDocsBarItems() {
        guard let completion = self.completion else {
            return
        }
        guard let url = URL(string: self.webUrl) else {
            return
        }
        let isShow = CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.accociateAppBadgeIsShow)
        // 返回doc按钮
        let lkItem = LKBarButtonItem(image: UDIcon.fileDocColorful, buttonType: .custom)
        if !isShow {
            lkItem.button.addBadge(UDBadgeConfig.dot)
        }
        
        lkItem.addTarget(self, action: #selector(self.clickDocsButton), for: .touchUpInside)
        
        let title = ""
        let image = UDIcon.fileDocColorful
        let action: (QuickLaunchBarItem) -> Void = { [weak self] item in
            self?.clickDocsButton()
        }
        var quickItem = QuickLaunchBarItem(name: title, nomalImage: image, disableImage: image, action: action)
        self.quickItem = quickItem
        if !isShow {
            quickItem.badge = Badge(type: .dot(.web), style: .strong)
        }
        
        completion(BusinessBarItemsForWeb(url: url, navigationBarItem: lkItem, launchBarItem: quickItem, extraMap: nil))
    }
    
    //文档按钮点击
    @objc private func clickDocsButton() {
        guard let vc = self.vc else {
            return
        }
        
        //还没有显示过红点
        if !CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.accociateAppBadgeIsShow) {
            CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.accociateAppBadgeIsShow)
            //重置下按钮不显示红点
            self.resetDocsBarItems()
        }
        
        if let referenceModel = self.referenceModel { //有关联文档则跳转到文档
            guard let urlStr = referenceModel.url,
                  !urlStr.isEmpty,
                  let url = URL(string: urlStr) else {
                DocsLogger.error("clickDocsButton url error, url:\(referenceModel.url ?? "")", component: LogComponents.associateApp)
                return
            }
            // 跳转文档
            self.push(url: url, vc: vc)
            AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .clickViewDocsEntrance,
                                                              showType: .viewDocs,
                                                              referenceModel: self.referenceModel,
                                                              webUrl: URL(string: self.webUrl),
                                                              urlId: self.urlMetaId)
        } else {
            //没有关联文档，进行关联或者创建
            self.associateOrCreateDoc(vc: vc)
        }
    }
    
    public func destroyBarItems() {
        self.vc = nil
    }
    
}

extension DocPluginForWebImp {
    //跳转文档
    private func push(url: URL, vc: UIViewController) {
        let context: [String: Any] = [RouterDefine.associateAppUrl: self.webUrl, RouterDefine.associateAppUrlMetaId: self.urlMetaId ?? 0]
        
        Navigator.shared.showDetailOrPush(url, context: context, wrap: LkNavigationController.self, from: vc, animated: true)
        
        // 上报安全合规统计埋点
        // 解析文档类型 + token
        let docInfo = DocsUrlUtil.getFileInfoNewFrom(url)
        guard let token = docInfo.token, let type = docInfo.type else {
            return
        }
        
        // 文档token
        var renderItems = [SecurityEvent_RenderItem]()
        var itemId = SecurityEvent_RenderItem()
        itemId.key = RenderItemKey.relationDocId.rawValue
        itemId.value = token
        renderItems.append(itemId)
        
        // 当前网页容器url
        var itemUrl = SecurityEvent_RenderItem()
        itemUrl.key = RenderItemKey.relationUrl.rawValue
        itemUrl.value = url.absoluteString
        renderItems.append(itemUrl)
        
        SecurityReviewManager.reportAction(type, operation: OperationType.operationsClickDocPlugin, driveType: nil, token: token, appInfo: nil, wikiToken: nil, renderItems: renderItems)
    }
    
    //创建或者关联文档
    func associateOrCreateDoc(vc: UIViewController) {
        let actionSheet = UDActionSheet.actionSheet()
        
        actionSheet.addItem(text: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_New_Button) { [weak self] in
            guard let self = self else {
                return
            }
            self.createAndAssociate(vc: vc)
            AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .clickCreateDocsEntrance, 
                                                              showType: .addDocs,
                                                              referenceModel: self.referenceModel,
                                                              webUrl: URL(string: self.webUrl),
                                                              urlId: self.urlMetaId)
            
            
        }

        actionSheet.addItem(text: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Select_Button) { [weak self] in
            
            guard let self = self else {
                return
            }
            //跳转picker
            self.associateSelectDocs(vc: vc)
            AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .clickRelationDocsEntrance,
                                                              showType: .addDocs,
                                                              referenceModel: self.referenceModel,
                                                              webUrl: URL(string: self.webUrl),
                                                              urlId: self.urlMetaId)
        }
        actionSheet.addItem(text: SKResource.BundleI18n.SKResource.Doc_Facade_Cancel, style: .cancel)
        vc.present(actionSheet, animated: true, completion: nil)
        
    }
    
    //跳转创建并关联文档
    
    func createAndAssociate(vc: UIViewController) {
        DocPluginForWebService.createReference(appUrl: self.webUrl) { url, _ in
            guard let url = url else {
                UDToast.showFailure(with: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_CreateFail_Toast, on: vc.view)
                return
            }
            //关联文档成功
            UDToast.showSuccess(with: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Linked_Toast(0), on: vc.view.window ?? vc.view)
            let model = AssociateAppModel.ReferencesModel()
            model.url = url
            self.referenceModel = model
            
            guard let pushUrl = URL(string: url) else {
                return
            }
            //关联成功，并进行跳转
            DispatchQueue.safetyAsyncMain { [weak self] in
                guard let self = self else {
                    return
                }
                self.push(url: pushUrl, vc: vc)
            }
            AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .successCreateDocs,
                                                              showType: .addDocs,
                                                              referenceModel: self.referenceModel,
                                                              webUrl: URL(string: self.webUrl),
                                                              urlId: self.urlMetaId)
        }
    }
    
    //关联已有文档
    func associateSelectDocs(vc: UIViewController) {
#if MessengerMod
        let selectResult: SelectResult = { result  in
            DocPluginForWebService.addReference(appUrl: self.webUrl, docList: result) { [weak self] isSuccess, _ in
                guard let self else {
                    return
                }
                if isSuccess {
                    //关联文档成功
                    UDToast.showSuccess(with: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_Linked_Toast(0), on: vc.view.window ?? vc.view)
                    
                    //内存记录下关联的第一篇文档
                    guard let firstModel = result.first else {
                        DocsLogger.error("addReference success but firstModel is nil", component: LogComponents.associateApp)
                        return
                    }
                    let model = AssociateAppModel.ReferencesModel()
                    model.url = firstModel.url
                    model.objToken = firstModel.docToken
                    model.objType = firstModel.docType.rawValue
                    self.referenceModel = model
                    
                    guard let urlString = model.url, let pushUrl = URL(string: urlString) else {
                        return
                    }
                    //关联成功，并进行跳转
                    DispatchQueue.safetyAsyncMain { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.push(url: pushUrl, vc: vc)
                    }
                    
                    AssociateAppTracker.reportPluginClickTrackerEvent(clickType: .successRelationDocs,
                                                                      showType: .addDocs,
                                                                      referenceModel: self.referenceModel,
                                                                      webUrl: URL(string: self.webUrl),
                                                                      urlId: self.urlMetaId)
                    
                } else {
                    UDToast.showFailure(with: SKResource.BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_LinkFail_Toast, on: vc.view)
                }
            }
        }
        
        let picker = self.createSelectDocsPickController(selectResult: selectResult)
        vc.present(picker, animated: true, completion: nil)
#endif
    }
}
