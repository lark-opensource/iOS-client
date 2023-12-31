//
//  CheckboxView.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/17.
//

import Foundation
import SnapKit
import ByteViewCommon
import UniverseDesignColor
import UniverseDesignCheckBox

protocol CheckboxViewListener: AnyObject {
    func didChangeCheckbox(isChecked: Bool)
}

final class CheckboxView: UIView {

    var isChecked: Bool {
        checkbox.isSelected
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 12.0
        return stackView
    }()

    private lazy var checkbox: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple) { [weak self] _ in
            self?.didTapCheckbox()
        }
        return checkbox
    }()

    private let imageView = UIImageView()
    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 749), for: .horizontal)
        return label
    }()

    private let itemSize: CGSize

    init(content: String,
         isChecked: Bool = false,
         textColor: UIColor = UIColor.ud.N400,
         itemSize: CGSize = .init(width: 24, height: 24)) {
        self.itemSize = itemSize
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 375, height: 88)))
        initialize()
        checkbox.isSelected = isChecked
        label.textColor = textColor
        setContent(content)
    }

    required init?(coder: NSCoder) {
        self.itemSize = .init(width: 24, height: 24)
        super.init(coder: coder)
        initialize()
    }

    private let listeners = Listeners<CheckboxViewListener>()

    func addListener(_ listener: CheckboxViewListener) {
        listeners.addListener(listener)
        fireListener()
    }

    private func fireListener() {
        listeners.forEach {
            $0.didChangeCheckbox(isChecked: isChecked)
        }
    }

    private func initialize() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(checkbox)
        stackView.addArrangedSubview(label)

        checkbox.snp.makeConstraints {
            $0.size.equalTo(itemSize)
        }

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(didTapCheckbox))
        self.addGestureRecognizer(tap)
    }

    func setContent(_ content: String?) {
        let expectText = content ?? label.attributedText?.string ?? ""
        label.attributedText = .init(string: expectText, config: .body)
    }

    @objc func didTapCheckbox() {
        self.checkbox.isSelected = !self.checkbox.isSelected
        fireListener()
    }
}
