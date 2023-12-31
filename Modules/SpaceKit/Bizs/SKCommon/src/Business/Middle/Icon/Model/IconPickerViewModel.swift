//
//  IconPickerViewModel.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/6.
//

import RxSwift
import RxCocoa
import Foundation
import SwiftyJSON
import SKFoundation

/*
class IconPickerViewModel {

    // 一期用不到Rx
    var categories: BehaviorRelay<[DocsIconCategory]> = BehaviorRelay<[DocsIconCategory]>(value: [])

    var modifyCallback: (([DocsIconCategory]) -> Void)?
    
    private var request: DocsRequest<JSON>?
    
    private var token: String
    
    private lazy var _decoder: JSONDecoder = JSONDecoder()

    private let disposeBag = DisposeBag()
    
    init(token: String) {
        self.token = token

        categories.asObservable().subscribe { [weak self] in
            self?.modifyCallback?($0.element ?? [])
        }.disposed(by: disposeBag)
    }

    func updateIcons(search: String = "", message: String = "") {
        requestIcons(search: search, message: message) { [weak self] results, err in
            guard let self = self else { return }
            guard err == nil else {
                IconPickerViewController.showOfflineToast()
                self.categories.accept([])
                return
            }
            self.categories.accept(results)
        }
    }
    
    private func requestIcons(search: String,
                              message: String,
                              _ didFinish: @escaping ([DocsIconCategory], Error?) -> Void) {
        request?.cancel()
        let iconTypes: [Int] = [2]
        let parameters: [String: Any] = ["token": token,
                                         // 后端暂时不加此接口，二期之后再考虑
//                                         "search": search,
//                                         "message": message,
                                         // 向后兼容接口，一期仅支持[2-image]
                                         "icon_types": iconTypes]
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.getIcon,
                                    params: parameters)
            .set(method: .GET)
            .set(encodeType: .urlEncodeAsQuery)
            .start(result: { result, error in
                let reqId = UUID()
                DocsLogger.info("Start request icons", extraInfo: ["message": message, "search": search, "req": reqId])
                guard error == nil, let result = result else {
                    DocsLogger.error("Fail to request icons", extraInfo: ["req": reqId], error: error)
                    didFinish([], error)
                    return
                }
                guard let resultsArr = result["data"]["data"].array else {
                    DocsLogger.error("Fail to decode icons", extraInfo: ["req": reqId,
                                                                         "rspCode": result["code"].int ?? -12345,
                                                                         "rspMsg": result["message"].string ?? "nil"], error: error)
                    didFinish([], error)
                    return
                }
                let results: [DocsIconCategory] = resultsArr.compactMap { DocsIconCategory($0) }
                var finalResults: [DocsIconCategory] = []
                if !results.isEmpty, var first = results.first {
                    results.enumerated().forEach { (index, category) in
                        if index != 0 {
                            // 这里用index没用id进行区分，是因为后台下发的每组的id都是一样的，0
                            // 这里这么改是为了让ColletionView只显示成一组的样子，不分组显示
                            first.iconSet.append(contentsOf: category.iconSet)
                        }
                    }
                    finalResults.append(first)
                }

                DocsLogger.info("Did finish request icons", extraInfo: ["count": result.count, "req": reqId])

                didFinish(finalResults, nil)
            })
    }
    
}
*/
