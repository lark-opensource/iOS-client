//
//  SmartCorrectService.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/5/25.
//

import Foundation
import UIKit
import EditTextView
import RxSwift
import LarkContainer
import LarkStorage
import LKCommonsLogging
import ServerPB
import LarkSearchCore
import LarkMessengerInterface
import LarkModel

public final class SmartCorrectServiceImpl: SmartCorrectService {
    private static let logger = Logger.log(SmartCorrectServiceImpl.self, category: "SmartCorrect.SmartCorrectService")
    private let viewModel: SmartCorrectViewModel
    private let disposeBag = DisposeBag()
    let userResolver: UserResolver
    public init(resolver: UserResolver) {
        self.userResolver = resolver
        self.viewModel = SmartCorrectViewModel(resolver: resolver)
    }
    public func setupCorrectService(chat: LarkModel.Chat?,
                                    scene: SmartCorrectScene,
                                    fromController: UIViewController?,
                                    inputTextView: LarkEditTextView?) {
        guard KVPublic.Setting.smartCorrect.value(forUser: userResolver.userID),
              AIFeatureGating.smartCorrect.isUserEnabled(userResolver: userResolver),
              #available(iOS 13.0, *) else {
            Self.logger.info("smart correct switch state: \(KVPublic.Setting.smartCorrect.value(forUser: userResolver.userID)), fg \(AIFeatureGating.smartCorrect.isUserEnabled(userResolver: userResolver))")
            return
        }
        guard let chatId = chat?.id,
              (chat?.chatMode) != .threadV2,
              (chat?.isPrivateMode) != true else {
            Self.logger.info("smart correct chat value \(chat?.id), chatModel \(String(describing: chat?.chatMode)),  isPrivateModel \(String(describing: chat?.isPrivateMode))")
            return
        }
        inputTextView?.delegate = viewModel
        inputTextView?.textDelegate = viewModel
        viewModel.viewController = fromController
        viewModel.inputTextView = inputTextView
        let inputText = inputTextView?.rx.text.orEmpty.asObservable()
        // 触发纠错请求
        inputText?
            .debounce(.milliseconds(1000),
                      scheduler: MainScheduler.instance)
            .filter { self.viewModel.validateShouldRequestSmartCorrect(validateString: $0) }
            .flatMapLatest { [weak self] (prefix) -> Observable<(String, ServerPB_Correction_AIGetTextCorrectionResponse)> in
                guard let self = self else { return Observable.just(("", ServerPB_Correction_AIGetTextCorrectionResponse())) }
                return self.viewModel.getSmartCorrectSuggestion(chatId: chatId,
                                                                prefix: prefix,
                                                                scene: scene)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, response) in
                guard let self = self else { return }
                Self.logger.info("getSmartCorrectSuggestion success!")
                self.viewModel.showSmartCorrectHighlight(with: response)
            }, onError: { (error) in
                Self.logger.info("getSmartCorrectSuggstion error = \(error)")
            })
            .disposed(by: disposeBag)
    }
}
