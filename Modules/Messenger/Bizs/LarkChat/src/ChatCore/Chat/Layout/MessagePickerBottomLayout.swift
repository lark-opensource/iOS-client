//
//  MessagePickerBottomLayout.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/13.
//

import Foundation
import SnapKit
import LarkContainer
import RxSwift
import RxCocoa
import LarkMessageBase
import LarkKeyCommandKit

class MessagePickerBottomLayout: BottomLayout, UserResolverWrapper {
    var chatBottomStatus: ChatBottomStatus = .none(display: false)

    var cancel: ChatMessagePickerCancelHandler = nil
    var finish: ChatMessagePickerFinishHandler = nil
    var ignoreDocAuth: Bool = false
    let userResolver: UserResolver

    private lazy var pickerAbility: ChatMessagePickerAbility = {
        return ChatMessagePickerAbility(userResolver: userResolver, finish: finish)
    }()

    private weak var _containerViewController: UIViewController?
    var containerViewController: UIViewController {
        return self._containerViewController ?? UIViewController()
    }

    private let bottomView: BottomConfirmView = {
        let view = BottomConfirmView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private let pickedMessages: BehaviorRelay<[ChatSelectedMessageContext]>

    init(userResolver: UserResolver,
         containerViewController: UIViewController,
         cancel: ChatMessagePickerCancelHandler,
         finish: ChatMessagePickerFinishHandler,
         ignoreDocAuth: Bool,
         pickedMessages: BehaviorRelay<[ChatSelectedMessageContext]>) {
        self._containerViewController = containerViewController
        self.cancel = cancel
        self.finish = finish
        self.ignoreDocAuth = ignoreDocAuth
        self.userResolver = userResolver
        self.pickedMessages = pickedMessages
    }

    func setupBottomView() {
        self.containerViewController.view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
        }

        bottomView.cancelCallBack = { [weak self] _ in
            self?.cancel?(.cancelBtnClick)
        }

        bottomView.finishCallBack = { [weak self] _ in
            self?.finishSelectMessage()
        }
    }

    func getBottomControlTopConstraintInView() -> SnapKit.ConstraintItem? {
        return bottomView.snp.top
    }

    func getBottomHeight() -> CGFloat {
        return self.bottomView.frame.height
    }

    private func finishSelectMessage() {
        self.pickerAbility.finishSelectMessage(selectedMessageContexts: self.pickedMessages.value,
                                               targetVC: self.containerViewController,
                                               ignoreDocAuth: self.ignoreDocAuth)
    }

    func subProviders() -> [LarkKeyCommandKit.KeyCommandProvider] {
        return []
    }

    func hasInputViewInFirstResponder() -> Bool {
        return false
    }

    func keyboardExpending() -> Bool {
        return false
    }

    func keepTableOffset() -> Bool {
        return false
    }

    func showToBottomTipIfNeeded() -> Bool {
        return false
    }

    func canHandleDropInteraction() -> Bool {
        return false
    }

    func handleTextTypeDropItem(text: String) {
    }
}
