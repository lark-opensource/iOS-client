//
//  NavigatorDefinition.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/15.
//

import Foundation
import EENavigator

public struct WarmStartBody: CodablePlainBody {

    public let text: String
    public static var pattern: String = "//demo/suspend/warmstart"

    public init(text: String) {
        self.text = text
    }
}

class WarmStartHandler: TypedRouterHandler<WarmStartBody> {

    override func handle(_ body: WarmStartBody, req: Request, res: Response) {
        let text = body.text
        res.end(resource: WarmStartViewController(text: text))
    }
}

public struct ColdStartBody: CodablePlainBody {

    public let text: String
    public static var pattern: String = "//demo/suspend/coldstart"

    public init(text: String) {
        self.text = text
    }
}

class ColdStartHandler: TypedRouterHandler<ColdStartBody> {

    override func handle(_ body: ColdStartBody, req: Request, res: Response) {
        let text = body.text
        res.end(resource: ColdStartViewController(text: text))
    }
}

public struct DetailVCBody: CodablePlainBody {

    public let tag: String
    public let color: String
    public static var pattern: String = "//demo/suspend/detailvc"

    public init(tag: String, color: String) {
        self.tag = tag
        self.color = color
    }
}

class DetailVCHandler: TypedRouterHandler<DetailVCBody> {

    override func handle(_ body: DetailVCBody, req: Request, res: Response) {
        let tag = body.tag
        let color = ColorHelper.colorWithHexString(hexString: body.color)
        DispatchQueue.main.async {
            if let uuid = req.context["suspendSourceID"] as? String {
                res.end(resource: DetailViewController(tag: Int(tag)!, color: color, uuid: uuid))
            } else {
                res.end(resource: DetailViewController(tag: Int(tag)!, color: color))
            }
        }
        res.wait()
    }
}

public struct UniqueVCBody: CodablePlainBody {

    public static var pattern: String = "//demo/suspend/uniquevc"

    public init() {}
}

class UniqueVCHandler: TypedRouterHandler<UniqueVCBody> {

    override func handle(_ body: UniqueVCBody, req: Request, res: Response) {
        if let uuid = req.context["suspendSourceID"] as? String {
            res.end(resource: UniqueViewController(uuid: uuid))
        } else {
            res.end(resource: UniqueViewController())
        }
    }
}
