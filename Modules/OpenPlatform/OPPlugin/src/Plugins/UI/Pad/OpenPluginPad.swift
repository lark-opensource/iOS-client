//
//  OpenPluginPad.swift
//  OPPlugin
//
//  Created by ChenMengqi on 2021/9/1.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSplitViewController
import LarkContainer
import OPFoundation


final class OpenPluginPad: OpenBasePlugin {
    enum PadDisplayScaleMode: String {
        case disableScale = "disableScale"
        case fullScreen = "fullScreen"
        case allVisible = "allVisible"
    }

    private static let errorMsgNotSupportScaleMode = "not support this scale mode"
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "getPadDisplayScaleMode", pluginType: Self.self, paramsType: OpenAPIBaseParams.self) { (this, params, context, callback)  in
            
            this.getPadDisplayScaleMode(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: "togglePadFullScreen", pluginType: Self.self, paramsType: OpenPluginPadParams.self) { (this, params, context, callback) in
            
            this.togglePadFullScreen(params: params, context: context, callback: callback)
        }
    }
    
    private func getPadDisplayScaleMode(params: OpenAPIBaseParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            let error = OpenAPIError(code: FullScreenIpadErrorCode.notSupportScaleMode)
                .setMonitorMessage(OpenPluginPad.errorMsgNotSupportScaleMode).setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        guard let controller = context.controller  else {
            context.apiTrace.error("context.controller nil? \(context.controller == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("context.controller nil? \(context.controller == nil)").setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        
        var displayModeResult : PadDisplayScaleMode
        
        if OPTemporaryContainerService.isGadgetTemporaryEnabled() && controller.isTemporaryChild {
            displayModeResult = .disableScale
            callback(.success(data: OpenPluginPadResult(displayScaleMode: displayModeResult.rawValue)))
            return
        }
        
        guard let split = controller.larkSplitViewController else {
            let error = OpenAPIError(code: FullScreenIpadErrorCode.notSupportScaleMode)
                .setMonitorMessage(OpenPluginPad.errorMsgNotSupportScaleMode).setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }

        if split.isCollapsed {
            displayModeResult = .disableScale
        } else {
            switch split.splitMode {
            case .twoOverSecondary, .twoDisplaceSecondary, .twoBesideSecondary, .oneOverSecondary, .oneBesideSecondary, .sideOnly:
                displayModeResult = .allVisible
            case .secondaryOnly:
                displayModeResult = .fullScreen
            }
        }
        callback(.success(data: OpenPluginPadResult(displayScaleMode: displayModeResult.rawValue)))
    }
    
    private func togglePadFullScreen(params: OpenPluginPadParams, context: OpenAPIContext, callback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)) {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            let error = OpenAPIError(code: FullScreenIpadErrorCode.notSupportScaleMode)
                .setMonitorMessage(OpenPluginPad.errorMsgNotSupportScaleMode).setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        guard let controller = context.controller  else {
            context.apiTrace.error("context.controller nil? \(context.controller == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("context.controller nil? \(context.controller == nil)").setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        
        guard let split = controller.larkSplitViewController else {
            let error = OpenAPIError(code: FullScreenIpadErrorCode.notSupportScaleMode)
                .setMonitorMessage(OpenPluginPad.errorMsgNotSupportScaleMode).setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        
        var displayMode : SplitViewController.SplitMode = split.splitMode
        if split.isCollapsed {
            let error = OpenAPIError(code: FullScreenIpadErrorCode.notSupportScaleMode)
                .setMonitorMessage(OpenPluginPad.errorMsgNotSupportScaleMode).setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        
        if let inPutDisplayMode = params.displayScaleMode {
            if inPutDisplayMode == PadDisplayScaleMode.allVisible.rawValue {
                //输入参数为目标状态，因此allVisible需要起始状态为 detailFullscreen
                displayMode = .secondaryOnly
            } else if inPutDisplayMode == PadDisplayScaleMode.fullScreen.rawValue{
                //输入参数为目标状态，因此detailFullscreen需要起始状态为allVisible
                displayMode = .twoOverSecondary
            } else {
                let error = OpenAPIError(code: FullScreenIpadErrorCode.notSupportScaleMode)
                    .setMonitorMessage(OpenPluginPad.errorMsgNotSupportScaleMode).setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
        }
        
        if displayMode != .secondaryOnly {
            // 进入全屏
            split.updateSplitMode(.secondaryOnly, animated: true)
        } else {
            // 退出全屏
            split.updateSplitMode(.twoOverSecondary, animated: true)
        }
        callback(.success(data:nil))
    }
}
