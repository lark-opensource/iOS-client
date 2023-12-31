//
//  DocumentActivityManager.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/11/9.
//

import Foundation
import SKFoundation
import RxSwift
import RxRelay

public protocol DocumentActivityReporter {
    func report(activity: DocumentActivity)
}

class DocumentActivityManager: DocumentActivityReporter {
    private typealias API = DocumentActivityAPI

    private var isReady = false
    private var reporting = false
    private var disposeBag = DisposeBag()

    private var storage: DocumentActivityStorage?

    static let shared = DocumentActivityManager()

    private init() {}

    func config() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleUserLogin),
                                               name: NSNotification.Name.Docs.userDidLogin,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleUserLogout),
                                               name: NSNotification.Name.Docs.userWillLogout,
                                               object: nil)

        // 无网到有网时，恢复上报
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .distinctUntilChanged()
            .subscribe(onNext: { [self] isReachable in
                guard isReachable else { return }
                startReport(delay: 2)
            })
            .disposed(by: disposeBag)
    }

    // handle user login logout
    @objc
    private func handleUserLogin() {
        setupIfNeed()
        startReport(delay: 2)
    }

    @objc
    private func handleUserLogout() {
        isReady = false
        storage = nil
        reporting = false
        disposeBag = DisposeBag()
    }

    private func setupIfNeed() {
        if isReady { return }
        guard let userID = User.current.basicInfo?.userID else {
            DocsLogger.error("setup document activity manager failed, userID is nil")
            spaceAssertionFailure()
            return
        }
        storage = DocumentActivityStorage(userID: userID)
        isReady = true
    }

    func report(activity: DocumentActivity) {
        setupIfNeed()

        guard isReady else {
            DocsLogger.error("document activity manager not ready when report")
            spaceAssertionFailure()
            return
        }

        storage?.save(activity: activity)
        startReport(delay: 1)
    }

    private func startReport(delay: Int) {
        if reporting { return }
        reporting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay)) { [self] in
            reportIfNeed()
        }
    }

    // 开始恢复上报
    private func reportIfNeed() {
        guard isReady, reporting else { return }
        DispatchQueue.global().async { [self] in
            guard let activities = storage?.getNextBatchActivities() else {
                DispatchQueue.main.async {
                    self.reporting = false
                }
                return
            }

            API.report(token: activities.objID, type: activities.objType, activities: activities.activities)
                .subscribe { [self] uuids in
                    storage?.delete(uuids: uuids)
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) {
                        self.reportIfNeed()
                    }
                } onError: { [self] error in
                    DocsLogger.error("resume batch report failed with error", error: error)
                    self.reporting = false
                }
                .disposed(by: disposeBag)
        }
    }
}
