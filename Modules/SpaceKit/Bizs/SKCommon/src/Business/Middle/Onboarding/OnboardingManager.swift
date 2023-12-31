// 
// Created by duanxiaochen.7 on 2019/11/4.
// Affiliated with SpaceKit.
//
// Description: OnboardingManager provides interfaces for businesses and handles the whole process of displaying onboardings.
// Documentation: https://bytedance.feishu.cn/docs/doccnyWfJvBKuhfHZ4Chf7a2otb#
// swiftlint:disable file_length

import SKFoundation
import RxSwift
import LarkExtensions

public final class OnboardingManager {
    /// The only way to access the one and only instance of OnboardingManager.
    public static var shared = OnboardingManager()

    // Is an onboarding session active?
    public private(set) var hasActiveOnboardingSession: Bool = false

    /// Globally disabled onboardings. FG configured.
    internal private(set) var blocklist: [OnboardingID] = []

    /// Temporarily inhibits all onboarding items from showing.
    internal private(set) var rejectsAllOnboardingTasks: Bool = false

    /// The task queue that pops only one at a time so as to make sure onboardings don't run into each other.
    private var taskQueue: [OnboardingTask] = [] {
        didSet {
            DocsLogger.onboardingInfo("引导队列：\(taskQueue.map { $0.id.rawValue })")
        }
    }

    /// The fullScreen window hosting the onboarding view which does not become `keyWindow` when shown.
    ///
    /// This is only effective when the dataSource explicitly called `generateFullScreenWindow(uponCurrentWindow:)` in
    /// the data source method `onboardingHostViewController(for:)`, where the returned host view controller is actually
    /// the `rootViewController` of this full screen window.
    ///
    /// The life cycle of this window is handled by the onboarding manager. You only take care of generating it.
    private var fullScreenWindow: UIWindow? {
        didSet {
            DocsLogger.onboardingInfo("\(fullScreenWindow == nil ? "移除掉引导 window 了" : "设置了新的全屏幕 window")")
        }
    }

    private var currentOnboardingViewController: OnboardingBaseViewController?

    /// Synchronizes local and remote storages of completions of onboardings.
    private var synchronizer = OnboardingSynchronizer.shared

    /// Expected next onboarding ID. The check procedure only takes place once.
    private var expectedNextTaskID: OnboardingID? {
        willSet {
            if let newValue = newValue, let currentTask = currentTask {
                DocsLogger.onboardingInfo("\(currentTask.id) 设置下次一定要播放 \(newValue)")
            }
        }
    }

    /// Current onboarding task.
    private var currentTask: OnboardingTask? {
        didSet {
            if let task = currentTask {
                if let expectedNextID = expectedNextTaskID {
                    expectedNextTaskID = nil
                    guard expectedNextID == task.id else {
                        DocsLogger.onboardingError("目前任务 \(task.id) 不符合上一个引导的 nextID 预期 \(expectedNextID)，所以不予播放，任务直接抛弃")
                        task.delegate?.onboardingNotExpected(for: task.id, expecting: expectedNextID)
                        removeFullScreenOnboardingWindow()
                        dequeue()
                        return
                    }
                }

                execute(task)
            } else {
                hasActiveOnboardingSession = false
            }
        }
    }

    /// A dictionary containing observable sequences for the upcoming onboarding's existence.
    /// Key: NSString representation of OnboardingID.
    /// Value: `ReplaySubject<Bool>` sequence to denote the lifetime of an onboarding view.
    ///
    /// You can leverage this method to notify the onboarding manager when it should actually present or dismiss
    /// the needed onboarding based on the boolean value sequence you emit.
    /// For example, when a button's presentation is controlled by an asynchronous event sent by JavaScript messages,
    /// the onboarding bubble pointing to the button should present only after the button has appeared, and should
    /// automatically dismiss when the button has disappeared.
    /// In this case, you would like to create a `Bool` value observable sequence and emit `true` and `false` values
    /// according to the button's appearance and disappearance. The onboarding manager subscribes to the sequence
    /// and automatically presents and dismisses onboarding views accordingly. The subscripition is disposed by calling
    /// `removeExistenceReplaySubject(for: id)`, and you must explicitly call it somewhere in your codes.
    ///
    /// You can also utilize this method to programmatically control an onboarding's presentation and dismissal
    /// regardless of the user's interaction with the mobile device. A typical usage would be setting an onboarding
    /// to automatically dismiss itself after a short period of time when the user does not touch the screen.
    /// The user can still manually dismiss the onboarding on their own.
    ///
    /// If you are not interested in this mechanism, you do not need to set.
    /// Then the appearance and disappearance of the onboarding view is solely controlled by the user's touch events.
    ///
    /// - Parameter id: The `ID` of the onboarding item.
    private var existenceReplaySubjects: [OnboardingID: ReplaySubject<Bool>] = [:]
}




// MARK: - Public interfaces for business about showing an onboarding.
public extension OnboardingManager {

    // MARK: Show Onboardings

    /// Exactly as the method name suggests.
    /// - Parameters:
    ///   - id: The ID of the onboarding task.
    ///   - delegate: Pass in your own class that conforms to protocol `OnboardingDelegate`.
    ///   - dataSource: Pass in your own class that conforms to protocol `OnboardingDataSource`.
    func showTextOnboarding(id: OnboardingID, delegate: OnboardingDelegate, dataSource: OnboardingDataSource) {
        if shouldDisplayOnboarding(id, delegate: delegate, dataSource: dataSource) {
            let task = OnboardingTextTask(called: id, delegate: delegate, dataSource: dataSource)
            register(task)
        } else {
            removeFullScreenOnboardingWindow()
            DocsLogger.onboardingInfo("该引导项没有通过安检，不予播放！")
        }
    }

    /// Exactly as the method name suggests.
    /// - Parameters:
    ///   - id: The ID of the onboarding task.
    ///   - delegate: Pass in your own class that conforms to protocol `OnboardingDelegate`.
    ///   - dataSource: Pass in your own class that conforms to protocols `OnboardingDataSource & OnboardingFlowDataSource`.
    func showFlowOnboarding(id: OnboardingID, delegate: OnboardingDelegate, dataSource: OnboardingFlowDataSources) {
        if shouldDisplayOnboarding(id, delegate: delegate, dataSource: dataSource) {
            let task = OnboardingFlowTask(called: id, delegate: delegate, dataSource: dataSource)
            register(task)
        } else {
            removeFullScreenOnboardingWindow()
            DocsLogger.onboardingInfo("该引导项没有通过安检，不予播放！")
        }
    }

    /// Exactly as the method name suggests.
    /// - Parameters:
    ///   - id: The ID of the onboarding task.
    ///   - delegate: Pass in your own class that conforms to protocol `OnboardingDelegate`.
    ///   - dataSource: Pass in your own class that conforms to protocols `OnboardingDataSource & OnboardingCardDataSource`.
    func showCardOnboarding(id: OnboardingID, delegate: OnboardingDelegate, dataSource: OnboardingCardDataSources) {
        if shouldDisplayOnboarding(id, delegate: delegate, dataSource: dataSource) {
            let task = OnboardingCardTask(called: id, delegate: delegate, dataSource: dataSource)
            register(task)
        } else {
            removeFullScreenOnboardingWindow()
            DocsLogger.onboardingInfo("该引导项没有通过安检，不予播放！")
        }
    }

    // MARK: Dismiss Onboardings

    /// Abort a designated onboarding task. If the current task is exactly the task to be removed,
    /// then this task will be aborted, the onboarding view will be removed, and no further onboarding tasks will be executed.
    /// Otherwise, the task is removed from the task queue, without affecting current onboarding process.
    ///
    /// Noted that if to remove the current task, only the onboarding view on screen will be removed.
    /// No delegate methods will be called, because the user might not have fully seen the onboarding content.

    /// Abort the current onboarding task and prevent further onboarding tasks until noticed if required.
    ///
    /// The current onboarding view on screen will be removed.
    /// The aborted onboarding is not marked finished, and no delegate methods will be called after removing the view,
    /// because the user might not have fully seen the onboarding content.
    /// - Parameter stopsFurtherOnboardings: Whether to prevent further onboarding views to show.
    func abortCurrentOnboardingProcess(stopsFurtherOnboardings: Bool) {
        currentOnboardingViewController?.disappearStyle = .immediatelyAfterUserInteraction
        currentOnboardingViewController?.removeSelf(shouldSetFinished: false)
        if stopsFurtherOnboardings {
            stopExecuting()
        }
    }

    // MARK: Showing Strategy

    /// Notify the onboarding manager that it should stop showing forthcomming onboardings.
    ///
    /// The onboarding manager will discard any new onboarding tasks created by calling `showOnboarding(id:delegate:dataSource)`.
    /// Any tasks already in the queue is removed immediately, too.
    /// - Parameter stop: A boolean flag indicating whether or not should stop showing further onboarding items.
    func setTemporarilyRejectsUpcomingOnboardings(_ stops: Bool = true) {
        rejectsAllOnboardingTasks = stops
        if stops {
            taskQueue = []
            DocsLogger.onboardingInfo("有人设置了不播放接下来的引导，所以清空了引导队列")
        }
    }

    /// Notice the observer that the target view for the onboarding has just appeared or disappeared.
    ///
    /// - Parameters:
    ///   - id: An array of ID of the onboarding task.
    ///   - updatedExistence: `true` if the target view just appeared, `false` if disappeared.
    func targetView(for ids: [OnboardingID], updatedExistence: Bool) {
        for id in ids {
            if existenceReplaySubjects[id] == nil && !hasFinished(id) && updatedExistence {
                setTargetViewExistenceObserver(for: id)
            }
            existenceReplaySubjects[id]?.onNext(updatedExistence)
            if !updatedExistence {
                removeExistenceReplaySubject(for: id)
            }
        }
    }

    /// Create an top level full screen `UIWindow` to host an onboarding view.
    /// **The window will not become key.**
    /// - Returns: The reference to the mounted onboarding window.
    func generateFullScreenWindow(uponCurrentWindow currentWindow: UIWindow) -> UIWindow {
        if let window = fullScreenWindow { return window }
        let onboardingWindow: UIWindow
        if #available(iOS 13.0, *), let scene = currentWindow.windowScene {
            onboardingWindow = UIWindow(windowScene: scene) // iOS 13 以上一定要用这种方式来创建 window
        } else {
            onboardingWindow = UIWindow(frame: currentWindow.frame)
        }
        onboardingWindow.windowIdentifier = "SKCommon.OnboardingWindow"
        onboardingWindow.windowLevel = .alert
        onboardingWindow.rootViewController = UIViewController()
        self.fullScreenWindow = onboardingWindow
        return onboardingWindow
    }

    /// Get current top onboarding id in viewController
    func getCurrentTopOnboardingID(in viewController: UIViewController) -> OnboardingID? {
        if let topVC = viewController.children.last as? OnboardingBaseViewController {
            return topVC.id
        }
        return nil
    }
}

// MARK: - Internal interfaces about onboarding iteration.
extension OnboardingManager {

    /// Abort the current onboarding task and remove the current onboarding view.
    ///
    /// No additional delegate methods are called in this method, so make sure you include necessary delegate method calls in the `completion` block.
    ///
    /// - Parameters:
    ///   - disappearStyle: How the onboarding view is being removed, immediately or countdown.
    ///   - completion: Anything you want to execute after removing the onboarding view.
    func removeCurrentOnboardingView(disappearStyle: OnboardingStyle.DisappearStyle, completion: (() -> Void)? = nil) {
        func removeCore(completion: (() -> Void)? = nil) {
            UIView.animate(withDuration: 0.1) { [self] in
                currentOnboardingViewController?.view.alpha = 0.0
            } completion: { [self] completed in
                if completed {
                    currentOnboardingViewController?.willMove(toParent: nil)
                    currentOnboardingViewController?.view.removeFromSuperview()
                    currentOnboardingViewController?.removeFromParent()
                    currentOnboardingViewController = nil
                    removeFullScreenOnboardingWindow()
                    completion?()
                }
            }
        }

        guard let currentTask = currentTask, let dataSource = currentTask.dataSource else {
            completion?()
            return
        }

        switch dataSource.onboardingDisappearStyle(of: currentTask.id) {
        case .immediatelyAfterUserInteraction, .countdownAfterAppearance:
            removeCore(completion: completion)
        case .countdownAfterUserInteraction(let countdown):
            DispatchQueue.main.asyncAfter(deadline: .now() + countdown) {
                removeCore(completion: completion)
            }
        }
    }

    /// When an onboarding task is already finished, this method is called to send a message of
    /// "continue executing the next task in the queue".
    ///
    /// If the next task in the task queue has an inconsistent ID with this, the task will **not** be executed and discarded immediately.
    /// However, this check procedure only takes place **ONCE**.
    /// If someone has made the onboarding manager reject all onboarding tasks, no tasks will be
    /// - Parameter nextID: Expected next onboarding task's ID.
    func continueExecuting(expectedNext nextID: OnboardingID?) {
        guard !rejectsAllOnboardingTasks else {
            DocsLogger.onboardingInfo("设置了不播放接下来的引导，所以清空所有引导任务")
            currentTask = nil
            expectedNextTaskID = nil
            taskQueue = []
            return
        }
        expectedNextTaskID = nextID
        dequeue()
    }

    /// This method is called to send a message of "stop executing any other tasks until further noticed".
    ///
    /// If there are remaining tasks pending in the task queue, they are discarded immediately.
    /// What's more, the onboarding manager begins rejecting all incoming onboarding requests.
    func stopExecuting() {
        currentTask = nil
        expectedNextTaskID = nil
        setTemporarilyRejectsUpcomingOnboardings()
    }
}



// MARK: - Interfaces about synchronization
extension OnboardingManager {
    /// Prepare the onboarding manager to use.
    /// - Parameter list: List of globally disabled onboardings.
    public func prepare(disabling list: [String]) {
        DocsLogger.onboardingInfo("FG 下发的引导黑名单：\(list)")
        blocklist = list.compactMap { OnboardingID(rawValue: $0) }
    }

    /// Convenience method for marking the user has seen the little red dot.
    /// - Parameter ids: An array of little red dot's identifier.
    public func markBadgeFinished(for ids: [String]) {
        synchronizer.setBadgesFinished(ids: ids)
    }

    /// Merge onboarding finishing statuses with given data.
    /// - Parameter data: An array of finish statuses of onboardings.
    public func markFinished(for ids: [OnboardingID]) {
        for id in ids where !hasFinished(id) {
            synchronizer.setFinished(id)
        }
    }

    /// An interface for checking whether an onboarding has displayed.
    /// - Parameter id: The onboarding id to check.
    public func hasFinished(_ id: OnboardingID) -> Bool {
        return synchronizer.isFinished(id)
    }

    internal func clearLocalCache() {
        synchronizer.clear()
        taskQueue = []
        currentTask = nil
		DocsLogger.onboardingInfo("已经清除缓存中的完成情况")
    }

    func removeExistenceReplaySubject(for id: OnboardingID) {
        guard let subject = existenceReplaySubjects[id] else {
            return
        }
        subject.dispose()
        existenceReplaySubjects[id] = nil
    }
}




// MARK: - Private Methods
private extension OnboardingManager {

    /// Check the eligibility of the onboarding.
    func shouldDisplayOnboarding(_ id: OnboardingID,
                                 delegate: OnboardingDelegate,
                                 dataSource: OnboardingDataSource) -> Bool {
        guard !blocklist.contains(id) else {
            DocsLogger.onboardingInfo("FG 告诉我 \(id.rawValue) 不能显示")
            delegate.onboardingDisabledInMinaConfiguration(for: id)
            return false
        }
        guard !synchronizer.isFinished(id) else {
            DocsLogger.onboardingInfo("\(id.rawValue) 已经显示过了")
            delegate.onboardingAlreadyFinished(id)
            return false
        }
        return true
    }

    /// Execute an onboarding task.
    /// - Parameter task: The task to be executed.
    func execute(_ task: OnboardingTask) {
        guard task.checkPreconditions() else {
            DocsLogger.onboardingError("\(task.id) 未通过前置条件检查")
            removeFullScreenOnboardingWindow()
            dequeue()
            return
        }

        guard !synchronizer.isFinished(task.id) else {
            DocsLogger.onboardingInfo("\(task.id.rawValue) 已经显示过了")
            task.delegate?.onboardingAlreadyFinished(task.id)
            removeFullScreenOnboardingWindow()
            dequeue()
            return
        }

        guard let hostVC = task.dataSource?.onboardingHostViewController(for: task.id) else {
            DocsLogger.onboardingError("Manager 准备播放引导 \(task.id)，却发现 hostVC 不见了")
            task.delegate?.onboardingMaterialNotEnough(for: task.id)
            removeFullScreenOnboardingWindow()
            dequeue()
            return
        }

        if task.dataSource?.onboardingType(of: task.id) != .card {
            guard let targetRect = task.dataSource?.onboardingTargetRect(for: task.id), targetRect != .zero else {
                DocsLogger.onboardingError("Manager 准备播放引导 \(task.id)，却发现引导指向位置非法")
                removeFullScreenOnboardingWindow()
                dequeue()
                return
            }
        }

        var onboardingVC: OnboardingBaseViewController!
        switch task {
        case let task as OnboardingTextTask:
            let textVC = OnboardingTextViewController(id: task.id, delegate: task.delegate, dataSource: task.dataSource)
            onboardingVC = textVC
        case let task as OnboardingFlowTask:
            let flowVC = OnboardingFlowViewController(id: task.id, delegate: task.delegate, dataSource: task.flowDataSource)
            onboardingVC = flowVC
        case let task as OnboardingCardTask:
            let cardVC = OnboardingCardViewController(id: task.id, delegate: task.delegate, dataSource: task.cardDataSource)
            onboardingVC = cardVC
        default: fatalError("Manager 收到了未知的任务") // 代码逻辑保证不会走到这里
        }

        attachOnboardingViewController(onboardingVC, to: hostVC)
    }

    /// Register a task.
    ///
    /// Push the task into the back of the task queue.
    /// If there is no task being executed currently, dequeue from the front and execute the task.
    /// - Parameter task: The task to be enrolled.
    func register(_ task: OnboardingTask) {
        guard !rejectsAllOnboardingTasks else {
            DocsLogger.onboardingInfo("设置了不播放接下来的引导，所以不予入队")
            task.delegate?.onboardingManagerRejectedThisTime(task.id)
            return
        }

        func push(_ task: OnboardingTask) {
            enqueue(task)
            if currentTask == nil {
                dequeue()
            }
        }

        hasActiveOnboardingSession = true

        if task.dataSource?.onboardingIsAsynchronous(for: task.id) == true {
            // 如果在这之前已经调用了 targetView(for:updatedExistence:)，那么 observer 就已经存在，下面这个方法不会生效，而且会 replay 最近一个值，直接进入订阅逻辑
            // 如果在这之前还没有调用 targetView(for:updatedExistence:)，那么在这里生成一个并且订阅，等候后来的 targetView(for:updatedExistence:)
            setTargetViewExistenceObserver(for: task.id)
            _ = existenceReplaySubjects[task.id]?
                .observeOn(MainScheduler.instance)
                .distinctUntilChanged()
                .subscribe(onNext: { [unowned self] show in
                    if !self.synchronizer.isFinished(task.id) {
                        if show {
                            push(task)
                        } else {
                            if currentTask?.id == task.id {
                                /**
                                 在正在显示引导的时候，被指向 view 消失，而用户还没有点击屏幕确认 acknowledge 或是 skip 的时候，
                                 读取 onboardingTargetViewDidDisappear 的配置，如果是 proceed 则不认为用户已经看过引导，
                                 只是单纯移除引导 view，下次需要重新显示该引导，直到用户点击屏幕主动确认
                                 */
                                let disappearBehavior = task.delegate?.onboardingTargetViewDidDisappear(for: task.id) ?? .proceed
                                currentOnboardingViewController?.disappearBehavior = disappearBehavior
                                self.currentOnboardingViewController?.removeSelf(shouldSetFinished: disappearBehavior != .proceed)
                            } else {
                                remove(task)
                            }
                        }
                    } else {
                        self.removeExistenceReplaySubject(for: task.id)
                    }
                })
        } else {
            push(task)
        }
        task.delegate?.onboardingDidRegister(task.id)
    }

    /// Push a task into the back of the task queue.
    ///
    /// If the task is already in the queue, nothing will happen. Otherwise, push the task into the back of the task queue.
    /// - Parameter task: The task to be pushed.
    func enqueue(_ task: OnboardingTask) {
        guard !taskQueue.contains(task) else {
            DocsLogger.onboardingInfo("\(task.id.rawValue) 已经在队列里面了")
            return
        }
        taskQueue.append(task)
    }

    /// Dequeue from the front of the task queue and execute the task.
    func dequeue() {
        guard !taskQueue.isEmpty else {
            currentTask = nil
            return
        }
        currentTask = taskQueue.removeFirst()
    }

    /// Remove a task from the queue.
    /// - Parameter task: The task to be removed.
    func remove(_ task: OnboardingTask) {
        if let pos = taskQueue.firstIndex(of: task) {
            taskQueue.remove(at: pos)
        }
    }

    func attachOnboardingViewController(_ onboardingVC: OnboardingBaseViewController, to hostViewController: UIViewController) {
        onboardingVC.delegate?.onboardingWillAttach(view: onboardingVC.view, for: onboardingVC.id)
        fullScreenWindow?.isHidden = false
        hostViewController.addChild(onboardingVC)
        hostViewController.view.addSubview(onboardingVC.view)
        currentOnboardingViewController = onboardingVC
        onboardingVC.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        onboardingVC.view.alpha = 0.0
        UIView.animate(withDuration: 0.1, animations: {
            onboardingVC.view.alpha = 1.0
        }, completion: { [unowned self] _ in
            onboardingVC.didMove(toParent: hostViewController)
            onboardingVC.delegate?.onboardingDidAppear(onboardingVC.id)
            self.addCountdownForAutoDisappearIfNeeded(for: onboardingVC)
        })
    }

    func removeFullScreenOnboardingWindow() {
        if fullScreenWindow != nil {
            fullScreenWindow?.isHidden = true
            fullScreenWindow = nil
        }
    }

    func setTargetViewExistenceObserver(for id: OnboardingID) {
        guard existenceReplaySubjects[id] == nil else {
            DocsLogger.onboardingInfo("\(id) 已经有现成的 replay subject 了")
            return
        }
        existenceReplaySubjects[id] = ReplaySubject<Bool>.create(bufferSize: 1)
    }

    func addCountdownForAutoDisappearIfNeeded(for onboardingVC: OnboardingBaseViewController) {
        guard case .countdownAfterAppearance(let countdown) = currentTask?.dataSource?.onboardingDisappearStyle(of: onboardingVC.id) else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + countdown) { [weak onboardingVC] in
            onboardingVC?.removeSelf()
        }
    }
}

extension DocsLogger {

    public class func onboardingDebug(_ log: String) {
        DocsLogger.debug("🍇 \(log)", component: "Onboarding")
    }

    public class func onboardingInfo(_ log: String) {
        DocsLogger.info("🍇 \(log)", component: "Onboarding")
    }

    public class func onboardingError(_ log: String) {
        DocsLogger.error("🍇 \(log)", component: "Onboarding")
    }
}
