//
//  FaceToFaceHeadView.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/8.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa

enum FaceToFaceHeadStatus {
    case hideTips // 隐藏文字，只展示数字
    case showError(String) // 展示错误
    case showNumbers([Int]) // 展示数字
}

final class FaceToFaceHeadView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        label.attributedText = NSAttributedString(
            string: BundleI18n.LarkContact.Lark_NearbyGroup_Instruction,
            attributes: [.paragraphStyle: paragraphStyle,
                         .font: UIFont.systemFont(ofSize: 16),
                         .foregroundColor: UIColor.ud.textTitle]
        )
        return label
    }()

    private lazy var faultLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 40
        return stackView
    }()

    private let sepratorLine: UIView = {
        let sepratorLine = UIView()
        sepratorLine.backgroundColor = UIColor.ud.lineDividerDefault
        return sepratorLine
    }()

    private let disposeBag = DisposeBag()
    private let codeNumberLimit: Int

    init(statusDriver: Driver<FaceToFaceHeadStatus>, codeNumberLimit: Int) {
        self.codeNumberLimit = codeNumberLimit
        super.init(frame: .zero)

        setupUI()
        statusDriver
            .drive(onNext: { [weak self] type in
                guard let self = self else { return }

                switch type {
                case .hideTips:
                    UIView.animate(withDuration: 0.5) {
                        self.titleLabel.alpha = 0
                        self.faultLabel.alpha = 0
                    } completion: { _ in
                        UIView.animate(withDuration: 0.5) {
                            self.stackView.spacing = 8
                            self.stackView.snp.remakeConstraints { (make) in
                                make.center.equalToSuperview()
                            }
                            self.layoutIfNeeded()
                        }
                    }
                case .showError(let errorMsg):
                    self.faultLabel.isHidden = false
                    self.faultLabel.text = errorMsg
                    self.stackView.arrangedSubviews.forEach { if let dotView = $0 as? FaceToFaceNumberDotView { dotView.hide() } }
                case .showNumbers(let numbers):
                    self.faultLabel.isHidden = true
                    self.stackView.arrangedSubviews.forEach {
                        guard let dotView = $0 as? FaceToFaceNumberDotView else { return }
                        let index = dotView.tag
                        if index < numbers.count {
                            dotView.show(number: numbers[index])
                        } else {
                            dotView.hide()
                        }
                    }
                }
            }).disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgBase
        self.addSubview(sepratorLine)
        self.addSubview(titleLabel)
        self.addSubview(faultLabel)
        self.addSubview(stackView)

        for index in 0..<self.codeNumberLimit {
            let dotView = FaceToFaceNumberDotView()
            dotView.tag = index
            stackView.addArrangedSubview(dotView)
        }

        sepratorLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(32)
            make.left.right.equalToSuperview().inset(16)
        }
        faultLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        stackView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(88)
        }
    }

}

final class FaceToFaceNumberDotView: UIView {
    private lazy var dotView: UIView = {
        let dotView = UIView()
        dotView.backgroundColor = UIColor.ud.iconN3
        dotView.layer.cornerRadius = 9
        dotView.isHidden = false
        return dotView
    }()

    private lazy var numberLabel: UILabel = {
        let numberLabel = UILabel()
        numberLabel.font = UIFont(name: "DINAlternate-Bold", size: 48)
        numberLabel.textColor = UIColor.ud.colorfulBlue
        numberLabel.isHidden = true
        return numberLabel
    }()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 26, height: 34)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = .clear
        self.addSubview(dotView)
        self.addSubview(numberLabel)
        dotView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }
        numberLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(number: Int) {
        self.numberLabel.text = "\(number)"
        self.dotView.isHidden = true
        self.numberLabel.isHidden = false
    }

    func hide() {
        self.numberLabel.text = ""
        self.dotView.isHidden = false
        self.numberLabel.isHidden = true
    }
}
