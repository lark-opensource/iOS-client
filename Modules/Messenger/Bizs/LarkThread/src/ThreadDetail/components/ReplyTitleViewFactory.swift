//
//  ReplyTitleViewFactory.swift
//  LarkThread
//
//  Created by liluobin on 2022/4/12.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer

protocol ThreadDisplayTitleView: UIView {
    func setObserveData(chatObservable: BehaviorRelay<Chat>)
}
final class ReplyTitleViewFactory {
    let userResolver: UserResolver
    enum Style {
        case source
        case normal
    }
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func createTitleViewWith(style: Style, rootMessageFromId: String, chatObservable: BehaviorRelay<Chat>, tap: (() -> Void)?) -> UIView {
        let titleView: ThreadDisplayTitleView
        switch style {
        case .normal:
            let view = ThreadDetailTitleView()
            view.onlyShowTitle(BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_Title)
            titleView = view
        case .source:
            let view = ReplyThreadSourceTitleView(userResolver: userResolver)
            view.rootMessageFromId = rootMessageFromId
            titleView = view
            view.tapSourceBlock = tap
            titleView.setObserveData(chatObservable: chatObservable)
        }
        return titleView
    }
}
