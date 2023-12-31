//
//  DocIconService.swift
//  LarkListItem
//
//  Created by Yuri on 2023/8/10.
//

import Foundation
import RxSwift
#if canImport(LarkDocsIcon)
import LarkDocsIcon
import LarkContainer

class DocIconService {
    var disposeBag = DisposeBag()
    var docsIconManager: DocsIconManager?

    var userId: String?
    func switchService(userId: String?) {
        if self.userId == userId { return }
        self.userId = userId
        do {
            let resolver = try Container.shared.getUserResolver(userID: userId)
            self.docsIconManager = try resolver.resolve(assert: DocsIconManager.self)
        } catch {

        }
    }

    func requestImage(userId: String?, info: ListItemNode.DocIcon, completion: @escaping ((UIImage?) -> Void)) {
        switchService(userId: userId)
        guard let docsIconManager else {
            completion(nil)
            return
        }
        disposeBag = DisposeBag()
        let shape: LarkDocsIcon.IconShpe = {
            switch info.style {
            case .circle: return .CIRCLE
            case .square: return .SQUARE
            case .outline: return .OUTLINE
            default: return .SQUARE
            }
        }()
        docsIconManager.getDocsIconImageAsync(iconInfo: info.iconInfo, url: "", shape: shape)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { image in
                completion(image)
            }, onError: { error in
                ListItemLogger.shared.info(module: ListItemLogger.Module.service, event: "doc icon get icon failed:", parameters: error.localizedDescription)
                completion(nil)
            })
            .disposed(by: disposeBag)
    }
}

#else
class DocIconService {
    var userId: String?
    func switchService(userId: String?) {}

    func requestImage(userId: String?, info: ListItemNode.DocIcon, completion: @escaping ((UIImage?) -> Void)) {
        completion(nil)
    }
}

#endif

