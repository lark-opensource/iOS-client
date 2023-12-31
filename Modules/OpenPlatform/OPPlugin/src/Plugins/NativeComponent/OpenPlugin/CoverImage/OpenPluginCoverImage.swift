//
//  OpenPluginCoverImage.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/5/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import TTMicroApp
import LarkContainer
import OPPluginManagerAdapter

final class OpenPluginCoverImage: OpenBasePlugin {

    // implemention of api handlers
    func insertCoverImage(params: OpenAPICoverImageParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: (OpenAPIBaseResponse<OpenAPIInsertCoverImageResult>) -> Void) {
        guard let componentManager = BDPComponentManager.shared() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext is nil")
            callback(.failure(error: error))
            return
        }
        guard let controller = context.controller,
              let appController = BDPAppController.currentAppPageController(controller, fixForPopover: false),
              let appPage = appController.appPage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("can not get current appPage VC for \(String(describing: context.controller))")
                .setOuterMessage("Must be in the applet runtime environment")
            callback(.failure(error: error))
            return
        }
        let componentID = componentManager.generateComponentID()
        let coverImageView = OpenComponentCoverImage(with: gadgetContext.uniqueID, model: params, componentID: componentID, trace: context.apiTrace) {
            do {
                let firEventInfo = try OpenAPIFireEventParams(event: "onCoverImageTapped",
                                                              sourceID: appPage.appPageID,
                                                              data: ["coverImageId": componentID,
                                                                     "data": params.data],
                                                              preCheckType: .none,
                                                              sceneType: .worker)
                let response = context.syncCall(apiName: "fireEvent", params: firEventInfo, context: context)
                switch response {
                case .failure(error: let err):
                    context.apiTrace.info("fireEvent onCoverImageTapped fail for app \(gadgetContext.uniqueID), error \(err)")
                default:
                    context.apiTrace.info("fireEvent onCoverImageTapped success for app \(gadgetContext.uniqueID)")
                }
            } catch {
                context.apiTrace.info("fireEvent onCoverImageTapped fail for app \(gadgetContext.uniqueID), error \(error)")
            }
        }
        context.apiTrace.info("insert CoverImage ID=\(componentID)")
        var hostView: UIView = appPage.scrollView
        if params.absolutelyFixed {
            hostView = appController.view
        } else if params.fixed {
            hostView = appPage
        }
        componentManager.insertComponentView(coverImageView, to: hostView)
        coverImageView.update(model: params)

        callback(.success(data: OpenAPIInsertCoverImageResult(componentID: componentID)))
    }

    func removeCoverImage(params: OpenAPICoverImageBaseParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        if params.componentID != Int.max {
            context.apiTrace.info("remove coverImage ID=\(params.componentID)")
            BDPComponentManager.shared()?.removeComponentView(byID: params.componentID)
        }
        callback(.success(data: nil))
    }

    func updateCoverImage(params: OpenAPICoverImageParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        if params.componentID != Int.max, let coverImage = BDPComponentManager.shared()?.findComponentView(byID: params.componentID) as? OpenComponentCoverImage {
            context.apiTrace.info("update coverImage ID=\(params.componentID)")
            coverImage.update(model: params)
        } else {
            context.apiTrace.warn("can not find coverImage ID=\(params.componentID) to update ")
        }
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        
        // register your api handlers here
        registerInstanceAsyncHandlerGadget(for: "insertCoverImage", pluginType: Self.self, paramsType: OpenAPICoverImageParams.self, resultType: OpenAPIInsertCoverImageResult.self) { (this, params, context,gadgetContext, callback) in
            
            this.insertCoverImage(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandler(for: "removeCoverImage", pluginType: Self.self, paramsType: OpenAPICoverImageBaseParams.self) { (this, params, context, callback) in
            
            this.removeCoverImage(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "updateCoverImage", pluginType: Self.self, paramsType: OpenAPICoverImageParams.self) { (this, params, context, callback) in
            
            this.updateCoverImage(params: params, context: context, callback: callback)
        }
    }

}
