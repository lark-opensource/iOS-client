//
//  NetDiagnoseSettingViewModel.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/16.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import RustPB
import Swinject
import LarkContainer
import BootManager
import LarkRustClient
import LarkFocus
import LarkStorage
import ThreadSafeDataStructure
import EENavigator

import Homeric
import LKCommonsTracker
import LarkMessengerInterface

/// 网络诊断vm代理
protocol NetDiagnoseSettingViewModelDelegate: AnyObject {
    //展示保存log分享框
    func showNetDiagnoseActionSheet(filePath: String)
}

//网络诊断状态
public enum NetDiagnoseStatus {
    case unStart  ///未开始
    case running  ///检测中
    case normal   ///检测正常
    case error   ///检测不可用
}

//网络诊断类型
public enum NetDiagnoseType {
    case PushNetStatus           ///网络状况
    case PushNetInterfaceConfig  ///是否使用代理和vpn
    case PushNetStatus_dns       ///dns状况
    case PushLarkApiReachable    ///检测API联通性
}

///检测项
public struct NetDiagnoseItem {
    ///检测类型
    public var netDiagnoseType: NetDiagnoseType
    ///检测名称
    public var itemName: String
    ///检测描述
    public var itemDesc: String
    ///检测状态
    public var status: NetDiagnoseStatus
    ///索引
    public var index: Int
    ///session id
    public var sessionID: String?

    init(itemName: String, itemDesc: String, status: NetDiagnoseStatus, index: Int, netDiagnoseType: NetDiagnoseType) {
        self.itemName = itemName
        self.itemDesc = itemDesc
        self.status = status
        self.index = index
        self.netDiagnoseType = netDiagnoseType
    }
}

final class NetDiagnoseSettingViewModel {
    private let disposeBag = DisposeBag()
    private let pushCenter: PushNotificationCenter
    public let from: NetDiagnoseSettingBody.Scene
    public let userNavigator: Navigatable
    private let rustService: SDKRustService
    weak var delegate: NetDiagnoseSettingViewModelDelegate?

    //UI数据源
    public var netDiagnoseItems: [NetDiagnoseItem] = []
    //接收到push的检测项结果
    public var pushNetDiagnoseItems: [NetDiagnoseItem] = []
    //下载日志
    private var diagnoseLogs: [String: String] = [:]
    //当前检测索引
    public var currentNetDiagnoseIndex: Int = 0
    //检测状态
    public var diagnoseStatus: NetDiagnoseStatus = .unStart
    //当前检测的sessionId
    private var currentSessionId: String?
    //刷新表格视图信号
    var reloadDataDriver: Driver<Void> { return reloadDataPublish.asDriver(onErrorJustReturn: ()) }
    private var reloadDataPublish = PublishSubject<Void>()

    init(pushCenter: PushNotificationCenter,
         from: NetDiagnoseSettingBody.Scene,
         userNavigator: Navigatable,
         rustService: SDKRustService) {
        self.pushCenter = pushCenter
        self.from = from
        self.userNavigator = userNavigator
        self.rustService = rustService
    }

    public func startObserver() {
        //接收诊断结果
        self.pushCenter.observable(for: PushLarkApiReachable.self).subscribe(onNext: {[weak self] pushMessage in
            DispatchQueue.main.async {
                self?.updateNetDiagnoseState(pushMessage: pushMessage)
            }
        }).disposed(by: self.disposeBag)
    }

    //生成sessionId
    private func getRandomSessionId(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in (letters.randomElement() ?? "a") })
    }

    //开始诊断
    public func startDiagnose() {
        guard self.diagnoseStatus == .unStart else {
            return
        }
        self.diagnoseStatus = .running
        self.currentNetDiagnoseIndex = 0
        self.netDiagnoseItems = self.netDiagnoseItems.map { (netDiagnose) -> NetDiagnoseItem in
            var newNetDiagnose = netDiagnose
            if newNetDiagnose.index == 0 {
                newNetDiagnose.status = .running
                newNetDiagnose = self.setNetDiagnoseItemDisplay(netDiagnoseItem: newNetDiagnose)
            }
            return newNetDiagnose
        }
        self.reloadDataPublish.onNext(())
        //调用检测接口
        self.currentSessionId = self.getRandomSessionId(length: 9)
        if let currentSessionId = currentSessionId {
            self.starDetectingNetwork(sessionId: currentSessionId)
        }
    }

    /*
        调用检测接口
        @param sessionId：诊断id
     */
    private func starDetectingNetwork(sessionId: String) {
        var request = RustPB.Tool_V1_StarDetectingNetworkRequest()
        request.sessionID = sessionId
        self.rustService.sendAsyncRequest(request).subscribe(onNext: { _ in
            }, onError: { _ in
            }).disposed(by: self.disposeBag)
    }

    //查看日志
    static var logIsDownLoading: Bool = false
    public func viewLogs() {
        if let currentSessionId = self.currentSessionId {
            //打开已下载的
            guard !self.diagnoseLogs.keys.contains(currentSessionId) else {
                if let filePath = self.diagnoseLogs[currentSessionId] {
                    self.showActionSheet(filePath: filePath)
                }
                return
            }
            //正在下载避免重复下载
            guard !NetDiagnoseSettingViewModel.logIsDownLoading else {
                return
            }
        }
        NetDiagnoseSettingViewModel.logIsDownLoading = true
        var request = RustPB.Tool_V1_SaveDetectingLogRequest()
        if let currentSessionId = self.currentSessionId {
            request.sessionID = currentSessionId
            request.filePath = self.logRootPath
            self.rustService.sendAsyncRequest(request).subscribe(onNext: { [weak self] (resp: Tool_V1_SaveDetectingLogResponse) in
                //是当前session id打开action sheet
                if self?.currentSessionId == currentSessionId {
                    DispatchQueue.main.async {
                        self?.diagnoseLogs.updateValue(resp.filePath, forKey: currentSessionId)
                        self?.showActionSheet(filePath: resp.filePath)
                        NetDiagnoseSettingViewModel.logIsDownLoading = false
                    }
                }
                }, onError: { error in
                    NetDiagnoseSettingViewModel.logIsDownLoading = false
                    print("error-\(error)")
                }).disposed(by: self.disposeBag)
        }
    }

    //显示保存log分享框
    private func showActionSheet(filePath: String) {
        MineTracker.trackNetworkSaveLog()
        self.delegate?.showNetDiagnoseActionSheet(filePath: filePath)
    }

    lazy var logRootPath: String = {
        let tmpLogPath = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "DetectingLogs"
        try? tmpLogPath.createDirectory()
        return tmpLogPath.absoluteString
    }()

    //更新检测状态
    private func updateNetDiagnoseState(pushMessage: PushMessage) {
        //适配检测数据
        if pushMessage is PushLarkApiReachable {
            var pushLarkApiReachable = pushMessage as? PushLarkApiReachable
            var apiStatusArray = pushLarkApiReachable?.larkApiReachable.apiStatus
            var connected: Bool = true
            if let apiStatusArray = apiStatusArray, !apiStatusArray.isEmpty {
                for apiStatus in apiStatusArray where !apiStatus.connected {
                    connected = apiStatus.connected
                    break
                }
            }
            //网络没链接，并且错误类型为unknown认为是serverError
            let serverError: Bool = (!connected && (pushLarkApiReachable?.larkApiReachable.errorType == .unknown))
            guard self.currentSessionId == pushLarkApiReachable?.larkApiReachable.sessionID else {
                return
            }
            self.pushNetDiagnoseItems = self.netDiagnoseItems.map { (netDiagnose) -> NetDiagnoseItem in
                var newNetDiagnose = netDiagnose
                var type: NetDiagnoseType = newNetDiagnose.netDiagnoseType
                switch type {
                case .PushNetInterfaceConfig:
                    newNetDiagnose.status = (pushLarkApiReachable?.larkApiReachable.errorType == .proxyError) ? .error : .normal
                case .PushNetStatus:
                    let isError = (pushLarkApiReachable?.larkApiReachable.errorType == .offlineError || pushLarkApiReachable?.larkApiReachable.errorType == .certificateError)
                    newNetDiagnose.status = isError ? .error : .normal
                case .PushNetStatus_dns:
                    newNetDiagnose.status = (pushLarkApiReachable?.larkApiReachable.errorType == .dnsError) ? .error : .normal
                case .PushLarkApiReachable:
                    newNetDiagnose.status = ((pushLarkApiReachable?.larkApiReachable.errorType == .serverError) || serverError) ? .error : .normal
                }
                newNetDiagnose.sessionID = pushLarkApiReachable?.larkApiReachable.sessionID
                return newNetDiagnose
            }
            //显示检测结果，模拟检测效果，每0.5s更新一下结果
            for index in 0...self.netDiagnoseItems.count - 1 {
                var dealyTime: Double = 0.50 * Double(index + 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + dealyTime, execute: { [weak self] in
                    guard self?.diagnoseStatus == .running else {
                        return
                    }
                    //更新UI数据源
                    if let netDiagnoseItems = self?.netDiagnoseItems {
                        self?.netDiagnoseItems = netDiagnoseItems.map { (netDiagnose) -> NetDiagnoseItem in
                            var newNetDiagnose = netDiagnose
                            //更新当前状态
                            if let currentNetDiagnoseIndex = self?.currentNetDiagnoseIndex,
                               newNetDiagnose.index == currentNetDiagnoseIndex,
                               let pushNetDiagnoseItems = self?.pushNetDiagnoseItems,
                               currentNetDiagnoseIndex < pushNetDiagnoseItems.count {
                                var pushNetDiagnoseItem = pushNetDiagnoseItems[currentNetDiagnoseIndex]
                                //如果是此次检测
                                if pushNetDiagnoseItem.sessionID == self?.currentSessionId {
                                    newNetDiagnose.status = pushNetDiagnoseItem.status
                                    newNetDiagnose = self?.setNetDiagnoseItemDisplay(netDiagnoseItem: newNetDiagnose) ?? newNetDiagnose
                                }
                            }
                            return newNetDiagnose
                        }
                    }
                    //开始loading下一个状态
                    self?.startNextDiagnose()
                    self?.reloadDataPublish.onNext(())
                })
            }
        }
    }

    //开始下一个诊断
    private func startNextDiagnose() {
        self.currentNetDiagnoseIndex += 1
        //已经是最后一个
        guard self.currentNetDiagnoseIndex < self.netDiagnoseItems.count else {
            self.completDiagnose()
            return
        }
        //开始下一个诊断
        self.netDiagnoseItems = self.netDiagnoseItems.map { (netDiagnose) -> NetDiagnoseItem in
            var newNetDiagnose = netDiagnose
            if newNetDiagnose.index == self.currentNetDiagnoseIndex {
                newNetDiagnose.status = .running
                newNetDiagnose = self.setNetDiagnoseItemDisplay(netDiagnoseItem: newNetDiagnose)
            }
            return newNetDiagnose
        }
    }

    //完成诊断
    private func completDiagnose() {
        guard self.diagnoseStatus == .running else {
            return
        }
        //修改状态
        self.currentNetDiagnoseIndex = -1
        //判断是否有异常
        var trackerParams: [String: String] = [:]
        trackerParams.updateValue(self.from.rawValue, forKey: "occasion")
        for netDiagnose in self.netDiagnoseItems {
            if let netDiagnose = netDiagnose as? NetDiagnoseItem, netDiagnose.status == .error {
                self.diagnoseStatus = .error
            }
            if let netDiagnose = netDiagnose as? NetDiagnoseItem, netDiagnose.netDiagnoseType == .PushNetStatus {
                trackerParams.updateValue(netDiagnose.status == .error ? "true" : "false", forKey: "is_network_error")
            }
            if let netDiagnose = netDiagnose as? NetDiagnoseItem, netDiagnose.netDiagnoseType == .PushNetInterfaceConfig {
                trackerParams.updateValue(netDiagnose.status == .error ? "true" : "false", forKey: "is_proxy_error")
            }
            if let netDiagnose = netDiagnose as? NetDiagnoseItem, netDiagnose.netDiagnoseType == .PushNetStatus_dns {
                trackerParams.updateValue(netDiagnose.status == .error ? "true" : "false", forKey: "is_dns_error")
            }
            if let netDiagnose = netDiagnose as? NetDiagnoseItem, netDiagnose.netDiagnoseType == .PushLarkApiReachable {
                trackerParams.updateValue(netDiagnose.status == .error ? "true" : "false", forKey: "is_api_error")
            }
        }
        //如果没有异常认为是正常
        if self.diagnoseStatus != .error {
            self.diagnoseStatus = .normal
        }
        //更新UI
        self.reloadDataPublish.onNext(())
        //埋点
        trackerParams.updateValue(self.diagnoseStatus == .error ? "true" : "false", forKey: "result")
        MineTracker.trackNetworkCheckView(trackerParams: trackerParams)
    }

    //取消诊断
    public func canceDiagnose() {
        guard self.diagnoseStatus != .unStart else {
            return
        }
        self.resetDiagnose()
    }

    //重新诊断
    public func againDiagnose() {
        MineTracker.trackNetworkReCheck()
        //重置状态
        self.resetDiagnose()
        //开始诊断
        self.startDiagnose()
    }

    //重置状态
    private func resetDiagnose() {
        self.diagnoseStatus = .unStart
        self.currentNetDiagnoseIndex = -1
        self.currentSessionId = ""
        self.pushNetDiagnoseItems.removeAll()
        //重置诊断项
        self.netDiagnoseItems = self.netDiagnoseItems.map { (netDiagnose) -> NetDiagnoseItem in
            var newNetDiagnose = netDiagnose
            newNetDiagnose.status = .unStart
            newNetDiagnose = self.setNetDiagnoseItemDisplay(netDiagnoseItem: newNetDiagnose)
            return newNetDiagnose
        }
        self.reloadDataPublish.onNext(())
    }

    //设置检测显示状态
    private func setNetDiagnoseItemDisplay(netDiagnoseItem: NetDiagnoseItem?) -> NetDiagnoseItem {
        guard var newNetDiagnoseItem = netDiagnoseItem else {
            return NetDiagnoseItem(itemName: "", itemDesc: "", status: .normal, index: 0, netDiagnoseType: .PushLarkApiReachable)
        }
        if newNetDiagnoseItem.netDiagnoseType == .PushNetStatus {
            if newNetDiagnoseItem.status == .unStart {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkStatusDesc
            }
            if newNetDiagnoseItem.status == .normal {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetWorkStatus_Normal
            }
            if newNetDiagnoseItem.status == .error {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetWorkStatus_Abnormal
            }
            if newNetDiagnoseItem.status == .running {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkStatusDesc
            }
        }
        if newNetDiagnoseItem.netDiagnoseType == .PushNetInterfaceConfig {
            if newNetDiagnoseItem.status == .unStart {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkProxyDesc
            }
            if newNetDiagnoseItem.status == .normal {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkProxy_Normal
            }
            if newNetDiagnoseItem.status == .error {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkProxy_Abnormal
            }
            if newNetDiagnoseItem.status == .running {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkProxyDesc
            }
        }
        if newNetDiagnoseItem.netDiagnoseType == .PushNetStatus_dns {
            if newNetDiagnoseItem.status == .unStart {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_DNSDesc()
            }
            if newNetDiagnoseItem.status == .normal {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_DNS_Normal
            }
            if newNetDiagnoseItem.status == .error {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_DNS_Abnormal
            }
            if newNetDiagnoseItem.status == .running {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_StabilityDesc()
            }
        }
        if newNetDiagnoseItem.netDiagnoseType == .PushLarkApiReachable {
            if newNetDiagnoseItem.status == .unStart {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_StabilityDesc()
            }
            if newNetDiagnoseItem.status == .normal {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Stability_Stable
            }
            if newNetDiagnoseItem.status == .error {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_Stability_Unstable()
            }
            if newNetDiagnoseItem.status == .running {
                newNetDiagnoseItem.itemDesc = BundleI18n.LarkMine.Lark_NetworkDiagnosis_StabilityDesc()
            }
        }
        return newNetDiagnoseItem
    }

    //初始化检测项
    public func setupNetDiagnoseItems() {
        //网络状态
        var state: NetDiagnoseItem = NetDiagnoseItem(itemName: BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetWorkStatus,
                                                     itemDesc: BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkStatusDesc,
                                                     status: .unStart,
                                                     index: 0,
                                                     netDiagnoseType: .PushNetStatus)
        netDiagnoseItems.append(state)
        //网络代理
        var agency: NetDiagnoseItem = NetDiagnoseItem(itemName: BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkProxy,
                                                      itemDesc: BundleI18n.LarkMine.Lark_NetworkDiagnosis_NetworkProxyDesc,
                                                      status: .unStart,
                                                      index: 1,
                                                      netDiagnoseType: .PushNetInterfaceConfig)
        netDiagnoseItems.append(agency)
        //DNS服务--Lark_NetworkDiagnosis_DNSDesc
        var dns: NetDiagnoseItem = NetDiagnoseItem(itemName: BundleI18n.LarkMine.Lark_NetworkDiagnosis_DNS,
                                                   itemDesc: BundleI18n.LarkMine.Lark_NetworkDiagnosis_DNSDesc(),
                                                   status: .unStart,
                                                   index: 2,
                                                   netDiagnoseType: .PushNetStatus_dns)
        netDiagnoseItems.append(dns)
        //服务稳定性
        var stability: NetDiagnoseItem = NetDiagnoseItem(itemName: BundleI18n.LarkMine.Lark_NetworkDiagnosis_Stability,
                                                         itemDesc: BundleI18n.LarkMine.Lark_NetworkDiagnosis_StabilityDesc(),
                                                         status: .unStart,
                                                         index: 3,
                                                         netDiagnoseType: .PushLarkApiReachable)
        netDiagnoseItems.append(stability)
    }
}
