//
//  FeedCache.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/17.
//  


import SKFoundation
import RxSwift
import HandyJSON
import SKInfra

class FeedCache {
    
    enum CacheError: Error {
        case emptyError
        case apiError
        case convertError
    }
    
    var docsInfo: DocsInfo
    var queue: DispatchQueue
    
    lazy private var cacheAPI: NewCacheAPI? =  {
        return DocsContainer.shared.resolve(NewCacheAPI.self)
    }()
    
    init(docsInfo: DocsInfo) {
        self.docsInfo = docsInfo
        self.queue = DispatchQueue(label: "com.feed.docs", qos: .default)
    }
    
    var cacheKey: String {
        let tenantId = User.current.info?.tenantID ?? ""
        let userId = User.current.info?.userID ?? ""
        return "\(tenantId)_\(userId)_\(OpenAPI.APIPath.getFeedV2)_ios_v3"
    }
    
    func setCache<T: NSCoding>(_ models: [T]) {
        // https://stackoverflow.com/questions/47960353/crash-while-archiving-data-by-nskeyedarchiver
        // 需要保证归档期间内存模型无改变，否则会crash。放在主线程中串行处理较为保险
        let key = self.cacheKey
        let token = self.docsInfo.objToken
        if let codingData = try? NSKeyedArchiver.archivedData(withRootObject: models, requiringSecureCoding: false) as NSCoding {
            DocsLogger.feedInfo("save models count: \(models.count)")
            self.cacheAPI?.set(object: codingData, for: token, subkey: key, cacheFrom: nil)
        } else {
            DocsLogger.feedInfo("archivedData models fail")
        }
    }
    
    func getCache<T: NSCoding>(type: T.Type) -> Observable<[T]> {
        Observable<[T]>.create { [weak self] (ob) -> Disposable in
            guard let self = self else { return Disposables.create {} }
            self.queue.async {
                let key = self.cacheKey
                let token = self.docsInfo.objToken
                guard let objectValue = self.cacheAPI?.object(forKey: token, subKey: key) else {
                    DocsLogger.feedError("caceh models is empty")
                    ob.onError(CacheError.emptyError)
                    return
                }
                guard let data = objectValue as? Data else {
                    DocsLogger.feedError("convert data fail")
                    ob.onError(CacheError.convertError)
                    return
                }
                if let models = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [T] {
                    DispatchQueue.main.async {
                        DocsLogger.feedInfo("fetch cache models count:\(models.count) isMain: \(Thread.isMainThread)")
                        ob.onNext(models)
                    }
                }
            }
            return Disposables.create {}
        }
        
    }
}
