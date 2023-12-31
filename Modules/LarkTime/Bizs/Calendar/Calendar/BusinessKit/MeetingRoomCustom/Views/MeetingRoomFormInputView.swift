//
//  MeetingRoomFormInputView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/4/14.
//

import UIKit
import RxRelay
import RxSwift
import UniverseDesignInput

final class MeetingRoomFormInputView: UIView {

    private static let WordLimit = 200

    private(set) lazy var questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var inputTextView: UDMultilineTextField = {
        let textView = UDMultilineTextField()
        textView.input.isScrollEnabled = false
        textView.config.maximumTextLength = Self.WordLimit
        textView.config.isShowBorder = true
        textView.config.textMargins = .init(edges: 8)
        textView.config.borderColor = .ud.lineBorderComponent
        textView.config.minHeight = 36
        return textView
    }()

    private let question: Rust.CustomizationQuestion
    private let bag = DisposeBag()

    let userInputRelay = PublishRelay<String>()

    init(question: Rust.CustomizationQuestion, userInput: String?) {
        self.question = question
        super.init(frame: .zero)

        let attrString = NSMutableAttributedString(string: question.label,
                                                   attributes: [.font: UIFont.body0,
                                                                .foregroundColor: UIColor.ud.textTitle])
        if question.isRequired {
            attrString.append(NSAttributedString(string: " *", attributes: [.font: UIFont.body0,
                                                                            .foregroundColor: UIColor.ud.functionDangerContentDefault]))
        }
        questionLabel.attributedText = attrString
        inputTextView.text = userInput
        inputTextView.placeholder = question.placeHolder

        addSubview(questionLabel)
        addSubview(inputTextView)

        questionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(snp.topMargin)
        }

        inputTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(questionLabel.snp.bottom).offset(15)
            make.bottom.equalToSuperview().offset(-10)
        }

        inputTextView.input.rx.text.orEmpty
            .bind(to: userInputRelay)
            .disposed(by: bag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
