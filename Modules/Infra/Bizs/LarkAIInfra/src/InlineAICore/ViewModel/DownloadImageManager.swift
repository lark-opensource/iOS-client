//
//  InlineAIImageManager.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/7/11.
//  


import UIKit
import ByteWebImage

protocol InlineAIImageManagerDelegate: AnyObject {
    func aiImageDownloadSuccess(with model: InlineAICheckableModel, image: UIImage?)
    func aiImageDownloadFailure(with model: InlineAICheckableModel)
}



class DownloadImageManager {

    weak var api: DownloadAIImageAPI?

    init(api: DownloadAIImageAPI?) {
        self.api = api
    }
    
    var dowloadTask: [String: Bool] = [:]
    
    weak var delegate: InlineAIImageManagerDelegate?

    func downloadImage(models: [InlineAICheckableModel]) {
        guard let api = api else {
            LarkInlineAILogger.warn("[ai image] dowloadAPI is nil")
            return
        }
        for model in models {
            if let urlString = model.source.urlString {
                let logId = urlString.md5()
                // url可能会一样，但是ID不一样，要保证每次下载都有回调，任务要绑ID，不能绑url
                let cacheId = model.id
                guard dowloadTask[cacheId] == nil else {
                    LarkInlineAILogger.warn("[ai image] dowload task:\(logId) is running")
                    continue
                }
                LarkInlineAILogger.info("[ai image] downloading id:\(logId)")
                dowloadTask[cacheId] = true
                api.requestImageURL(urlString: urlString) { [weak self] imageResult in
                    switch imageResult {
                    case .failure(let error):
                        LarkInlineAILogger.info("[ai image] error: \(error)")
                        self?.delegate?.aiImageDownloadFailure(with: model)
                    case let .success(result):
                        if result.image == nil {
                            LarkInlineAILogger.info("[ai image] error, image is nil, id:\(logId)")
                        } else {
                            LarkInlineAILogger.info("[ai image] download successid:\(logId)")
                        }
                        self?.delegate?.aiImageDownloadSuccess(with: model, image: result.image)
                    }
                    self?.dowloadTask[cacheId] = nil
                }
            }
        }
    }
}
