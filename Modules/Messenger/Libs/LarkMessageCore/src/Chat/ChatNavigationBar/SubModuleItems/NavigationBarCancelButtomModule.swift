//
//  NavigationBarCancelButtomModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/21.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkOpenChat
import RxSwift

public final class NavigationBarCancelButtomModule: BaseNavigationBarItemSubModule {
    public override class var name: String { return "NavigationBarCancelButtomModule" }
    private var _items: [ChatNavigationExtendItem] = []

    public override var items: [ChatNavigationExtendItem] {
        return _items
    }
    private let disposeBag: DisposeBag = DisposeBag()

    lazy private var cancelNavibarButton: UIButton = {
        let button = UIButton()
        button.addPointerStyle()
        let color = self.context.navigationBarDisplayStyle().elementTintColor()
        button.setTitle(BundleI18n.LarkMessageCore.Lark_Legacy_Cancel, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.rx.tap.asDriver()
            .drive(onNext: { [weak self, weak button] (_) in
                guard let `self` = self, let btn = button else { return }
                guard let chatOpenService = try? self.context.userResolver.resolve(assert: ChatOpenService.self) else { return }
                chatOpenService.endMultiSelect()
            }).disposed(by: disposeBag)
        return button
    }()

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        _items = []
        if self.context.currentSelectMode() == .multiSelecting {
            _items.append(ChatNavigationExtendItem(type: .cancel,
                                                   view: cancelNavibarButton))
        }
    }

    public override func barStyleDidChange() {
        self.cancelNavibarButton.setTitleColor(self.context.navigationBarDisplayStyle().elementTintColor(), for: .normal)
    }
}
