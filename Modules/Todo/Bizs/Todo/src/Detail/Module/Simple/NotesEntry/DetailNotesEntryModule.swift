//
//  DetailNotesEntryModule.swift
//  Todo
//
//  Created by 张威 on 2021/10/18.
//

import RxSwift
import RxCocoa
import LarkUIKit
import EditTextView
import EENavigator
import LarkContainer
import TodoInterface

/// Detail - NotesEntry - Module
/// 详情页编辑场景的 notes 模块

// nolint: magic number
final class DetailNotesEntryModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailNotesEntryViewModel

    private lazy var notesView = DetailNotesEntryView()
    private let disposeBag = DisposeBag()
    private var inputController: InputController { viewModel.inputController }

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        guard context.scene.isForEditing else {
            assertionFailure("just for editing")
            return
        }
        setupView()
        setupViewModel()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(notesView)
        notesView.snp.makeConstraints { $0.edges.equalToSuperview() }

        notesView.textView.delegate = self
        notesView.textView.textDelegate = self

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleViewTap))
        tap.delegate = self
        notesView.textView.addGestureRecognizer(tap)

        notesView.onTap = { [weak self] in self?.handleViewTap() }
    }

    private func setupViewModel() {
        viewModel.baseTextAttrs = notesView.textView.defaultTypingAttributes
        viewModel.rxViewData
            .subscribe(onNext: { [weak self] in
                self?.notesView.updateAttrText($0)
            })
            .disposed(by: disposeBag)
        viewModel.setup()
    }

    @objc
    private func handleViewTap() {
        guard let viewController = context.viewController else { return }

        switch viewModel.tapViewMessage() {
        case .disableTip:
            if let window = viewController.view.window {
                Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
            }
        case let .detail(isEditable, richContent):
            let vc = DetailNotesViewController(
                resolver: userResolver,
                richContent: richContent,
                isEditable: isEditable,
                inputController: inputController
            )
            vc.onSave = { [weak self] richContent in
                self?.viewModel.updateNotes(richContent)
            }
            userResolver.navigator.present(
                vc,
                wrap: LkNavigationController.self,
                from: viewController,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        }
    }

}

// MARK: - Input Delegate

extension DetailNotesEntryModule: UITextViewDelegate, EditTextViewTextDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        return false
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

}

// MARK: - Gesture Delegate

extension DetailNotesEntryModule: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
        guard
            let containerVC = context.viewController,
            let tapItem = inputController.captureTapItem(with: gesture, in: notesView.textView)
        else {
            return true
        }
        inputController.handleTapAction(tapItem, from: containerVC)
        return false
    }

}
