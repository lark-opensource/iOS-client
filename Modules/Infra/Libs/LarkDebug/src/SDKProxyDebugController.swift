//
//  SDKProxyDebugController.swift
//  LarkDebug
//
//  Created by liuwanlin on 2020/3/19.
//
import UIKit
#if !LARK_NO_DEBUG
import Foundation
import LarkRustClient

final class SDKProxyDebugController: UIViewController {
    private var hostField: UITextField!
    private var channelField: UITextField!
    private var proxyField: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存",
            style: .plain,
            target: self,
            action: #selector(save)
        )

        let hostLabel = UILabel()
        hostLabel.text = "Socket地址"
        self.view.addSubview(hostLabel)
        hostLabel.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(10)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }

        hostField = UITextField()
        hostField.borderStyle = .line
        self.view.addSubview(hostField)
        hostField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.left.equalTo(hostLabel.snp.right).offset(10)
            make.height.equalTo(30)
        }

        let channelLabel = UILabel()
        channelLabel.text = "Channel"
        self.view.addSubview(channelLabel)
        channelLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(hostLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }

        channelField = UITextField()
        channelField.borderStyle = .line
        self.view.addSubview(channelField)
        channelField.snp.makeConstraints { (make) in
            make.top.equalTo(hostField.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.left.equalTo(channelLabel.snp.right).offset(10)
            make.height.equalTo(30)
        }

        let proxyLabel = UILabel()
        proxyLabel.text = "代理Command id（每行一个）"
        self.view.addSubview(proxyLabel)
        proxyLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.top.equalTo(channelLabel.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(30)
        }

        proxyField = UITextView()
        proxyField.font = UIFont.systemFont(ofSize: 14)
        proxyField.layer.borderWidth = 1
        proxyField.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(proxyField)
        proxyField.snp.makeConstraints { (make) in
            make.top.equalTo(proxyLabel.snp.bottom).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.left.equalTo(channelField)
            make.height.equalTo(200)
        }

        load()
    }

    func load() {
        #if canImport(SocketIO)
        if let config = MockClientConfig.load() {
            self.hostField.text = config.socketURL
            self.channelField.text = config.channel
            self.proxyField.text = config.proxyRequests.map { "\($0)" }.joined(separator: "\n")
        }
        #endif
    }

    @objc
    func save() {
        #if canImport(SocketIO)
        let socketURL = (self.hostField.text ?? "").trimmingCharacters(in: .whitespaces)
        let channel = (self.channelField.text ?? "").trimmingCharacters(in: .whitespaces)
        let proxyRequests = (self.proxyField.text ?? "")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .compactMap { Int($0) }

        let config = MockClientConfig(socketURL: socketURL, channel: channel, proxyRequests: proxyRequests)
        MockClientConfig.save(config: config)
        #endif
        self.navigationController?.popViewController(animated: true)
    }
}
#endif
