//
//  DocsShortCutHandler.swift
//  LarkSpaceKit
//
//  Created by lizechuang on 2020/9/25.
//
// Docs文件Feed列表置顶，使用外部能力，在胶水层执行该操作。

import RxSwift
import RustPB
import Swinject

extension DocsFactoryDependencyImpl {

    func markFeedCardShortcut(feedId: String, isShortcut: Bool,
                              type: Basic_V1_Channel.TypeEnum,
                              onSuccess: ((_ tips: String) -> Void)? = nil,
                              onFailed: ((_ error: Error) -> Void)? = nil) {
        var channel = Basic_V1_Channel()
        channel.id = feedId
        channel.type = type

        var shortcut = Feed_V1_Shortcut()
        shortcut.channel = channel

        if isShortcut {
            self.deleteShortcuts([shortcut])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    if let onSuccess = onSuccess {
                        onSuccess(BundleI18n.CCMMod.Lark_Chat_QuickswitcherUnpinClickToasts)
                    }
                }, onError: { (error) in
                    if let onFailed = onFailed {
                        onFailed(error)
                    }
                }).disposed(by: self.disposeBag)
        } else {
            self.createShortcuts([shortcut])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    if let onSuccess = onSuccess {
                        onSuccess(BundleI18n.CCMMod.Lark_Chat_QuickswitcherUnpinClickToasts)
                    }
                }, onError: { (error) in
                    if let onFailed = onFailed {
                        onFailed(error)
                    }
                }).disposed(by: self.disposeBag)
        }
    }

    private func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        #if MessengerMod
        return self.feedAPI.deleteShortcuts(shortcuts)
        #else
        return .empty()
        #endif
    }

    private func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        #if MessengerMod
        return self.feedAPI.createShortcuts(shortcuts)
        #else
        return .empty()
        #endif
    }
}
