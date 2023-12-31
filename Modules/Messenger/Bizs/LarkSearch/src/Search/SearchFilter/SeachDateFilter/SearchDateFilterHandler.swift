//
//  SearchDateFilterHandler.swift
//  LarkSearch
//
//  Created by zc09v on 2019/9/3.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import LarkNavigator

final class SearchDateFilterHandler: UserTypedRouterHandler {
    func handle(_ body: SearchDateFilterBody, req: Request, res: Response) throws {
        let vc = SearchDateFilterViewController(startDate: body.startDate,
                                                endDate: body.endDate,
                                                fromView: body.fromView,
                                                enableSelectFuture: body.enableSelectFuture)
        vc.finishChooseBlock = { (vc, startDate, endDate) in
            body.confirm?(vc, startDate, endDate)
        }
        res.end(resource: vc)
    }
}
