//
//  ChatCalendarBannerModule.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/9.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel

public class ChatCalendarBannerModule: ChatBannerSubModule {
    public override class var name: String { return "ChatCalendarBannerModule" }
    private var calendarCanHandle: Bool = true

    private lazy var custemContentView: UIView = {
        let contentView = UIView()
        let label = UILabel()
        label.text = "ChatCalendarBannerModule"
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        contentView.backgroundColor = .green
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
        print("ChatCalendarBannerModule contentView")
        return self.custemContentView
    }

    public override class func canInitialize(context: ChatBannerContext) -> Bool {
        print("ChatCalendarBannerModule canInitialize")
        return true
    }

    public override func canHandle(model: ChatBannerMetaModel) -> Bool {
        print("ChatCalendarBannerModule canHandle: \(self.calendarCanHandle)")
        return self.calendarCanHandle
    }

    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        print("ChatCalendarBannerModule handler")
        return [self]
    }

    public override func onRefresh() {
        super.onRefresh()
        print("ChatCalendarBannerModule onRefresh")
    }

    public override func beginActivaty() {
        super.beginActivaty()
        print("ChatCalendarBannerModule beginActivaty")
    }

    public override func endActivaty() {
        super.endActivaty()
        print("ChatCalendarBannerModule endActivaty")
    }

    public override func createViews(model: ChatBannerMetaModel) {
        super.createViews(model: model)
        print("ChatCalendarBannerModule createViews")
        self.display = true
    }

    public override func updateViews(model: ChatBannerMetaModel) {
        super.updateViews(model: model)
        print("ChatCalendarBannerModule updateViews")
    }

    public override func willGetContentView() {
        super.willGetContentView()
        print("ChatCalendarBannerModule willGetContentView")
    }

    @objc
    private func buttonAction() {
        self.calendarCanHandle = false
        self.display = false
        self.context.resolver.resolve(ChatOpenService.self)!.reloadBanner()
    }
}
