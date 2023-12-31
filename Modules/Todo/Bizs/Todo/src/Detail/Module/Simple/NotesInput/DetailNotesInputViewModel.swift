//
//  DetailNotesInputViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/10/18.
//

import RxSwift
import RxCocoa
import LarkContainer

/// Detail - NotesInput - ViewModel

final class DetailNotesInputViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var baseTextAttrs = [AttrText.Key: Any]()
    let inputController: InputController

    private let disposeBag = DisposeBag()
    private let store: DetailModuleStore

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
        self.inputController = InputController(resolver: userResolver, sourceId: store.state.scene.todoId)
        store.rxValue(forKeyPath: \.activeChatters)
            .bind(to: inputController.rxActiveChatters)
            .disposed(by: disposeBag)
    }

    func setup() -> Driver<AttrText> {
        return store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .map { [weak self] _ -> AttrText in
                guard let self = self else {
                    return .init()
                }
                let richContent = self.store.state.richNotes
                return self.inputController.makeAttrText(from: richContent, with: self.baseTextAttrs)
            }
            .asDriver(onErrorJustReturn: .init())
    }

    func notesDidChange(_ attrText: AttrText) {
        let richContent = inputController.makeRichContent(from: attrText)
        store.dispatch(.updateNotes(richContent))
    }

}
