//
//  SKEntryRouterHandler.swift
//  SpaceKit
//
//  Created by Gill on 2019/12/23.
//

import Foundation
import EENavigator

public final class SKEntryBody: PlainBody {

    public static let fileEntryListKey = "com.bytedance.docs.SKEntryBodyFileEntryListKey"
    public static let fromKey = "com.bytedance.docs.SKEntryBodyFromKey"

    public static let pattern = "//client/doc/entry"

    let file: SpaceEntry
    public init(_ file: SpaceEntry) {
        self.file = file
    }
}

public final class SKEntryRouterHandler: TypedRouterHandler<SKEntryBody> {
    public override init() {
        super.init()
    }
    override public func handle(_ body: SKEntryBody, req: EENavigator.Request, res: Response) {
        let (vc, _) = SKRouter.shared.open(with: body.file, params: req.context)
        guard let browser = vc else {
            res.end(resource: EmptyResource())
            return
        }
        /// https://bytedance.feishu.cn/space/doc/doccnMSr0QNqIaqMiJFklgFjRAh#
        if browser is ContinuePushedVC {
            res.end(resource: EmptyResource())
            return
        }
        res.end(resource: browser)
    }
}
