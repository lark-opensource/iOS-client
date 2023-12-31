//
//  NetworkControlEntranceViewController.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/3/31.
//

import Foundation
import SnapKit
import LarkSensitivityControl
import LarkEMM
import LarkSecurityComplianceInfra
import UniverseDesignToast
import UniverseDesignActionPanel
import UniverseDesignLoading
import LarkRustHTTP
import SwiftyJSON
import TTNetworkManager
import LarkRustClient
import RustPB
import LarkContainer
import RxSwift
import TSPrivacyKit

enum RequestType: String, Codable, CaseIterable {
    case GET
    case POST
}

enum NetworkType: String, Codable, CaseIterable {
    case RustSDK
    case TTNetworkManager
    case URLSession
}
protocol A {
    
}
struct ConfigCache: Codable {
    let requestType: RequestType
    let networkType: NetworkType
    let url: String
    let parameters: String
}

final class NetworkControlEntranceViewController: UIViewController {
    
    let storage = SCKeyValue.globalMMKV()
    let handler = NetworkControlPushTrackHandler()
    
    let urlTextView = SCDebugTextView()
    let paramTextView = SCDebugTextView()
    let eventTextView = SCDebugTextView()
    let eventFilterInputView = UITextField()
    
    @Provider
    var rustService: RustService
    
    var eventList: [String] = []
    var disposeBag: DisposeBag?
    
    var requestType = RequestType.GET
    var networkType = NetworkType.URLSession
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerEventObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        releaseEventObserver()
    }
    
    private func buildView() {
        //bg color
        self.view.backgroundColor = .white
        //bg tap
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(didTapEmpty))
        self.view.addGestureRecognizer(tapGes)
        
        //bar buttons
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Default", style: .plain, target: self, action: #selector(didClickDefaultSettingBtn)),
            UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(didClickSaveSettingBtn)),
            UIBarButtonItem(title: "Load", style: .plain, target: self, action: #selector(didClickLoadSettingBtn)),
        ]
        
        //MARK: - URL Input View
        //url title
        let urlInputTitle = UILabel()
        urlInputTitle.text = "输入待测试URL："
        urlInputTitle.textColor = .black
        urlInputTitle.font = .systemFont(ofSize: 17)
        view.addSubview(urlInputTitle)
        urlInputTitle.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(view.snp.topMargin)
        }
        
        //url copy and paste button
        let urlCopyBtn = UIButton()
        urlCopyBtn.setTitle("Copy", for: .normal)
        urlCopyBtn.setTitleColor(.black, for: .normal)
        urlCopyBtn.setTitleColor(.white, for: .highlighted)
        urlCopyBtn.titleLabel?.font = .systemFont(ofSize: 14)
        urlCopyBtn.backgroundColor = .gray
        urlCopyBtn.layer.cornerRadius = 4
        urlCopyBtn.addTarget(self, action: #selector(didClickURLCopyBtn), for: .touchUpInside)
        view.addSubview(urlCopyBtn)
        urlCopyBtn.snp.makeConstraints { make in
            make.top.equalTo(urlInputTitle.snp.bottom).offset(12)
            make.rightMargin.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 40))
        }
        
        let urlPasteBtn = UIButton()
        urlPasteBtn.setTitle("Paste", for: .normal)
        urlPasteBtn.setTitleColor(.black, for: .normal)
        urlPasteBtn.setTitleColor(.white, for: .highlighted)
        urlPasteBtn.titleLabel?.font = .systemFont(ofSize: 14)
        urlPasteBtn.backgroundColor = .gray
        urlPasteBtn.layer.cornerRadius = 4
        urlPasteBtn.addTarget(self, action: #selector(didClickURLPasteBtn), for: .touchUpInside)
        view.addSubview(urlPasteBtn)
        urlPasteBtn.snp.makeConstraints { make in
            make.top.equalTo(urlCopyBtn.snp.bottom).offset(8)
            make.right.size.equalTo(urlCopyBtn)
        }
        
        //url input view
        urlTextView.font = .systemFont(ofSize: 14)
        urlTextView.layer.borderColor = UIColor.gray.cgColor
        urlTextView.layer.borderWidth = 1.5
        urlTextView.returnKeyType = .done
        urlTextView.keyboardType = .URL
        view.addSubview(urlTextView)
        urlTextView.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(urlCopyBtn)
            make.bottom.equalTo(urlPasteBtn)
            make.right.equalTo(urlCopyBtn.snp.left).offset(-8)
        }
        
        //MARK: - Parameters Input View
        // parameters title
        let paramTitle = UILabel()
        paramTitle.text = "输入网络请求参数："
        paramTitle.textColor = .black
        paramTitle.font = .systemFont(ofSize: 17)
        view.addSubview(paramTitle)
        paramTitle.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(urlTextView.snp.bottom).offset(12)
        }
        
        // parameters copy & paste button
        let paramCopyBtn = UIButton()
        paramCopyBtn.setTitle("Copy", for: .normal)
        paramCopyBtn.setTitleColor(.black, for: .normal)
        paramCopyBtn.setTitleColor(.white, for: .highlighted)
        paramCopyBtn.titleLabel?.font = .systemFont(ofSize: 14)
        paramCopyBtn.backgroundColor = .gray
        paramCopyBtn.layer.cornerRadius = 4
        paramCopyBtn.addTarget(self, action: #selector(didClickParameterCopyBtn), for: .touchUpInside)
        view.addSubview(paramCopyBtn)
        paramCopyBtn.snp.makeConstraints { make in
            make.top.equalTo(paramTitle.snp.bottom).offset(12)
            make.rightMargin.equalToSuperview()
            make.size.equalTo(CGSize(width: 80, height: 40))
        }
        
        let paramPasteBtn = UIButton()
        paramPasteBtn.setTitle("Paste", for: .normal)
        paramPasteBtn.setTitleColor(.black, for: .normal)
        paramPasteBtn.setTitleColor(.white, for: .highlighted)
        paramPasteBtn.titleLabel?.font = .systemFont(ofSize: 14)
        paramPasteBtn.backgroundColor = .gray
        paramPasteBtn.layer.cornerRadius = 4
        paramPasteBtn.addTarget(self, action: #selector(didClickParameterPasteBtn), for: .touchUpInside)
        view.addSubview(paramPasteBtn)
        paramPasteBtn.snp.makeConstraints { make in
            make.top.equalTo(paramCopyBtn.snp.bottom).offset(8)
            make.right.size.equalTo(paramCopyBtn)
        }
        
        //parameters input view
        paramTextView.font = .systemFont(ofSize: 14)
        paramTextView.layer.borderColor = UIColor.gray.cgColor
        paramTextView.layer.borderWidth = 1.5
        paramTextView.returnKeyType = .done
        paramTextView.keyboardType = .default
        view.addSubview(paramTextView)
        paramTextView.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(paramCopyBtn)
            make.bottom.equalTo(paramPasteBtn)
            make.right.equalTo(paramCopyBtn.snp.left).offset(-8)
        }
        
        //request type
        let requestTypTitle = UILabel()
        requestTypTitle.text = "网络请求类型（单击切换）："
        requestTypTitle.textColor = .black
        requestTypTitle.font = .systemFont(ofSize: 17)
        view.addSubview(requestTypTitle)
        requestTypTitle.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(paramTextView.snp.bottom).offset(12)
        }
        
        let requestTypeBtn = UIButton()
        requestTypeBtn.setTitle(requestType.rawValue, for: .normal)
        requestTypeBtn.setTitleColor(.black, for: .normal)
        requestTypeBtn.setTitleColor(.white, for: .highlighted)
        requestTypeBtn.layer.cornerRadius = 4
        requestTypeBtn.titleLabel?.font = .systemFont(ofSize: 14)
        requestTypeBtn.backgroundColor = .gray
        requestTypeBtn.addTarget(self, action: #selector(didClickChoiseRequestTypeBtn(btn:)), for: .touchUpInside)
        view.addSubview(requestTypeBtn)
        requestTypeBtn.snp.makeConstraints { make in
            make.top.equalTo(requestTypTitle.snp.bottom).offset(8)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(40)
        }
        
        //network type
        let networkTypTitle = UILabel()
        networkTypTitle.text = "网络库类型（单击切换）："
        networkTypTitle.textColor = .black
        networkTypTitle.font = .systemFont(ofSize: 17)
        view.addSubview(networkTypTitle)
        networkTypTitle.snp.makeConstraints { make in
            make.leftMargin.equalToSuperview()
            make.top.equalTo(requestTypeBtn.snp.bottom).offset(12)
        }
        
        let networkTypeBtn = UIButton()
        networkTypeBtn.setTitle(networkType.rawValue, for: .normal)
        networkTypeBtn.setTitleColor(.black, for: .normal)
        networkTypeBtn.setTitleColor(.white, for: .highlighted)
        networkTypeBtn.layer.cornerRadius = 4
        networkTypeBtn.titleLabel?.font = .systemFont(ofSize: 14)
        networkTypeBtn.backgroundColor = .gray
        networkTypeBtn.addTarget(self, action: #selector(didClickChoiseNetworkTypeBtn(btn:)), for: .touchUpInside)
        view.addSubview(networkTypeBtn)
        networkTypeBtn.snp.makeConstraints { make in
            make.top.equalTo(networkTypTitle.snp.bottom).offset(8)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(40)
        }
        
        //event title
        let eventTitle = UILabel()
        eventTitle.text = "网络事件"
        eventTitle.textColor = .black
        eventTitle.font = .systemFont(ofSize: 17)
        view.addSubview(eventTitle)
        eventTitle.snp.makeConstraints { make in
            make.top.equalTo(networkTypeBtn.snp.bottom).offset(12)
            make.leftMargin.equalToSuperview()
            make.width.equalTo(100)
        }

        eventFilterInputView.font = .systemFont(ofSize: 14)
        eventFilterInputView.layer.borderColor = UIColor.gray.cgColor
        eventFilterInputView.layer.borderWidth = 1.5
        eventFilterInputView.returnKeyType = .done
        eventFilterInputView.keyboardType = .default
        eventFilterInputView.clearButtonMode = .always
        eventFilterInputView.placeholder = "filter expr"
        eventFilterInputView.delegate = self
        view.addSubview(eventFilterInputView)
        eventFilterInputView.snp.makeConstraints { make in
            make.left.equalTo(eventTitle.snp.right).offset(5)
            make.centerY.equalTo(eventTitle)
            make.height.equalTo(24)
            make.rightMargin.equalToSuperview()
        }
        
        eventTextView.textColor = .gray
        eventTextView.isEditable = false
        eventTextView.font = .systemFont(ofSize: 14)
        eventTextView.layer.borderColor = UIColor.gray.cgColor
        eventTextView.layer.borderWidth = 1.5
        eventTextView.returnKeyType = .done
        eventTextView.keyboardType = .default
        eventTextView.showsVerticalScrollIndicator = true
        view.addSubview(eventTextView)
        eventTextView.snp.makeConstraints { make in
            make.leftMargin.rightMargin.equalToSuperview()
            make.top.equalTo(eventTitle.snp.bottom).offset(8)
        }
        
        //send request
        let sendRequestBtn = UIButton()
        sendRequestBtn.setTitle("send request", for: .normal)
        sendRequestBtn.setTitleColor(.black, for: .normal)
        sendRequestBtn.setTitleColor(.white, for: .highlighted)
        sendRequestBtn.titleLabel?.font = .systemFont(ofSize: 14)
        sendRequestBtn.backgroundColor = .green
        sendRequestBtn.layer.cornerRadius = 4
        sendRequestBtn.addTarget(self, action: #selector(didClickSendRequestBtn), for: .touchUpInside)
        view.addSubview(sendRequestBtn)
        sendRequestBtn.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottomMargin)
            make.leftMargin.rightMargin.equalToSuperview()
            make.height.equalTo(40)
            make.top.equalTo(eventTextView.snp.bottom).offset(12)
        }
        
    }
}

// MARK: - Action
extension NetworkControlEntranceViewController {
    
    static let cacheKey = "NetworkControlDebugConfigCacheKey"
    
    private static let pasteboardConfig = PasteboardConfig(token: Token(kTokenAvoidInterceptIdentifier))
    
    @objc
    private func didTapEmpty() {
        urlTextView.resignFirstResponder()
        paramTextView.resignFirstResponder()
        eventFilterInputView.resignFirstResponder()
    }
    
    @objc
    private func didClickURLCopyBtn() {
        SCPasteboard.general(Self.pasteboardConfig).string = urlTextView.text
    }
    
    @objc
    private func didClickURLPasteBtn() {
        urlTextView.text = SCPasteboard.general(Self.pasteboardConfig).string
    }
    
    @objc
    private func didClickParameterCopyBtn() {
        SCPasteboard.general(Self.pasteboardConfig).string = paramTextView.text
    }
    
    @objc
    private func didClickParameterPasteBtn() {
        paramTextView.text = SCPasteboard.general(Self.pasteboardConfig).string
    }
    
    @objc
    private func didClickSendRequestBtn() {
        guard let url = urlTextView.text, !url.isEmpty else {
            UDToast.showFailure(with: "URL不能为空", on: self.view)
            return
        }
        
        switch networkType {
        case .RustSDK: sendRustSDKRequest(url, type: requestType, param: paramTextView.text)
        case .TTNetworkManager: sendTTNetworkManagerRequest(url, type: requestType, param: paramTextView.text)
        case .URLSession: sendURLSessionRequest(url, type: requestType, param: paramTextView.text)
        }
    }
    
    @objc
    private func didClickChoiseRequestTypeBtn(btn: UIButton) {
        let source = UDActionSheetSource(sourceView: btn, sourceRect: btn.bounds, arrowDirection: .up)
        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        
        actionSheet.setTitle("网络请求类型切换")
        RequestType.allCases.forEach { type in
            actionSheet.addDefaultItem(text: type.rawValue) { [weak self] in
                guard let self = self else { return }
                self.requestType = type
                btn.setTitle(type.rawValue, for: .normal)
            }
        }
        actionSheet.setCancelItem(text: "取消")
        self.present(actionSheet, animated: true)
    }
    
    @objc
    private func didClickChoiseNetworkTypeBtn(btn: UIButton) {
        let source = UDActionSheetSource(sourceView: btn, sourceRect: btn.bounds, arrowDirection: .up)
        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        
        actionSheet.setTitle("网络库切换")
        NetworkType.allCases.forEach { type in
            actionSheet.addDefaultItem(text: type.rawValue) { [weak self] in
                guard let self = self else { return }
                self.networkType = type
                btn.setTitle(type.rawValue, for: .normal)
            }
        }
        actionSheet.setCancelItem(text: "取消")
        self.present(actionSheet, animated: true)
    }
    
    @objc
    private func didClickLoadSettingBtn() {
        guard let cache: ConfigCache = storage.value(forKey: Self.cacheKey) else {
            UDToast.showFailure(with: "读取配置失败", on: self.view)
            return
        }
        urlTextView.text = cache.url
        paramTextView.text = cache.parameters
        requestType = cache.requestType
        networkType = cache.networkType
        UDToast.showSuccess(with: "读取配置完成", on: self.view)
    }
    
    @objc
    private func didClickSaveSettingBtn() {
        let cache = ConfigCache(requestType: requestType, networkType: networkType, url: urlTextView.text, parameters: paramTextView.text)
        storage.set(cache, forKey: Self.cacheKey)
        UDToast.showSuccess(with: "保存完成", on: self.view)
    }
    
    @objc
    private func didClickDefaultSettingBtn() {
        urlTextView.text = "https://internal-api-security.feishu.cn/lark/scs/compliance/ping/"
        paramTextView.text = nil
        requestType = .GET
        networkType = .URLSession
    }
}

extension NetworkControlEntranceViewController {
    
    private func sendRustSDKRequest(_ urlStr: String, type: RequestType, param: String?) {
        let task = buildSessionTask(urlStr: urlStr, type: type, param: param, useRust: true)
        task?.resume()
    }
    
    private func sendTTNetworkManagerRequest(_ urlStr: String, type: RequestType, param: String?) {
        let spinConf = UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 80, color: .red), textLabelConfig: UDSpinLabelConfig(text: "网络请求中", font: .systemFont(ofSize: 18), textColor: .red))
        let spin = UDSpin(config: spinConf)
        spin.addToCenter(on: self.view)
        TTNetworkManager.shareInstance().requestForJSON(withURL: urlStr, params: JSON(parseJSON: param ?? "").dictionaryObject, method: type.rawValue, needCommonParams: false) { error, data in
            DispatchQueue.main.async {
                spin.removeFromSuperview()
                if let error = error {
                    UDToast.showFailure(with: "网络请求失败:\(error.localizedDescription)", on: self.view, delay: 10)
                } else {
                    UDToast.showSuccess(with: "网络请求成功", on: self.view, delay: 3)
                }
            }
        }
    }
    
    private func sendURLSessionRequest(_ urlStr: String, type: RequestType, param: String?) {
        let task = buildSessionTask(urlStr: urlStr, type: type, param: param, useRust: false)
        task?.resume()
    }
    
    private func buildSessionTask(urlStr: String, type: RequestType, param: String?, useRust: Bool) -> URLSessionDataTask? {
        let session: URLSession
        if useRust {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.protocolClasses = [RustHttpURLProtocol.self]
            session = URLSession(configuration: config)
        } else {
            session = URLSession.shared
        }
        
        var urlComponents = URLComponents(string: urlStr)
        
        if type == .GET, let param = param, !param.isEmpty {
            let jsonObj = JSON(parseJSON: param)
            let dict = jsonObj.dictionaryValue
            let queryItems = dict.map { key, value in
                URLQueryItem(name: key, value: value.string)
            }
            if !queryItems.isEmpty {
                var originQueryItems = urlComponents?.queryItems ?? []
                originQueryItems.append(contentsOf: queryItems)
                urlComponents?.queryItems = originQueryItems
            }
        }
        guard let url = try? urlComponents?.asURL() else {
            UDToast.showFailure(with: "url解析失败, 请检查格式是否正确", on: self.view)
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = type.rawValue
        
        if type == .POST, let param = param, !param.isEmpty {
            let jsonObj = JSON(parseJSON: param)
            do {
                request.httpBody = try jsonObj.rawData()
            } catch {
                UDToast.showFailure(with: "解析参数失败:\(error)", on: self.view)
                return nil
            }
        }
        let spinConf = UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 80, color: .red), textLabelConfig: UDSpinLabelConfig(text: "网络请求中", font: .systemFont(ofSize: 18), textColor: .red))
        let spin = UDSpin(config: spinConf)
        spin.addToCenter(on: self.view)
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                spin.removeFromSuperview()
                if let error = error {
                    UDToast.showFailure(with: "网络请求失败:\(error.localizedDescription)", on: self.view, delay: 10)
                } else {
                    UDToast.showSuccess(with: "网络请求成功", on: self.view, delay: 3)
                }
            }
        }
        return task
    }
}

extension NetworkControlEntranceViewController: UITextFieldDelegate, NetworkControlPushTrackHandlerDelegate {
    
    func registerEventObserver() {
        let disposeBag = DisposeBag()
        
        let observer: Observable<RustPB.Statistics_V1_Track> = rustService.register(pushCmd: .pushTrack)
        observer.subscribeOn(MainScheduler.instance).subscribe(onNext: {[weak self] track in
            guard let self = self else { return }
            guard track.type == .slardar else { return }
            guard track.key == "pns_network" else { return }
            let slardarParam = track.slardarParam
            
            let content = """
            Key: \(track.key)
            Category: \(slardarParam.category)
            Metrics: \(slardarParam.metric)
            """
            DispatchQueue.main.async {
                self.addEvent(content: content)
            }
        }).disposed(by: disposeBag)
        
        self.handler.delegate = self
        TSPKEventManager.registerSubsciber(handler, on: .networkResponse)
        let dispose = Disposables.create {[weak self] in
            TSPKEventManager.unregisterSubsciber(self?.handler, on: .networkResponse)
        }
        
        disposeBag.insert(dispose)
        
        self.disposeBag = disposeBag
    }
    
    func releaseEventObserver() {
        self.disposeBag = nil
    }
    
    func addEvent(content: String) {
        while eventList.count >= 500 {
            eventList.remove(at: 0)
        }
        eventList.append(content)
        
        guard !eventFilterInputView.isEditing else { return }
        
        guard let text = eventFilterInputView.text, text.count > 0 else {
            eventTextView.text = eventTextView.text + "\n" + content
            return
        }
        
        
        if content.contains(text) {
            eventTextView.text = eventTextView.text + "\n" + content
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let filterText = textField.text ?? ""
        var content = eventList.reduce("") { partialResult, currentValue in
            if filterText.count == 0 {
                return partialResult + "\n" + currentValue
            } else {
                if currentValue.contains(filterText) {
                    return partialResult + "\n" + currentValue
                } else {
                    return partialResult
                }
            }
        }
        eventTextView.text = content
        eventTextView.btd_scrollToBottom()
    }
    
    func didReceiveNetworkEvent(key: String, category: String, metric: String) {
        DispatchQueue.main.async {
            self.addEvent(content: """
            Key: \(key)
            Category: \(category)
            Metrics: \(metric)
            """)
        }
    }
}
