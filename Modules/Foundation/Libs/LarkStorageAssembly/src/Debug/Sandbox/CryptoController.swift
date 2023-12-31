//
//  CryptoController.swift
//  LarkStorageAssembly
//
//  Created by 7Up on 2023/9/15.
//

#if !LARK_NO_DEBUG
import Foundation
import UIKit
import LarkStorage
import UniverseDesignToast
import LarkContainer
import EENavigator
import SnapKit

/// 本工具提供三个区域，对应三个 Section，每个 section 对应一个文件
/// - section 0:
///
/// - section 1:
/// - section 2:

private final class RowItem {
    var title: String
    var detail: String?
    var action: () -> Void
    init(title: String, detail: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.action = action
    }
}

func showInfo(_ info: String) {
    guard let window = Navigator.shared.mainSceneWindow else { return }
    UDToast.showTips(with: info, on: window)
}

func showError(_ err: Error) {
    guard let window = Navigator.shared.mainSceneWindow else { return }
    UDToast.showFailure(with: err.localizedDescription, on: window)
}

private class CryptoSection0 {
    lazy var basePath: IsoPath = {
        let space: Space = .user(id: Container.shared.getCurrentUserResolver().userID)
        let path = IsoPath.in(space: space, domain: Domain.biz.microApp.child("section0"))
            .build(.cache)
        try? path.removeItem()
        try? path.createDirectoryIfNeeded()
        return path
    }()

    lazy var filePath = basePath + "hello.txt"

    weak var host: UIViewController?
    init(host: UIViewController) {
        self.host = host
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var fileInfo: String {
        var strList = [String]()
        strList.append("--- File Info ---")
        guard filePath.exists else {
            strList.append("Status：missing")
            return strList.joined(separator: "\n")
        }
        strList.append("Path: \(filePath.relativePath(to: AbsPath.home) ?? "")")
        let bytesCount = ByteCountFormatter.string(
            fromByteCount: Int64(filePath.fileSize ?? 0),
            countStyle: .file
        )
        strList.append("Size: \(bytesCount)")
        if let updateAt = filePath.attributes[.modificationDate] as? Date {
            strList.append("UpdatedAt: \(Self.dateFormatter.string(from: updateAt))")
        }
        return strList.joined(separator: "\n")
    }

    lazy var items: [RowItem] = [
        RowItem(title: "确认是否开启加密") {
            let isEnableCrypto = SBCipherManager.shared.cipher(for: .default)?.isEnabled() ?? false
            showInfo("加密情况：\(isEnableCrypto ? "已配置加密" : "未配置加密")")
        },
        RowItem(title: "确定文件是否被加密") {
            guard self.filePath.exists else {
                showInfo("文件不存在")
                return
            }
            guard let cipher = SBCipherManager.shared.cipher(for: .default) else {
                showInfo("缺少 Cipher")
                return
            }
            let result = cipher.checkEncrypted(forPath: self.filePath.absoluteString) ? "已加密" : "未加密"
            showInfo(result)
        },
        RowItem(title: "本地预览") {
            guard self.filePath.exists else {
                showInfo("文件不存在")
                return
            }
            let vc = ContainerPreviewController(path: self.filePath.absoluteString)
            self.host?.navigationController?.pushViewController(vc, animated: true)
        },
        RowItem(title: "明文覆盖写", detail: "写 1024 次 'hello'") {
            let str = (0..<1024).map { _ in "hello" }.joined()
            do {
                try str.write(to: self.filePath)
            } catch {
                SBUtils.log.error("[normal_write_failed]: \(error)")
                showError(error)
            }
        },
        RowItem(title: "加密覆盖写", detail: "写 1024 次 'hello'") {
            let str = (0..<1024).map { _ in "hello" }.joined()
            do {
                try str.write(to: self.filePath.usingCipher())
            } catch {
                SBUtils.log.error("[crypto_write_failed]: \(error)")
                showError(error)
            }
        },
        RowItem(title: "明文追加写（v1）", detail: "FileHandle 追加 1024 次 'world'") {
            do {
                let fileHandle = try self.filePath.fileWritingHandle()
                _ = try fileHandle.sb.seekToEnd()
                for i in 0..<1024 {
                    try fileHandle.sb.write(contentsOf: "world".data(using: .utf8) ?? { fatalError() }())
                }
                try fileHandle.sb.close()
            } catch {
                SBUtils.log.error("[normal_append_write_failed]: \(error)")
                showError(error)
            }
        },
        RowItem(title: "明文追加写（v2）", detail: "FileHandle 追加 1024 次 'world'") {
            do {
                let fileHandle = try self.filePath.fileHandleForWriting(append: true)
                _ = try fileHandle.seekToEnd()
                for i in 0..<1024 {
                    try fileHandle.write(contentsOf: "world".data(using: .utf8) ?? { fatalError() }())
                }
                try fileHandle.close()
            } catch {
                SBUtils.log.error("[normal_append_write_failed]: \(error)")
                showError(error)
            }
        },
        RowItem(title: "密文追加写（v2）", detail: "FileHandle 追加 1024 次 'world'") {
            do {
                let fileHandle = try self.filePath.usingCipher().fileHandleForWriting(append: true)
                _ = try fileHandle.seekToEnd()
                for i in 0..<1024 {
                    try fileHandle.write(contentsOf: "world".data(using: .utf8) ?? { fatalError() }())
                }
                try fileHandle.close()
            } catch {
                SBUtils.log.error("[crypto_append_write_failed]: \(error)")
                showError(error)
            }
        },
    ]
}

class CryptoController: UITableViewController {
    private lazy var section0 = CryptoSection0(host: self)

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section0.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let item = section0.items[indexPath.row]
        cell.textLabel?.text = item.title
        if let detail = item.detail {
            cell.detailTextLabel?.text = detail
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        view.addSubview(label)
        label.text = section0.fileInfo
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 20, vertical: 0))
        }
        label.numberOfLines = 0
        view.backgroundColor = .systemPink.withAlphaComponent(0.5)

        return view
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        section0.items[indexPath.row].action()
        tableView.reloadData()
    }
}

#endif
