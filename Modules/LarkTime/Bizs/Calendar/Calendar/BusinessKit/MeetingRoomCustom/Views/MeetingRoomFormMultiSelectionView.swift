//
//  MeetingRoomFormMultiSelectionView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/4/2.
//

import UniverseDesignIcon
import UIKit
import RxSwift
import RxRelay
import Kingfisher
import UniverseDesignInput
import UniverseDesignCheckBox

final class MeetingRoomFormMultiSelectionView: UIView {
    private(set) lazy var questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        return stackView
    }()

    private let question: Rust.CustomizationQuestion

    private let selectedOptionViewsRelay = BehaviorRelay<[MeetingRoomFormMultiSelectionOptionView]>(value: [])
    let selectedOptionRelay = PublishRelay<(String, [String])>()
    let imageSelectedRelay = PublishRelay<(UIImage, String)>()
    let userInputRelay = PublishRelay<String>()
    private let bag = DisposeBag()

    init(question: Rust.CustomizationQuestion, selectedOptionKeys: [String], userInput: String?) {
        self.question = question
        super.init(frame: .zero)

        preservesSuperviewLayoutMargins = true

        addSubview(questionLabel)
        addSubview(optionsStackView)

        questionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(snp.topMargin)
        }

        optionsStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(questionLabel.snp.bottom).offset(14)
            make.bottom.equalTo(snp.bottom)
        }

        let attrString = NSMutableAttributedString(string: question.label,
                                                   attributes: [.font: UIFont.body0,
                                                                .foregroundColor: UIColor.ud.textTitle])
        if question.isRequired {
            attrString.append(NSAttributedString(string: " *", attributes: [.font: UIFont.body0,
                                                                            .foregroundColor: UIColor.ud.functionDangerContentDefault]))
        }
        questionLabel.attributedText = attrString
        for option in question.options {
            let itemView = MeetingRoomFormMultiSelectionOptionView()
            itemView.optionLabel.text = option.optionLabel
            itemView.key = option.optionKey
            itemView.isInput = option.isOthers
            if option.isOthers {
                itemView.optionLabel.text = BundleI18n.Calendar.Calendar_Common_Others
                itemView.placeholder = option.optionLabel
                if selectedOptionKeys.contains(option.optionKey) {
                    itemView.inputTextView.text = userInput
                }
                itemView.inputTextView.input.rx.text.orEmpty
                    .bind(to: userInputRelay)
                    .disposed(by: bag)
            }
            if !option.optionImageURL.isEmpty, let imageURL = URL(string: option.optionImageURL) {
                itemView.imageView.kf.setImage(with: imageURL)
                itemView.imageView.kf.indicatorType = .activity
                itemView.imageView.isHidden = false
                itemView.imageView.isUserInteractionEnabled = true

                let tap = UITapGestureRecognizer()
                itemView.imageView.addGestureRecognizer(tap)
                tap.rx.event
                    .compactMap { ($0.view as? UIImageView)?.image.map { ($0, imageURL.absoluteString) } }
                    .bind(to: imageSelectedRelay)
                    .disposed(by: bag)
            }
            itemView.isSelected = selectedOptionKeys.contains(option.optionKey)
            optionsStackView.addArrangedSubview(itemView)
        }

        let optionViews = optionsStackView.arrangedSubviews.compactMap { $0 as? MeetingRoomFormMultiSelectionOptionView }

        Observable.combineLatest(optionViews.map(\.selectedRelay))
            .map {
                zip($0, optionViews)
                    .filter { $0.0 }
                    .map { $0.1 }
            }
            .bind(to: selectedOptionViewsRelay)
            .disposed(by: bag)

        selectedOptionViewsRelay
            .map { (question.indexKey, $0.map(\.key)) }
            .bind(to: selectedOptionRelay)
            .disposed(by: bag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MeetingRoomFormMultiSelectionOptionView: UIView {

    private static let WordLimit = 200
    private let bag = DisposeBag()
    let selectedRelay = BehaviorRelay<Bool>(value: false)

    var isSelected: Bool {
        get { indicatorView.isSelected }
        set {
            selectedRelay.accept(newValue)
            indicatorView.isSelected = newValue
            if isInput { inputTextView.isHidden = !newValue }
        }
    }
    var key = ""
    // 是否是带textfield，需要用户手动输入的选项
    var isInput = false

    var placeholder: String = "" {
        didSet {
            inputTextView.placeholder = placeholder
        }
    }

    private lazy var indicatorView = UDCheckBox(boxType: .multiple, config: .init(style: .square))

    private(set) lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.body1
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private(set) lazy var inputTextView: UDMultilineTextField = {
        let textView = UDMultilineTextField()
        textView.input.isScrollEnabled = false
        textView.config.maximumTextLength = Self.WordLimit
        textView.config.textMargins = .init(edges: 8)
        textView.config.isShowBorder = true
        textView.config.borderColor = .ud.lineBorderComponent
        textView.config.minHeight = 36
        return textView
    }()

    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKeyNoLimitSize(.googleColorful)
        imageView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        imageView.layer.borderWidth = 1
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        let stackView = UIStackView(arrangedSubviews: [optionLabel, imageView, inputTextView])
        addSubview(stackView)
        addSubview(indicatorView)
        imageView.isHidden = true
        inputTextView.isHidden = true

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading

        indicatorView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.leading.equalToSuperview()
            make.centerY.equalTo(optionLabel.snp.centerY)
        }

        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        inputTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(snp.topMargin)
            make.bottom.equalTo(snp.bottomMargin)
            make.trailing.equalToSuperview()
            make.leading.equalTo(indicatorView.snp.trailing).offset(12)
        }

        let tap = UITapGestureRecognizer()
        addGestureRecognizer(tap)
        let toggleCallBack: ((Any) -> Void) = { [weak self] _ in self?.isSelected.toggle() }
        tap.rx.event
            .bind(onNext: toggleCallBack)
            .disposed(by: bag)
        indicatorView.tapCallBack = toggleCallBack
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
