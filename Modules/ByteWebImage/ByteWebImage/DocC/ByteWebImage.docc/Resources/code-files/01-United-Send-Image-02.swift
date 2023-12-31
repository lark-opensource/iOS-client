import ByteWebImage

// 类需要继承自LarkSendImageUploader
class ThisUploader: LarkSendImageUploader {
    // 遵守协议：明确上传接口返回的类型
    typealias AbstractType = String
    // 遵守协议：在这个方法内调用上传接口
    func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<ResultType> {
        // 可以通过此方法拿到「检查通过」+「压缩完成」的图片数据
        let compressResults: [CompressResult]? = request.getCompressResult()
        // 转换成上传接口需要的数据格式
        let thisData: [Data] = compressResults.map { .... }
        // 调用上传接口，将数据传输下去
        // 假设uploadFunc(data: [Data]) -> Observable<String>
        return UploadService.uploadFunc(data: thisData)
    }
}

let thisUploader = ThisUploader()
let thisRequest = SendImageRequest(
    input: .asset(PHAsset), // 还可以选择data，image等入参
    sendImageConfig: SendImageConfig(
        isSkipError: false, // 如果图片在「检查和压缩」阶段出错，是否跳过当前步骤
        checkConfig: SendImageCheckConfig(isOrigin: false), // 还有其他参数，具体说明看文档
        compressConfig: SendImageCompressConfig()), // 还有其他参数，具体说明看文档
    uploader: thisUploader
)
