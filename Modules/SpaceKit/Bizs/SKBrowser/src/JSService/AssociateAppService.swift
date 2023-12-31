//
//  AssociateAppService.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/10/13.
//

import Foundation
import SKCommon
import SKFoundation
import UniverseDesignToast
import LarkContainer

public final class AssociateAppService: BaseJSService {}

extension AssociateAppService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.associateAppUrlInfo,
                .associateAppShowUrlListPanel,
                .associateAppShowDisassociateMoreDialog]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        
        DocsLogger.info("AssociateAppService, serviceName=\(serviceName) \(self.editorIdentity)", component: LogComponents.associateApp)
        switch serviceName {
        case DocsJSService.associateAppUrlInfo.rawValue: //关联关系数据获取，接口把关联关系数据给到native
            guard let references = params["data"] as? [[String: Any]] else {
                DocsLogger.info("associateAppUrlInfo, data is error: \(params)", component: LogComponents.associateApp)
                return
            }
            
            do {
                let referencesData = try JSONSerialization.data(withJSONObject: references)
                let referencesArray = try JSONDecoder().decode([AssociateAppModel.ReferencesModel].self, from: referencesData)
                self.model?.hostBrowserInfo.docsInfo?.references = referencesArray
                
            } catch {
                DocsLogger.info("associateAppUrlInfo, references decode error: \(error)", component: LogComponents.associateApp)
            }
            
            
        case DocsJSService.associateAppShowUrlListPanel.rawValue://文档内查看关联的应用
            guard let references = params["data"] as? [[String: Any]] else {
                DocsLogger.info("associateAppShowUrlListPanel, data is error: \(params)", component: LogComponents.associateApp)
                return
            }
            
            
            do {
                let referencesData = try JSONSerialization.data(withJSONObject: references)
                let referencesArray = try JSONDecoder().decode([AssociateAppModel.ReferencesModel].self, from: referencesData)
                
                //跳转关联事项页面
                guard let currentVC = navigator?.currentBrowserVC else { return }
                guard let model = self.model else { return }
                let viewModel = AssociateAppViewModel(userResolver: model.userResolver)
                viewModel.references = referencesArray
                let associateAppVC = AssociateAppViewController(viewModel: viewModel)
                currentVC.present(associateAppVC, animated: true)
                
            } catch {
                DocsLogger.info("associateAppShowUrlListPanel, references decode error: \(references)", component: LogComponents.associateApp)
            }
            
            
            break
        case DocsJSService.associateAppShowDisassociateMoreDialog.rawValue: //解除关联的二次弹出
            guard let hostVC = navigator?.currentBrowserVC else { return }
            guard let docsInfo = self.model?.hostBrowserInfo.docsInfo else  { return }
            guard let webBrowser = self.model?.jsEngine as? WebBrowserView else {
                DocsLogger.info("associateAppShowDisassociateMoreDialog, get webBrowser nil", component: LogComponents.associateApp)
                return
            }
            
            DocPluginForWebService.showTipAndDeleteReference(appUrl: webBrowser.fileConfig?.associateAppUrl, 
                                                             urlMetaId: webBrowser.fileConfig?.associateAppUrlMetaId, 
                                                             hostVC: hostVC, 
                                                             docList: [(docToken: docsInfo.objToken, docType: docsInfo.type)]) { isSuccess, error in
                DocsLogger.info("UtilMoreDataProvider, deleteReference isSuccess:\(isSuccess) , error: \(String(describing: error))", component: LogComponents.associateApp)
            }
        default:
            break
        }
    }
}
