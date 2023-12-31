//
//  ChatMeetingBannerModule.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/9.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel

public class ChatMeetingBannerModule: ChatBannerSubModule {
    public override class var name: String { return "ChatMeetingBannerModule" }

    private lazy var custemContentView: UIView = {
        let contentView = UIView()
        let label = UILabel()
        label.text = "ChatMeetingBannerModule"
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        contentView.backgroundColor = .blue
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.edges.equalToSuperview()
        }
        let button = UIButton(type: .custom)
        button.setTitle("X", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.setTitleColor(.red, for: .normal)
        contentView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return contentView
    }()

    public override func contentView() -> UIView? {
        print("ChatMeetingBannerModule contentView")
        return self.custemContentView
    }

    public override class func canInitialize(context: ChatBannerContext) -> Bool {
        print("ChatMeetingBannerModule canInitialize")
        return true
    }

    public override func canHandle(model: ChatBannerMetaModel) -> Bool {
        print("ChatMeetingBannerModule canHandle: \(model.chat.type == .group)")
        return model.chat.type == .group
    }

    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        print("ChatMeetingBannerModule handler")
        return [self]
    }

    public override func onRefresh() {
        super.onRefresh()
        print("ChatMeetingBannerModule onRefresh")
    }

    public override func beginActivaty() {
        super.beginActivaty()
        print("ChatMeetingBannerModule beginActivaty")
    }

    public override func endActivaty() {
        super.endActivaty()
        print("ChatMeetingBannerModule endActivaty")
    }

    public override func createViews(model: ChatBannerMetaModel) {
        super.createViews(model: model)
        print("ChatMeetingBannerModule createViews")
        self.display = true
    }

    public override func updateViews(model: ChatBannerMetaModel) {
        super.updateViews(model: model)
        print("ChatMeetingBannerModule updateViews")
    }

    public override func willGetContentView() {
        super.willGetContentView()
        print("ChatMeetingBannerModule willGetContentView")
    }

    @objc
    private func buttonAction() {
        self.display = false
        self.context.resolver.resolve(ChatOpenService.self)!.refreshBanner()
    }
}
