//
//  DocsDebugLogSendVC.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/5/12.
//
#if BETA || ALPHA || DEBUG
import Foundation
import UIKit
import SnapKit
import SSZipArchive
import SKUIKit
import SKFoundation
import UniverseDesignToast
import LarkStorage

public final class DocsDebugLogSendVC: UIViewController {
    private var childrenPath: [SKFilePath] = []
    private var shareVc: UIDocumentInteractionController!
    private var tableView: UITableView?
    private var bottomView: UIView?
    private var loadingView: UIView?
    private var indicatorView: UIActivityIndicatorView?

    private var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    private var isDemoDocsApp: Bool {
        //安全起见，加个版本判断
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return DocsSDK.isInDocsApp && (appVersion == "999.999.999")
    }

    private var notSupportIMShare: Bool {
        //demo || 飞书单品不支持Im分享
        return DocsSDK.isInDocsApp || DocsSDK.isInLarkDocsApp
    }

    deinit {
        shareVc = nil
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        if appVersion.contains("alpha") ||
            appVersion.contains("beta") ||
            isDemoDocsApp {
            setupUI()
            reloadChildPaths()
        } else {
            UDToast.showFailure(with: "版本不支持", on: self.view.window ?? self.view)
        }
    }

    private func setupUI() {
        let tableViewTemp = UITableView()
        view.addSubview(tableViewTemp)
        tableViewTemp.dataSource = self
        tableViewTemp.delegate = self
        self.tableView = tableViewTemp
        let barItem = UIBarButtonItem(title: "选择", style: .plain, target: self, action: #selector(navigationRightItemClick(item:)))
        self.navigationItem.rightBarButtonItem = barItem

        ///底部的view
        let btmView = UIView()
        view.addSubview(btmView)
        self.bottomView = btmView

        let btn1 = UIButton(type: .custom)
        btn1.backgroundColor = .darkGray
        btn1.setTitle("全选", for: .normal)
        btn1.setTitleColor(.white, for: .normal)
        btn1.addTarget(self, action: #selector(selectAllOrDeSelect(btn:)), for: .touchUpInside)
        btmView.addSubview(btn1)
        btn1.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(btmView).multipliedBy(0.5)
        }

        let btn2 = UIButton(type: .custom)
        btn2.backgroundColor = .red
        btn2.setTitle("发送", for: .normal)
        btn2.setTitleColor(.white, for: .normal)
        btn2.addTarget(self, action: #selector(sendLog(btn:)), for: .touchUpInside)
        btmView.addSubview(btn2)
        btn2.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(btmView).multipliedBy(0.5)
        }

        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
        loadingView.isHidden = true
        view.addSubview(loadingView)
        self.loadingView = loadingView

        let indicatorView = UIActivityIndicatorView(style: .white)
        indicatorView.hidesWhenStopped = true
        view.addSubview(indicatorView)
        self.indicatorView = indicatorView

        loadingView.snp.makeConstraints({ (make) in
            make.left.right.top.bottom.equalToSuperview()
        })

        indicatorView.snp.makeConstraints({ (make) in
            make.center.equalTo(loadingView)
            make.width.height.equalTo(30)
        })

        tableView?.snp.makeConstraints({ (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(btmView)
        })

        bottomView?.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalTo(self.view).offset(60)
        }

    }

    private func showLoadingView(show: Bool) {
        self.loadingView?.isHidden = !show
        if show {
            self.indicatorView?.startAnimating()
        } else {
            self.indicatorView?.stopAnimating()
        }
    }

    private func showEditView(show: Bool) {
        bottomView?.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            if show {
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                make.bottom.equalTo(self.view).offset(60)
            }
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc
    private func navigationRightItemClick(item: UIBarButtonItem) {
        if item.title == "选择" {
            if childrenPath.count == 0 {
                return
            }
            item.title = "取消"
            tableView?.setEditing(true, animated: true)
            showEditView(show: true)
        } else {
            item.title = "选择"
            tableView?.setEditing(false, animated: true)
            showEditView(show: false)
        }
    }

    @objc
    private func selectAllOrDeSelect(btn: UIButton) {
        if btn.title(for: .normal) == "全选" {
            for i in 0..<childrenPath.count {
                tableView?.selectRow(at: IndexPath(row: i, section: 0), animated: false, scrollPosition: .none)
            }
            btn.setTitle("全不选", for: .normal)
        } else {
            tableView?.reloadData()
            btn.setTitle("全选", for: .normal)
        }
    }

    @objc
    private func sendLog(btn: UIButton) {
        var pathToSend = [String]()
        let indexsOfSel = tableView?.indexPathsForSelectedRows
        indexsOfSel?.forEach({ (indexPath) in
            let path = childrenPath[indexPath.row]
            pathToSend.append(path.pathString)
        })
        guard pathToSend.count > 0 else {
            return
        }
        let toZipDir = zipDir(createIfNot: false)
        try? toZipDir.removeItem()
        _ = zipDir(createIfNot: true)
        let zipPath = pathToZip()
        self.showLoadingView(show: true)
        DispatchQueue.global().async {
            DocsLogger.info("[SKFilePath] DocsDebugLogSendVC =\(pathToSend), zipPath=\(zipPath.pathString)")
            let suc = SSZipArchive.createZipFile(atPath: zipPath.pathString, withFilesAtPaths: pathToSend)
            DocsLogger.info("[SKFilePath] DocsDebugLogSendVC zip, suc=\(suc)")
            DispatchQueue.main.async {
                self.showLoadingView(show: false)
                if self.notSupportIMShare {
                    self.openFileController(path: zipPath)
                } else {
                    let NSStr = zipPath.pathString as NSString
                    let fileName = NSStr.lastPathComponent
                    NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification),
                                                    object: LarkOpenEvent.sendDebugFile(path: zipPath.pathString,
                                                                                        fileName: fileName, vc: self))
                }
            }
        }
    }

    private func reloadChildPaths() {
        let path = SKFilePath.absPath(AbsPath.document)
                                        .appendingRelativePath("sdk_storage")
                                        .appendingRelativePath("log")
                                        .appendingRelativePath("xlog")
        let subs = (try? path.contentsOfDirectory()) ?? []
        for subPath in subs {
            childrenPath.append(path.appendingRelativePath(subPath))
        }
    }

    private func pathToZip() -> SKFilePath {
        let toZipDir = zipDir(createIfNot: true)
        let zipName = "Lark_\(date2String(Date())).zip"
        let logZipDestPath = toZipDir.appendingRelativePath("\(zipName)")
        return logZipDestPath
    }

    private func zipDir(createIfNot: Bool) -> SKFilePath {
        let path = SKFilePath.globalSandboxWithLibrary
                                        .appendingRelativePath("SKResource")
                                        .appendingRelativePath("logSendZipTemp")
        if createIfNot {
            do {
                try path.createDirectoryIfNeeded()
            } catch {
                DocsLogger.error("[SKFilePath] zipDir create file error", extraInfo: nil, error: error, component: nil)
            }
        }
        return path
    }

    //日期 -> 字符串
    func date2String(_ date: Date, dateFormat: String = "MM-dd_HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        let date = formatter.string(from: date)
        return date
    }

    fileprivate func openFileController(path: SKFilePath) {
        let vc = UIDocumentInteractionController()
        vc.url = URL(fileURLWithPath: path.pathString)
        vc.presentOptionsMenu(from: self.view.bounds, in: self.view, animated: true)
        shareVc = vc
    }
}

extension DocsDebugLogSendVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.isEditing == false else { return }
        let fullPath = childrenPath[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)

        if notSupportIMShare {
            openFileController(path: fullPath)
        } else {
            let NSStr = fullPath.pathString as NSString
            let fileName = NSStr.lastPathComponent
            NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification),
                                            object: LarkOpenEvent.sendDebugFile(path: fullPath.pathString, fileName: fileName, vc: self))
        }
    }

    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: UITableViewCell.EditingStyle.delete.rawValue | UITableViewCell.EditingStyle.insert.rawValue) ?? UITableViewCell.EditingStyle.none
    }
}

extension DocsDebugLogSendVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellid = "LarkLogInDocsCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellid)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellid)
        }
        let fullPath = childrenPath[indexPath.row].pathString as NSString
        let cellTitle = fullPath.lastPathComponent
        cell?.textLabel?.text = cellTitle

        return cell!
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return childrenPath.count
    }
}
#endif
