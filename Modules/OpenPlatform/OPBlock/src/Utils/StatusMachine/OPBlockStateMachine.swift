//
//  StateMachine.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/8/15.
//

import Foundation
import LKCommonsLogging

// 一套通用的状态机管理器，方便后续扩展block生命周期相关的状态
public final class OPBlockStateMachine<Trigger, Status> where Trigger: Hashable, Status: Hashable {
	
	private let logger = Logger.log(OPBlockContainer.self, category: "OPBlockStateMachine")
	
	// 注册的状态转换流程
	private var validTransformations: [Trigger: [Transformation<Trigger, Status>]] = [:]
	
	// 状态机当前状态
	public private(set) var currentStatus: Status
	
	public init(initalStatus: Status) {
		self.currentStatus = initalStatus
	}
	
	// 注册各触发器对应的状态转换，支持链式调用
	@discardableResult
	public func register(_ transformation: Transformation<Trigger, Status>) -> OPBlockStateMachine<Trigger, Status> {
		objc_sync_enter(validTransformations)
		defer {
			objc_sync_exit(validTransformations)
		}
		let trigger = transformation.trigger
		var transformations = validTransformations[trigger] ?? []
		if let trans = transformations.first(where: { $0.from == transformation.from }) {
			logger.error("trigger \(trigger) already exist from \(trans.from) to \(trans.to)")
			assertionFailure("already has trigger \(trans.trigger) from status \(trans.from) to status \(trans.to)")
			return self
		}
		transformations.append(transformation)
		validTransformations[trigger] = transformations
		return self
	}
	
	// 收到触发时间，转换状态
	@discardableResult
	public func transform(by trigger: Trigger) -> (Bool, Status){
		objc_sync_enter(self)
		defer {
			objc_sync_exit(self)
		}
		guard let transformations = validTransformations[trigger] else {
			logger.error("trigger \(trigger) not exist")
			return (false, currentStatus)
		}
		guard let transformation = transformations.first(where: { $0.from == currentStatus }) else {
			logger.error("trigger \(trigger) invalid for current status \(currentStatus)")
			return (false, currentStatus)
		}
		transformation.beforeTransform?()
		currentStatus = transformation.to
		transformation.afterTransform?()
		logger.info("transform status success by trigger \(trigger) from \(transformation.from) to \(transformation.to)")
		return (true, currentStatus)
	}
}

public struct Transformation<Trigger, Status> where Trigger: Hashable, Status: Hashable {
	
	public let trigger: Trigger
	
	public let from: Status
	
	public let to: Status
	
	public var beforeTransform: (() -> Void)?
	
	public var afterTransform: (() -> Void)?

	public init(by trigger: Trigger,
		 from: Status,
		 to: Status,
		 beforeTransform: (() -> Void)? = nil,
		 afterTransform: (() -> Void)? = nil) {
		self.trigger = trigger
		self.from = from
		self.to = to
		self.beforeTransform = beforeTransform
		self.afterTransform = afterTransform
	}
	
}
