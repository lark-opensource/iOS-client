//
//  DebugViewControllerHandler.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/17/19.
//
#if !LARK_NO_DEBUG
import Foundation
import EENavigator

final class DebugViewControllerHandler: TypedRouterHandler<DebugBody> { //Global
    override func handle(_ body: DebugBody, req: Request, res: Response) {
        res.end(resource: DebugViewController())
    }
}
#endif
