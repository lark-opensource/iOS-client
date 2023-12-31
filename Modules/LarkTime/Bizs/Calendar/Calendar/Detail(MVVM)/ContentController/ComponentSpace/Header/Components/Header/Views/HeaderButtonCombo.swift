//
//  HeaderButtonCombo.swift
//  Calendar
//
//  Created by harry zou on 2019/5/24.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import RoundedHUD
import RxSwift
import LarkUIKit
import LarkInteraction

protocol HeaderButtonComboDelegate: AnyObject {
    func chatEntranceTapped(_ gustrue: UITapGestureRecognizer)
    func meetingMinutesTapped()
}

protocol EventHeaderButtonViewDataType {
    var buttonTextColor: UIColor { get }
    var buttonBackgroundColor: UIColor { get }
    var chatBtnDisplayType: Rust.EventButtonDisplayType { get }
    var docsBtnDisplayType: Rust.EventButtonDisplayType { get }
    var isShowVideo: Bool { get }
    var isChatExist: Bool { get }
    var isDocsExist: Bool { get }
}

final class HeaderButtonComboView: UIView {

    var viewData: EventHeaderButtonViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            updateViewContent(with: viewData)
        }
    }

    weak var delegate: HeaderButtonComboDelegate?

    private lazy var stackview: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        return stack
    }()

    private lazy var chatButton = HeaderButton()
    private lazy var docsButton = HeaderButton()

    private let disposeBag = DisposeBag()


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    private func setupViews() {
        self.snp.makeConstraints { make in
            make.height.equalTo(28)
        }

        addSubview(stackview)
        stackview.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        stackview.addArrangedSubview(chatButton)
        stackview.addArrangedSubview(docsButton)

        chatButton.isHidden = true
        docsButton.isHidden = true

        chatButton.addTarget(self, action: #selector(chatButtonPressed(_:)), for: .touchUpInside)

        docsButton.rx.tap
            .debounce(DispatchTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.docsButtonPressed()
            }).disposed(by: disposeBag)
    }

    private func updateViewContent(with viewData: EventHeaderButtonViewDataType) {
        if viewData.chatBtnDisplayType != .hidden {
            chatButton.alpha = 1
            chatButton.isHidden = false
            let titleStr = viewData.isChatExist ? BundleI18n.Calendar.Calendar_Legacy_EnterGroup :
                BundleI18n.Calendar.Calendar_Legacy_CreateGroup
            let icon: UDIconType = viewData.isChatExist ? .chatOutlined : .addChatOutlined
            // 不可编辑
            if viewData.chatBtnDisplayType != .shown && viewData.chatBtnDisplayType != .shownChatOpenEntryAuth {
                chatButton.alpha = 0.4
            }
            chatButton.centerContent()
            chatButton.updateContent(iconKey: icon, title: titleStr, color: viewData.buttonTextColor)
            chatButton.backgroundColor = viewData.buttonBackgroundColor
        } else {
            chatButton.isHidden = true
        }

        if viewData.docsBtnDisplayType != .hidden {
            docsButton.alpha = 1
            docsButton.isHidden = false
            let titleStr = viewData.isDocsExist ? BundleI18n.Calendar.Calendar_Legacy_ViewNotes :
                            BundleI18n.Calendar.Calendar_Legacy_CreateNotes
            let icon: UDIconType = viewData.isDocsExist ? .docOutlined : .addDocOutlined
            // 不可编辑
            if viewData.docsBtnDisplayType != .shown {
                docsButton.alpha = 0.4
            }
            docsButton.centerContent()
            docsButton.updateContent(iconKey: icon, title: titleStr, color: viewData.buttonTextColor)
            docsButton.backgroundColor = viewData.buttonBackgroundColor
        } else {
            docsButton.isHidden = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func chatButtonPressed(_ gustrue: UITapGestureRecognizer) {
        delegate?.chatEntranceTapped(gustrue)
    }

    @objc
    private func docsButtonPressed() {
        delegate?.meetingMinutesTapped()
    }
}
