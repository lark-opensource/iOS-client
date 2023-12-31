//
//  CompressImagePlugin.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/3/9.
//

import OPFoundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSetting
import OPSDK
import OPPluginManagerAdapter

extension OpenPluginImage {
    
    /// 可抽象下沉
    private func genError(_ code: OpenAPIErrorCodeProtocol, _ message: String) -> OpenAPIError {
        OpenAPIError(code: code)
            .setMonitorMessage(message)
    }
    
    /// 读取文件数据
    /// - Parameters:
    ///   - src: 文件路径
    ///   - fsContext: 读取上下文
    /// - Returns: data
    /// 这个方法会抛出异常
    /// 这块感觉也很通用，要不要下沉个统一的中间件，file -> data，但是代码量也挺小，看看吧
    private func read(src: String, fsContext: FileSystem.Context) throws -> Data {
        let file = try FileObject(rawValue: src)
        return try FileSystem.readFile(file, context: fsContext)
    }
    
    /// 数据写入文件，落盘
    /// - Parameters:
    ///   - data: 目标 data
    ///   - fsContext: 读取上下文
    /// - Returns: 文件路径
    private func write(data: Data, fsContext: FileSystem.Context) throws -> String {
        let randomFile = FileObject.generateRandomTTFile(type: .temp, fileExtension: TMACustomHelper.contentType(forImageData: data))
        try FileSystemCompatible.writeSystemData(data, to: randomFile, context: fsContext)
        return randomFile.rawValue
    }
    
    /// 将二进制数据进行压缩或者移动
    /// - Parameter data: 图片的二进制数据
    /// - Returns: data 压缩后的数据
    private func compress(data: Data, quality: Int) throws -> Data {
        guard let image = UIImage(data: data), BDPImageHelper.mimeType(forImageData: data) == BDPImageHelper.mimeType(for: .JPEG) else {
            return data
        }
        
        let realQuality: Int
        if 1...100 ~= quality {
            realQuality = quality
        } else {
            realQuality = 80
        }
        
        let floatQuality = CGFloat(realQuality) / 100
        guard let compressData = image.jpegData(compressionQuality: floatQuality) else {
            throw genError(OpenAPICommonErrorCode.unknown, "compress image fail")
                .setErrno(OpenAPICommonErrno.unknown)
        }
        return compressData
    }
    
    func compressImageV2(with params: OpenPluginCompressImageRequest,
                         context: OpenAPIContext,
                         gadgetContext: GadgetAPIContext,
                         callback: @escaping (OpenAPIBaseResponse<OpenPluginCompressImageResponse>) -> Void) {
        do {
            context.apiTrace.info("compressImageV2 begin quality: \(params.quality), \(params.src)")
            let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID, trace: context.apiTrace, tag: "compressImage")
            // 读数据
            let data = try read(src: params.src, fsContext: fsContext)
            context.apiTrace.info("compressImageV2 read data done")
            
            // 压缩数据
            let compressedData = try compress(data: data, quality: params.quality)
            context.apiTrace.info("compressImageV2 compress image done")

            // 写数据
            let filePath = try write(data: compressedData, fsContext: fsContext)
            context.apiTrace.info("compressImageV2 save to file done")
            let result = OpenPluginCompressImageResponse(tempFilePath: filePath)
            callback(.success(data: result))
            context.apiTrace.info("compressImageV2 success")
        } catch let error as FileSystemError {
            context.apiTrace.error("compressImageV2 failed, \(error)")
            let apiError = genError(OpenAPICommonErrorCode.unknown, "write image to file failed, error \(error)")
            switch error {
            case .readPermissionDenied,
                    .fileNotExists,
                    .invalidFilePath,
                    .isNotFile:
                apiError.setErrno(error.fileCommonErrno)
            default:
                apiError.setErrno(OpenAPICommonErrno.unknown)
            }
            callback(.failure(error: apiError))
        } catch let e as OpenAPIError {
            context.apiTrace.error("compressImageV2 failed, \(e)")
            callback(.failure(error: e))
        } catch {
            context.apiTrace.error("compressImageV2 failed, unknown exec")
            assertionFailure()
            let error = genError(OpenAPICommonErrorCode.unknown, "write image to file unknown failed")
                .setErrno(OpenAPICommonErrno.unknown)
            callback(.failure(error: error))
        }
    }
    
}
