//
//  DocChangePermissionHandler.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/20.
//

import Foundation
import UIKit
import Homeric
import EENavigator
import LarkModel
import Swinject
import LarkContainer
import RxSwift
import UniverseDesignToast
import LKCommonsTracker
import LarkActionSheet
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignFont
import UniverseDesignActionPanel
import LarkNavigator

public final class DocChangePermissionHandler: UserTypedRouterHandler {
    public func handle(_ body: DocChangePermissionBody, req: EENavigator.Request, res: Response) throws {
        let chat = body.chat
        let docPermission = body.docPermission
        lazy var docAPI: DocAPI? = {
            return try? self.userResolver.resolve(assert: DocAPI.self)
        }()

        guard let sourceView = body.sourceView else { return }

        var maxLengthTip: String = ""
        var tips: [String] = []
        for (offset, permission) in docPermission.optionalPermissions.enumerated() {
            var tip: String
            switch chat.type {
            case .group, .topicGroup:
                tip = String(format: BundleI18n.LarkMessageCore.Lark_Legacy_DocsActionsheetTipGroup, permission.displayNameWithPermissionType(.thirdPersonPlural))
            case .p2P:
                tip = String(format: BundleI18n.LarkMessageCore.Lark_Legacy_DocsActionSheetTip, chat.displayName, permission.displayNameWithPermissionType(.thirdPerson))
            @unknown default:
                assert(false, "new value")
                tip = ""
            }

            tips.append(tip)

            if tip.count > maxLengthTip.count {
                maxLengthTip = tip
            }
        }

        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = maxLengthTip
        textLabel.numberOfLines = 1

        //24为文字两边的边距
        let preferredContentWidth = textLabel.intrinsicContentSize.width + 24
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         preferredContentWidth: preferredContentWidth,
                                         arrowDirection: .up)

        let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))

        for (offset, permission) in docPermission.optionalPermissions.enumerated() {
            let tip = tips[offset]

            if offset == docPermission.selectedPermissionIndex {
                actionsheet.addItem(UDActionSheetItem(title: tip, titleColor: UIColor.ud.colorfulBlue))
            } else {
                actionsheet.addItem(UDActionSheetItem(title: tip) {
                    var disposeBag = DisposeBag()
                    docAPI?
                        .updatePermission([docPermission.key: Int(permission.code)], messageID: docPermission.messageID )
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak req] _ in
                            disposeBag = DisposeBag()
                            guard let window = req?.from.fromViewController?.view.window else { return }
                            UDToast.showSuccess(with: tip, on: window)
                        })
                        .disposed(by: disposeBag)
                    DocChangePermissionHandler.trackDocsChangeShare(Int(permission.code))
                })
            }
        }

        actionsheet.setCancelItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
        res.end(resource: actionsheet)
    }
}

extension DocChangePermissionHandler {
    static func trackDocsChangeShare(_ permissionCode: Int) {
        Tracker.post(TeaEvent(Homeric.DOCS_CHANGE_SHARE, category: "docs", params: [
            "change_to": getDocAuth(permissionCode)
            ])
        )
    }

    private static func getDocAuth(_ permissionCode: Int) -> String {
        var auth: String
        switch permissionCode {
        case 1: auth = "read"
        case 4: auth = "edit"
        case 501: auth = "forbidden"
        default: auth = "unknown"
        }
        return auth
    }
}
