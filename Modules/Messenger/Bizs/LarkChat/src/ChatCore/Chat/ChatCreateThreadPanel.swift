//
//  ChatCreateThreadPanel.swift
//  LarkChat
//
//  Created by ByteDance on 2022/10/9.
//

import UIKit
import Foundation
import UniverseDesignIcon
import LarkCore
import RxSwift

protocol ChatCreateThreadPanelDelegate: AnyObject {
    func createNewThread()
    func showChatMenu()
}

class ChatCreateThreadPanel: UIView {
    weak var delegate: ChatCreateThreadPanelDelegate?
    private let disposeBag: DisposeBag = DisposeBag()
    var hasChatMenuItem: Bool {
        didSet {
            self.layout()
        }
    }
    private let createThreadItem: CreateThreadItem
    private lazy var chatMenuButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.menuHideOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        button.imageView?.contentMode = .center
        button.backgroundColor = UIColor.ud.bgBody
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(clickChatMenuButton), for: .touchUpInside)
        return button
    }()

    init(hasChatMenuItem: Bool, chatWrapper: ChatPushWrapper) {
        let isAllowPost = chatWrapper.chat.value.isAllowPost
        self.createThreadItem = CreateThreadItem(useDisableStyle: !isAllowPost)
        createThreadItem.layer.masksToBounds = true
        createThreadItem.layer.cornerRadius = 6
        self.hasChatMenuItem = hasChatMenuItem
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.addSubview(createThreadItem)
        self.addSubview(chatMenuButton)
        let tap = UITapGestureRecognizer(target: self, action: #selector(createThreadItemClick))
        createThreadItem.addGestureRecognizer(tap)
        self.layout()
        chatWrapper.chat
            .distinctUntilChanged({ chat1, chat2 in
                return chat1.isAllowPost == chat2.isAllowPost
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                self?.createThreadItem.useDisableStyle = !chat.isAllowPost
            }).disposed(by: self.disposeBag)
    }

    func layout() {
        if hasChatMenuItem {
            chatMenuButton.alpha = 1
            chatMenuButton.snp.remakeConstraints { make in
                make.left.top.equalToSuperview().offset(8)
                make.height.width.equalTo(46)
            }
            createThreadItem.snp.remakeConstraints { make in
                make.left.equalTo(chatMenuButton.snp.right).offset(8)
                make.top.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.height.equalTo(46)
                make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-8)
            }
        } else {
            chatMenuButton.alpha = 0
            createThreadItem.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(8)
                make.top.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.height.equalTo(46)
                make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-8)
            }
        }
    }

    @objc
    func clickChatMenuButton() {
        self.delegate?.showChatMenu()
    }

    @objc
    func createThreadItemClick() {
        self.delegate?.createNewThread()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class CreateThreadItem: UIView {
    private let addImageView: UIImageView
    private let title: UILabel
    var useDisableStyle: Bool {
        didSet {
            if useDisableStyle {
                addImageView.image = UDIcon.addMiddleOutlined.ud.withTintColor(UIColor.ud.iconDisabled)
                title.textColor = UIColor.ud.textDisabled
            } else {
                addImageView.image = UDIcon.addMiddleOutlined.ud.withTintColor(UIColor.ud.primaryContentPressed)
                title.textColor = UIColor.ud.textLinkNormal
            }
        }
    }
    init(useDisableStyle: Bool) {
        self.useDisableStyle = useDisableStyle
        self.addImageView = UIImageView(frame: .zero)
        self.title = UILabel(frame: .zero)
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        let centerContainer = UIView(frame: .zero)
        self.addSubview(centerContainer)
        centerContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let addImage: UIImage
        if useDisableStyle {
            addImage = UDIcon.addMiddleOutlined.ud.withTintColor(UIColor.ud.iconDisabled)
            title.textColor = UIColor.ud.textDisabled
        } else {
            addImage = UDIcon.addMiddleOutlined.ud.withTintColor(UIColor.ud.primaryContentPressed)
            title.textColor = UIColor.ud.textLinkNormal
        }
        addImageView.image = addImage
        centerContainer.addSubview(addImageView)
        addImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        title.text = BundleI18n.LarkChat.Lark_IM_SwitchedTopicGroup_NewTopic_Button
        title.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        centerContainer.addSubview(title)
        title.snp.makeConstraints { make in
            make.left.equalTo(addImageView.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
