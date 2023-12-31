//
//  DefaultCCMDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteView
import WebKit
import UniverseDesignToast

final class DefaultCCMDependency: CCMDependency {
    func isDocsURL(_ urlString: String) -> Bool {
        true
    }

    /// 创建文档工厂
    func createFollowDocumentFactory() -> FollowDocumentFactory {
        DefaultFollowDocumentFactory()
    }

    /// 下载Lark文档缩略图
    /// - Parameters:
    ///   - url: 图片 url
    ///   - thumbnailInfo: ["nonce":"随机数", "secret":"秘钥","type" :"解密方式"]
    ///   - imageSize: 目标图片大小, nil 表示不调整，直接返回原图
    ///   - completion: 下载完成的回调
    func downloadThumbnail(url: String, thumbnailInfo: [String: Any], imageSize: CGSize?,
                           completion: @escaping (Result<UIImage, Error>) -> Void) {
    }

    func createNotesDocumentFactory() -> NotesDocumentFactory {
        DefaultNotesDocumentFactory()
    }

    func createBVTemplate() -> BVTemplate? {
        return nil
    }

    func createLkNavigationController() -> UINavigationController {
        return UINavigationController()
    }

    func setDocsIcon(iconInfo: String, url: String, completion: ((UIImage) -> Void)?) {
    }

    func getDocsAPIDomain() -> String {
        return ""
    }
}

// MARK: - Magic Share

class DefaultFollowDocumentFactory: FollowDocumentFactory {
    func startMeeting() {}

    func stopMeeting() {}

    func open(url: String) -> FollowDocument? {
        DefaultFollowVC(url)
    }

    func openGoogleDrive(url: String, injectScript: String?) -> FollowDocument? {
        DefaultFollowVC(url)
    }
}

private class DefaultFollowVC: UIViewController, FollowDocument, WKNavigationDelegate {
    weak var delegate: FollowDocumentDelegate?
    let followUrl: String
    let webView = WKWebView()

    init(_ url: String) {
        self.followUrl = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        webView.navigationDelegate = self
        if let url = URL(string: self.followUrl) {
            webView.load(URLRequest(url: url))
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private weak var loadingToast: UDToast?
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        self.loadingToast = UDToast.showLoading(with: "Mocking CCM", on: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        delegate?.followDidReady(self)
        self.loadingToast?.remove()
    }

    func setDelegate(_ delegate: FollowDocumentDelegate) {
        self.delegate = delegate
    }

    var followTitle: String {
        webView.title ?? "follow"
    }

    var followVC: UIViewController {
        self
    }

    var scrollView: UIScrollView? {
        return nil
    }

    var canBackToLastPosition: Bool {
        return false
    }

    func startRecord() {
    }

    func stopRecord() {
    }

    func startFollow() {
    }

    func stopFollow() {
    }

    func setState(states: [String], meta: String?) {
    }

    func getState(callBack: @escaping ([String], String?) -> Void) {
    }

    func reload() {
    }

    func injectJS(_ script: String) {
    }

    func backToLastPosition() {
    }

    func clearLastPosition(_ token: String?) {
    }

    func keepCurrentPosition() {
    }

    func updateOptions(_ options: String?) {
    }

    func willSetFloatingWindow() {
    }

    func finishFullScreenWindow() {
    }

    func updateContext(_ context: String?) {
    }

    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?) {
    }
}

// MARK: - Notes

class DefaultNotesDocumentFactory: NotesDocumentFactory {

    func create(url: URL, config: NotesAPIConfig) -> NotesDocument? {
        return DefaultNotesDocument()
    }
}

class DefaultNotesDocument: NotesDocument {

    var docVC: UIViewController = UIViewController()

    var status: NotesDocumentStatus = .success

    func setDelegate(_ delegate: NotesDocumentDelegate) {
    }

    func updateSettingConfig(_ settingConfig: [String: Any]) {
    }

    func invoke(command: String, payload: [String: Any]?, callback: NotesInvokeCallBack?) {
    }
}
