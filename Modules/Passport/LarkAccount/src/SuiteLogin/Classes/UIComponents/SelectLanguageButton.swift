//
//  SelectLanguageButton.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/12.
//

import Foundation
import LarkUIKit
import RxSwift
import LarkLocalizations

class SelectLanguageButton: SideIconButton {

    let disposeBag = DisposeBag()
    weak var presentVC: UIViewController?
    let didStartSelect: (() -> Void)?

    init(presentVC: UIViewController, didStartSelect: (() -> Void)?) {
        self.presentVC = presentVC
        self.didStartSelect = didStartSelect

        super.init(
            leftIcon: Resource.V3.lan_icon.ud.withTintColor(UIColor.ud.iconN2),
            title: LanguageManager.currentLanguage.displayName,
            rightIcon: Resource.V3.lan_arrow.ud.withTintColor(UIColor.ud.textCaption)
        )

        self.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self](_) in
                self?.switchLocaleButtonTapped()
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func switchLocaleButtonTapped() {
        self.didStartSelect?()
        let vc = LkNavigationController(rootViewController: SelectLanguageController())
        if Display.pad {
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = self
            vc.popoverPresentationController?.sourceRect = self.bounds
        } else {
            vc.modalPresentationStyle = .fullScreen
        }
        presentVC?.present(vc, animated: true, completion: nil)
    }
}
