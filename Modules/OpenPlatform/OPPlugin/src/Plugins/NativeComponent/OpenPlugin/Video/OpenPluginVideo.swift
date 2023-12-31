//
//  OpenpluginVideo.swift
//  OPPlugin
//
//  Created by bytedance on 2021/6/8.
//

import UIKit
import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import OPPluginBiz
import LarkContainer

final class OpenPluginVideo: OpenBasePlugin, BDPVideoPlayerControlProtocol {
    var frameID:Int?
    var videoContext:OpenAPIContext?
    func insertVideoPlayer(params: OpenPluginVideoParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginVideoInsertResult>) -> Void) {
        context.apiTrace.info("insertVideoPlayer start")
        guard let page = context.enginePageForComponent else {
            context.apiTrace.error("not in H5 / Native-App")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("not in H5 / Native-App")
            callback(.failure(error: error))
            return
        }
        self.videoContext = context
        self.frameID = params.frameId
        let uniqueID = gadgetContext.uniqueID
        let componentID = params.videoId
        let model = self.coverToVideoModel(params: params, uniqueID: uniqueID)
            /// cacheDir 老逻辑也是类似的做法，如果因为前置流程或者 tmp 本身为空导致设置了空，会有问题吗？保持一致先把完整日志打上。
            let common = BDPCommonManager.shared()?.getCommonWith(uniqueID)
            let tmpPath = common?.sandbox?.privateTmpPath()
            model.cacheDir = tmpPath ?? ""
            context.apiTrace.info("setup cache dir", additionalData: [
                "hasCommon": "\(common != nil)",
                "hasSandbox": "\(common?.sandbox != nil)",
                "hasTmpPath": "\(tmpPath != nil)"
            ])

            /// FileSystem 不应该包含处理 http/https 等链接，这里为了兼容需要分开处理。
            if params.filePath.hasPrefix("https") || params.filePath.hasPrefix("http") {
                model.filePath = params.filePath
            } else {
                do {
                    let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: context.apiTrace, tag: "videoComponent")
                    let file = try FileObject(rawValue: params.filePath)

                    /// 现在暂时使用兼容接口传递。
                    /// BDPVideoViewModel 继承了 JSONModel，filePath 无法直接改造为 OPFileOject。
                    /// 这个 viewmodel 本身的设计和使用已经不适应这个时代了，但是旧版 API 还在使用 JSONModel 的能力。
                    /// 后续需要先改造 viewModel，再将收敛后的文件能力改造到 viewModel 上，业务使用不感知。
                    let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)

                    /// 原逻辑需要使用 file:// 域能力
                    model.filePath = URL(fileURLWithPath: systemFilePath).absoluteString
                /// 以前的逻辑所有处理的错误都是打了一句错误日志，并没有在 API 上返回错误，这里将这些错误暴露出来，属于新增错误。
                /// 对于 commonManager，common，storageModule 等失败场景，应当返回失败。
                /// 对于 filePath 拿不到或者拿到不可用的场景，就算放过它执行下去，能正常播放吗？
                } catch let error as FileSystemError {
                    callback(.failure(error: error.openAPIError))
                    return
                } catch {
                    callback(.failure(error: error.fileSystemUnknownError))
                    return
                }
            }
        let avoidSameLayerRender:Bool
        if let routeMediatorManager = BDPRouteMediator.sharedManager() {
            avoidSameLayerRender = routeMediatorManager.isVideoAvoidSameLayerRenderForUniqueID(uniqueID)
        } else {
            context.apiTrace.error("routeMediatorManager is nil")
            avoidSameLayerRender = false
        }
        // ⚠️该组件为同层渲染组件，SuperView 为 WKScrollView (WKWebView 解析网页生成的层级节点)
        // WKScrollView 的 [x, y] 为真实的 style.top, style.left
        // 因此该组件 View 相对于父 View 位置应设为 [0, 0]
        if !avoidSameLayerRender {
            context.apiTrace.info("insertVideoPlayer avoid SameLayer with render")
            model.frame = CGRect(origin: CGPointZero, size: model.frame.size)
        }
        
        let videoView = OPPluginBizFactory.videoPlayer(model: model, componentID: componentID)
        
        videoView.delegate = self
        guard videoView.isKind(of: UIView.self) else {
            context.apiTrace.error("video component is not UIView")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("video component is not UIView")
            callback(.failure(error: error))
            return
        }
        context.apiTrace.info("insertVideoPlayer location webview")
        if avoidSameLayerRender {
            context.apiTrace.info("insertVideoPlayer avoidSameLayerRender action start")
            guard let componentManager = BDPComponentManager.shared() else {
                context.apiTrace.error("insertVideoPlayer componentManager is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("insertVideoPlayer componentManager is nil")
                callback(.failure(error: error))
                return
            }
            let success = componentManager.insertComponentView(videoView as? UIView & BDPComponentViewProtocol, to: page.scrollView, stringID: componentID)
            context.apiTrace.info("insertVideoPlayer insertComponentView result = \(success)")
            if success {
                callback(.success(data: OpenPluginVideoInsertResult(videoPlayerId: componentID)))
            } else {
                context.apiTrace.error("insert videoview fail")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("insert videoview fail")
                callback(.failure(error: error))
            }
        } else {
            page.bdp_insertComponent(videoView, atIndex: componentID, completion: { (success) in
                if success {
                    callback(.success(data: OpenPluginVideoInsertResult(videoPlayerId: componentID)))
                } else {
                    context.apiTrace.error("bdp_insert videoview fail")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("bdp_insert videoview fail")
                    callback(.failure(error: error))
                }
            })
        }
        context.apiTrace.info("insertVideoPlayer end")
    }

    func updateVideoPlayer(params: OpenPluginVideoParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("updateVideoPlayer start")
        guard let page = context.enginePageForComponent else {
            context.apiTrace.error("not in H5 / Native-App")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("not in H5 / Native-App")
            callback(.failure(error: error))
            return
        }
        self.videoContext = context
        self.frameID = params.frameId
        let componentID = params.videoPlayerId
        let uniqueID = gadgetContext.uniqueID
        let model = coverToVideoModel(params: params, uniqueID: uniqueID)
        
            /// FileSystem 不应该包含处理 http/https 等链接，这里为了兼容需要分开处理。
            if params.filePath.hasPrefix("https") || params.filePath.hasPrefix("http") {
                model.filePath = params.filePath
            } else {
                do {
                    let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: context.apiTrace, tag: "videoComponent")
                    let file = try FileObject(rawValue: params.filePath)

                    /// 现在暂时使用兼容接口传递。
                    /// BDPVideoViewModel 继承了 JSONModel，filePath 无法直接改造为 OPFileOject。
                    /// 这个 viewmodel 本身的设计和使用已经不适应这个时代了，但是旧版 API 还在使用 JSONModel 的能力。
                    /// 后续需要先改造 viewModel，再将收敛后的文件能力改造到 viewModel 上，业务使用不感知。
                    let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)

                    /// 原逻辑需要使用 file:// 域能力
                    model.filePath = URL(fileURLWithPath: systemFilePath).absoluteString
                /// 以前的逻辑所有处理的错误都是打了一句错误日志，并没有在 API 上返回错误，这里将这些错误暴露出来，属于新增错误。
                /// 对于 commonManager，common，storageModule 等失败场景，应当返回失败。
                /// 对于 filePath 拿不到或者拿到不可用的场景，就算放过它执行下去，能正常播放吗？
                } catch let error as FileSystemError {
                    callback(.failure(error: error.openAPIError))
                    return
                } catch {
                    callback(.failure(error: error.fileSystemUnknownError))
                    return
                }
            }
        
        let avoidSameLayerRender:Bool
        if let routeMediatorManager = BDPRouteMediator.sharedManager() {
            avoidSameLayerRender = routeMediatorManager.isVideoAvoidSameLayerRenderForUniqueID(uniqueID)
        } else {
            context.apiTrace.error("routeMediatorManager is nil")
            avoidSameLayerRender = false
        }
        // ⚠️该组件为同层渲染组件，SuperView 为 WKScrollView (WKWebView 解析网页生成的层级节点)
        // WKScrollView 的 [x, y] 为真实的 style.top, style.left
        // 因此该组件 View 相对于父 View 位置应设为 [0, 0]
        if !avoidSameLayerRender {
            context.apiTrace.info("updateVideoPlayer avoid SameLayer with render")
            model.frame = CGRect(origin: CGPointZero, size: model.frame.size)
        }
        func view() -> UIView? {
            if avoidSameLayerRender {
                if let componentManager = BDPComponentManager.shared() {
                   return componentManager.findComponentView(byStringID: componentID)
                } else {
                    context.apiTrace.info("componentManager is nil")
                    return nil
                }
            } else {
                return page.bdp_component(fromIndex: componentID)
            }
        }
        guard let view = view() else {
            context.apiTrace.error("videoId is invalid")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("videoId is invalid")
            callback(.failure(error: error))
            return
        }
        guard view.isKind(of: UIView.self) else {
            context.apiTrace.error("video component is not UIView")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("video component is not UIView")
            callback(.failure(error: error))
            return
        }
        guard view.conforms(to: BDPVideoViewDelegate.self) else {
            context.apiTrace.error("video component not conforms delegate")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("video component not conforms delegate")
            callback(.failure(error: error))
            return
        }
        context.apiTrace.info("updateVideoPlayer view comfirm BDPVideoViewDelegate protocol")
        if let videoView = view as? BDPVideoViewDelegate {
            videoView.update(with: model)
            context.apiTrace.info("updateVideoPlayer update view model")
        } else {
            context.apiTrace.info("updateVideoPlayer not BDPVideoViewDelegate")
        }
        if !avoidSameLayerRender {
            page.bdp_insertComponent(view, atIndex: componentID, completion: { (success) in
                context.apiTrace.info("bdp_insertComponentResult:\(success), componentID:\(componentID)")
            })
        } else {
            context.apiTrace.info("avoidSameLayerRender:\(avoidSameLayerRender)")
        }
        callback(.success(data: nil))
        context.apiTrace.info("updateVideoPlayer end")
    }

    func removeVideoPlayer(params: OpenPluginVideoRemoveParams, context:OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("removeVideoPlayer start")
        guard let page = context.enginePageForComponent else {
            context.apiTrace.error("not in H5 / Native-App")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("not in H5 / Native-App")
            callback(.failure(error: error))
            return
        }
        self.videoContext = context
        self.frameID = params.frameId
        let uniqueID = gadgetContext.uniqueID
        let componentID = params.videoPlayerId
        let avoidSameLayerRender:Bool
        if let routeMediatorManager = BDPRouteMediator.sharedManager() {
            avoidSameLayerRender = routeMediatorManager.isVideoAvoidSameLayerRenderForUniqueID(uniqueID)
        } else {
            context.apiTrace.error("routeMediatorManager is nil")
            avoidSameLayerRender = false
        }
        func view() -> UIView? {
            if avoidSameLayerRender {
                if let componentManager = BDPComponentManager.shared() {
                   return componentManager.findComponentView(byStringID: componentID)
                } else {
                    context.apiTrace.info("componentManager is nil")
                    return nil
                }
            } else {
                return page.bdp_component(fromIndex: componentID)
            }
        }
        if let videoView = view() as? BDPVideoViewDelegate {
            context.apiTrace.info("removeVideoPlayer stop")
            videoView.stop?()
        } else {
            context.apiTrace.info("removeVideoPlayer videoView as? BDPVideoViewDelegate fail")
        }
        if avoidSameLayerRender {
            context.apiTrace.info("removeVideoPlayer remove ComponentView:\(componentID)")
            if let componentManager = BDPComponentManager.shared() {
                componentManager.removeComponentView(byStringID: componentID)
            } else {
                context.apiTrace.info("componentManager is nil")
            }
        } else {
            context.apiTrace.info("removeVideoPlayer bdp_removeComponentAtIndex:\(componentID)")
            page.bdp_removeComponent(atIndex: componentID)
        }
        callback(.success(data: nil))
        context.apiTrace.info("removeVideoPlayer call end")
    }

    func operateVideoContext(params: OpenPluginVideoOperateParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("operateVideoContext start")
        guard let page = context.enginePageForComponent else {
            context.apiTrace.error("not in H5 / Native-App")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("not in H5 / Native-App")
            callback(.failure(error: error))
            return
        }
        self.videoContext = context
        self.frameID = params.frameId
        let uniqueID = gadgetContext.uniqueID
        let type = params.type
        let componentID = params.videoPlayerId
        let avoidSameLayerRender:Bool
        if let routeMediatorManager = BDPRouteMediator.sharedManager() {
            avoidSameLayerRender = routeMediatorManager.isVideoAvoidSameLayerRenderForUniqueID(uniqueID) ?? false
        } else {
            context.apiTrace.error("routeMediatorManager is nil")
            avoidSameLayerRender = false
        }
        func view() -> UIView? {
            if avoidSameLayerRender {
                if let componentManager = BDPComponentManager.shared() {
                   return componentManager.findComponentView(byStringID: componentID)
                } else {
                    context.apiTrace.info("componentManager is nil")
                    return nil
                }
            } else {
                return page.bdp_component(fromIndex: componentID)
            }
        }
        if let videoView = view() as? UIView & BDPVideoViewDelegate {
            context.apiTrace.info("operateVideoContext location view")
            if type == "seek" {
                context.apiTrace.info("operateVideoContext seek")
                let time = params.data
                videoView.seek?(time, completion: { (success) in
                    if success {
                        context.apiTrace.error("seek success")
                        callback(.success(data: nil))
                    } else {
                        context.apiTrace.error("seek failed")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setOuterMessage("seek failed")
                        callback(.failure(error: error))
                    }
                })
            } else if type == "play" {
                context.apiTrace.info("operateVideoContext play")
                videoView.play?()
                callback(.success(data: nil))
            } else if type == "pause" {
                context.apiTrace.info("operateVideoContext pause")
                videoView.pause?()
                callback(.success(data: nil))
            } else if type == "stop" {
                context.apiTrace.info("operateVideoContext stop")
                videoView.stop?()
                callback(.success(data: nil))
            } else if type == "requestFullScreen" {
                context.apiTrace.info("operateVideoContext requestFullScreen")
                videoView.enterFullScreen?()
                callback(.success(data: nil))
            } else if type == "exitFullScreen" {
                context.apiTrace.info("operateVideoContext exitFullScreen")
                videoView.exitFullScreen?()
                callback(.success(data: nil))
            } else {
                context.apiTrace.error("invalid type param")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("invalid type param")
                callback(.failure(error: error))
            }
        } else {
            context.apiTrace.error("videoView is not UIView & BDPVideoViewDelegate")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("invalid type param")
            callback(.failure(error: error))
        }
        context.apiTrace.info("operateVideoContext end")
    }

    func coverToVideoModel(params:OpenPluginVideoParams, uniqueID: OPAppUniqueID) -> BDPVideoViewModel {
        let model = BDPVideoViewModel()
        model.hide = params.hide
        model.autoplay = params.autoplay
        model.loop = params.loop
        model.frame = CGRectMake(CGFloat(params.position["left"] ?? 0), CGFloat(params.position["top"] ?? 0), CGFloat(params.position["width"] ?? 0), CGFloat(params.position["height"] ?? 0))
        model.data = params.data
        model.filePath = params.filePath
        model.poster = OPPathTransformHelper.buildURL(path: params.poster, uniqueID: uniqueID, tag: "videoComponent")
        model.initialTime = CGFloat(params.initialTime)
        model.duration = CGFloat(params.duration)
        model.objectFit = params.objectFit
        model.cacheDir = params.cacheDir
        model.encryptToken = params.encryptToken
        model.muted = params.muted
        model.controls = params.controls
        model.showFullscreenBtn = params.showFullscreenBtn
        model.showPlayBtn = params.showPlayBtn
        model.playBtnPosition = params.playBtnPosition
        model.autoFullscreen = params.autoFullscreen
        model.showMuteBtn = params.showMuteBtn
        model.header = OpenNativeComponentUtils.checkAndConvertVideoHeader(header: params.header)
        return model;
    }

    func bdp_videoPlayerStateChange(_ state: BDPVideoPlayerState, videoPlayer: (UIView & BDPVideoViewDelegate)!) {
        guard let videoContext = self.videoContext else {
            return
        }
        videoContext.apiTrace.info("bdp_videoPlayerStateChangeStart:\(state)")
        if let videoPlayer = videoPlayer {
            let componentID = videoPlayer.componentID ?? ""
            let data = videoPlayer.model.data ?? ""
            let frameID = self.frameID ?? 0
            switch state {
            case .finished:
                self.fireEvent(event: "onVideoEnded", sourceID: frameID, data: ["videoPlayerId" :componentID, "data": data])
            case .playing:
                self.fireEvent(event: "onVideoPlay", sourceID: frameID, data: ["videoPlayerId": componentID, "data": data])
            case .paused, .break:
                self.fireEvent(event: "onVideoPause", sourceID: frameID, data: ["videoPlayerId": componentID, "data": data])
            case .timeUpdate:
                self.fireEvent(event: "onVideoTimeUpdate", sourceID: frameID, data: ["videoPlayerId": componentID, "data": data, "currentTime": videoPlayer.currentTime, "duration": videoPlayer.duration])
            case .fullScreenChange:
                if videoPlayer.fullScreen {
                    self.fireEvent(event: "onVideoFullScreenChange", sourceID: frameID, data: [
                                    "videoPlayerId": componentID,
                                    "data": data,
                                    "fullScreen": videoPlayer.fullScreen,
                                    "duration": videoPlayer.duration])
                } else {
                    self.fireEvent(event: "onVideoFullScreenChange", sourceID: frameID, data: [
                                    "videoPlayerId": componentID,
                                    "data": data,
                                    "fullScreen": videoPlayer.fullScreen])
                }
            case .error:
                guard let gadgetContext = videoContext.gadgetContext else {
                    videoContext.apiTrace.info("videoPlayerStateChange gadgetContext is nil")
                    return
                }
                BDPTracker.event(BDPTEVideoComponentError, attributes: nil, uniqueID: gadgetContext.uniqueID)
                self.fireEvent(event: "onVideoError", sourceID: frameID, data: ["videoPlayerId": componentID, "data": data])
            case .waiting:
                self.fireEvent(event: "onVideoWaiting", sourceID: frameID, data: ["videoPlayerId": componentID, "data": data])
            default:
                videoContext.apiTrace.error("videoPlayer state error")
                break
            }
        } else {
            videoContext.apiTrace.error("videoPlayer is nil")
        }
    }

    private func fireEvent(event: String, sourceID: Int, data: [AnyHashable: Any]?) {
        guard let context = self.videoContext else {
            return
        }
        do {
            let fireEvent = try OpenAPIFireEventParams(event: event,
                                                       sourceID: sourceID,
                                                       data: data ?? [:],
                                                       preCheckType: .none,
                                                       sceneType: .worker)
            let response = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            switch response {
            case let .failure(error: e):
                context.apiTrace.error("fire event \(event) fail \(e)")
            default:
                context.apiTrace.info("fire event \(event) success")
            }
        } catch {
            context.apiTrace.info("generate fire event params error \(error)")
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "insertVideoPlayer", pluginType: Self.self, paramsType: OpenPluginVideoParams.self, resultType: OpenPluginVideoInsertResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.insertVideoPlayer(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "updateVideoPlayer", pluginType: Self.self, paramsType: OpenPluginVideoParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.updateVideoPlayer(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "removeVideoPlayer", pluginType: Self.self, paramsType: OpenPluginVideoRemoveParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.removeVideoPlayer(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "operateVideoContext", pluginType: Self.self, paramsType: OpenPluginVideoOperateParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.operateVideoContext(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
