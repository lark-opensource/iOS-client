//
//  MeetingRoomFormBottomView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/3/28.
//

import UIKit
import RxCocoa
import RichLabel
import EENavigator
import LarkUIKit
import RxSwift

final class MeetingRoomFormBottomView: UIView {

    private(set) lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.Calendar.Calendar_Common_Cancel, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.cornerRadius = 6
        return button
    }()

    private(set) lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitle(BundleI18n.Calendar.Calendar_Common_Done, for: .normal)
        button.layer.cornerRadius = 6
        return button
    }()

    private lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 17
        return stackView
    }()

    private lazy var tipsLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = UIColor.ud.bgBody
        label.numberOfLines = 0
        return label
    }()

    private lazy var seplineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    fileprivate var _chatterTapped = PublishSubject<String>()

    static let enabledBackgoundColor = UIColor.ud.primaryContentDefault
    static let disabledBackgoundColor = UIColor.ud.fillDisabled

    override init(frame: CGRect) {
        super.init(frame: frame)

        preservesSuperviewLayoutMargins = true

        addSubview(bottomStackView)
        bottomStackView.addArrangedSubview(cancelButton)
        bottomStackView.addArrangedSubview(confirmButton)
        addSubview(tipsLabel)
        addSubview(seplineView)

        bottomStackView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leadingMargin)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-5)
            make.height.equalTo(48)
        }

        tipsLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(bottomStackView)
            make.bottom.equalTo(bottomStackView.snp.top).offset(-26)
        }

        seplineView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(tipsLabel)
            make.bottom.equalTo(tipsLabel.snp.top).offset(-18)
            make.height.equalTo(1)
            make.top.equalToSuperview()
        }

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if tipsLabel.preferredMaxLayoutWidth < 0 {
            tipsLabel.preferredMaxLayoutWidth = bounds.width - 2 * 20
            tipsLabel.invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    func update(contact: [(String, String)]) {
        let username = contact.map(\.1).joined(separator: BundleI18n.Calendar.Calendar_Common_Comma)
        let text = BundleI18n.Calendar.Calendar_MeetingRoom_ContactPersonResponsbileForSetUp(username: username)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .justified
        let attributedText = NSMutableAttributedString(string: text,
                                                       attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                                    .font: UIFont.body3])
        var nameRange = (text as NSString).range(of: username)
        attributedText.addAttribute(.foregroundColor, value: UIColor.ud.primaryPri700, range: nameRange)
        nameRange = (text as NSString).range(of: username, options: .backwards)
        attributedText.addAttribute(.foregroundColor, value: UIColor.ud.primaryPri700, range: nameRange)
        tipsLabel.attributedText = attributedText

        contact.forEach { id, name in
            let forwardRange = (text as NSString).range(of: name)
            let backwardRange = (text as NSString).range(of: name, options: .backwards)
            var link = LKTextLink(range: forwardRange, type: .link)
            link.url = URL(string: id)
            link.linkTapBlock = { [weak self] _, link in
                guard let window = self?.window, let id = link.url?.absoluteString else { return }
                CalendarTracer.shared.formJumpToChatter()
                self?._chatterTapped.onNext(id)
//                let body = PersonCardBody(chatterId: id)
//                if Display.pad {
//                    Navigator.shared.present(body: body, from: window)
//                } else {
//                    Navigator.shared.push(body: body, from: window)
//                }
            }
            tipsLabel.addLKTextLink(link: link)
            link = LKTextLink(range: backwardRange, type: .link)
            link.url = URL(string: id)
            link.linkTapBlock = { [weak self] _, link in
                guard let window = self?.window, let id = link.url?.absoluteString else { return }
                CalendarTracer.shared.formJumpToChatter()
                self?._chatterTapped.onNext(id)
            }
            tipsLabel.addLKTextLink(link: link)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Reactive where Base: MeetingRoomFormBottomView {
    var chatterTapped: Driver<String> {
        base._chatterTapped.asDriver(onErrorDriveWith: .empty())
    }
}
