//
//  OpenPluginGetVideoInfoAPI.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE on 2023/4/12 08:54:29
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkOpenPluginManager
import MobileCoreServices
import LarkContainer

// MARK: - OpenPluginGetVideoInfoAPI
final class OpenPluginGetVideoInfoAPI: OpenBasePlugin {
    
    func getVideoInfo(
        params: OpenPluginGetVideoInfoRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetVideoInfoResponse>) -> Void) {
            do {
                context.apiTrace.info("getVideoInfo src:\(params.src)")
                let file = try FileObject(rawValue: params.src) // JSSDK 已经处理了 http 的下载，到 API 都是ttfile
                let fsContext = FileSystem.Context(
                    uniqueId: gadgetContext.uniqueID,
                    trace: context.apiTrace,
                    tag: "getVideoInfo",
                    isAuxiliary: true
                )
                let filePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)
                
                let avAsset = AVAsset(url: URL(fileURLWithPath: filePath))
                //视频 mineType
                guard let mineType = mimeTypeForFile(at: filePath) else {
                    context.apiTrace.error("getVideoInfo: mineType nil, filePath: \(filePath)")
                    let apiError = OpenAPIError(errno: OpenAPIGetVideoInfoErrno.typeNotSupport).setMonitorMessage("mineType nil")
                    callback(.failure(error: apiError))
                    return
                }
                guard mineType.hasPrefix("video") else {
                    context.apiTrace.error("getVideoInfo: invalidate mineType:\(mineType), filePath: \(filePath)")
                    let apiError = OpenAPIError(errno: OpenAPIGetVideoInfoErrno.typeNotSupport).setMonitorMessage("invalidate mineType")
                    callback(.failure(error: apiError))
                    return
                }
                
                //视频时长
                let duration = CMTimeGetSeconds(avAsset.duration)
                let str = String(format: "%.1f", duration)
                let videoDuration = Double(str) ?? 0
                context.apiTrace.info("getVideoInfo: mineType:\(mineType), videoDuration:\(videoDuration)")
                
                let tracks = avAsset.tracks(withMediaType: .video)
                guard let track = tracks.first else {
                    context.apiTrace.error("getVideoInfo: getVideoTracks fail, filePath: \(filePath)")
                    let apiError = OpenAPIError(errno: OpenAPIGetVideoInfoErrno.canNotGetInfo).setMonitorMessage("getVideoTracks fail")
                    callback(.failure(error: apiError))
                    return
                }
                //获取视频宽高
                let videoSize = track.naturalSize.applying(track.preferredTransform)
                let videoWidth = Int(abs(videoSize.width))
                let videoHeight = Int(abs(videoSize.height))
                
                //视频大小
                let size = LSFileSystem.fileSize(path: filePath)
                let fileSizeKb = Int(Double(size) / 1024.0)
                context.apiTrace.info("getVideoInfo: videoWidth:\(videoWidth), videoHeight:\(videoHeight), fileSizeKb:\(fileSizeKb)")

                guard size > 0, videoWidth > 0, videoHeight > 0 else {
                    context.apiTrace.error("getVideoInfo: invalidate size or videoWidth or videoHeight, filePath: \(filePath)")
                    let apiError = OpenAPIError(errno: OpenAPIGetVideoInfoErrno.canNotGetInfo).setMonitorMessage("invalidate size or videoWidth or videoHeight")
                    callback(.failure(error: apiError))
                    return
                }
                
                let result = OpenPluginGetVideoInfoResponse(
                    type: mineType,
                    duration: videoDuration,
                    size: fileSizeKb,
                    height: videoHeight,
                    width: videoWidth,
                    path: nil   //path字段jssdk统一处理
                )
                callback(.success(data: result))
            }catch let fileError as FileSystemError {
                callback(.failure(error: OpenAPIError(errno: fileError.fileCommonErrno)))
            } catch {
                let apiError = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                    .setMonitorMessage("getVideoInfo unknown error \(error)")
                callback(.failure(error: apiError))
            }
    }
    
    func mimeTypeForFile(at filePath: String) -> String? {
        let url = URL(fileURLWithPath: filePath)
        guard let fileExtension = url.pathExtension as CFString?,
            let fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil)?.takeRetainedValue(),
            let mimeType = UTTypeCopyPreferredTagWithClass(fileUTI, kUTTagClassMIMEType)?.takeUnretainedValue() as String?
            else { return nil }

        return mimeType
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "getVideoInfo", pluginType: Self.self, paramsType: OpenPluginGetVideoInfoRequest.self, resultType: OpenPluginGetVideoInfoResponse.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("getVideoInfo API call start")
            this.getVideoInfo(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("getVideoInfo API call end")
        }
    }
}
