//
//  MyAIPadButton.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/12/12.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import FigmaKit

class MyAIPadButton: UIControl {

    lazy var iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UDIcon.getIconByKey(.myaiColorful, size: CGSize(width: 24, height: 24))
        return iv
    }()

    lazy var textLabel: FKGradientLabel = {
        let label = FKGradientLabel(pattern: GradientPattern(direction: .diagonal45, colors: [UIColor(hex: "#4752E6"), UIColor(hex: "#CF5ECF")]))
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.isUserInteractionEnabled = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.addArrangedSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
        stackView.addArrangedSubview(textLabel)
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with viewModel: MyAIViewModel) {
        if viewModel.isShowListening {
            textLabel.text = viewModel.displayName
            textLabel.isHidden = false
        } else {
            textLabel.text = nil
            textLabel.isHidden = true
        }
    }
}
