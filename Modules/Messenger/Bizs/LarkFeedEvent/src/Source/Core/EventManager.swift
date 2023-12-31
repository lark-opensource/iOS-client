//
//  EventManager.swift
//  LarkFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkModel
import LarkContainer
import LarkOpenFeed

final class EventManager {
    static let log = Logger.log(EventManager.self, category: "LarkEvent")
    private let disposeBag = DisposeBag()
    let dataQueue = EventDataQueue()

    private(set) var providers: [EventBiz: EventProvider] = [:]
    private var dataModule = EventDataModule()
    private let inputDataCommand: PublishRelay<EventDataCommand> = PublishRelay()

    private let outputDataCommand: BehaviorRelay<EventDataModule> = BehaviorRelay(value: EventDataModule())
    var dataObservable: Observable<EventDataModule> {
        outputDataCommand.asObservable()
    }
    var data: EventDataModule {
        outputDataCommand.value
    }
    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
        bind()
        var providers: [EventBiz: EventProvider] = [:]
        EventFactory.allProviders(context: resolver, dataCommand: inputDataCommand)
            .forEach { provider in
                providers[provider.biz] = provider
            }
        self.providers = providers
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bind() {
        inputDataCommand
            .subscribe(onNext: { [weak self] command in
                guard let self = self else { return }
                let task = { [weak self] in
                    guard let self = self else { return }
                    self.handle(command: command)
                }
                self.dataQueue.addTask(task)
            }).disposed(by: disposeBag)
        screenShot()
    }

    private func handle(command: EventDataCommand) {
        switch command {
        case .insertOrUpdate(let items):
            self.dataModule.insertOrUpdate(items: items)
        case .remove(let ids):
            self.dataModule.remove(ids: ids)
        }
        self.outputDataCommand.accept(self.dataModule)
    }

    func fillter(item: EventItem) {
       let task = { [weak self] in
           guard let self = self else { return }
           self.dataModule.fillter(items: [item])
           guard let provider = self.providers[item.biz] else { return }
           provider.fillter(items: [item])
       }
       self.dataQueue.addTask(task)
    }

    func fillter(items: [EventItem]) {
        let task = { [weak self] in
            guard let self = self else { return }
            self.dataModule.fillter(items: items)
            self.providers.values.forEach { provider in
                provider.fillterAllitems()
            }
        }
        self.dataQueue.addTask(task)
    }
}

// 监听截屏事件，打log
extension EventManager {
    func screenShot() {
        _ = NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.print(data: self.data, extraInfo: "printscreen")
            })

//        NotificationCenter.default.rx.notification(FeedNotification.didChangeDebugMode)
//            .subscribe(onNext: { _ in
//            }).disposed(by: disposeBag)
    }

    func handleDebugEvent(data: EventDataModule) {
        let info = "\(data.datas.map({ $0.id }))"
        UIPasteboard.general.string = info
        print(data: data, extraInfo: "debug")
//        UDToast.showTips(with: info, on: UIApplication.shared.keyWindow)
    }

    private func print(data: EventDataModule, extraInfo: String) {
        let logs = data.description.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            EventManager.log.info("eventlog/\(extraInfo)<\(i)>. \(log)")
        }
    }
}
