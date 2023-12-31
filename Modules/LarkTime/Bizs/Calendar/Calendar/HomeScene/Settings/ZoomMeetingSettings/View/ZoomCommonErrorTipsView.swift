//
//  ZoomCommonErrorTipsView.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation

enum ZoomErrorType {
    case single
    case list
}

// 用于错误提示的TipsView ，可支持多条和单条

final class ZoomCommonErrorTipsView: UIView {
    var errorType: ZoomErrorType = .single {
        didSet {
            switch errorType {
            case .single:
                titleLabel.isHidden = false
                errorStackView.isHidden = true
            case .list:
                titleLabel.isHidden = true
                errorStackView.isHidden = false
            }
        }
    }

    private lazy var errorContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.isHidden = true
        return label
    }()

    private lazy var errorStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.isHidden = true
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        layoutSingleError()
    }

    private func layoutSingleError() {
        addSubview(errorContainerView)
        errorContainerView.addSubview(titleLabel)
        errorContainerView.addSubview(errorStackView)

        errorContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(4)
            make.right.equalToSuperview()
        }

        errorStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configSingleError(title: String) {
        titleLabel.text = title
        errorType = .single
    }

    func configErrorsList(titles: [String]) {
        errorStackView.clearSubviews()
        titles.map { errorStr in
            let label = UILabel()
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.ud.functionDangerContentDefault
            label.text = errorStr
            errorStackView.addArrangedSubview(label)
        }
        errorType = .list
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
