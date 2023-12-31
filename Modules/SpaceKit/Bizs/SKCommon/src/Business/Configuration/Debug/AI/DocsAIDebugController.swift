//
//  DocsAIDebugController.swift
//  SKCommon
//
//  Created by ByteDance on 2023/10/8.
//

import Foundation
import SnapKit
import LarkAIInfra
import UniverseDesignToast
import UniverseDesignDialog

#if BETA || ALPHA || DEBUG
/// 浮窗roaster资源调试
class DocsAIDebugController: UIViewController {
    
    enum Items: String, CaseIterable {
        case roadsterReplace = "roadsterReplace"
        case roadsterReset = "roadsterReset"
    }
    
    private var items: [Items] { Items.allCases }
    
    private let util = LarkInlineAIDebugUtility()
    
    private lazy var tableview: UITableView = {
        let tbv = UITableView(frame: .zero)
        tbv.delegate = self
        tbv.dataSource = self
        tbv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tbv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = DebugCellTitle.inlineAIResSetting.rawValue
        
        view.addSubview(tableview)
        tableview.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func pickRoasterZipfile() {
        let picker = _PickerController(completion: { [weak self] url in
            guard let self = self, let url = url else { return }
            do {
                try self.util.replaceWith(roadsterZipURL: url)
                UDToast.showSuccess(with: "roadster替换完成,请重启", on: self.view)
            } catch {
                UDToast.showFailure(with: "roadster替换错误:\(error)", on: self.view)
            }
        })
        self.present(picker, animated: true)
    }
}

extension DocsAIDebugController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        switch items[indexPath.row] {
        case .roadsterReplace:
            pickRoasterZipfile()
        case .roadsterReset:
            do {
                try util.recoverOriginRoadsterRes()
                UDToast.showSuccess(with: "roadster重置完成,请重启", on: view)
            } catch {
                UDToast.showFailure(with: "roadster重置错误:\(error)", on: view)
            }
        }
    }
}

extension DocsAIDebugController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch items[indexPath.row] {
        case .roadsterReplace:
            cell.textLabel?.text = "roadster替换(选取zip)"
        case .roadsterReset:
            cell.textLabel?.text = "roadster重置"
        }
        return cell
    }
}

private class _PickerController: UIDocumentPickerViewController, UIDocumentPickerDelegate {

    private var completion: ((URL?) -> Void)?

    init(completion: ((URL?) -> Void)?) {
        self.completion = completion
        super.init(documentTypes: ["public.item", "public.zip-archive"], in: .import)
        delegate = self
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: Delegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion?(urls.first) // 单选即可
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?(nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        completion?(url)
    }
}
#endif
