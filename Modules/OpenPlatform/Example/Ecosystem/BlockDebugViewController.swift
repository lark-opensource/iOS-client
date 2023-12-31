//
//  BlockDebugViewController.swift
//  Ecosystem
//
//  Created by Meng on 2021/7/19.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import OPSDK
import OPBlockInterface
import SnapKit
import LarkOPInterface
import UniverseDesignButton
import UniverseDesignColor
import UniverseDesignInput
import UniverseDesignIcon
import Blockit
import LarkContainer

class BlockDebugViewController: UIViewController {

    @InjectedUnsafeLazy private var blockService: BlockitService
    
    private var blockContainer: OPContainerProtocol?

    private static let inputConfig = UDTextFieldUIConfig(isShowBorder: true, clearButtonMode: .always)

    private let appIdInput = UDTextField(config: BlockDebugViewController.inputConfig)
    private let blockTypeIdInput = UDTextField(config: BlockDebugViewController.inputConfig)
    private let blockIdInput = UDTextField(config: BlockDebugViewController.inputConfig)

    private let reloadButton = UDButton(UDButtonUIConifg.textBlue)
    private let containerView = UIView(frame: .zero)
    private let scrollView = UIScrollView()

    private let controlGuide = UIView()

    private lazy var outputTextArea: UITextView = {
        let view = UITextView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        view.textColor = .green
        view.font = UIFont.systemFont(ofSize: 10)
        view.isEditable = false
        return view
    }()

    deinit {
        blockContainer?.destroy(monitorCode: OPSDKMonitorCode.cancel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Block Test"
        view.backgroundColor = UDColor.bgBase

        appIdInput.placeholder = "appId:"
        blockTypeIdInput.placeholder = "blockTypeId:"
        blockIdInput.placeholder = "blockId:"

        reloadButton.config.type = .big
        reloadButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
        reloadButton.setTitle("reload", for: .normal)
        reloadButton.setImage(UDIcon.replaceOutlined, for: .normal)

        containerView.backgroundColor = UDColor.primaryOnPrimaryFill
        scrollView.backgroundColor = UDColor.bgBase

        view.addSubview(scrollView)

        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(controlGuide)
        scrollView.addSubview(appIdInput)
        scrollView.addSubview(blockTypeIdInput)
        scrollView.addSubview(blockIdInput)
        scrollView.addSubview(reloadButton)
        scrollView.addSubview(containerView)
        scrollView.addSubview(outputTextArea)

        controlGuide.snp.makeConstraints { (make) in
            make.height.equalTo(180.0)
            make.width.equalToSuperview()
            make.leading.top.equalToSuperview()
        }

        appIdInput.snp.makeConstraints { (make) in
            make.leading.top.equalTo(controlGuide).inset(8.0)
            make.trailing.equalTo(reloadButton.snp.leading).offset(20)
        }

        blockIdInput.snp.makeConstraints { (make) in
            make.leading.equalTo(controlGuide).inset(8.0)
            make.trailing.equalTo(reloadButton.snp.leading).offset(20)
            make.centerY.equalTo(controlGuide)
        }

        blockTypeIdInput.snp.makeConstraints { (make) in
            make.leading.bottom.equalTo(controlGuide).inset(8.0)
            make.trailing.equalTo(reloadButton.snp.leading).offset(20)
        }

        reloadButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        reloadButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        reloadButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(controlGuide)
            make.trailing.equalTo(controlGuide.snp.trailing).inset(8.0)
        }
        
        containerView.snp.makeConstraints { (make) in
            make.top.equalTo(controlGuide.snp.bottom)
            make.height.equalTo(500)
            make.width.equalToSuperview()
            make.leading.equalToSuperview()
        }

        outputTextArea.snp.makeConstraints { (make) in
            make.top.equalTo(containerView.snp.bottom).offset(10)
            make.width.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(200)
            make.bottom.equalToSuperview()
        }
        reload()
    }

    @objc func reload() {
        blockContainer?.destroy(monitorCode: OPSDKMonitorCode.cancel)
        blockContainer = nil

        outputTextArea.text = ""
        let appId = appIdInput.text ?? ""
        let blockTypeId = blockTypeIdInput.text ?? ""
        let blockId = blockIdInput.text ?? ""

        if appId.isEmpty || (blockTypeId.isEmpty && blockId.isEmpty) {
            return
        }

        let uniqueID = OPAppUniqueID (
            appID: appId, identifier: blockTypeId, versionType: .preview, appType: .block, instanceID: "block_debug"
        )

        let config = OPBlockContainerConfig(uniqueID: uniqueID, blockLaunchMode: .default, previewToken: "", host: "workplace")
        let data = OPBlockContainerMountData(scene: .undefined)
        let slot = OPViewRenderSlot(view: containerView, defaultHidden: false)
        slot.delegate = self

        if !blockId.isEmpty {
            blockService.mountBlock(byID: blockId,
                                    slot: slot,
                                    data: data,
                                    config: config,
                                    plugins: [],
                                    delegate: self)
        } else {
            let blockInfo = OPBlockInfo(blockID: "",
                                        blockTypeID: blockTypeId,
                                        sourceData: [:])
            
            blockService.mountBlock(byEntity: blockInfo,
                                    slot: slot,
                                    data: data,
                                    config: config,
                                    plugins: [],
                                    delegate: self)
        }
    }

    private func print(_ log: Any?) {
        DispatchQueue.main.async {
            self._print(log)
        }
    }
    
    private func _print(_ log: Any?) {
        outputTextArea.text = "\(outputTextArea.text ?? "")\r\(log ?? "")"
        let bottomOffset = CGPoint(x: 0, y: outputTextArea.contentSize.height - outputTextArea.bounds.size.height)
        if bottomOffset.y > 0 {
            outputTextArea.setContentOffset(bottomOffset, animated: true)
        }
    }
}

extension BlockDebugViewController: OPRenderSlotDelegate {
    func onRenderAttatched(renderSlot: OPRenderSlotProtocol) {
        print(#function)
    }

    func onRenderRemoved(renderSlot: OPRenderSlotProtocol) {
        print(#function)
    }

    func currentViewControllerForPresent() -> UIViewController? {
        print(#function)
        return self
    }

    func currentNavigationControllerForPush() -> UINavigationController? {
        print(#function)
        return self.navigationController
    }
}
    
extension BlockDebugViewController: OPBlockHostProtocol {
    /// Block 收到日志消息
    func didReceiveLogMessage(_ sender: OPBlockEntityProtocol, level: OPBlockDebugLogLevel, message: String, context: OPBlockContext) {
        print("\(#function): \(message)")
    }
    /// Block 内容大小发生变化
    func contentSizeDidChange(_ sender: OPBlockEntityProtocol, newSize: CGSize, context: OPBlockContext) {
        print("\(#function): height:\(newSize.height), width:\(newSize.width)")
        containerView.snp.updateConstraints { (make) in
            make.height.equalTo(newSize.height)
        }
    }

    /// 隐藏loading
    func hideBlockHostLoading(_ sender: OPBlockEntityProtocol) {
        print("\(#function)")
    }

	func onBlockLoadReady(_ sender: OPBlockEntityProtocol, context: OPBlockContext) {
		print("\(#function): runtime ready")
	}
}
    
extension BlockDebugViewController: OPBlockWebLifeCycleDelegate {
    // 页面开始加载, 会发送多次
    // 每次路由跳转新页面加载成功触发
    func onPageStart(url: String?, context: OPBlockContext) {
        print(#function)
    }

    // 页面加载成功, 会发送多次
    // 每次路由跳转新页面加载成功触发
    func onPageSuccess(url: String?, context: OPBlockContext) {
        print(#function)
    }

    // 页面加载失败，会发送多次
    // 每次路由跳转新页面加载失败触发
    func onPageError(url: String?, error: OPError, context: OPBlockContext) {
        print(#function)
    }

    // 页面运行时崩溃，会发送多次
    // 目前web场景会发送此事件，每次收到web的ProcessDidTerminate触发
    func onPageCrash(url: String?, context: OPBlockContext) {
        print(#function)
    }

    // block 内容大小发生变化，会发送多次
    func onBlockContentSizeChanged(height: CGFloat, context: OPBlockContext) {
        print("\(#function): height:\(height)")
        containerView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }
}

extension BlockDebugViewController: BlockitLifeCycleDelegate {
    /// mountBlock 成功
    /// - Parameter container: 内部 block 的抽象容器
    func onBlockMountSuccess(container: OPBlockContainerProtocol, context: OPBlockContext) {
        print(#function)
    }

    /// mountBlock 失败
    /// - Parameter error: 目前错误基本就几个，比如 id 网络请求失败，初始化参数错误
    func onBlockMountFail(error: OPError, context: OPBlockContext) {
        print(#function)
    }

    /// block 设置为不可用状态，但是并没有销毁相关环境
    func onBlockUnMount(context: OPBlockContext) {
        print(#function)
    }

    /// block 已经销毁
    func onBlockDestroy(context: OPBlockContext) {
        print(#function)
    }

    /// block 加载开始，当前时机为容器创建完成，开始网络请求
    func onBlockLoadStart(context: OPBlockContext) {
        print(#function)
    }

    /// block 配置解析完成
    /// - Parameter config: block 业务中的根目录 index.json 解析完成
    func onBlockConfigLoad(config: OPBlockProjectConfig, context: OPBlockContext) {
        print(#function)
    }

    /// block 启动成功
    func onBlockLaunchSuccess(context: OPBlockContext) {
        print(#function)
    }

    /// block 启动失败
    /// - Parameter error: 错误的信息，参照 OPBlockitMonitorCodeLaunch
    func onBlockLaunchFail(error: OPError, context: OPBlockContext) {
        print(#function)
    }

    /// block 暂停
    func onBlockPause(context: OPBlockContext) {
        print(#function)
    }

    /// block 重新运行
    func onBlockResume(context: OPBlockContext) {
        print(#function)
    }

    /// block 可见状态
    func onBlockShow(context: OPBlockContext) {
        print(#function)
    }

    /// block 不可见
    func onBlockHide(context: OPBlockContext) {
        print(#function)
    }

    /// block 异步请求的 meta & pkg 下载完成
    func onBlockUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext) {
        print(#function)
    }

    /// block 在 creator 模式下创建成功
    /// - Parameter info: block 对应的信息，使用该 info 即可以直接创建 block
    func onBlockCreatorSuccess(info: BlockInfo, context: OPBlockContext) {
        print(#function)
    }

    /// block 在 creator 模式下创建失败
    /// 可能是业务侧主动取消，并不见得发生错误，关于 error 还有待商榷
    func onBlockCreatorFailed(context: OPBlockContext) {
        print(#function)
    }
}

