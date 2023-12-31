//
//  UGDialogTemplate.swift
//  UGDialog
//
//  Created by ByteDance on 2022/8/8.
//

import Foundation
import UniverseDesignDialog
import EENavigator
import RustPB
import LKRichView
import LarkUIKit
import LarkContainer
import LarkDialogManager

public typealias RichText = RustPB.Basic_V1_RichText

enum UGDialogButtontType: Int {
    case applink = 1
    case url = 2
    case exitAPP = 3
}

final class UGDialogButton {
    var buttonType: UGDialogButtontType
    var buttonTitle: String
    var link: String?
    var isMainButton: Bool
    var needManualCustom: Bool
    weak var reachPoint: DialogReachPoint?

    public init(type: UGDialogButtontType, title: String, link: String? = nil, isMainButton: Bool = false, needManualCustom: Bool = false, reachPoint: DialogReachPoint? = nil) {
        self.buttonType = type
        self.buttonTitle = title
        self.link = link
        self.isMainButton = isMainButton
        self.needManualCustom = needManualCustom
        self.reachPoint = reachPoint
    }
}

public final class UGDialogTemplate: DialogReachPointDelegate, UserResolverWrapper {
    
    @ScopedInjectedLazy private var dialogManagerService: DialogManagerService?
    
    var richTextHandler: ((RichText) -> LKRichView)?
    public let userResolver: UserResolver

    public init(userResolver: UserResolver, richTextHandler: ((RichText) -> LKRichView)?) {
        self.userResolver = userResolver
        self.richTextHandler = richTextHandler
    }

    public func onShow(dialogReachPoint: DialogReachPoint) {
        guard let jsonData = dialogReachPoint.dialogData?.data.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
              let window = userResolver.navigator.mainSceneWindow else {
            return
        }
        dialogReachPoint.reportEvent(eventName: .onRemove)
        // 解析标题
        let title = jsonObject["title"] as? String ?? ""
        // 解析按钮
        let buttonObjects = jsonObject["buttons"] as? [AnyObject] ?? []
        var buttonDirection = buttonObjects.count > 2 ? DialogButtonDirection.vertical : DialogButtonDirection.horizontal
        if Display.pad {
            buttonDirection = .horizontal
        }
        let dialog = RichTextDialog(userResolver: userResolver, buttonDirection: buttonDirection)
        dialog.setTitle(title: title)
        // 设置弹窗按钮
        var buttons:[UGDialogButton] = []
        var needManualCustom = false
        for i in 0 ..< buttonObjects.count {
            guard let dict = buttonObjects[i] as? [String: Any] else {
                continue
            }
            let title = dict["text"] as? String ?? ""
            let link = dict["link"] as? String ?? ""
            let type = UGDialogButtontType(rawValue: dict["kind"] as? Int ?? 1) ?? .applink
            let manualCustom = dict["needManualConsume"] as? Bool ?? false
            let button = UGDialogButton(type: type,
                                        title: title,
                                        link: link,
                                        isMainButton: i == 0,
                                        needManualCustom: manualCustom,
                                        reachPoint: dialogReachPoint)
            buttons.append(button)
            if !needManualCustom {
                needManualCustom = manualCustom
            }
        }
        dialog.setButtons(buttons: buttons)
        if !needManualCustom {
            dialogReachPoint.reportClosed()
        }

        // 解析content
        guard let richTextData = jsonObject["content"] as? String,
              let richText = try? RichText(jsonString: richTextData),
              let contentView = richTextHandler?(richText) else {
            return
        }
        let imageUrl = jsonObject["image"] as? String
        dialog.setRichTextContent(topImageUrl: imageUrl, richTextView: contentView)
        dialogManagerService?.addTask(task: DialogTask(onShow: { [weak self] in
            guard let self, let window = self.userResolver.navigator.mainSceneWindow else {
                return
            }
            self.userResolver.navigator.present(dialog, from: window)
        }))
    }
}
