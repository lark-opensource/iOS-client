//
//  MyLibraryIneractionHandler.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/24.
//

import Foundation
import RxCocoa
import RxSwift
import SKCommon
import SKFoundation

public protocol MyLibraryInteractionType {
    func getMyLibrarySpaceId() -> Single<String>
}

public class MyLibraryInteractionHandler: MyLibraryInteractionType {
    private let disposeBag = DisposeBag()
    
    public enum LibraryError: Error {
        case selfRefrenceError
    }
    
    public init() {}
    
    public func getMyLibrarySpaceId() -> Single<String> {
        if let spaceId = MyLibrarySpaceIdCache.get() {
            DocsLogger.info("wiki.my.library --- get library spaceId succees from cache")
            return .just(spaceId)
        }
        
        return WikiNetworkManager.shared.getWikiLibrarySpaceId()
                .catchError( { [weak self] error in
                    guard let self else {
                        return .error(LibraryError.selfRefrenceError)
                    }
                    let code = (error as NSError).code
                    if let wikiError = WikiErrorCode(rawValue: code),
                       wikiError == .sourceNotExist {
                        //用户没有文档库，需要客户端调用创建接口新建
                        DocsLogger.info("wiki.my.library --- get library spaceId error, code is sourceNotExist, should create library!")
                        return self.createMyLibraryIfNeed()
                    } else {
                        DocsLogger.error("wiki.my.library --- get library spaceId error, error: \(error)")
                        throw error
                    }
                })
            
    }
    
    private func createMyLibraryIfNeed() -> Single<String> {
        let uniqID = String(Date().timeIntervalSince1970)
        return WikiNetworkManager.shared.createMyLibrary(uniqID: uniqID)
    }
    
}
