//
//  DebugTaskViewController.swift
//  LarkCleanAssembly
//
//  Created by 7Up on 2023/7/11.
//

#if !LARK_NO_DEBUG

import Foundation
import UIKit
import EENavigator
import LarkClean
import LarkAlertController
import LarkAccountInterface
import LarkContainer
import SnapKit
import UniverseDesignLoading

class DebugTaskSubscriber: CleanTaskSubscriber {
    let handler: (CleanTaskCompletion) -> Void

    init(handler: @escaping (CleanTaskCompletion) -> Void) {
        self.handler = handler
    }

    func receive(completion: CleanTaskCompletion) {
        handler(completion)
    }
}

final class DebugTaskViewController: UITableViewController {
    lazy var allTaskHandlers: [(name: String, handler: CleanTaskHandler)] = {
        var ret = [(name: String, handler: CleanTaskHandler)]()
        for (name, handler) in LarkClean.allTaskHandlers() {
            ret.append((name, handler))
        }
        return ret
    }()

    private let processingView = UDLoading.presetSpin(loadingText: "正在执行", textDistribution: .vertial)

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTaskHandlers.count
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = allTaskHandlers[indexPath.row].name
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "trash")
            let view = UIImageView(image: image)
            view.tintColor = .systemRed
            cell.accessoryView = view
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        @Provider var passport: PassportService

        let userList = passport.userList.map { user in
            return CleanContext.User(userId: user.userID, tenantId: user.tenant.tenantID)
        }
        showProcessingView()
        let subscriber = DebugTaskSubscriber { [weak self] completion in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.hideProcessingView()
                let alert = LarkAlertController()
                switch completion {
                case .finished:
                    alert.setTitle(text: "成功")
                case .failure(let err):
                    alert.setTitle(text: "失败")
                    alert.setContent(text: "Error: \(err)")
                }
                alert.addPrimaryButton(text: "知道了")
                Navigator.shared.present(alert, from: self)
            }
        }
        allTaskHandlers[indexPath.row].handler(.init(userList: userList), subscriber)
    }

    private func showProcessingView() {
        if processingView.superview == nil {
            tableView.addSubview(processingView)
            processingView.snp.makeConstraints { $0.center.equalToSuperview() }
        }
        processingView.isHidden = false
    }

    private func hideProcessingView() {
        processingView.isHidden = true
        processingView.removeFromSuperview()
    }
}

#endif
