//
//  BDPPreloadHnadlerMangerTests.swift
//  TTMicroApp-Unit-Tests
//
//  Created by laisanpin on 2022/11/2.
//

import Foundation
import XCTest
import OPSDK

@testable import TTMicroApp

class MockBizMeta: OPBizMetaProtocol {
    var uniqueID: OPAppUniqueID

    var appVersion: String = ""

    func toJson() throws -> String {
        return "MockBizMeta"
    }

    var appID: String = ""

    var appName: String = ""

    var applicationVersion: String = ""

    var appIconUrl: String = ""

    var openSchemas: [Any]? = nil

    var useOpenSchemas: Bool? = false

    var botID: String = ""

    var canFeedBack: Bool = false

    var shareLevel: Int = 0

    init(_ uniqueID: OPAppUniqueID) {
        self.uniqueID = uniqueID
    }
}

class MockPackageBusinessData: TTMicroApp.AppMetaPackageProtocol, TTMicroApp.AppMetaAuthProtocol, TTMicroApp.AppMetaBusinessDataProtocol {
    var urls: [URL] = []
    var md5: String = ""
}

class MockBizAndAppMeta: OPBizMetaProtocol, AppMetaProtocol {
    var uniqueID: OPAppUniqueID

    var appVersion: String = ""

    func toJson() throws -> String {
        return "MockBizAndAppMeta"
    }

    var version: String = ""

    var name: String = ""

    var iconUrl: String = ""

    var packageData: TTMicroApp.AppMetaPackageProtocol = MockPackageBusinessData()

    var authData: TTMicroApp.AppMetaAuthProtocol = MockPackageBusinessData()

    var businessData: TTMicroApp.AppMetaBusinessDataProtocol = MockPackageBusinessData()

    var appID: String = ""

    var appName: String = ""

    var applicationVersion: String = ""

    var appIconUrl: String = ""

    var openSchemas: [Any]? = nil

    var useOpenSchemas: Bool? = false

    var botID: String = ""

    var canFeedBack: Bool = false

    var shareLevel: Int = 0

    init(_ uniqueID: OPAppUniqueID) {
        self.uniqueID = uniqueID
    }
}

class MockPackageModule: NSObject, BDPPackageModuleProtocol {
    var moduleManager: BDPModuleManager?

    var pkgDownloadError: OPError?

    public var fileReader: BDPPkgFileManagerHandleProtocol?

    func getSDKVersion(withContext context: BDPPluginContext) -> String {
        return ""
    }

    func getSDKUpdateVersion(withContext context: BDPPluginContext) -> String {
        return ""
    }

    func getAppVersion(withContext context: BDPPluginContext) -> String {
        return "1.0.0"
    }

    var packageInfoManager: BDPPackageInfoManagerProtocol {
        return BDPPackageInfoManager(appType: .gadget)
    }

    func checkLocalOrDownloadPackage(with context: BDPPackageContext, localCompleted localCompletedBlock: ((BDPPkgFileManagerHandleProtocol) -> Void)?, downloadPriority: Float, downloadBegun downloadBegunBlock: BDPPackageDownloaderBegunBlock?, downloadProgress downloadProgressBlock: BDPPackageDownloaderProgressBlock?, downloadCompleted downloadCompletedBlock: BDPPackageDownloaderCompletedBlock? = nil) {

    }

    func fetchSubPackage(with context: BDPPackageContext, localCompleted localCompletedBlock: ((BDPPkgFileManagerHandleProtocol) -> Void)?, downloadPriority: Float, downloadBegun downloadBegunBlock: BDPPackageDownloaderBegunBlock?, downloadProgress downloadProgressBlock: BDPPackageDownloaderProgressBlock?, downloadCompleted downloadCompletedBlock: BDPPackageDownloaderCompletedBlock? = nil) {

    }

    func checkLocalPackageReader(with context: BDPPackageContext) -> BDPPkgFileManagerHandleProtocol? {
        return nil
    }

    func predownloadPackage(with context: BDPPackageContext, priority: Float, begun begunBlock: BDPPackageDownloaderBegunBlock?, progress progressBlock: BDPPackageDownloaderProgressBlock?, completed completedBlock: BDPPackageDownloaderCompletedBlock? = nil) {
        if let downloadError = pkgDownloadError {
            completedBlock?(downloadError, false, fileReader)
        } else {
            completedBlock?(nil, false, fileReader)
        }
    }

    func normalLoadPackage(with context: BDPPackageContext, priority: Float, begun begunBlock: BDPPackageDownloaderBegunBlock?, progress progressBlock: BDPPackageDownloaderProgressBlock?, completed completedBlock: BDPPackageDownloaderCompletedBlock? = nil) {

    }

    func asyncDownloadPackage(with context: BDPPackageContext, priority: Float, begun begunBlock: BDPPackageDownloaderBegunBlock?, progress progressBlock: BDPPackageDownloaderProgressBlock?, completed completedBlock: BDPPackageDownloaderCompletedBlock? = nil) {

    }

    func stopDownloadPackage(with context: BDPPackageContext) throws {

    }

    func isLocalPackageExsit(_ context: BDPPackageContext) -> Bool {
        return false
    }

    func deleteLocalPackage(with context: BDPPackageContext) throws {

    }

    func deleteAllLocalPackages(with uniqueID: OPAppUniqueID) throws {

    }

    func closeDBQueue() {

    }
}

class MockPreloadHandleInjector: BDPPreloadHandleInjector {
    var injectorMeta: OPBizMetaProtocol?

    let shouldIntercept: Bool

    init(shouldIntercept: Bool) {
        self.shouldIntercept = shouldIntercept
    }

    func onInjectMeta(uniqueID: OPAppUniqueID, handleInfo: BDPPreloadHandleInfo) -> OPBizMetaProtocol? {
        return injectorMeta
    }

    func onInjectInterceptor(scene: BDPPreloadScene, handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        if shouldIntercept {
            let commonInterceptor: BDPPreHandleInterceptor = { _ in
                return BDPInterceptorResponse(intercepted: false)
            }

            let interceptor: BDPPreHandleInterceptor = { _ in
                return BDPInterceptorResponse(intercepted: true)
            }
            return [interceptor, commonInterceptor]
        } else {
            return nil
        }
    }
}

class BDPPreloadHandlerManagerTests: XCTestCase {
    let appLaunchHandleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget), scene: .AppLaunch, scheduleType: .toBeScheduled)

    let silencePushHandleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget), scene: .SilenceUpdatePush, scheduleType: .directHandle)

    let preloadPushHandleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_3", identifier: nil, versionType: .current, appType: .gadget), scene: .PreloadPush, scheduleType: .toBeScheduled)

    let silencePullHandleInfo =
        BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_4", identifier: nil, versionType: .current, appType: .gadget), scene: .SilenceUpdatePull, scheduleType: .directHandle)

    let preloadPullHandleInfo =
        BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_5", identifier: nil, versionType: .current, appType: .gadget), scene: .PreloadPull, scheduleType: .toBeScheduled)

    let metaExpiredHandleInfo =
        BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_6", identifier: nil, versionType: .current, appType: .gadget), scene: .MetaExpired, scheduleType: .toBeScheduled)

    let blockPreloadPullHandleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_block_1", identifier: "block_1", versionType: .current, appType: .block), scene: .PreloadPull, scheduleType: .toBeScheduled)

    let blockMetaExpiredHandleInfo = BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_block_2", identifier: "block_2", versionType: .current, appType: .block), scene: .MetaExpired, scheduleType: .toBeScheduled)

    // MARK: insertTasksV2 TestCases
    func test_insertTasks_needInsertTasks() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let insertTasks = [appLaunchHandleInfo,
                           silencePushHandleInfo,
                           silencePullHandleInfo,
                           preloadPushHandleInfo,
                           preloadPullHandleInfo,
                           metaExpiredHandleInfo]
            .map {
                BDPPreloadInfoTask(handleInfo: $0)
            }

        // Act
        let needInsertTasks = prehandleManager.insertTasksV2(taskInfoList: insertTasks)

        // Assert
        XCTAssertEqual(insertTasks.count, needInsertTasks.count)
    }

    func test_insertTasks_directTasksOrder() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let insertTasks = [appLaunchHandleInfo,
                           silencePushHandleInfo,
                           silencePullHandleInfo,
                           preloadPushHandleInfo,
                           preloadPullHandleInfo,
                           metaExpiredHandleInfo]
            .map {
                BDPPreloadInfoTask(handleInfo: $0)
            }

        // Act
        let _ = prehandleManager.insertTasksV2(taskInfoList: insertTasks)

        // Assert
        guard let directHandleTasks = prehandleManager.taskListMap[.gadget]?[.directHandle] else {
            throw XCTSkip("directHandle taskList is nil")
        }

        let direHandleTasksOrders = directHandleTasks.map({ $0.handleInfo.uniqueID.appID })
        let expectOrder = [silencePushHandleInfo, silencePullHandleInfo].map({ $0.uniqueID.appID })

        XCTAssertEqual(direHandleTasksOrders, expectOrder)
    }

    func test_insertTasks_gadgetScheduleTasksOrder() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let insertGadgetTasksPartOne = [appLaunchHandleInfo,
                                        preloadPullHandleInfo,
                                        metaExpiredHandleInfo]
            .map {
                BDPPreloadInfoTask(handleInfo: $0)
            }

        let insertGadgetTasksPartTwo = [silencePushHandleInfo,
                                        silencePullHandleInfo,
                                        preloadPushHandleInfo].map {
            BDPPreloadInfoTask(handleInfo: $0)
        }

        let insertBlockTasks = [blockMetaExpiredHandleInfo, blockPreloadPullHandleInfo].map {
            BDPPreloadInfoTask(handleInfo: $0)
        }

        // Act
        let _ = prehandleManager.insertTasksV2(taskInfoList: insertGadgetTasksPartOne)
        let _ = prehandleManager.insertTasksV2(taskInfoList: insertBlockTasks)
        let _ = prehandleManager.insertTasksV2(taskInfoList: insertGadgetTasksPartTwo)

        //Assert
        guard let scheduleHandleTasks = prehandleManager.taskListMap[.gadget]?[.toBeScheduled] else {
            throw XCTSkip("scheduleHandleTasks taskList is nil")
        }

        let scheduleTasksOrder = scheduleHandleTasks.map({ $0.handleInfo.uniqueID.appID })
        let expectOrder = [appLaunchHandleInfo,
                           preloadPushHandleInfo,
                           preloadPullHandleInfo,
                           metaExpiredHandleInfo].map({ $0.uniqueID.appID })

        XCTAssertEqual(scheduleTasksOrder, expectOrder)
    }

    func test_insertTasks_blockScheduleTasksOrder() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let insertGadgetTasks = [appLaunchHandleInfo,
                                 silencePushHandleInfo,
                                 silencePullHandleInfo,
                                 preloadPushHandleInfo,
                                 preloadPullHandleInfo,
                                 metaExpiredHandleInfo]
            .map {
                BDPPreloadInfoTask(handleInfo: $0)
            }

        let insertBlockTasks = [blockMetaExpiredHandleInfo, blockPreloadPullHandleInfo].map {
            BDPPreloadInfoTask(handleInfo: $0)
        }

        // Act
        let _ = prehandleManager.insertTasksV2(taskInfoList: insertGadgetTasks)
        let _ = prehandleManager.insertTasksV2(taskInfoList: insertBlockTasks)

        //Assert
        guard let scheduleHandleTasks = prehandleManager.taskListMap[.block]?[.toBeScheduled] else {
            throw XCTSkip("scheduleHandleTasks taskList is nil")
        }

        let scheduleTasksOrder = scheduleHandleTasks.map({ $0.handleInfo.uniqueID.fullString })
        let expectOrder = [blockPreloadPullHandleInfo,
                           blockMetaExpiredHandleInfo].map({ $0.uniqueID.fullString })

        XCTAssertEqual(scheduleTasksOrder, expectOrder)
    }

    // MARK: insertAndReorderTask TestCases
    func test_insertAndReorderTask_output() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let insertTasks = [appLaunchHandleInfo,
                           silencePushHandleInfo,
                           silencePullHandleInfo,
                           preloadPushHandleInfo,
                           preloadPullHandleInfo,
                           metaExpiredHandleInfo]
            .map {
                BDPPreloadInfoTask(handleInfo: $0)
            }

        let currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.directHandle : [
                    BDPPreloadInfoTask(handleInfo:BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget), scene: .SilenceUpdatePush, scheduleType: .directHandle))
                ],
                BDPPreloadScheduleType.toBeScheduled : [
                    BDPPreloadInfoTask(handleInfo: BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_3", identifier: nil, versionType: .current, appType: .gadget), scene: .MetaExpired, scheduleType: .toBeScheduled)),
                    BDPPreloadInfoTask(handleInfo: BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_6", identifier: nil, versionType: .current, appType: .gadget), scene: .MetaExpired, scheduleType: .toBeScheduled))
                ]
            ]
        ]

        // Act
        var needInsertTasks = [BDPPreloadInfoTask]()
        for taskInfo in insertTasks {
            prehandleManager.insertAndReorderTask(taskInfo: taskInfo, taskListMap: currentTaskListMap) { taskInfo, needAppend, sortedTasks in
                if needAppend {
                    needInsertTasks.append(taskInfo)
                }
            }
        }

        // Assert
        XCTAssertEqual(needInsertTasks.count, 3)
    }

    func test_insertAndReorderTask_direct_reorder() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let insertTasks = [silencePushHandleInfo, preloadPullHandleInfo, metaExpiredHandleInfo].map {
            BDPPreloadInfoTask(handleInfo: $0)
        }

        var currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.directHandle : [
                    BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)
                ],
                BDPPreloadScheduleType.toBeScheduled : [
                    BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo),
                    BDPPreloadInfoTask(handleInfo: preloadPushHandleInfo)
                ]
            ]
        ]

        // Act
        for task in insertTasks {
            prehandleManager.insertAndReorderTask(taskInfo: task, taskListMap: currentTaskListMap) { taskInfo, needAppend, sortedTasks in
                let handleInfo = taskInfo.handleInfo
                var taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = currentTaskListMap[handleInfo.uniqueID.appType] ?? [:]
                taskListMapWithScheduleType[handleInfo.scheduleType] = sortedTasks
                currentTaskListMap[handleInfo.uniqueID.appType] = taskListMapWithScheduleType
            }
        }

        // Assert
        if let directHandleTasks = currentTaskListMap[.gadget]?[.directHandle] {
            XCTAssertEqual(directHandleTasks.map({
                $0.handleInfo.uniqueID.appID
            }), [silencePushHandleInfo.uniqueID.appID, silencePullHandleInfo.uniqueID.appID])
        } else {
            throw XCTSkip("can not get directHandleTasks")
        }
    }

    func test_insertAndReorderTask_schedule_reorder() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let insertTasks = [silencePushHandleInfo, preloadPullHandleInfo, appLaunchHandleInfo].map {
            BDPPreloadInfoTask(handleInfo: $0)
        }

        var currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.directHandle : [
                    BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)
                ],
                BDPPreloadScheduleType.toBeScheduled : [
                    BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo),
                    BDPPreloadInfoTask(handleInfo: preloadPushHandleInfo)
                ]
            ]
        ]

        // Act
        for task in insertTasks {
            prehandleManager.insertAndReorderTask(taskInfo: task, taskListMap: currentTaskListMap) { taskInfo, needAppend, sortedTasks in
                let handleInfo = taskInfo.handleInfo
                var taskListMapWithScheduleType: [BDPPreloadScheduleType: [BDPPreloadInfoTask]] = currentTaskListMap[handleInfo.uniqueID.appType] ?? [:]
                taskListMapWithScheduleType[handleInfo.scheduleType] = sortedTasks
                currentTaskListMap[handleInfo.uniqueID.appType] = taskListMapWithScheduleType
            }
        }

        // Assert
        if let scheduleHandleTasks = currentTaskListMap[.gadget]?[.toBeScheduled] {
            XCTAssertEqual(scheduleHandleTasks.map({
                $0.handleInfo.uniqueID.appID
            }), [appLaunchHandleInfo.uniqueID.appID, preloadPushHandleInfo.uniqueID.appID, preloadPullHandleInfo.uniqueID.appID, metaExpiredHandleInfo.uniqueID.appID])
        } else {
            throw XCTSkip("can not get scheduleHandleTasks")
        }
    }

    func test_insertAndReorderTask_addListenersAndInjectors() throws {
        // Act
        let idleSilenceUpdatePullTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)
        let runPreloadPullTask = BDPPreloadInfoTask(handleInfo: preloadPullHandleInfo)
        runPreloadPullTask.updateTaskStatus(status: .running)

        let listenerOne = MockPreloadHandleListenerAndInjector(identify: "listenerOne")
        let listenerTwo = MockPreloadHandleListenerAndInjector(identify: "listenerTwo")
        let injectorOne = MockPreloadHandleListenerAndInjector(identify: "injectorOne")
        let injectorTwo = MockPreloadHandleListenerAndInjector(identify: "injectorTwo")

        idleSilenceUpdatePullTask.appendListeners([listenerOne, listenerTwo])
        idleSilenceUpdatePullTask.appendInjectors([injectorOne])

        runPreloadPullTask.appendListeners([listenerTwo])
        runPreloadPullTask.appendInjectors([injectorOne, injectorTwo])

        let prehandleManager = BDPPreloadHandlerManager()

        let insertTasks = [idleSilenceUpdatePullTask, runPreloadPullTask]

        let cachedSilenceUpdatePullTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)
        let cachedPreloadPullTask = BDPPreloadInfoTask(handleInfo: preloadPullHandleInfo)

        cachedSilenceUpdatePullTask.appendListeners([listenerOne])
        cachedSilenceUpdatePullTask.appendInjectors([injectorOne])

        cachedPreloadPullTask.appendListeners([listenerTwo])
        cachedPreloadPullTask.appendInjectors([injectorTwo])

        let currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.directHandle : [
                    cachedSilenceUpdatePullTask
                ],
                BDPPreloadScheduleType.toBeScheduled : [
                    cachedPreloadPullTask
                ]
            ]
        ]

        // Act
        for task in insertTasks {
            prehandleManager.insertAndReorderTask(taskInfo: task, taskListMap: currentTaskListMap) { taskInfo, needAppend, sortedTasks in
            }
        }

        if let _cachedSilenceUpdatePullTask = currentTaskListMap[.gadget]?[.directHandle]?.first,
           let _cachedPreloadPullTask = currentTaskListMap[.gadget]?[.toBeScheduled]?.first {
            guard _cachedSilenceUpdatePullTask.listeners.count == 2 else {
                XCTFail("silenceUpdatePullTask linseners count incorrect, expect 2 but \(_cachedSilenceUpdatePullTask.listeners.count)")
                return
            }

            guard _cachedSilenceUpdatePullTask.injectors.count == 1 else {
                XCTFail("silenceUpdatePullTask injector count incorrect, expect 1 but \(_cachedSilenceUpdatePullTask.injectors.count)")
                return
            }

            guard _cachedPreloadPullTask.listeners.count == 1 else {
                XCTFail("preloadPullTask listeners count incorrect, expect 1 but \(_cachedPreloadPullTask.listeners.count)")
                return
            }

            guard _cachedPreloadPullTask.injectors.count == 2 else {
                XCTFail("preloadPullTask injectors count incorrect, expect 2 but \(_cachedPreloadPullTask.listeners.count)")
                return
            }

            XCTAssertTrue(true)
        } else {
            throw XCTSkip("can not get cachedSilenceUpdatePullTask or _cachedPreloadPullTask")
        }
    }

    // MARK: taskListReplaceLowPriorityTask TestCases
    func test_taskListReplaceLowPriorityTask() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let tasks = [appLaunchHandleInfo, metaExpiredHandleInfo].map {
            BDPPreloadInfoTask(handleInfo: $0)
        }

        let taskInfo = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)

        // Act
        prehandleManager.taskListReplaceLowPriorityTask(taskList: tasks, with: taskInfo)

        // Assert
        XCTAssertEqual(tasks.map({
            $0.handleInfo.uniqueID.appID
        }), [appLaunchHandleInfo.uniqueID.appID, silencePullHandleInfo.uniqueID.appID])
    }

    // MARK: taskListAddTaskListenersAndInjectors
    func test_taskListAddTaskListenersAndInjectors() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let appLaunchTask = BDPPreloadInfoTask(handleInfo: appLaunchHandleInfo)
        let expiredTask = BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo)

        let tasks = [appLaunchTask, expiredTask]

        let taskInfo = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)

        let listenerOne = MockPreloadHandleListenerAndInjector(identify: "listenerOne")
        let listenerTwo = MockPreloadHandleListenerAndInjector(identify: "listenerTwo")
        let injectorOne = MockPreloadHandleListenerAndInjector(identify: "injectorOne")

        taskInfo.appendListeners([listenerOne, listenerTwo])
        taskInfo.appendInjectors([injectorOne])

        // Act
        prehandleManager.taskListAddTaskListenersAndInjectors(taskList: tasks, taskInfo: taskInfo)

        // Assert
        guard appLaunchTask.listeners.count == 2 else {
            XCTFail("appLaunchTask listeners count incorrect, expect 2 but \(appLaunchTask.listeners.count)")
            return
        }

        guard appLaunchTask.injectors.count == 1 else {
            XCTFail("appLaunchTask injectors count incorrect, expect 1 but \(appLaunchTask.injectors.count)")
            return
        }

        guard expiredTask.listeners.count == 2 else {
            XCTFail("expiredTask listeners count incorrect, expect 2 but \(expiredTask.listeners.count)")
            return
        }

        guard expiredTask.injectors.count == 1 else {
            XCTFail("expiredTask injectors count incorrect, expect 1 but \(expiredTask.injectors.count)")
            return
        }

        XCTAssertTrue(true)
    }

    // MARK: queueWithTask TestCases
    func test_queueWithTask_sameTypeTaskQueue() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let directHandleTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)
        let anotherDirectHandleTask = BDPPreloadInfoTask(handleInfo: silencePushHandleInfo)

        // Act
        let queue = prehandleManager.queueWithTask(taskInfo: directHandleTask)
        let cachedQueue = prehandleManager.queueWithTask(taskInfo: anotherDirectHandleTask)

        // Assert
        XCTAssertEqual(queue.name, cachedQueue.name)
    }

    func test_queueWithTask_diffScheduleTypeTaskQueue() {
        let prehandleManager = BDPPreloadHandlerManager()
        let directHandleTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)
        let scheduleHandleTask = BDPPreloadInfoTask(handleInfo: preloadPullHandleInfo)

        // Act
        let directHandleQueue = prehandleManager.queueWithTask(taskInfo: directHandleTask)
        let scheduleHandleQueue = prehandleManager.queueWithTask(taskInfo: scheduleHandleTask)

        // Assert
        XCTAssertNotEqual(directHandleQueue.name, scheduleHandleQueue.name)
    }

    func test_queueWithTask_diffAppTypeTaskQueue() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let gadgetTask = BDPPreloadInfoTask(handleInfo: preloadPullHandleInfo)
        let blockTask = BDPPreloadInfoTask(handleInfo: blockPreloadPullHandleInfo)

        // Act
        let gadgetQueue = prehandleManager.queueWithTask(taskInfo: gadgetTask)
        let blockQueue = prehandleManager.queueWithTask(taskInfo: blockTask)

        // Assert
        XCTAssertNotEqual(gadgetQueue.name, blockQueue.name)
    }

    //MARK: removeTask(taskInfo: in:) TestCases
    func test_removeTask_removeTasks() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let needRemovedTasks = [BDPPreloadInfoTask(handleInfo: silencePushHandleInfo),
                                BDPPreloadInfoTask(handleInfo: preloadPushHandleInfo),
                                BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo)]

        var currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.directHandle : [
                    BDPPreloadInfoTask(handleInfo: BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget), scene: .AppLaunch, scheduleType: .directHandle))
                ],
                BDPPreloadScheduleType.toBeScheduled : [
                    BDPPreloadInfoTask(handleInfo: BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_3", identifier: nil, versionType: .current, appType: .gadget), scene: .MetaExpired, scheduleType: .toBeScheduled)),
                    BDPPreloadInfoTask(handleInfo: preloadPullHandleInfo)
                ]
            ]
        ]

        // Act
        for task in needRemovedTasks {
            let removedScheduleTaskList = prehandleManager.removeTask(taskInfo: task, in: currentTaskListMap)
            currentTaskListMap[task.handleInfo.uniqueID.appType] = removedScheduleTaskList
        }

        // Assert
        guard let directHandleTasks = currentTaskListMap[.gadget]?[.directHandle] else {
            throw XCTSkip("can not get directHandleTasks")
        }

        guard let scheduleHandleTasks = currentTaskListMap[.gadget]?[.toBeScheduled] else {
            throw XCTSkip("can not get scheduleHandleTasks")
        }


        let directTasksResult = directHandleTasks.isEmpty

        let scheduleTasksResult = scheduleHandleTasks.map {
            $0.handleInfo.uniqueID.appID
        } == [preloadPullHandleInfo.uniqueID.appID]


        XCTAssertTrue(directTasksResult && scheduleTasksResult, "directTasksResult: \(directTasksResult), scheduleTasksResult: \(scheduleTasksResult)")
    }

    func test_removeTask_removeDiffScheduleTypeTask() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let needRemovedTask = BDPPreloadInfoTask(handleInfo: preloadPushHandleInfo)

        let cachedTask = BDPPreloadInfoTask(handleInfo: BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: "cli_mock_3", identifier: nil, versionType: .current, appType: .gadget), scene: .MetaExpired, scheduleType: .directHandle))
        let currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.toBeScheduled : [
                    cachedTask
                ]
            ]
        ]

        // Act
        let removedScheduleTaskList = prehandleManager.removeTask(taskInfo: needRemovedTask, in: currentTaskListMap)

        // Assert
        guard let scheduleHandleTasks = removedScheduleTaskList[.toBeScheduled] else {
            throw XCTSkip("can not get scheduleHandleTasks")
        }

        XCTAssertEqual(scheduleHandleTasks.map({
            $0.handleInfo.uniqueID.appID
        }), [cachedTask.handleInfo.uniqueID.appID])
    }

    func test_removeTask_removeRunTask() throws {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()

        let needRemovedTask = BDPPreloadInfoTask(handleInfo: preloadPushHandleInfo)

        let cachedTask = BDPPreloadInfoTask(handleInfo: preloadPushHandleInfo)
        cachedTask.updateTaskStatus(status: .running)
        let currentTaskListMap = [
            OPAppType.gadget : [
                BDPPreloadScheduleType.toBeScheduled : [
                    cachedTask
                ]
            ]
        ]

        // Act
        let removedScheduleTaskList = prehandleManager.removeTask(taskInfo: needRemovedTask, in: currentTaskListMap)

        // Assert
        guard let scheduleHandleTasks = removedScheduleTaskList[.toBeScheduled] else {
            throw XCTSkip("can not get scheduleHandleTasks")
        }

        XCTAssertEqual(scheduleHandleTasks.count, 1)
    }

    //MARK: interceptResponse TestCases
    func test_interceptResponse_beIntercepted() {
        // Arrange
        let mockTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)

        let injectorOne = MockPreloadHandleInjector(shouldIntercept: true)
        let injectorTwo = MockPreloadHandleInjector(shouldIntercept: false)

        mockTask.appendInjectors([injectorOne, injectorTwo])

        let prehandleManager = BDPPreloadHandlerManager()

        // Act
        guard let interceptResponse = prehandleManager.interceptResponse(taskInfo: mockTask) else {
            XCTFail("should get intercepted response")
            return
        }

        XCTAssertTrue(interceptResponse.intercepted, "intercepted tag should be true")
    }

    func test_interceptResponse_notIntercepted() {
        // Arrange
        let mockTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)

        let injectorOne = MockPreloadHandleInjector(shouldIntercept: false)
        let injectorTwo = MockPreloadHandleInjector(shouldIntercept: false)

        mockTask.appendInjectors([injectorOne, injectorTwo])

        let prehandleManager = BDPPreloadHandlerManager()

        // Act
        let interceptResponse = prehandleManager.interceptResponse(taskInfo: mockTask)

        // Assert
        XCTAssertTrue(interceptResponse == nil)
    }

    //MARK: injectedMeta(from:) TestCases
    func test_injectedMeta_withMetaInject() {
        // Arrange
        let mockTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)

        let injectorOne = MockPreloadHandleInjector(shouldIntercept: false)
        let mockUniqueID = OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget)
        injectorOne.injectorMeta = MockBizAndAppMeta(mockUniqueID)
        let injectorTwo = MockPreloadHandleInjector(shouldIntercept: false)

        mockTask.appendInjectors([injectorOne, injectorTwo])

        let prehandleManager = BDPPreloadHandlerManager()

        // Act
        guard let injectedMeta = prehandleManager.injectedMeta(from: mockTask) else {
            XCTFail("injected meta should not be nil")
            return
        }

        // Assert
        XCTAssertEqual(injectedMeta.uniqueID.fullString, mockUniqueID.fullString)
    }

    func test_injectedMeta_withoudMetaInject() {
        // Arrange
        let mockTask = BDPPreloadInfoTask(handleInfo: silencePullHandleInfo)

        let injectorOne = MockPreloadHandleInjector(shouldIntercept: false)
        let injectorTwo = MockPreloadHandleInjector(shouldIntercept: false)

        mockTask.appendInjectors([injectorOne, injectorTwo])

        let prehandleManager = BDPPreloadHandlerManager()

        // Act
        let injectedMeta = prehandleManager.injectedMeta(from: mockTask)

        // Assert
        XCTAssertTrue(injectedMeta == nil, "should not get injected meta")
    }

    //MARK: startToPackageDownload TestCases
    func test_startToPackageDownload_success() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let mockAppMeta = MockBizAndAppMeta(OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget))

        let mockPkgCtx = BDPPackageContext(appMeta: MockBizAndAppMeta(OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget)), packageType: .pkg, packageName: "mockPkg", trace: BDPTracingManager.sharedInstance().generateTracing())
        let mockFileReader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: mockPkgCtx)

        let mockPackageModule = MockPackageModule()
        mockPackageModule.fileReader = mockFileReader

        let promise = expectation(description: "result should be success")

        // Act
        prehandleManager.startToPackageDownload(mockAppMeta, taskInfo: BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo), packageProvider: mockPackageModule) { result in
            guard result else {
                XCTFail("should success")
                return
            }
            promise.fulfill()
        }

        // Assert
        wait(for: [promise], timeout: 3)
    }

    func test_startToPackageDownload_invalidMeta() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let mockBizMeta = MockBizMeta(OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget))

        let promise = expectation(description: "result should be failed, because meta can not convert")

        // Act
        prehandleManager.startToPackageDownload(mockBizMeta, taskInfo: BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo), packageProvider: MockPackageModule()) { result in
            guard result else {
                promise.fulfill()
                return
            }
            XCTFail("should not success, test invalid meta")
        }

        // Assert
        wait(for: [promise], timeout: 3)
    }

    func test_startToPackageDownload_pkgDownloadCallbackWithNilFileReader() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let mockAppMeta = MockBizAndAppMeta(OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget))

        let mockPackageModule = MockPackageModule()

        let promise = expectation(description: "result should be failed, file reader is nil")

        // Act
        prehandleManager.startToPackageDownload(mockAppMeta, taskInfo: BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo), packageProvider: mockPackageModule) { result in
            guard result else {
                promise.fulfill()
                return
            }
            XCTFail("should not success, test file reader is nil")
        }

        // Assert
        wait(for: [promise], timeout: 3)
    }

    func test_startToPackageDownload_pkgDownloadCallbackWithError() {
        // Arrange
        let prehandleManager = BDPPreloadHandlerManager()
        let mockAppMeta = MockBizAndAppMeta(OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget))

        let mockPkgCtx = BDPPackageContext(appMeta: MockBizAndAppMeta(OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget)), packageType: .pkg, packageName: "mockPkg", trace: BDPTracingManager.sharedInstance().generateTracing())
        let mockFileReader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: mockPkgCtx)

        let mockPackageModule = MockPackageModule()
        mockPackageModule.fileReader = mockFileReader
        mockPackageModule.pkgDownloadError = OPError.error(monitorCode: OPMonitorCode(domain: "MockMonitor", code: -1, level: OPMonitorLevelTrace, message: "It's a mock monitor code"))

        let promise = expectation(description: "result should be failed, pkg download failed with error")

        // Act
        prehandleManager.startToPackageDownload(mockAppMeta, taskInfo: BDPPreloadInfoTask(handleInfo: metaExpiredHandleInfo), packageProvider: mockPackageModule) { result in
            guard result else {
                promise.fulfill()
                return
            }
            XCTFail("should not success, test pkg download failed")
        }

        // Assert
        wait(for: [promise], timeout: 3)
    }
}
