//
//  ViewController.swift
//  LibArchiveExample
//
//  Created by ZhangYuanping on 2021/9/12.
//  


import UIKit
import SnapKit
import LibArchiveKit

class ViewController: UIViewController {

    enum ArchiveMethod: String, CaseIterable {
        case libArchiveSwift
        case libArchiveList
        case libArchiveHasPasscode
        
        var description: String {
            switch self {
            case .libArchiveSwift:
                return "全量解压"
            case .libArchiveList:
                return "按需解压"
            case .libArchiveHasPasscode:
                return "检查密码"
            }
        }
    }
    
    private let archiveQueue = DispatchQueue(label: "LibArchiveKit.ArchiveFile.Queue")
    var currentMethod = ArchiveMethod.libArchiveSwift
    var tableView = UITableView()
    
    var items = [FileItem]()
    var entries = [LibArchiveEntry]()
    var currentURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = UIColor.white
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        var actions = [UIAction]()
        for method in ArchiveMethod.allCases {
            let action = UIAction(title: method.description, image: UIImage(systemName: "folder")) { [weak self] action in
                self?.currentMethod = method
                self?.selectFile()
            }
            actions.append(action)
        }
        
        let menuBarButton = UIBarButtonItem(
            title: "Add",
            image: UIImage(systemName: "plus"),
            primaryAction: nil,
            menu: UIMenu(title: "", children: actions)
        )
        self.navigationItem.rightBarButtonItem = menuBarButton
    }
    
    @objc private func selectFile() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        picker.delegate = self
        navigationController?.present(picker, animated: true, completion: nil)
    }
    
    private func loadURL(_ url: URL) {
        print("----loadURL: \(url.path)")
        currentURL = url
        switch currentMethod {
        case .libArchiveList:
            libArchiveList(url: url)
        case .libArchiveSwift:
            libArchiveSwift(url: url)
        case .libArchiveHasPasscode:
            libArchiveHasPasscode(url: url)
        }
    }

    
    // MARK: - LibArchive
    
    private func libArchiveSwift(url: URL) {
        let unZipPath = NSTemporaryDirectory() + url.lastPathComponent
        let startTime = Date().timeIntervalSince1970
        
        archiveQueue.async {
            // 测试记录 md5 耗时
            let fileMD5 = MD5.calculateMD5(of: url)
            print("--- file md5 \(String(describing: fileMD5))")
            let costTime = (Date().timeIntervalSince1970 - startTime) * 1000
            print("---- costTime md5: \(costTime)")
            
            do {
                let archive = try LibArchiveFile(path: url.path)
                if archive.isEncrypted == true {
                    try archive.extract(toDir: URL(fileURLWithPath: unZipPath), passcode: "123456")
                } else {
                    try archive.extract(toDir: URL(fileURLWithPath: unZipPath))
                }
                let costTime = (Date().timeIntervalSince1970 - startTime) * 1000
                print("---- costTime libArchive: \(costTime)")
                DispatchQueue.main.async {
                    self.loadPath(filePath: unZipPath)
                }
            } catch {
                let error = error as? LibArchiveError
                print("-----error: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    private func libArchiveList(url: URL) {
        archiveQueue.async {
            do {
                let archive = try LibArchiveFile(path: url.path)
                let entries = try archive.parseFileList()
                DispatchQueue.main.async {
                    self.entries = entries
                    self.tableView.reloadData()
                }
            } catch {
                let error = error as? LibArchiveError
                print("-----error: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func libArchiveSingle(url: URL, entryPath: String) {
        let unZipPath = NSTemporaryDirectory() + url.lastPathComponent
        let archive = try? LibArchiveFile(path: url.path)
        try? archive?.extract(entryPath: entryPath, toDir: URL(fileURLWithPath: unZipPath))
        loadPath(filePath: NSTemporaryDirectory())
    }
    
    private func libArchiveHasPasscode(url: URL) {
        let archive = try? LibArchiveFile(path: url.path)
        if archive?.isEncrypted == true {
            print("---- hasPasscode true")
        } else {
            print("---- hasPasscode false")
        }
    }

    func delete(path: String) {
        let fileManager = FileManager()
        try? fileManager.removeItem(atPath: path)
        tableView.reloadData()
    }
}


// MARK: - UIDocumentPickerDelegate
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        loadURL(urls[0])
    }
}


// MARK: - File Browser
extension ViewController {
    private func loadPath(filePath: String) {
        currentMethod = .libArchiveSwift
        var files = [FileItem]()
        let fileManager = FileManager.default
        var targetPath: String = filePath
        if targetPath.isEmpty {
            targetPath = NSHomeDirectory()
        } else {
            let file = FileItem(name: "🔙..", path: filePath, type: .up)
            files.append(file)
        }
        
        var paths = [String]()
        
        do {
            try paths = fileManager.contentsOfDirectory(atPath: targetPath)
        } catch  {
            print("---- fileManager.contentsOfDirectory \(error.localizedDescription)")
        }
        guard paths.count > 0 else { return }
        for itemPath in paths {
            if itemPath.hasPrefix(".") {
                continue
            }
            var isDir: ObjCBool = ObjCBool(false)
            let fullPath = (targetPath as NSString).appendingPathComponent(itemPath)
            fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
            var file: FileItem = FileItem(name: "", path: "", type: .none)
            file.path = fullPath
            if isDir.boolValue {
                file.type = .directory
                file.name = "📂" + itemPath
            } else {
                file.type = .file
                file.name = "📄" + itemPath
            }
            files.append(file)
        }
        items = files
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch currentMethod {
        case .libArchiveList:
            cell.textLabel?.text = entries[indexPath.row].path
        default:
            cell.textLabel?.text = items[indexPath.row].name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentMethod {
        case .libArchiveList:
            return entries.count
        default:
            return items.count
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch currentMethod {
        case .libArchiveList:
            guard let url = currentURL else { return }
            libArchiveSingle(url: url, entryPath: entries[indexPath.row].path)
        case .libArchiveSwift:
            let item = items[indexPath.row]
            switch item.type {
            case .up:
                let strPath = item.path as NSString
                loadPath(filePath: (strPath.deletingLastPathComponent) as String)
            case .file:
                let ql = DriveQLPreviewController(fileURL: URL(fileURLWithPath: item.path))
                navigationController?.pushViewController(ql, animated: true)
            case .directory:
                loadPath(filePath: item.path)
            case .none:
                break
            }
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard currentMethod == .libArchiveSwift else { return nil }
        let deleteAction = UIContextualAction(style: .normal, title: "删除") { [weak self] (action, view, resultClosure) in
            guard let self = self else { return }
            let current = self.items[indexPath.row]
            self.delete(path: current.path)
            self.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        deleteAction.backgroundColor = .red
        let actions = UISwipeActionsConfiguration(actions: [deleteAction])
        return actions
    }
}


