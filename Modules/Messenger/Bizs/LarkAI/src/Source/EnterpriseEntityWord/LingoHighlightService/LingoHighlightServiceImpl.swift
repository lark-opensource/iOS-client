//
//  LingoHighlightServiceImpl.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import LKCommonsLogging
import UIKit
import EditTextView
import RxSwift
import LarkContainer
import LarkStorage
import ServerPB
import LarkModel
import LarkSearchCore
import LarkMessengerInterface

public final class LingoHighlightServiceImpl: LingoHighlightService {
    private static let logger = Logger.log(LingoHighlightServiceImpl.self, category: "EnterpriseEntityWord.lingoHighlight")
    private let viewModel: LingoHighlightViewModel

    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.viewModel = LingoHighlightViewModel(resolver: resolver)
    }
    public func setupLingoHighlight(chat: LarkModel.Chat?,
                                    fromController: UIViewController?,
                                    inputTextView: LarkEditTextView?,
                                    getMessageId: (() -> String)? = nil) {
        let eewSetting = KVPublic.Setting.enterpriseEntityMessage.value(forUser: userResolver.userID)
        let eewFG = AIFeatureGating.lingoHighlightOnKeyboard.isUserEnabled(userResolver: userResolver)
        guard eewSetting, eewFG else {
            Self.logger.info("lingo highlight switch state: \(eewSetting) fg \(eewFG)")
            return
        }

        guard (chat?.isCrossTenant) != true, (chat?.isPrivateMode) != true else {
            Self.logger.info("[lingoHighlight] chatModel: \(chat?.isCrossTenant), \(chat?.isPrivateMode) ")
            return
        }
        inputTextView?.delegate = viewModel
        inputTextView?.textDelegate = viewModel
        viewModel.viewController = fromController
        viewModel.inputTextView = inputTextView
        viewModel.chatId = chat?.id ?? ""
        viewModel.getMessageId = getMessageId
        let inputText = inputTextView?.rx.text.orEmpty.asObservable()

        inputText?
            .debounce(.milliseconds(1000),
                      scheduler: MainScheduler.instance)
            .filter { [weak self] in self?.viewModel.validateShouldRequestLingo(validateString: $0) ?? false }
            .flatMapLatest { [weak self] (_) -> Observable<([(NSRange, String)], ServerPB_Enterprise_entitiy_BatchRecallResponse)?> in
                /// flatMapLatest 只会订阅最新的内部序列， 这样发送请求是实时最新的。
                guard let self = self else { return Observable.empty() }
                return self.viewModel.getLingoHighlightSuggestion(chatId: chat?.id,
                                                                  messageId: getMessageId?())
            }
            .compactMap { $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (prefix, response) in
                guard let self = self else { return }
                Self.logger.info("getLingoHighlightSuggestion success!")
                self.viewModel.showLingoHighlight(prefix: prefix, with: response)
            }, onError: {(error) in
                Self.logger.info("getLingoHighlightSuggestion error = \(error)")
            })
            .disposed(by: disposeBag)

    }
}
