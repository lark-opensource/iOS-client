//
//  BTBlockCatalogService.swift
//  SKBitable
//
//  Created by zoujie on 2023/9/6.
//  


import SKFoundation
import SKCommon
import SKUIKit

final class BlockCatalogService: BaseJSService {}

extension BlockCatalogService: DocsJSServiceHandler {
    
    var container: BTContainer? {
        get {
            return (registeredVC as? BitableBrowserViewController)?.container
        }
    }
    
    var handleServices: [DocsJSService] {
        return [.setBlockCatalogContainer]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        switch DocsJSService(serviceName) {
        case .setBlockCatalogContainer:
            BlockCatalogueModel.desrializedGlobalAsync(with: params, callbackInMainQueue: true) { [weak self] model in
                guard let catalogParams = model, let self = self else {
                    DocsLogger.btInfo("[BTBlockCatalogService] invalid actionParams \(params)")
                    return
                }
                
                guard let container = self.container else {
                    DocsLogger.btInfo("[BTBlockCatalogService] container is nil")
                    return
                }
                
                DocsLogger.btInfo("[BTBlockCatalogService] set catalogData shouldClose:\(catalogParams.closePanel)")
                let permissionObj = BasePermissionObj.parse(params)
                let baseToken = params["baseId"] as? String ?? ""
                let baseContext = BaseContextImpl(baseToken: baseToken, service: self, permissionObj: permissionObj, from: "blockCatalog")
                
                container.updateBlockCatalogueModel(blockCatalogueModel: catalogParams, baseContext: baseContext)
            }
            break
        default:
            ()
        }
    }
}

extension BlockCatalogService: BaseContextService {}
