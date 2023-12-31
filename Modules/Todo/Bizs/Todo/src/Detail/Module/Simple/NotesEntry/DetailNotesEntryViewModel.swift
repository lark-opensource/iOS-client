//
//  DetailNotesEntryViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/10/18.
//

import RxSwift
import RxCocoa
import LarkContainer

/// Detail - NotesEntry - ViewModel

final class DetailNotesEntryViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var baseTextAttrs = [AttrText.Key: Any]()
    let inputController: InputController
    var canEditNotes: Bool { store.state.permissions.notes.isEditable }
    let rxViewData = BehaviorRelay<AttrText?>(value: nil)

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

    func setup() {
        store.rxValue(forKeyPath: \.richNotes)
            .observeOn(MainScheduler.instance)
            .map { [weak self] richContent -> AttrText? in
                guard let self = self else { return nil }
                let mutAttrText = self.inputController.makeAttrText(
                    from: richContent,
                    with: self.baseTextAttrs
                )
                if self.inputController.needsEndEmptyChar(in: mutAttrText) {
                    self.inputController.appendEndEmptyChar(in: mutAttrText, with: self.baseTextAttrs)
                }
                return mutAttrText
            }
            .bind(to: rxViewData)
            .disposed(by: disposeBag)

        inputController.rxActiveChatters
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .map { [weak self] _ -> AttrText? in
                guard let self = self else { return nil }
                var mutAttrText = MutAttrText(attributedString: self.rxViewData.value ?? .init())
                self.inputController.resetAtInfo(in: mutAttrText)
                return mutAttrText
            }
            .bind(to: rxViewData)
            .disposed(by: disposeBag)
    }

    func updateNotes(_ richContent: Rust.RichContent) {
        store.dispatch(.updateNotes(richContent))
    }

    enum TapViewMessage {
        case disableTip(String)
        case detail(isEditable: Bool, richContent: Rust.RichContent)
    }

    /// tap 行为
    func tapViewMessage() -> TapViewMessage {
        let isEditable = store.state.permissions.notes.isEditable
        let attrTextLength = rxViewData.value?.length ?? 0
        if isEditable || attrTextLength > 0 {
            return .detail(isEditable: isEditable, richContent: store.state.richNotes)
        } else {
            return .disableTip(I18N.Todo_Task_NoEditAccess)
        }
    }

}
