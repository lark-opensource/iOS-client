//
//  OPTabGadgetTestViewController.swift
//  OPGadget
//
//  Created by yinyuan on 2020/11/27.
//

import Foundation
import OPSDK
import SnapKit
import LarkOPInterface
import OPGadget
import OPFoundation

@objcMembers
public class OPTabGadgetTestViewController: UIViewController {
    
    private lazy var containerViewController: UIViewController = {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        viewController.view.layer.cornerRadius = 5
        viewController.view.layer.masksToBounds = true
        return viewController
    }()
    
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
        container?.destroy(monitorCode: OPSDKMonitorCode.cancel)
    }
    
    private var container: OPContainerProtocol?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "嵌入式小程序 Test"
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        
        // 添加子VC
        addChild(containerViewController)
        view.addSubview(containerViewController.view)
        containerViewController.didMove(toParent: self)
        containerViewController.view.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview().offset(-20)
            maker.height.equalTo(200)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(10)
        }
        
        view.addSubview(outputTextArea)
        outputTextArea.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview().offset(-20)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(containerViewController.view.snp.bottom).offset(10)
            maker.bottom.equalToSuperview().offset(-20)
        }
        
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: #selector(testActions(_:)))
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        setupGadget()
    }
    
    func setupGadget() {

        let uniqueID = OPAppUniqueID(appID: "cli_9cb844403dbb9108", identifier: nil, versionType: .current, appType: .gadget, instanceID: "main_tab")
        
        let application = OPApplicationService.current.getApplication(appID: uniqueID.appID) ?? OPApplicationService.current.createApplication(appID: uniqueID.appID)
        
        let container = application.createContainer(
            uniqueID: uniqueID,
            containerConfig: OPGadgetContainerConfig(previewToken: nil, enableAutoDestroy: false))
        
        let renderSlot = OPChildControllerRenderSlot(
            parentViewController: containerViewController,
            defaultHidden: false)
        renderSlot.delegate = self
        
        container.addLifeCycleDelegate(delegate: self)

        container.mount(
            data: OPGadgetContainerMountData(scene: .mainTab, startPage: nil),
            renderSlot: renderSlot
        )
        
        self.container = container
        
    }
    
    @objc
    func testActions(_ sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Show Gadget container", style: .default, handler: { (action) in
            self.containerViewController.view.isHidden = false
            self.container?.notifySlotShow()
        }))
        alert.addAction(UIAlertAction(title: "Hide Gadget container", style: .default, handler: { (action) in
            self.containerViewController.view.isHidden = true
            self.container?.notifySlotHide()
        }))
        alert.addAction(UIAlertAction(title: "Unmount Gadget", style: .default, handler: { (action) in
            self.container?.unmount(monitorCode: OPSDKMonitorCode.cancel)
        }))
        alert.addAction(UIAlertAction(title: "(Re)Mount Gadget", style: .default, handler: { (action) in
            let renderSlot = OPChildControllerRenderSlot(
                parentViewController: self.containerViewController,
                defaultHidden: false)
            renderSlot.delegate = self
            
            self.container?.mount(
                data: OPGadgetContainerMountData(scene: .mainTab, startPage: nil),
                renderSlot: renderSlot
            )
        }))
        alert.addAction(UIAlertAction(title: "Destroy Gadget", style: .default, handler: { (action) in
            self.container?.destroy(monitorCode: OPSDKMonitorCode.cancel)
        }))
        alert.addAction(UIAlertAction(title: "Reload(same Gadget)", style: .default, handler: { (action) in
            self.container?.reload(monitorCode: OPSDKMonitorCode.cancel)
        }))
        alert.addAction(UIAlertAction(title: "Rebuild(new Gadget)", style: .default, handler: { (action) in
            
            self.container?.destroy(monitorCode: OPSDKMonitorCode.cancel)
            self.container = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setupGadget()
            }
        }))
        alert.addAction(UIAlertAction(title: "Resize Gadget container", style: .default, handler: { (action) in
            if self.containerViewController.view.frame.height == 200 {
                self.containerViewController.view.snp.updateConstraints { (maker) in
                    maker.height.equalTo(300)
                    maker.width.equalToSuperview().offset(-20)
                }
            } else if self.containerViewController.view.frame.height == 300 {
                self.containerViewController.view.snp.updateConstraints { (maker) in
                    maker.height.equalTo(250)
                    maker.width.equalToSuperview().offset(-150)
                }
            } else {
                self.containerViewController.view.snp.updateConstraints { (maker) in
                    maker.height.equalTo(200)
                    maker.width.equalToSuperview().offset(-20)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Invoke API", style: .default, handler: { (action) in
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            self.apiList.forEach { (api) in
                guard let apiName = api.first?.key, let params = api.first?.value else {
                    return
                }
                alert.addAction(UIAlertAction(title: apiName, style: .default, handler: { (action) in
                    let apiContext = OPEventContext(
                        userInfo: [:]
                    )
                    _ = self.container?.sendEvent(
                        eventName: apiName,
                        params: params,
                        callbackBlock: { (result) in
                            self.print("api:\(apiName) result:\(result)")
                        },
                        context: apiContext
                    )
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                
            }))
            self.present(alert, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private var apiList = [
        ["showModal": ["title": "测试标题", "content": "测试内容", "confirmText": "测试确认"]],
        ["showToast": ["title": "这是一个Toast"]],
        ["hideToast": [:]],
        ["login": [:]],
        ["getUserInfo": [:]],
        ["enterProfile": ["openid": ""]],
        ["openSchema": [
            "schema": "https://applink.feishu.cn/client/mini_program/open?appId=cli_9c21a4767c305107",
            "external": "true"]],
        ["chooseChat": [:]],
        ["chooseContact": [:]],
        ["chooseImage": [:]],
        ["docsPicker": [:]],
        ["createRequestTask": ["url":"https://bytedance.com/"]],
        ["operateRequestTask": ["url":"https://bytedance.com/"]],
        ["createSocketTask": [:]],
        ["operateSocketTask": [:]]
    ]
    
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

extension OPTabGadgetTestViewController: OPRenderSlotDelegate {
    public func onRenderAttatched(renderSlot: OPRenderSlotProtocol) {
        
    }
    
    public func onRenderRemoved(renderSlot: OPRenderSlotProtocol) {
        
    }
    
    public func currentViewControllerForPresent() -> UIViewController? {
        return self
    }
    
    public func currentNavigationControllerForPush() -> UINavigationController? {
        return self.navigationController
    }
}

extension OPTabGadgetTestViewController: OPContainerLifeCycleDelegate {
    
    public func containerDidLoad(container: OPContainerProtocol) {
       print("LifeCycle:containerDidLoad")
    }
    
    public func containerDidReady(container: OPContainerProtocol) {
        print("LifeCycle:containerDidReady")
    }
    
    public func containerDidFail(container: OPContainerProtocol, error: OPError) {
        print("LifeCycle:containerDidFail \(error)")
    }
    
    public func containerDidUnload(container: OPContainerProtocol) {
        print("LifeCycle:containerDidUnload")
    }
    
    public func containerDidDestroy(container: OPContainerProtocol) {
        print("LifeCycle:containerDidDestroy")
    }
    
    public func containerDidShow(container: OPContainerProtocol) {
        print("LifeCycle:containerDidShow")
    }
    
    public func containerDidHide(container: OPContainerProtocol) {
        print("LifeCycle:containerDidHide")
    }
    
    public func containerDidPause(container: OPContainerProtocol) {
        print("LifeCycle:containerDidPause")
    }
    
    public func containerDidResume(container: OPContainerProtocol) {
        print("LifeCycle:containerDidResume")
    }
    
    public func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig) {
        print("LifeCycle:containerConfigDidLoad")
    }
    
}

