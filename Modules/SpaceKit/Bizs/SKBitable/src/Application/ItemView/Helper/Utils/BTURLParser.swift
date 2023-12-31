//
//  BTDocumentURLParser.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/21.
//  


import SKFoundation
import SKCommon
import RxSwift
import SpaceInterface

final class BTURLParser {
    
    private let disposeBag = DisposeBag()
    /// 查看是否是文档链接
    /// - Parameters:
    ///   - url: 链接
    ///   - completion: 是文档链接和请求成功会返回 atInfo
    func parseAtInfoFormURL(_ url: String, completion: @escaping ((AtInfo?) -> Void)) {
        InternalDocAPI().getAtInfoByURL(url)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                switch res {
                case .success(let atInfo):
                    completion(atInfo)
                case .failure(let error):
                    completion(nil)
                    DocsLogger.info("DocumentURLParser get atInfo by url failure \(error)")
                }
            })
            .disposed(by: self.disposeBag)
    }
}
