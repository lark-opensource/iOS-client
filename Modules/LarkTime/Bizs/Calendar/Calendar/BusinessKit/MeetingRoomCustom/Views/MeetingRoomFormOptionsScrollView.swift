//
//  MeetingRoomFormOptionsScrollView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/4/12.
//

import UIKit
import RxSwift
import RxRelay
import LarkUIKit

final class MeetingRoomFormOptionsScrollView: UIScrollView {

    typealias QuestionKey = String
    typealias OptionKey = String
    typealias UserInputContent = String

    let selectionRelay = PublishRelay<(QuestionKey, [OptionKey])>()
    let userInputRelay = PublishRelay<(QuestionKey, UserInputContent)>()
    let previewImageRelay = PublishRelay<(UIImage, String)>()

    private let bag = DisposeBag()

    private lazy var baseStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        keyboardDismissMode = .interactive
        showsVerticalScrollIndicator = false

        addSubview(baseStackView)
        baseStackView.snp.makeConstraints { make in
            make.leading.equalTo(frameLayoutGuide.snp.leading)
            make.trailing.equalTo(frameLayoutGuide.snp.trailing)
            make.edges.equalToSuperview()
        }

        if Display.phone {
            Observable
                .merge(NotificationCenter.default.rx.notification(UIResponder.keyboardDidHideNotification),
                       NotificationCenter.default.rx.notification(UIResponder.keyboardDidChangeFrameNotification))
                .subscribeForUI(onNext: { [weak self] notification in
                    guard let self = self else { return }

                    guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

                    let keyboardScreenEndFrame = keyboardValue.cgRectValue
                    let keyboardViewEndFrame = self.convert(keyboardScreenEndFrame, from: self.window)

                    if notification.name == UIResponder.keyboardDidHideNotification {
                        self.contentInset = .zero
                    } else {
                        self.contentInset = UIEdgeInsets(top: 0,
                                                         left: 0,
                                                         bottom: keyboardViewEndFrame.height - self.safeAreaInsets.bottom,
                                                         right: 0)
                    }
                })
                .disposed(by: bag)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(form: Rust.CustomizationForm, currentSelections: Rust.CustomizationFormSelections, currentInputs: Rust.CustomizationFormUserInputs) {
        baseStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        form.compactMap { question -> UIView? in
            switch question.customizationType {
            case .singleSelect:
                let selection = currentSelections[question.indexKey]
                let input = currentInputs[question.indexKey]
                if let selection = selection { assert(selection.selectedOptionKeys.count == 1) }
                let view = MeetingRoomFormSingleSelectionView(question: question,
                                                              selectedOptionKey: selection?.selectedOptionKeys.first,
                                                              userInput: input)
                view.imageSelectedRelay
                    .bind(to: previewImageRelay)
                    .disposed(by: bag)
                view.selectedOptionRelay
                    .bind(to: selectionRelay)
                    .disposed(by: bag)
                view.userInputRelay
                    .map { (question.indexKey, $0 ) }
                    .bind(to: userInputRelay)
                    .disposed(by: bag)
                return view
            case .multipleSelect:
                let view = MeetingRoomFormMultiSelectionView(question: question,
                                                             selectedOptionKeys: currentSelections[question.indexKey]?.selectedOptionKeys ?? [],
                                                             userInput: currentInputs[question.indexKey])
                view.imageSelectedRelay
                    .bind(to: previewImageRelay)
                    .disposed(by: bag)
                view.selectedOptionRelay
                    .bind(to: selectionRelay)
                    .disposed(by: bag)
                view.userInputRelay
                    .map { (question.indexKey, $0 ) }
                    .bind(to: userInputRelay)
                    .disposed(by: bag)
                return view
            case .input:
                let view = MeetingRoomFormInputView(question: question, userInput: currentInputs[question.indexKey])
                view.userInputRelay
                    .map { (question.indexKey, $0 ) }
                    .bind(to: userInputRelay)
                    .disposed(by: bag)
                return view
            @unknown default:
                return nil
            }

        }
        .forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            baseStackView.addArrangedSubview($0)
        }
    }

}
