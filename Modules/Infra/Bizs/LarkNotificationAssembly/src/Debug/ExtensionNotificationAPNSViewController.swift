//
//  ExtensionNotificationAPNSViewController.swift
//  LarkExtensionAssembly
//
//  Created by yaoqihao on 2022/7/4.
//
// swiftlint:disable all
import UIKit
import Foundation
import EditTextView
import EENotification
import FigmaKit
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignInput
import LarkNotificationServiceExtension

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

//text = "格式说明: https://bytedance.feishu.cn/docx/doxcnxPzQ7nE3ZJZGlOJVju7uYe"

final class ExtensionNotificationAPNSViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {

    private var stencil: [(String, String)] = [
        ("空白模板", """
        {
            "aps": {
                "alert": {
                "title": ""
                "body": ""
            },
            "mutable-content": 1,
            "sound": "default",
            "target-content-id": "default"
            },
            "extra_str": "{\\"Sid\\":\\" \\",\\"Time\\": ,\\"belong_to\\":1,\\"biz\\":\\" \\",\\"direct\\":2,\\"mutable_badge\\":true,\\"mutable_content\\":true
            }\\n"
        }
        """),
        ("普通模板", """
           {
            "aps": {
                "alert": {
                "body": "asdasdassadjhaskjdhaksjdhkjashdkasjdhkajsdhkjasdhkasjdhkasjdhkasjfhkasjfhksfhlkasfhauehgajksdfhjakslfhldasfhaskldjhfakuiewhfiuewqhfiewhfiewuhfliehfihsifhisfhsdf"
                },
                "mutable-content": 1,
                "sound": "default",
                "target-content-id": "default"
            },
            "extra_str": "{\\"Sid\\":\\"7088194223614197764\\",\\"Time\\":1631541295,\\"belong_to\\":1,\\"biz\\":\\"lark\\",\\"channel\\":\\"chat\\",\\"chat_digest_id\\":\\"c16e197e3fb7ef77f4b8666a801ba86e\\",\\"chat_id\\":6606123347466391552,\\"command\\":1205,\\"message_id\\":7098931939603644420,\\"direct\\":2,\\"image_url\\":\\"aHR0cHM6Ly9pbnRlcm5hbC1hcGktbGFyay1maWxlLmZlaXNodS5jbi9zdGF0aWMtcmVzb3VyY2UvYXZhdGFyLzJmYWJhMGUyLTNiMTUtNDNjYy1hOTE3LWZhNDVmZTdlMGU5Z18zMjAuanBlZw==\\",\\"is_recall\\":false,\\"mutable_badge\\":true,\\"mutable_content\\":true,\\"quick_reply_category\\":1,\\"not_comm_notification\\":false,\\"not_incr_badge\\":false,\\"prune_outline\\":true,\\"sender_digest_id\\":\\"cb93a471d4eaf3537789babb0b57baab\\",\\"sender_name\\":\\"姚启灏\\",\\"channel_name\\":\\"issue: [跟进中] iOS推送oncall群群名显示异常2\\",\\"is_reply\\":false}\\n"
          }
          """),
    ]

    private var errorText: String = ""

    private lazy var saveButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: "发送")
        item.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
        return item
    }()

    private lazy var cancelButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: "取消")
        item.setProperty(alignment: .left)
        item.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        item.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        item.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        return item
    }()

    /// 上边的编辑区域
    private lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 1
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        return view
    }()

    private lazy var textView: LarkEditTextView = {
        let textView = LarkEditTextView()
        textView.backgroundColor = UIColor.clear
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.maxHeight = 0
        textView.defaultTypingAttributes = [
            .font: Cons.descriptionFont,
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                return paragraphStyle
            }()
        ]
        /// 调整占位符格式
        textView.placeholderTextView.typingAttributes = [
            .font: Cons.descriptionFont,
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        return textView
    }()

    /// 清空textView按钮
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UDIcon.getIconByKey(.closeOutlined).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)
        button.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        button.tintColor = UIColor.ud.iconN3
        return button
    }()

    /// 内容剩余可输入长度
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    /// 下面的历史记录区域
    private var historyHeader: UILabel = {
        let label = UILabel()
        label.text = "模版"
        label.font = Cons.headerFont
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var histroyTable: InsetTableView = {
        let tableView = InsetTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "推送模拟"
        self.view.backgroundColor = UIColor.ud.bgFloatBase

        self.isNavigationBarHidden = false
        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = cancelButton

        /// 创建topView
        do {
            view.addSubview(topView)
            topView.addSubview(textView)
            topView.addSubview(clearButton)
            topView.addSubview(numberLabel)
            view.addSubview(historyHeader)
            view.addSubview(histroyTable)

            topView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(20)
                make.leading.trailing.equalTo(histroyTable.insetLayoutGuide)
                make.height.equalTo(Cons.textViewHeiht)
            }
            /// 中间的textView
            textView.snp.makeConstraints { (make) in
                make.top.equalTo(10)
                make.bottom.equalTo(-28)
                make.left.equalToSuperview().offset(Cons.hPadding)
                make.right.equalToSuperview().offset(-Cons.hPadding)
            }
            clearButton.snp.makeConstraints { (make) in
                make.bottom.equalTo(-12)
                make.width.height.equalTo(14)
                make.right.equalTo(-12)
            }
            /// 剩余可输入长度
            numberLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(clearButton)
                make.right.equalTo(clearButton.snp.left).offset(-10)
            }
        }

        historyHeader.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(28)
            make.height.equalTo(Cons.headerFont.figmaHeight)
            make.top.equalTo(topView.snp.bottom).offset(16)
        }
        histroyTable.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(historyHeader.snp.bottom).offset(4)
        }
    }

    @objc
    private func dismissSelf() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc
    private func didTapSaveButton() {
        guard let dict = getDict() else {
            errorText = "格式错误"
            return
        }
        errorText = ""

        guard let aps = dict["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let extra = dict["extra_str"] as? String else {
            return
        }

        var request = NotificationRequest(group: aps["thread-id"] as? String ?? "",
                                          identifier: aps["identifier"] as? String ?? "",
                                          version: "",
                                          userInfo: dict,
                                          trigger: nil)

        request.badge = aps["badge"] as? Int
        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""

        request.title = title
        request.body = body

        setUserDefault(title: title, body: body, extra: extra)

        NotificationManager.shared.addOrUpdateNotification(request: request) { [weak self] error in
            if error != nil {
                self?.errorText = "发送失败"
                return
            }

            DispatchQueue.main.async {
                self?.dismissSelf()
            }
        }
    }

    @objc
    private func didTapCancelButton() {
        dismissSelf()
    }

    @objc
    private func didTapClearButton() {
        self.textView.text = ""
    }

    private func setUserDefault(title: String, body: String, extra: String) {
        guard let data = extra.data(using: .utf8) else {
            return
        }

        do {
            var _body = "***"
            if body.count > 4 {
                let lowerBound = body.startIndex
                let upperBound = body.index(body.startIndex, offsetBy: 2)
                _body = body[lowerBound..<upperBound] + body
            }
            var dict: [String: Any] = [:]
            if let _dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                dict = _dict
                dict["apns.title"] = title
                dict["apns.body"] = body
            }

            var dataSource: [[String: Any]] = []
            if let _dataSource = NotificationDebugCache.receivedContents {
                dataSource = _dataSource
            }
            dataSource.append(dict)
            NotificationDebugCache.receivedContents = dataSource
        } catch {
        }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stencil.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.stencil.count else { return UITableViewCell() }
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self)){
            cell.textLabel?.text = stencil[indexPath.row].0
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        self.textView.text = stencil[indexPath.row].1
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        view.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
    }

    func textViewDidChange(_ textView: UITextView) {

    }
    private func getDict() -> [String: Any]? {
        if let text = self.textView.text?
            .trimmingCharacters(in: CharacterSet.whitespaces)
            .trimmingCharacters(in: .newlines),
           !text.isEmpty,
           let data = text.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    errorText = "格式错误"
                    return nil
                }
                return dict
            } catch {
            }
        }
        errorText = "格式错误"
        return nil
    }
}

extension ExtensionNotificationAPNSViewController {

    enum Cons {
        static var descriptionFont: UIFont { .systemFont(ofSize: 16) }
        static var headerFont: UIFont { .systemFont(ofSize: 14) }
        static var textViewHeiht: CGFloat { 180 }
        static var hMargin: CGFloat { 16 }
        static var hPadding: CGFloat { 12 }
    }
}
// swiftlint:enable all
