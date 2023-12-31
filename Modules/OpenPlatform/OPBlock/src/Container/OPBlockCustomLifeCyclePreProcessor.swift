//
//  OPBlockCustomLifeCyclePreProcessor.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/8/18.
//

import Foundation
import OPBlockInterface
import ECOProbe

// block自定义生命周期预处理器，目前接收宿主vc显示与app前后台逻辑，以及block内部透传生命周期事件
class OPBlockCustomLifeCyclePreProcessor: OPBlockHostCustomLifeCycleTriggerProtocol,
										  OPBlockInternalCustomLifeCycleTriggerProtocol {
	// block 显示状态：宿主vc显示&&app前台才显示block
	enum OPBlockShowHideStatus: String {
		case allHide
		case appHide
		case hostHide
		case show
	}

	// block 显示触发事件
	enum OPBlockShowHideTrigger: String {
		case appEnterBackground
		case appEnterForeground
		case hostVCShow
		case hostVCHide
	}

	private weak var container: OPBlockContainer?
	private let trace: OPTrace
	private let showHideStateMachine = OPBlockStateMachine<OPBlockShowHideTrigger, OPBlockShowHideStatus>(initalStatus: .allHide)

	init(container: OPBlockContainer, trace: OPTrace) {
		self.container = container
		self.trace = trace
		registerTrigger()
		observeAppLifeCycleNotification()
	}

	func triggerBlockLifeCycle(_ trigger: OPBlockLifeCycleTriggerEvent) {
		trace.info("block internal trigger event \(trigger)")
		// 透传内部生命周期事件
		container?.lifeCycleStateMachine.transform(by: trigger)
		switch trigger {
		case .finishLoad:
			// 根据当前app状态，进行一次通知，确保onLoad后显示正确状态
			showHideStateMachine.transform(by: UIApplication.shared.applicationState == .background ? .appEnterBackground : .appEnterForeground)
		default:
			break
		}
	}

	func hostViewControllerDidAppear(_ appear: Bool) {
		trace.info("host trigger vc event, appear: \(appear)")
		showHideStateMachine.transform(by: appear ? .hostVCShow : .hostVCHide)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

}

extension OPBlockCustomLifeCyclePreProcessor {

	private func registerTrigger() {
		// 子状态满足后触发block真正的show, hide
		let showBlock = { [weak self] in
			self?.trace.info("change block status to show")
			self?.container?.lifeCycleStateMachine.transform(by: .show)
			return
		}
		let hideBlock = { [weak self] in
			self?.trace.info("change block status to hide")
			self?.container?.lifeCycleStateMachine.transform(by: .hide)
			return
		}
		// 注册内部showHide子状态流转, 处理block及宿主状态merge
		showHideStateMachine
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .appEnterBackground, from: .hostHide, to: .allHide))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .appEnterBackground, from: .show, to: .appHide, afterTransform: hideBlock))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .appEnterForeground, from: .allHide, to: .hostHide))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .appEnterForeground, from: .appHide, to: .show, afterTransform: showBlock))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .hostVCHide, from: .appHide, to: .allHide))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .hostVCHide, from: .show, to: .hostHide, afterTransform: hideBlock))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .hostVCShow, from: .allHide, to: .appHide))
			.register(Transformation<OPBlockShowHideTrigger, OPBlockShowHideStatus>(by: .hostVCShow, from: .hostHide, to: .show, afterTransform: showBlock))
	}

	// 监听app前后台，结合宿主前后台定义block onShow/onHide 生命周期事件
	private func observeAppLifeCycleNotification() {
		NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
											   object: nil,
											   queue: nil) { [weak self] _ in
			self?.showHideStateMachine.transform(by: .appEnterForeground)
		}
		NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
											   object: nil,
											   queue: nil) { [weak self] _ in
			self?.showHideStateMachine.transform(by: .appEnterBackground)
		}
	}

}
