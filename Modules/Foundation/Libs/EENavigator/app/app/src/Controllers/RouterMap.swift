//
//  RouterMap.swift
//  EENavigatorDemo
//
//  Created by liuwanlin on 2018/9/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import EENavigator

struct FeedBody: CodablePlainBody {
    static let pattern = "//feed"

    var count: Int
}

func registerRouter() {
    Navigator.shared.defaultSchemesBlock = { ["nav"] }

    Navigator.shared.registerMiddleware { (_, res) in
        print(res.request.url.absoluteString)
    }

    Navigator.shared.registerMiddleware(postRoute: true) { (_, res) in
        if res.resource == nil {
            res.end(resource: NotFoundViewController())
        }
    }

    Navigator.shared.registerRoute(pattern: "//clendar") { (_, res) in
        let vc = CalendarViewController()
        let nvc = UINavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    Navigator.shared.registerRoute(type: FeedBody.self) { (body, _, res) in
        print("hhhhh", body.count)
        let vc = FeedViewController()
        let nvc = UINavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }
    Navigator.shared.registerRoute(pattern: "//mine") { (_, res) in
        let vc = MineViewController()
        let nvc = UINavigationController(rootViewController: vc)
        res.end(resource: nvc)
    }

    Navigator.shared.registerRoute(pattern: "//chat/:chatId") { (req, res) in
        let vc = ChatViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.chatId = req.parameters["chatId"] as? String ?? ""
        res.end(resource: vc)
    }

    Navigator.shared.registerRoute(pattern: "//async") { (req, res) in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            let vc = ChatViewController()
            vc.hidesBottomBarWhenPushed = true
            vc.chatId = req.parameters["chatId"] as? String ?? ""
            res.end(resource: vc)
        })
        res.wait()
    }

    Navigator.shared.registerRoute(pattern: "//chat/setting/:chatId") { (req, res) in
        let vc = ChatSettingViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.chatId = req.parameters["chatId"] as? String ?? ""
        res.end(resource: vc)
    }

    Navigator.shared.registerRoute(pattern: "//present/:chatId") { (req, res) in
        let vc = PresentViewController()
        vc.chatId = req.parameters["chatId"] as? String ?? ""
        res.end(resource: vc)
    }
}
