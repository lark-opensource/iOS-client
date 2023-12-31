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
