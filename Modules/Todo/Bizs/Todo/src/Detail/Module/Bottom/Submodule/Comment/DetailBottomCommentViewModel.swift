//
//  DetailBottomCommentViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/5/12.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkAccountInterface

/// Detail - Bottom - Comment - ViewModel

final class DetailBottomCommentViewModel: UserResolverWrapper {
    typealias Draft = (scene: CommentInputScene, content: CommentInputContent?)
    var userResolver: LarkContainer.UserResolver
    let rxShowBadge = BehaviorRelay(value: false)
    var isAvaiable: Bool {
        return store.state.scene.isForEditing && store.state.permissions.comment.isReadable
    }

    var todoId: String { store.state.scene.todoId ?? "" }
    var chatId: String? { store.state.scene.chatId }

    @ScopedInjectedLazy private var commentApi: TodoCommentApi?

    private var currentUserId: String { userResolver.userID }

    private let disposeBag = DisposeBag()
    private let store: DetailModuleStore

    // 真·draft. create & reply 场景的 input，会进持久化的 draft
    let rxRealDraft = BehaviorRelay<Draft>(value: (scene: .create, content: nil))
    // 编辑场景的草稿（存于内存，app 生命周期）
    private static var editDraft = [String: CommentInputContent]()

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() -> Driver<Bool> {
        store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .map { [weak self] _ -> Bool in
                guard let state = self?.store.state, let todo = state.todo else { return false }
                return todo.selfPermission.isReadable && !todo.isDeleted && state.scene.isForEditing && state.permissions.comment.isReadable
            }
            .do(onSuccess: { [weak self] isAvailable in
                if isAvailable {
                    self?.setupDraft()
                }
            })
            .asDriver(onErrorJustReturn: false)
    }

    func makeInputController(forScene scene: CommentInputScene) -> InputController {
        let sourceId: String?
        switch scene {
        case .edit(let commentId): sourceId = commentId
        default: sourceId = nil
        }
        let inputController = InputController(resolver: userResolver, sourceId: sourceId)
        store.rxValue(forKeyPath: \.activeChatters).startWith(store.state.activeChatters)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak inputController] set in
                inputController?.rxActiveChatters.accept(set)
            })
            .disposed(by: disposeBag)
        return inputController
    }

    func trackAction(_ action: String) {
        Detail.tracker(
            .todo_comment,
            params: [
                "action": action,
                "source": "task_detail",
                "task_id": todoId
            ]
        )
    }

    // MARK: Draft

    func preferredScene() -> CommentInputScene {
        return rxRealDraft.value.scene
    }

    func draftInputContent(for scene: CommentInputScene) -> CommentInputContent? {
        var content: CommentInputContent?
        switch scene {
        case .edit(let commentId):
            let key = editDraftKey(for: commentId)
            content = Self.editDraft[key]
        default:
            if scene == rxRealDraft.value.scene {
                content = rxRealDraft.value.content
            }
        }
        guard let ret = content, isCommentInputContentVisible(ret) else {
            return nil
        }
        return ret
    }

    func setDraftInputContent(_ content: CommentInputContent, for scene: CommentInputScene) {
        if case .edit(let commentId) = scene {
            let key = editDraftKey(for: commentId)
            Self.editDraft[key] = content
        } else {
            var info = Rust.CreateCommentInfo()
            info.attachments = content.attachments
            info.fileAttachments = content.fileAttachments
            info.content = content.richContent
            info.cid = UUID().uuidString
            info.type = .richText
            if case let .reply(parentId, rootId) = scene {
                info.replyParentID = parentId
                info.replyRootID = rootId
            }
            commentApi?.setCommentDraft(withTodoId: todoId, info: info).subscribe().disposed(by: disposeBag)
            rxRealDraft.accept((scene, content))
        }
    }

    func setDraftInputContentForDeinit(_ content: CommentInputContent, for scene: CommentInputScene) {
        if case .edit(let commentId) = scene {
            let key = editDraftKey(for: commentId)
            Self.editDraft[key] = content
        } else {
            var info = Rust.CreateCommentInfo()
            info.attachments = content.attachments
            info.fileAttachments = content.fileAttachments
            info.content = content.richContent
            info.cid = UUID().uuidString
            info.type = .richText
            if case let .reply(parentId, rootId) = scene {
                info.replyParentID = parentId
                info.replyRootID = rootId
            }
            commentApi?.setCommentDraft(withTodoId: todoId, info: info).subscribe().disposed(by: disposeBag)
        }
    }

    func clearDraftInputContent(for scene: CommentInputScene) {
        if case .edit(let commentId) = scene {
            let key = editDraftKey(for: commentId)
            Self.editDraft.removeValue(forKey: key)
        }
        commentApi?.clearCommentDraft(byTodoId: todoId).subscribe().disposed(by: disposeBag)
        rxRealDraft.accept((.create, nil))
    }

    private func setupDraft() {
        // 根据 realDraft 设置红点（badge）
        rxRealDraft
            .map { [weak self] draft -> Bool in
                guard let self = self, let content = draft.content else { return false }
                return self.isCommentInputContentVisible(content)
            }
            .distinctUntilChanged()
            .bind(to: rxShowBadge)
            .disposed(by: disposeBag)

        // init realDraft
        commentApi?.getCommentDraft(withTodoId: todoId).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] info in
                guard let self = self else { return }
                guard let info = info,
                      self.isCommentInputContentVisible((info.content, info.attachments, info.fileAttachments)) else {
                    self.rxRealDraft.accept((scene: .create, content: nil))
                    return
                }
                let content = (
                    richContent: info.content,
                    attachments: info.attachments,
                    fileAttachments: info.fileAttachments
                )
                let scene: CommentInputScene
                if !info.replyParentID.isEmpty && !info.replyRootID.isEmpty {
                    scene = .reply(parentId: info.replyParentID, rootId: info.replyRootID)
                } else {
                    scene = .create
                }
                self.rxRealDraft.accept((scene: scene, content: content))
            }, onError: { [weak self] _ in
                self?.rxRealDraft.accept((scene: .create, content: nil))
            })
            .disposed(by: disposeBag)
    }

    private func editDraftKey(for commentId: String) -> String {
        return "\(currentUserId)_\(todoId)_\(commentId)"
    }

    private func isCommentInputContentVisible(_ content: CommentInputContent) -> Bool {
        return content.richContent.richText.hasVisibleContent()
                || !content.attachments.isEmpty
                || !content.fileAttachments.isEmpty
    }

}
