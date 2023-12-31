//
//  DetailSummaryViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/2/1.
//

import RxSwift
import RxCocoa
import LarkContainer
import TodoInterface
import RustPB
import LarkAccountInterface

/// Detail - Summary - ViewModel

final class DetailSummaryViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var baseTextAttrs = [AttrText.Key: Any]()

    let inputController: InputController

    @ScopedInjectedLazy private var completeService: CompleteService?
    private var currentUserId: String { userResolver.userID }

    struct CoreInfo {
        var attrText: AttrText
        var isEditable: Bool
        var hasStrikethrough: Bool
        var checkBoxState: CheckboxState
        var isMilestone: Bool
    }
    var onCoreUpdate: ((CoreInfo) -> Void)?

    struct ExtraInfo {
        enum ChangedReason {
            case activeChatters
            case strikethrough(Bool)
        }
        var changed: ChangedReason
        var transform: (AttrText) -> AttrText
    }
    var onExtraUpdate: ((ExtraInfo) -> Void)?

    private let disposeBag = DisposeBag()
    private var coreDisposable: Disposable?
    private let store: DetailModuleStore

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
        self.inputController = InputController(resolver: resolver, sourceId: store.state.scene.todoId)
        store.rxValue(forKeyPath: \.activeChatters)
            .bind(to: inputController.rxActiveChatters)
            .disposed(by: disposeBag)
    }

    /// 初始化
    func setup(completion: @escaping (AttrText?) -> Void) {
        store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] _ in
                guard let self = self else { return }
                if self.store.state.scene.isForCreating {
                    let attrText = self.inputController.makeAttrText(
                        from: self.store.state.richSummary,
                        with: self.baseTextAttrs
                    )
                    completion(attrText)
                } else {
                    self.coreDisposable = self.observeCoreChanged()
                    completion(nil)
                }
                self.observeExtraChanged()
            })
            .disposed(by: disposeBag)
    }

    /// 是否是执行人
    func isAssignee(_ userId: String) -> Bool {
        return store.state.assignees.contains(where: { $0.identifier == userId })
    }

    /// 模块不可点击的 tip 提醒
    func uneditableTapTip() -> String {
        if case .doc = store.state.todo?.source {
            return I18N.Todo_Task_UnableEditTaskFromDocs
        } else {
            return I18N.Todo_Task_NoEditAccess
        }
    }

    // MARK: View Action

    /// 开始编辑（编辑场景）
    func beginEditing() {
        coreDisposable?.dispose()
        coreDisposable = nil
    }

    /// 编辑中
    func handleEdit(_ attrText: AttrText) {
        guard store.state.scene.isForCreating else { return }
        let richSummary = inputController.makeRichContent(from: attrText)
        store.dispatch(.updateSummary(richSummary))
    }

    /// 结束编辑
    func endEditing(_ attrText: AttrText) {
        let richSummary = inputController.makeRichContent(from: attrText)
        store.dispatch(.updateSummary(richSummary), onState: nil) { [weak self] res in
            if case .failure(let err) = res {
                Detail.logger.error("update summary failed. err: \(err)")
            }
            guard let self = self else { return }
            // 重新建立监听
            self.coreDisposable = self.observeCoreChanged()
        }
    }

    func updateReserveAssignee(_ assignee: Assignee) {
        store.dispatch(.updateReserveAssignee(assignee))
    }

    func removeReserveAssignee(_ assignee: Assignee) {
        store.dispatch(.removeReserveAssignee(assignee))
    }

    func appendAssignee(_ assignee: Assignee) {
        store.dispatch(.appendAssignees([assignee]))
    }

    // MARK: Private

    private func observeExtraChanged() {
        inputController.rxActiveChatters
            .distinctUntilChanged()
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                let extraInfo = ExtraInfo(changed: .activeChatters) { [weak self] attrText in
                    guard let self = self else { return attrText }
                    let mutAttrText = MutAttrText(attributedString: attrText)
                    self.inputController.resetAtInfo(in: mutAttrText)
                    return mutAttrText
                }
                self?.onExtraUpdate?(extraInfo)
            })
            .disposed(by: disposeBag)

        if store.state.scene.isForEditing {
            store.rxValue(forKeyPath: \.completedState)
                .map(\.isCompleted)
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] isCompleted in
                    let extraInfo = ExtraInfo(changed: .strikethrough(isCompleted)) { [weak self] attrText in
                        guard let self = self else { return attrText }
                        let mutAttrText = MutAttrText(attributedString: attrText)
                        self.setStrikethroughHidden(!isCompleted, for: mutAttrText)
                        return mutAttrText
                    }
                    self?.onExtraUpdate?(extraInfo)
                })
                .disposed(by: disposeBag)
        }
    }

    private func observeCoreChanged() -> Disposable? {
        guard store.state.scene.isForEditing else { return nil }

        let rxIsEditable = store.rxValue(forKeyPath: \.permissions)
            .startWith(store.state.permissions)
            .map(\.summary.isEditable)
            .distinctUntilChanged()
        let rxSummary = store.rxValue(forKeyPath: \.richSummary)
            .startWith(store.state.richSummary)
        let rxCompletedState = store.rxValue(forKeyPath: \.completedState)
            .startWith(store.state.completedState)
            .distinctUntilChanged()
        let rxIsMilestone = store.rxValue(forKeyPath: \.isMilestone).distinctUntilChanged()
        let disposable = Observable.combineLatest(rxIsEditable, rxSummary, rxCompletedState, rxIsMilestone)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isEditable, richContent, completedState, isMilestone in
                guard let self = self else { return }

                let mutAttrText = self.inputController.makeAttrText(from: richContent, with: self.baseTextAttrs)
                if self.inputController.needsEndEmptyChar(in: mutAttrText) {
                    self.inputController.appendEndEmptyChar(in: mutAttrText, with: self.baseTextAttrs)
                }
                // 已完成要有横线
                self.setStrikethroughHidden(!completedState.isCompleted, for: mutAttrText)

                var checkState: CheckboxState {
                    if let todo = self.store.state.todo, todo.isCompleteEnabled(with: completedState) {
                        return .enabled(isChecked: completedState.isCompleted)
                    } else {
                        return .disabled(isChecked: completedState.isCompleted, hasAction: false)
                    }
                }

                let coreInfo = CoreInfo(
                    attrText: mutAttrText,
                    isEditable: isEditable,
                    hasStrikethrough: completedState.isCompleted,
                    checkBoxState: checkState,
                    isMilestone: FeatureGating(resolver: self.userResolver).boolValue(for: .gantt) && isMilestone
                )
                self.onCoreUpdate?(coreInfo)
            })
        return disposable
    }

    private func setStrikethroughHidden(_ isHidden: Bool, for mutAttrText: MutAttrText) {
        let fullRange = NSRange(location: 0, length: mutAttrText.length)
        mutAttrText.beginEditing()
        mutAttrText.enumerateAttribute(.strikethroughStyle, in: fullRange, options: []) { (value, range, _) in
            guard let num = value as? NSNumber else { return }
            mutAttrText.removeAttribute(.strikethroughStyle, range: range)
        }
        if !isHidden {
            mutAttrText.addAttribute(.strikethroughStyle, value: NSNumber(value: 1), range: fullRange)
        }
        mutAttrText.endEditing()
    }

}

// MARK: - Complete
extension DetailSummaryViewModel {

    func completeActionSheetData() -> (role: CompleteRole?, [(role: CompleteRole, title: String)]?)? {
        let assignees = store.state.assignees, completeState = store.state.completedState
        // 整个任务仅需我来完成
        let uncompleted = assignees.filter { $0.completedTime == nil }
        let onlyMeNeedsComplete = uncompleted.count == 1 && uncompleted.first?.identifier == currentUserId
        switch completeState {
        case .outsider: return (.todo, nil)
        case .assignee(let isCompleted):
            if let todo = store.state.todo, todo.editable(for: .todoCompletedMilliTime) {
                if todo.isTodoCompleted {
                    // "恢复任务"
                    return (.todo, nil)
                } else {
                    if onlyMeNeedsComplete {
                        return (.`self`, nil)
                    } else {
                        let selfTitle = isCompleted ? I18N.Todo_CollabTask_MeCompleted : I18N.Todo_CollabTask_OnlyMeCompleted
                        return (nil, [
                            // isSelfCompleted ? "我已完成" : "仅我完成"
                            (.`self`, selfTitle),
                            // "完成任务"
                            (.todo, I18N.Todo_Task_CompleteTaskButton)
                        ])
                    }
                }
            }
            return (.`self`, nil)
        case .creator(let isCompleted): return (.todo, nil)
        case .creatorAndAssignee(let isTodoCompleted, let isSelfCompleted):
            if isTodoCompleted {
                // "恢复任务"
                return (.todo, nil)
            } else {
                if onlyMeNeedsComplete {
                    return (.`self`, nil)
                } else {
                    let selfTitle = isSelfCompleted ? I18N.Todo_CollabTask_MeCompleted : I18N.Todo_CollabTask_OnlyMeCompleted
                    return (nil, [
                        // isSelfCompleted ? "我已完成" : "仅我完成"
                        (.`self`, selfTitle),
                        // "完成任务"
                        (.todo, I18N.Todo_Task_CompleteTaskButton)
                    ])
                }
            }
        case .classicMode: return (.todo, nil)
        }
    }

    func checkDependent() -> DetailDependentDialogCustomViewData? {
        // 只有或签任务且未完成到已完成才会有弹窗
        guard store.state.mode == .taskComplete, !store.state.completedState.isCompleted else {
            return nil
        }
        guard let preDeps = store.state.dependents?.filter({ $0.dependentType == .prev }) else {
            return nil
        }
        guard !preDeps.isEmpty else { return nil }
        var viewData = DetailDependentDialogCustomViewData()
        guard let depsMap = store.state.dependentsMap else {
            Detail.logger.error("dependent map is empty")
            viewData.headerText = I18N.Todo_GanttView_CompleteBlockedBy_Desc(preDeps.count)
            return viewData
        }

        let titles: [String] = preDeps
            .filter({ $0.dependentType == .prev })
            .compactMap { ref in
                guard let task = depsMap[ref.dependentTaskGuid],
                      !(task.completedMilliTime > 0) else {
                    return nil
                }
                guard task.selfPermission.isReadable else {
                    return I18N.Todo_Tasks_BlockingTasksNoPermissionView_Text
                }
                var text = task.richSummary.richText.lc.summerize()
                if text.isEmpty {
                    text = I18N.Todo_Task_NoTitlePlaceholder
                }
                return text
            }
        guard !titles.isEmpty else { return nil }
        viewData.headerText = I18N.Todo_GanttView_CompleteBlockedBy_Desc(titles.count)
        viewData.items = titles
        return viewData
    }

    func getCustomComplete() -> CustomComplete? {
        guard let todo = store.state.todo else {
            return nil
        }
        return completeService?.customComplete(from: todo)
    }

    func doubleCheckBeforeToggleCompleteState(role: CompleteRole) -> CompleteDoubleCheckContext? {
        guard let todo = store.state.todo, let completeService = completeService else {
            return nil
        }
        var state = store.state.completedState
        if todo.editable(for: .todoCompletedMilliTime) {
            state = completeService.mergeCompleteState(store.state.completedState, with: todo.isTodoCompleted)
        }

        return completeService.doubleCheckBeforeToggleState(
            state,
            with: role,
            assignees: store.state.assignees
        )
    }

    /// Toggle 完成状态的结果
    typealias ToggleSuccess = (toast: String?, needsExit: Bool)

    /// Toggle 完成
    func toggleComplete(role: CompleteRole, completion: @escaping (UserResponse<ToggleSuccess>) -> Void) {
        guard let todo = store.state.todo, let completeService = completeService else {
            Detail.assertionFailure()
            completion(.success((toast: nil, needsExit: false)))
            return
        }
        var fromState = completeService.state(for: todo)
        if todo.editable(for: .todoCompletedMilliTime) {
            fromState = completeService.mergeCompleteState(fromState, with: todo.isTodoCompleted)
        }
        Detail.logger.info("check box toggleComplete from: \(fromState), role: \(role)")

        store.dispatch(.updateCurrentUserCompleted(fromState: fromState, role: role), onState: nil) { res in
            switch res {
            case .success:
                Detail.logger.info("toggleComplete succeed")
                let toast = fromState.toggleSuccessToast(by: role)
                completion(.success((toast: toast, needsExit: false)))
            case .failure(let err):
                Detail.logger.error("toggleComplete failed. err:\(err)")
                completion(.failure(err))
            }
        }

        Detail.Track.clickCheckBox(with: todo, fromState: fromState, role: .todo)
    }
}
