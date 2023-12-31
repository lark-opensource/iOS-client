//
//  ShareViewController.swift
//  shareExtension
//
//  Created by K3 on 2018/6/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import LarkExtensionCommon
import LarkLocalizations

private let CellReuseIdentifier = "CellReuse"

private let initOnce: Void = {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all
}()

final class ShareViewController: UITableViewController {
    fileprivate var tableHeader: UIView?
    private lazy var items: [ShareTargetItem] = {
        return makeItems()
    }()

    fileprivate var config = ShareExtensionConfig.share
    fileprivate lazy var adapter = {
        return ShareTableHeaderAdapter(viewWidth: view.bounds.width)
    }()

    fileprivate var content: ShareContent?

    fileprivate var viewDidAppearOnce: Bool = false
    fileprivate var opensEml: Bool = false

    override func viewDidLoad() {
        _ = initOnce
        super.viewDidLoad()

        customNavigation()
        customTableView()

        configViewDetail(isHidden: true)

        self.config.cleanShareCache()

        self.extensionContext?.se.preloadShareContent({ self.config.randomFileURL() }, callback: { [weak self] (result) in
                    guard let `self` = self else { return }
                    switch result {
                    case .success(let content):
                        LarkShareExtensionLogger.shared.info("preloadShareContent succeed")
                        DispatchQueue.main.async {
                            self.startCheckLogin(with: content)
                        }
                    case .failure(let type):
                        LarkShareExtensionLogger.shared.error("preloadShareContent failed, type: \(type.localizedDescription)")
                        DispatchQueue.main.async {
                            self.showUnsupportAlert(with: type)
                        }
                    }
                })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewDidAppearOnce = true
        if opensEml {
            sendShareData(with: .eml)
        }
    }

    // 在系统app的extension页面，下滑返回时，不会调用的deinit方法。导致NavigationController、ViewController、View等一系列都不会释放
    // 在MovieView中添加的监听不会remove，导致第二次进入MovieView会继续监听第一次的视频
    // 所以在viewDidDisappear中强制退出，释放view
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.main.async { [weak self] in
            let error = NSError(domain: "Lark.shareExtension.viewDidDisappear", code: NSUserCancelledError, userInfo: nil)
            self?.extensionContext?.cancelRequest(withError: error)
        }
    }
}

private extension ShareViewController {
    func configViewDetail(isHidden: Bool) {
        self.navigationController?.view.isHidden = isHidden
        self.view.isHidden = isHidden
    }

    func startCheckLogin(with content: ShareContent) {
        self.content = content

        if !config.isLarkLogin {
            showLoginAlert()

            return
        }

        // 用户直接打开 eml 文件.
        if config.isLarkMailEnabled,
           let item = content.item as? ShareFileItem,
           // 中文会导致 URL 构建失败, 所以先百分号编码.
           let percentEncodedName = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: percentEncodedName),
           url.pathExtension == "eml" || url.pathExtension == "msg" {
            if viewDidAppearOnce {
                sendShareData(with: .eml)
            } else {
                opensEml = true
            }
            return
        }

        showDetail()
    }

    func customNavigation() {
        let exitItem = UIBarButtonItem(title: BundleI18n.ShareExtension.Lark_Legacy_Cancel, style: .done, target: self, action: #selector(cancelShare))
        navigationItem.leftBarButtonItem = exitItem
        navigationItem.title = BundleI18n.bundleDisplayName
        navigationController?.navigationBar.barStyle = .default
    }

    func customTableView() {
        tableView.register(ShareTargetCell.self, forCellReuseIdentifier: CellReuseIdentifier)
        tableView.separatorStyle = .none
        tableView.bounces = false
        view.backgroundColor = ColorPub.bgBase
    }

    func customTableHeader() {
        guard let content = self.content,
            let header = adapter.header(with: content) as? UIView else {
            return
        }

        let separator = UIView()
        separator.backgroundColor = ColorPub.N300
        header.addSubview(separator)
        separator.frame = CGRect(x: 0, y: header.bounds.size.height - 0.5, width: header.bounds.size.width, height: 0.5)

        tableView.tableHeaderView = header
        tableHeader = header
    }

    func showDetail() {
        configViewDetail(isHidden: false)
        customTableHeader()
    }

    func showLoginAlert() {
        showAlert(BundleI18n.ShareExtension.Lark_Legacy_ShareLoginCheckFailed())
    }

    func showUnsupportAlert(with type: ShareUnsupportErrorType) {
        let message: String
        switch type {
        case .unknown:
            message = BundleI18n.ShareExtension.Lark_Legacy_ShareUnknownError
        case .noData, .loadDataFaild:
            message = BundleI18n.ShareExtension.Lark_Legacy_SharePrepareDataError
        case .unsupportAttachmentCount:
            message = BundleI18n.ShareExtension.Lark_Legacy_ShareNumberOfFilesExceeded
        case .unsupportType:
            message = BundleI18n.ShareExtension.Lark_Legacy_ShareUnsupportTypeError
        case .unsupportTextLength:
            message = BundleI18n.ShareExtension.Lark_Legacy_ShareUnsupportTextlengthError
        case .unsupportFileSize(_, let fileSizeLimit):
            let fileSizeLimitString = fileSizeToString(fileSizeLimit)
            message = BundleI18n.ShareExtension.Lark_File_ToastSingleFileSizeLimit(fileSizeLimitString)
        case .unsupportMixImageAndVideo:
            message = BundleI18n.ShareExtension.Lark_Legacy_CannotPickBothType
        }
        showAlert(message)
    }

    /// 将文件大小转换为字符串
    /// 当文件小于1GB时，以MB为单位表示，否则以GB为单位表示
    private func fileSizeToString(_ fileSize: UInt64) -> String {
        let megaByte: UInt64 = 1024 * 1024
        let gigaByte = 1024 * megaByte
        if fileSize < gigaByte {
            let fileSizeInMB = Double(fileSize) / Double(megaByte)
            return String(format: "%.2fMB", fileSizeInMB)
        } else {
            let fileSizeInGB = Double(fileSize) / Double(gigaByte)
            return String(format: "%.2fGB", fileSizeInGB)
        }
    }

    func showAlert(_ message: String) {
        let controller = UIAlertController(title: BundleI18n.bundleDisplayName, message: message, preferredStyle: .alert)
        controller.addAction(
            UIAlertAction(
                title: BundleI18n.ShareExtension.Lark_Legacy_ShareAlertOK,
                style: .default
            ) { [weak self] _ in
                self?.cancelShare()
            }
        )
        self.present(controller, animated: true, completion: nil)
    }

    @objc
    func cancelShare() {
        let error = NSError(domain: "Lark.shareExtension.UserCancelError", code: NSUserCancelledError, userInfo: nil)
        extensionContext?.cancelRequest(withError: error)
    }

    func shareCompletion() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

extension ShareViewController {
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: ShareTargetCell = tableView.dequeueReusableCell(withIdentifier: CellReuseIdentifier, for: indexPath) as? ShareTargetCell else {
            return UITableViewCell()
        }
        cell.item = item(at: indexPath)
        return cell
    }

    fileprivate func item(at indexPath: IndexPath) -> ShareTargetItem? {
        guard indexPath.row < items.count else {
            return nil
        }
        return items[indexPath.row]
    }
}

extension ShareViewController {
    // swiftlint:disable did_select_row_protection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        (tableView.cellForRow(at: indexPath) as? ShareTargetCell)?.item?.tapHandler?()
    }
    // swiftlint:enable did_select_row_protection

    fileprivate func makeItems() -> [ShareTargetItem] {
        return [
            ShareTargetItem(icon: Resources.send_to_myself, title: BundleI18n.ShareExtension.Lark_Legacy_ShareToSelf, tapHandler: { [weak self] in
                self?.sendToMyself()
            }),
            ShareTargetItem(icon: Resources.send_to_qun, title: BundleI18n.ShareExtension.Lark_Legacy_ShareToChat, tapHandler: { [weak self] in
                self?.sendToFriend()
            })
        ]
    }

    fileprivate func sendToMyself() {
        sendShareData(with: .myself)
    }

    fileprivate func sendToFriend() {
        sendShareData(with: .friend)
    }

    private func sendShareData(with targetType: ShareTagetType) {
        guard let content = self.content else {
            self.showAlert(BundleI18n.ShareExtension.Lark_Legacy_SharePrepareDataError)
            self.shareCompletion()
            return
        }

        content.targetType = targetType
        content.loadItemData()
        ShareExtensionConfig.share.save(content)
        OpenTool.open(url: URL(string: ShareExtensionConfig.share.urlString))
        self.shareCompletion()
    }
}

private struct ShareTargetItem {
    var icon: UIImage
    var title: String
    var tapHandler: (() -> Void)?
}

final class ShareTargetCell: UITableViewCell {
    let titleLabel: UILabel = UILabel()
    let iconView: UIImageView = UIImageView()

    fileprivate let separator = UIView()
    fileprivate var item: ShareTargetItem? {
        didSet {
            titleLabel.text = item?.title
            iconView.image = item?.icon
        }
    }

    override var frame: CGRect {
        didSet {
            titleLabel.frame = CGRect(x: 48, y: 15, width: self.frame.width - 48 - 16, height: self.frame.height - 15 - 14)
            separator.frame = CGRect(x: 48, y: self.frame.height - 0.5, width: self.frame.width - 48, height: 0.5)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(iconView)
        iconView.frame = CGRect(x: 15, y: 16, width: 20, height: 20)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = ColorPub.N900
        addSubview(titleLabel)

        separator.backgroundColor = ColorPub.N300
        addSubview(separator)

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = ColorPub.N300.withAlphaComponent(0.5)

        backgroundColor = ColorPub.bgCell
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum ColorPub {
    static var N50: UIColor {
        return makeDynamicColor(
            light: rgb(0xF5F6F7),
            dark: rgb(0x1F1F1F)
        )
    }

    static var N300: UIColor {
        return makeDynamicColor(
            light: rgb(0xDEE0E3),
            dark: rgb(0x434343)
        )
    }

    static var N900: UIColor {
        return makeDynamicColor(
            light: rgb(0x1F2329),
            dark: rgb(0xF0F0F0)
        )
    }

    static var bgCell: UIColor {
        return makeDynamicColor(
            light: rgb(0xFFFFFF),
            dark: rgb(0x262626)
        )
    }

    static var bgBase: UIColor {
        return makeDynamicColor(
            light: rgb(0xF2F3F5),
            dark: rgb(0x171717)
        )
    }

    static func makeDynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait -> UIColor in
                switch trait.userInterfaceStyle {
                case .dark: return dark
                default:    return light
                }
            }
        } else {
            return light
        }
    }

    static func rgb(_ rgb: UInt32) -> UIColor {
        return color(
            CGFloat((rgb & 0xFF0000) >> 16),
            CGFloat((rgb & 0x00FF00) >> 8),
            CGFloat((rgb & 0x0000FF))
        )
    }

    static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> UIColor {
        // swiftlint:disable all
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
        // swiftlint:enable all
    }
}
