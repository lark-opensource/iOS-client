//
//  PolicyEngineEventDebugViewController.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/3.
//

import UIKit
import LarkPolicyEngine
import LarkSecurityComplianceInfra
import SnapKit
import EENavigator
import LarkContainer

final class PolicyEngineDebugEventRecorder: LarkPolicyEngine.Observer {
    static let shared = PolicyEngineDebugEventRecorder()
    
    var updateEvent: (() -> Void)?
    
    var recording = false
    var eventList = [(Date, Event)]()
    
    func notify(event: Event) {
        if recording {
            DispatchQueue.main.async { [weak self] in
                self?.eventList.append((Date(), event))
                self?.updateEvent?()
            }
        }
    }
}

final class PolicyEngineEventDebugViewController: UIViewController {

    let eventLogTextView = SCDebugTextView()
    
    let userResolver: UserResolver
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //register event observer
        let policyEngine = try? userResolver.resolve(assert: PolicyEngineService.self)
        
        policyEngine?.register(observer: PolicyEngineDebugEventRecorder.shared)
        
        buildView()
        
        PolicyEngineDebugEventRecorder.shared.updateEvent = { [weak self] in
            self?.eventLogTextView.text = PolicyEngineDebugEventRecorder.shared.eventList.reduce("", { partialResult, event in
                return partialResult + "\(event.0.dateTimeString())- \(event.0.unixTimestamp)-- Event Name: \(event.1)\n"
            })
        }
    }
    
    func buildView() {
        view.backgroundColor = .gray
        //event log view
        eventLogTextView.isEditable = false
        eventLogTextView.layer.cornerRadius = 4
        eventLogTextView.layer.shadowColor = UIColor.gray.cgColor
        eventLogTextView.layer.shadowRadius = 2
        eventLogTextView.layer.shadowOpacity = 1
        eventLogTextView.layer.shadowOffset = CGSize(width: 1, height: 1)
        eventLogTextView.backgroundColor = .white
        view.addSubview(eventLogTextView)
        eventLogTextView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin)
            make.left.right.equalToSuperview().inset(5)
        }
        
        let sendEventBtn = UIButton()
        sendEventBtn.setTitle("发送事件", for: .normal)
        sendEventBtn.layer.borderColor = UIColor.gray.cgColor
        sendEventBtn.layer.borderWidth = 2
        sendEventBtn.layer.cornerRadius = 4
        sendEventBtn.backgroundColor = .greenSea
        sendEventBtn.addTarget(self, action: #selector(didClickSendEventBtn), for: .touchUpInside)
        view.addSubview(sendEventBtn)
        sendEventBtn.snp.makeConstraints { make in
            make.top.equalTo(eventLogTextView.snp.bottom).offset(10)
            make.bottom.equalTo(view.snp.bottomMargin)
            make.left.right.equalToSuperview().inset(5)
            make.height.equalTo(40)
        }
        
        updateListenItem()
        
    }
    
    @objc
    private func didClickSendEventBtn() {
        guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
        let dialog = UIAlertController(title: "发送事件", message: nil, preferredStyle: .actionSheet)
        dialog.addAction(UIAlertAction(title: "策略定时拉取事件", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let policyEngineService = try? self.userResolver.resolve(assert: PolicyEngineService.self)
            policyEngineService?.postEvent(event: .timerEvent)
        }))
        dialog.addAction(UIAlertAction(title: "取消", style: .cancel))
        Navigator.shared.present(dialog, from: fromVC)
    }
    
    func updateListenItem() {
        if PolicyEngineDebugEventRecorder.shared.recording {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(didClickStopListen))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(didClickStartListen))
        }
    }
    
    @objc
    private func didClickStartListen() {
        PolicyEngineDebugEventRecorder.shared.recording = true
        updateListenItem()
    }
    
    @objc
    private func didClickStopListen() {
        PolicyEngineDebugEventRecorder.shared.recording = false
        updateListenItem()
    }
}
