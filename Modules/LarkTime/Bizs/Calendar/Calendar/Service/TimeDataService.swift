//
//  TimeDataService.swift
//  Calendar
//
//  Created by JackZhao on 2023/11/13.
//

import RustPB
import RxSwift
import RxRelay
import Foundation
import CTFoundation
import LarkRichTextCore
import LKCommonsLogging
import CalendarFoundation
import UniverseDesignIcon
import LarkTimeFormatUtils

// 数据拉取策略
enum TimeDataFetchStrategy {
    case coldLaunch
    case normal
    case forceFetch
}

// 数据拉取场景
enum TimeDataFetchScene: String {
    case nonAllDay
    case allDay
    case list
    case month
}

// 数据拉取结果
enum TimeDataFetchResult {
    case all
    case part
    case none
}

protocol TimeDataService: AnyObject {
    var rxTimeBlocksChange: Observable<Void> { get }
    
    // 时间容器变更通知
    var timeContainerChanged: PublishRelay<Void> { get }

    func getTimeBlockDataBy(range: JulianDayRange,
                            timezone: TimeZone,
                            scene: TimeDataFetchScene) -> (TimeBlockModelMap, TimeDataFetchResult)

    func fetchTimeBlockDataBy(range: JulianDayRange,
                              timezone: TimeZone,
                              strategy: TimeDataFetchStrategy,
                              scene: TimeDataFetchScene) -> Observable<[JulianDay : [TimeBlockModel]]>
    
    func fetchTimeBlockDataBy(range: JulianDayRange,
                              timezone: TimeZone,
                              scene: TimeDataFetchScene) -> Observable<[JulianDay : [TimeBlockModel]]>

    func fetchTimeBlockById(_ id: String, 
                            containerIDOnDisplay: String,
                            timezone: TimeZone) -> Observable<TimeBlock>

    func patchTimeBlock(id: String,
                        containerIDOnDisplay: String,
                        startTime: Int64?,
                        endTime: Int64?,
                        actionType: UpdateTimeBlockActionType) -> Observable<Void>
    
    // 获取当前用户的时间容器
    func getTimeContainers() -> [TimeContainerModel]
    
    // 同步当前用户的时间容器，并缓存，发送变更通知，业务方通过 GetTimeContainers 来获取最新时间容器数据，不可在 timeContainerChanged 监听里调用，避免循环
    @discardableResult
    func fetchTimeContainers() -> Observable<Void>

    // 更新时间容器配置
    func updateTimeContainerInfo(id: String, isVisibile: Bool?, colorIndex: ColorIndex?) -> Observable<Void>
    
    // 仅勾选此时间容器
    func specifyVisibleOnlyTimeContainer(with id: String) -> Observable<Void>

    // 点击进入详情页，路由到任务body
    func enterDetail(from: UIViewController, id: String)

    // 可点击icon被点击
    func tapIconTapped(model: BlockDataProtocol, isCompleted: Bool, from: UIViewController)
    
    func prepareDiskData(firstScreenDayRange: JulianDayRange)
    
    func forceUpdateTimeBlockData()
}

public protocol TimeBlockDependency {
    func openTaskPage(from: UIViewController, id: String)
}

protocol TimeBlockAPI {
    func patchTimeBlock(id: String,
                        containerIDOnDisplay: String,
                        startTime: Int64?,
                        endTime: Int64?,
                        actionType: UpdateTimeBlockActionType) -> Observable<UpdateTimeBlockTimeRangeResponse> //修改时间
    
    //获取当前用户给定范围的时间块
    func fetchTimeBlock(startTime: Int64, endTime: Int64, timezone: String, needContainer: Bool) -> Observable<GetTimeBlocksWithTimeRangeResponse>
    
    func fetchTimeBlockById(_ id: String,
                            containerIDOnDisplay: String,
                            timezone: TimeZone) -> Observable<TimeBlockWithIDResponse>

    // 可点击icon被点击
    func finishTask(id: String, containerIDOnDisplay: String, isCompleted: Bool) -> Observable<CompleteTaskBlockWithIDInTimeContainerResponse>
}
    
protocol TimeContainerAPI {
    /// 获取用户所有时间容器
    func fetchTimeContainers() -> Observable<GetAllTimeContainersResponse>
    /// 更新时间容器配置
    func updateTimeContainerInfo(id: String, isVisibile: Bool?, colorIndex: ColorIndex?) -> Observable<Calendar_V1_UpdateTimeContainerInfoResponse>
    /// 仅勾选此时间容器
    func specifyVisibleOnlyTimeContainer(with id: String) -> Observable<Calendar_V1_SpecifyVisibleOnlyTimeContainerResponse>
}

// MARK: alias
typealias UpdateTimeBlockTimeRangeResponse = RustPB.Calendar_V1_UpdateTimeBlockTimeRangeResponse
typealias GetTimeBlocksWithTimeRangeResponse = RustPB.Calendar_V1_GetTimeBlocksWithTimeRangeResponse
typealias CompleteTaskBlockWithIDInTimeContainerResponse = RustPB.Calendar_V1_CompleteTaskBlockWithIDInTimeContainerResponse
typealias UpdateTimeBlockActionType = RustPB.Calendar_V1_UpdateTimeBlockTimeRangeRequest.ActionType
typealias TimeBlock = RustPB.Calendar_V1_TimeBlock
typealias TimeBlockModelMap = [JulianDay: [TimeBlockModel]]
typealias TimeContainerSaveInfo = RustPB.Calendar_V1_UpdateTimeContainerInfoRequest.TimeContainerSaveInfo
typealias TimeContainer = RustPB.Calendar_V1_TimeContainer
typealias UpdateTimeContainerInfoResponse = RustPB.Calendar_V1_UpdateTimeContainerInfoResponse
typealias GetAllTimeContainersResponse = RustPB.Calendar_V1_GetAllTimeContainersResponse
typealias TimeBlockWithIDResponse = RustPB.Calendar_V1_GetTimeBlockWithIDResponse

// MARK: - TimeContaienr

// 时间容器日志
struct TimeContainerLogger {
    static let logger = Logger.log(CalendarList.self, category: "lark.calendar.time_container")

    static func info(_ message: String) {
        logger.info(message)
    }

    static func error(_ message: String) {
        logger.error(message)
    }

    static func warn(_ message: String) {
        logger.warn(message)
    }

    static func debug(_ message: String) {
        logger.debug(message)
    }
}
