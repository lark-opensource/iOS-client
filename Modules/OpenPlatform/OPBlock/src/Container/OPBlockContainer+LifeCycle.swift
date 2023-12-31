//
//  OPBlockContainer+LifeCycle.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/8/16.
//

import Foundation
import OPBlockInterface
import OPSDK

enum OPBlockLifeCycleStatus: String {
	case loading
	case onShow
	case onHide
	case onDestory
}

extension OPBlockContainer {
	func reigsterLifeCycleStatusTrigger() {
		// 触发显示，对于block container来说目前等同于blockit调用onshow
		let changeToShow: ()->Void = { [weak self] in
			self?.notifySlotShow()
		}
		// 触发隐藏，对于block container来说目前等同于blockit调用onHide
		let changeToHide: ()->Void = { [weak self] in
			self?.notifySlotHide()
		}
		// 触发销毁，对于block container来说目前等同于blockit调用unMountBlock
		let changeToDestory: ()->Void = { [weak self] in
			self?.unmount(monitorCode: OPBlockitMonitorCodeLaunch.cancel)
			self?.destroy(monitorCode: OPBlockitMonitorCodeLaunch.cancel)
		}

		lifeCycleStateMachine
			.register(Transformation<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>(by: .finishLoad, from: .loading, to: .onHide))
			.register(Transformation<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>(by: .show, from: .onHide, to: .onShow, afterTransform: changeToShow))
			.register(Transformation<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>(by: .hide, from: .onShow, to: .onHide, afterTransform: changeToHide))
			.register(Transformation<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>(by: .destory, from: .loading, to: .onDestory, afterTransform: changeToDestory))
			.register(Transformation<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>(by: .destory, from: .onShow, to: .onDestory, afterTransform: changeToDestory))
			.register(Transformation<OPBlockLifeCycleTriggerEvent, OPBlockLifeCycleStatus>(by: .destory, from: .onHide, to: .onDestory, afterTransform: changeToDestory))
		}
}
