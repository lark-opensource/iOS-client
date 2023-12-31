//
//  WADetailDebugController.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/12/4.
//

import Foundation
import UniverseDesignColor
import EENavigator
import LarkRustHTTP


class WADetailDebugController: UIViewController {
    private lazy var dataSource: [(String, [WADebugCellItem])] = {
        return WADetailDebugItemDataProvider().configDataSource()
    }()
    
    private let cellID = NSStringFromClass(UITableViewCell.self)
    
    private lazy var debugTablewView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        return view
    }()
    
    private(set) var rustURLSession: RustHTTPSession
    private let requestQueue = DispatchQueue(label: "WebAppDataSession-\(UUID().uuidString)")
    
    init() {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 10
        operationQueue.underlyingQueue = self.requestQueue
        
        rustURLSession = RustHTTPSession(configuration: RustHTTPSessionConfig.default,
                                         delegate: WADataSessionHandler(),
                                         delegateQueue: operationQueue)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigator()
    }
    
    private func setupUI() {
        self.title = "WA Debug Panel"
        self.view.backgroundColor = UDColor.N00
        view.addSubview(debugTablewView)
        
        debugTablewView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupNavigator() {
        navigationItem.setLeftBarButton({
            return UIBarButtonItem(title: "back", style: .done, target: self, action: #selector(didClickBackHandler))
        }(), animated: false)
    }
    
    @objc
    private func didClickBackHandler() {
        if self === self.navigationController?.viewControllers.first {
            self.dismiss(animated: false, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension WADetailDebugController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < dataSource.count else {
            assertionFailure("please check wa debug items")
            return 1
        }
        return dataSource[section].1.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource[indexPath.section].1[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        cell.textLabel?.textColor = UDColor.N1000
        cell.accessoryView = nil
        cell.selectionStyle = .none
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.detail
        cell.accessibilityIdentifier = item.title
        
        switch item.type {
        case .text:
            break
        case .tap:
            break
        case let .switchButton(isOn, tag):
            cell.accessoryView = {
                let switchButton = UISwitch()
                switchButton.isOn = isOn
                switchButton.tag = tag.rawValue
                switchButton.accessibilityIdentifier = String("switch_\(item.title)")
                switchButton.addTarget(self, action: #selector(didClickSwitchButton(sender:)), for: .valueChanged)
                return switchButton
            }()
            cell.selectionStyle = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].0
    }
}

extension WADetailDebugController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}


extension WADetailDebugController {
    @objc
    private func didClickSwitchButton(sender: UISwitch) {
        switch sender.tag {
        case WADebugCellItem.WADebugSwitchButtonTag.updatePkgVersion.rawValue:
            showCustomWAPkgVersioAlert(sender: sender)
        default:
            return
        }
    }
    
    private func showCustomWAPkgVersioAlert(sender: UISwitch) {
        let isOn = sender.isOn
        guard isOn else {
            //关闭按钮
            //重置包版本为默认版本
            let alert = UIAlertController(title: "Has been changed defult pkg version", message: "Please reopen app", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "confirm", style: .destructive, handler: { _ in
                assertionFailure()
            }))
            Navigator.shared.present(alert, from: self)
            return
        }
        
        let currentVersion = ""
        let alert = UIAlertController(title: "Input WA pkg url", message: "cuurent pkg version: ", preferredStyle: .alert)
        
        alert.addTextField { textFiled in
            textFiled.text = currentVersion
            textFiled.keyboardType = .numbersAndPunctuation
            textFiled.accessibilityIdentifier = "textFiled_pkg_version"
        }
        
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { [weak alert] _ in
            alert?.dismiss(animated: true)
            sender.isOn = false
        }))
        
        alert.addAction(UIAlertAction(title: "confirm", style: .destructive, handler: { [weak alert, weak self] _ in
            guard let self else {
                return
            }
            guard let urlString = alert?.textFields?.first?.text, !urlString.isEmpty else {
                // toast提示不能为空
                return
            }
            
            guard let url = URL(string: urlString) else {
                return
            }
            
            // 下载版本包
            let task = rustURLSession.downloadTask(with: URLRequest(url: url)) { url, response, error in
                //TODO: 处理包资源替换
            }
            
            task.resume()
        }))
        
        Navigator.shared.present(alert, from: self)
    }
}
