//
//  SearchPopupHelper.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import SnapKit
import EENavigator
import LarkUIKit

public protocol ISearchPopupView: UIView {
    func show()
    func dismiss(completion: @escaping () -> Void)
}

public protocol ISearchPopupContentView: UIView {

    func updateContainerSize(size: CGSize)

}

final class SearchPopupHelper {

    private var viewContainer: SearchPopupContainer?
    private var vcContainer: SearchPopupViewController?

    func showup(sourceVC: UIViewController, contentView: ISearchPopupContentView) {
        if Display.pad {
            let vc = SearchPopupViewController(contentView: contentView)
            vc.view.backgroundColor = UIColor.clear
            vc.isNavigationBarHidden = true
            self.vcContainer = vc
            Navigator.shared.present(vc,
                                     wrap: LkNavigationController.self,
                                     from: sourceVC,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            let viewContainer = SearchPopupContainer(frame: sourceVC.view.frame, contentView: contentView)
            self.viewContainer = viewContainer
            sourceVC.view.addSubview(viewContainer)
            viewContainer.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            viewContainer.show()
        }

    }

    func dismiss(completion: @escaping () -> Void) {
        if Display.pad {
            self.vcContainer?.dismiss(animated: true) {
                completion()
                self.vcContainer = nil
            }
        } else {
            self.viewContainer?.dismiss(completion: {
                completion()
                self.viewContainer = nil
            })
        }
    }

}
