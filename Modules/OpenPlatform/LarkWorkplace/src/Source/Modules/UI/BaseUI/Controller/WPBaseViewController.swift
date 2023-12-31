//
//  WPBaseViewController.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/9/17.
//

import UIKit
import SnapKit

class WPBaseViewController: UIViewController {

    /// 顶部容器，位于状态视图上方，其高度由子视图决定
    /// 默认为空 View，如有需要动态展示的视图可以加到其中
    private(set) lazy var topContainer = UIView()

    /// 状态视图
    lazy var stateView: WPPageStateView = {
        WPPageStateView()
    }()

    /// VC 当前是否可见（didAppear）
    private(set) var isAppeared: Bool = false

    /// 页面进入时间戳
    private(set) var pageEnterTs: TimeInterval?

    /// 页面离开时间戳
    private(set) var pageLeaveTs: TimeInterval?

    private var willResignActiveObserver: Any?
    private var didBecomeActiveObserver: Any?

    // MARK: - init

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let willResignActiveObserver = willResignActiveObserver {
            NotificationCenter.default.removeObserver(willResignActiveObserver)
        }
        if let didBecomeActiveObserver = didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }

    // MARK: - public func

    /// 应用进入后台，收到 UIApplication.willResignActiveNotification 通知
    func onPageWillResignActive() {
        if isAppeared {
            pageLeaveTs = Date().timeIntervalSince1970
        }
    }

    /// 应用回到前台，收到 UIApplication.didBecomeActiveNotification 通知
    func onPageDidBecomeActive() {
        if isAppeared {
            pageEnterTs = Date().timeIntervalSince1970
            pageLeaveTs = nil
        }
    }

    // MARK: - life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(topContainer)
        view.addSubview(stateView)
        topContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            // 当 topContainer 中没有子视图时，优先拉长 stateView
            make.height.equalTo(0.0).priority(.low)
        }
        stateView.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        baseObserverInit()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isAppeared = true
        pageEnterTs = Date().timeIntervalSince1970
        pageLeaveTs = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isAppeared = false
        pageLeaveTs = Date().timeIntervalSince1970
    }

    private func baseObserverInit() {
        willResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.onPageWillResignActive()
        }

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.onPageDidBecomeActive()
        }
    }
}
