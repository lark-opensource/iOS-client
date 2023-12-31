//
//  TimeDataServiceImpl+Action.swift
//  Calendar
//
//  Created by JackZhao on 2023/12/15.
//

import RxRelay
import RxSwift
import Foundation
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast

extension TimeDataServiceImpl {
    //修改时间
    func patchTimeBlock(id: String,
                        containerIDOnDisplay: String,
                        startTime: Int64?,
                        endTime: Int64?,
                        actionType: UpdateTimeBlockActionType) -> Observable<Void> {
        Self.logger.info("patchTimeBlock id = \(id) startTime = \(startTime ?? 0) endTime = \(endTime ?? 0) actionType = \(actionType)")
        return self.timeBlockAPI?.patchTimeBlock(id: id,
                                          containerIDOnDisplay: containerIDOnDisplay,
                                          startTime: startTime,
                                          endTime: endTime,
                                          actionType: actionType).map { _ in } ?? .empty()
    }
    
    // 点击进入详情页，路由到任务body
    func enterDetail(from: UIViewController, id: String) {
        Self.logger.info("enterDetail id = \(id)")
        dependency?.openTaskPage(from: from, id: id)
    }
    
    func tapIconTapped(model: BlockDataProtocol, isCompleted: Bool, from: UIViewController) {
        Self.logger.info("finishTask start, id = \(model.id) isCompleted = \(isCompleted)")
        CalendarTracerV2.CalendarMain.normalTrackClick {
            var map = [String: Any]()
            map["click"] = isCompleted ? "complete_task" : "cancel_complete_task"
            if let timeBlock = model as? TimeBlockModel {
                map["task_id"] = timeBlock.taskId
            }
            return map
        }
        model.process { type in
            guard case .timeBlock(let timeBlockModel) = type else {
                assertionFailure("now not support")
                return
            }
            let toast = isCompleted ? I18n.Calendar_G_ThisTaskComplete_Toast : I18n.Calendar_G_OkCanceled_Toast
            timeBlockAPI?.finishTask(id: timeBlockModel.id,
                                     containerIDOnDisplay: timeBlockModel.containerIDOnDisplay,
                                     isCompleted: isCompleted)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak from] _ in
                    guard let view = from?.view else { return }
                    Self.logger.info("finishTask success, id =\(timeBlockModel.id)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UDToast.showSuccess(with: toast, on: view)
                    }
                }, onError: { [weak from] error in
                    guard let view = from?.view else { return }
                    Self.logger.error("finishTask error, id =\(timeBlockModel.id)", error: error)
                    UDToast.showFailure(with: error.getTitle() ?? I18n.Calendar_G_SomethingWentWrong, on: view)
                }).disposed(by: bag)
        }
    }
}
