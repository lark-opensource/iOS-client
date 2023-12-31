//
//  FileCryptorLookupHeaderHandler.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/7/5.
//

import LarkContainer
import CryptoSwift
import LarkAccountInterface
import LarkSecurityCompliance
import UniverseDesignToast

class FileCryptorLookupHeaderHandler: FileCryptoDebugHandle {
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    
    @ScopedProvider var cryptoService: FileCryptoService!
    @ScopedProvider var userService: PassportUserService!
    @Provider var passportService: PassportService
    
    
    required init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
    }
    
    func handle() {
        print(">>>>>>", NSTemporaryDirectory())
        guard let viewController, let view = viewController.view.superview else { return }
        let alert = UIAlertController(title: "请输出要读取Header的文件路径", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "文件路径"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak alert] _ in
            guard let path = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            if !FileManager.default.fileExists(atPath: path) {
                UDToast.showFailure(with: "文件不存在，请重新输入", on: view)
            } else {
                //goto new page
                let nc = UINavigationController(rootViewController: CryptorHeaderPage(filePath: path))
                self.navigator.present(nc, from: viewController)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        navigator.present(alert, from: viewController)
    }
}
    

fileprivate struct Display {
    let name: String
    let display: String
    
    init(data: Data, section: AESHeader.Section) {
        self.name = "\(section)"
        if section == .version {
            let value = data.withUnsafeBytes { $0.load(as: UInt8.self) }.littleEndian
            let kind = AESFileKind(rawValue: value) ?? .regular
            self.display = "\(kind)"
        } else if [.uid, .did, .magic1, .magic2, .nonce, .keyHasher].contains(section) {
            let value = data.withUnsafeBytes { $0.load(as: Int64.self) }.littleEndian
            self.display = value.description
        } else {
            self.display = data.bytes.description
        }
    }
}

fileprivate final class CryptorHeaderPage: UITableViewController {
    
    let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    var displays: [Display] = []
    
    func handleHeader(_ header: AESHeader) {
        self.displays = header.values.map {
            Display(data: $0.value, section: $0.key)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(CryptorHeaderPage.done))
        navigationItem.title = "查看Header"
        do {
            let handle = try SCFileHandle(path: filePath, option: .read)
            try handle.seek(toOffset: 0)
            if let headerData = try handle.read(upToCount: Int(AESHeader.size)) {
                let header = try AESHeader(data: headerData)
                handleHeader(header)
            }
            try handle.close()
            
        } catch {
            print("ERROR: ", error)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displays.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let value =  displays[indexPath.row]
        cell?.textLabel?.text = "\(value.name): \(value.display)"
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func done() {
        navigationController?.dismiss(animated: true)
    }
}
