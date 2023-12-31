//
//  SettingServiceImpl.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/24.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa

final class SettingServiceImpl: SettingService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    let defaultDueTimeDayOffset: Int64 = 18 * 60
    let defaultStartTimeDayOffset: Int64 = 9 * 60
    let defaultDueReminderOffset: Int64 = 0

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var settingNoti: SettingNoti?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?

    private let store: RxStore<SettingState, SettingAction>
    private let disposeBag = DisposeBag()
    private var isNeedFetchData = true

    init(resolver: UserResolver) {
        self.userResolver = resolver
        store = .init(name: "Setting.Store", state: .default)
        store.initialize()
        registerPush()
    }

    func fetchDataIfNeeded() {
        Setting.logger.info("fetchDataIfNeeded. isNeedFetchData: \(isNeedFetchData)")
        if isNeedFetchData {
            fetchSetting()
        }
    }

    func forceFetchData() { fetchSetting(forceServer: true) }

    func value<V>(forKeyPath keyPath: WritableKeyPath<SettingState, V>) -> V {
        return store.state[keyPath: keyPath]
    }

    func observe<V>(forKeyPath keyPath: WritableKeyPath<SettingState, V>) -> Observable<V> {
        return store.rxValue(forKeyPath: keyPath)
    }

    func update<V>(_ value: V, forKeyPath keyPath: WritableKeyPath<SettingState, V>, onError: (() -> Void)?) {
        // launch screen
        let launchScreenKey = \SettingState.listLaunchScreen
        if keyPath.hashValue == launchScreenKey.hashValue,
           let launchScreen = value as? [Rust.ListLaunchScreen],
            let first = launchScreen.first {
            updateLaunchScreen(first, onError: onError)
            return
        }

        // List Setting
        let hookKeyPath = \SettingState.listViewSettings

        var state = store.state
        if hookKeyPath.hashValue == keyPath.hashValue,
           let newValue = value as? [Rust.ListViewType: Rust.ListViewSetting] {
            // listViewSettings 是增量更新，特别处理
            newValue.forEach { state.listViewSettings[$0.key] = $0.value }
        } else {
            state[keyPath: keyPath] = value
        }
        store.setState(state)

        // hook 了 listViewSettings 的修改，需要单独走接口
        if keyPath.hashValue == hookKeyPath.hashValue,
           let listViewSettings = value as? [Rust.ListViewType: Rust.ListViewSetting] {
            listViewSettings.forEach { updateListViewSetting($0.value, onError: onError) }
            return
        }

        operateApi?.updateSetting(from: store.state.toPb()).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: {
                    Setting.tracker(.todo_daily_reminder_settings, params: ["is_on": state.enableDailyRemind])
                    Setting.logger.info("updateSetting successed. setting: \(state.logInfo)")
                },
                onError: { error in
                    onError?()
                    Setting.logger.info("updateSetting failed. error: \(error)")
                }
        ).disposed(by: disposeBag)
    }

    func updateCache<V>(_ value: V, forKeyPath keyPath: WritableKeyPath<SettingState, V>) {
        var state = store.state
        state[keyPath: keyPath] = value
        store.setState(state)
    }

}

// MARK: Privates

extension SettingServiceImpl {

    private func fetchSetting(forceServer: Bool = false) {
        fetchApi?.getSetting(forceServer).take(1).asSingle()
            .subscribe(
                onSuccess: { [weak self] setting in
                    let state = SettingState(pb: setting)
                    Setting.logger.info("fetchSetting successed. setting: \(state.logInfo)")
                    self?.store.setState(state)
                    self?.isNeedFetchData = false
                },
                onError: { error in
                    Setting.logger.info("fetchSetting failed. error: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func registerPush() {
        settingNoti?.rxSetting
            .subscribe(onNext: { [weak self] push in
                let state = SettingState(pb: push.setting)
                self?.store.setState(state)
                self?.isNeedFetchData = false
                Setting.logger.info("receive a setting push. setting: \(state.logInfo)")
            })
            .disposed(by: disposeBag)
    }

    private func updateListViewSetting(_ listViewSetting: Rust.ListViewSetting, onError: (() -> Void)?) {
        operateApi?.updateListViewSetting(viewSetting: listViewSetting).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: {
                    Setting.logger.info("updateListViewSetting successed. setting: \(listViewSetting.logInfo)")
                },
                onError: { error in
                    onError?()
                    Setting.logger.info("updateListViewSetting failed. error: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func updateLaunchScreen(_ launchScreen: Rust.ListLaunchScreen, onError: (() -> Void)?) {
        operateApi?.updateLaunchScreen(from: launchScreen).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: {
                    Setting.logger.info("updateLaunchScreen successed. setting: \(launchScreen.logInfo)")
                },
                onError: { error in
                    onError?()
                    Setting.logger.info("updateLaunchScreen failed. error: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }
}
