//
//  AgreementLabel.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/12.
//

import UIKit
import RxSwift

class AgreementView: UIView {

    typealias ClickAction = (_ link: URL, _ checked: Bool, LinkClickableLabel) -> Void
    typealias AgreementLinks = [(name: String, url: URL)]

    var checked: Bool {
        get { checkBox.isSelected }
        set { checkBox.isSelected = newValue }
    }

    private let disposeBag = DisposeBag()
    private lazy var checkBox: V3Checkbox = {
        let cb = V3Checkbox(iconSize: Layout.checkBoxSize)
        cb.hitTestEdgeInsets = Layout.checkBoxInsets
        cb.rx.controlEvent(UIControl.Event.valueChanged).subscribe { [weak self] _ in
            self?.checkAction(cb.isSelected)
        }.disposed(by: disposeBag)
        return cb
    }()

    private let clickAction: ClickAction
    private let checkAction: (Bool) -> Void
    private lazy var linkLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        lbl.textContainerInset = .zero
        lbl.textContainer.lineFragmentPadding = 0
        return lbl
    }()

    init(needCheckBox: Bool,
         plainString: String,
         links: AgreementLinks,
         checkAction: @escaping (Bool) -> Void = { _ in },
         clickAction: @escaping ClickAction) {
        self.checkAction = checkAction
        self.clickAction = clickAction
        super.init(frame: .zero)
        addSubview(linkLabel)

        if needCheckBox {
            addSubview(checkBox)
            checkBox.snp.makeConstraints { (make) in
                make.top.greaterThanOrEqualToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalTo(linkLabel.snp.firstBaseline).offset(Layout.checkBoxYOffset)
            }

            linkLabel.snp.makeConstraints { (make) in
                make.top.greaterThanOrEqualToSuperview()
                make.left.equalTo(checkBox.snp.right).offset(6)
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        } else {
            linkLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }

        updateContent(plainString: plainString, links: links)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(plainString: String, links: AgreementLinks, color: UIColor = UIColor.ud.textTitle) {
        linkLabel.attributedText = .makeLinkString(plainString: plainString, links: links, color: color)
    }
}

extension AgreementView: LinkClickableLabelDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let linkLabel = textView as? LinkClickableLabel {
            if linkLabel.tapPosition < characterRange.lowerBound ||
                linkLabel.tapPosition >= characterRange.upperBound {
                return false
            }
        }
        if interaction == .invokeDefaultAction {
            clickAction(URL, checkBox.isSelected, linkLabel)
        }
        return false
    }
}

extension AgreementView {
    enum Layout {
        static let checkBoxSize: CGSize = CGSize(width: 14.0, height: 14.0)
        static let checkBoxYOffset: CGFloat = 2
        static let checkBoxInsets: UIEdgeInsets = UIEdgeInsets(top: -30, left: -50, bottom: -30, right: -30)
    }
}
