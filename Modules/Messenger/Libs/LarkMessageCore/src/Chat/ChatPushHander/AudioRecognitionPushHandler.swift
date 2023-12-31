//
//  AudioRecognitionPushHandler.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2019/7/9.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import UniverseDesignToast
import LarkSDKInterface
import EENavigator

final class AudioRecognitionPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(
        channelId: String,
        needCachePush: Bool,
        userResolver: UserResolver
    ) -> PushHandler {
        return AudioRecognitionPushHandler(channelId: channelId, needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class AudioRecognitionPushHandler: PushHandler {
    var channelId: String

    let disposeBag: DisposeBag = DisposeBag()
    init(channelId: String, needCachePush: Bool, userResolver: UserResolver) {
        self.channelId = channelId
        super.init(needCachePush: needCachePush, userResolver: userResolver)
    }

    override func startObserve()throws {
        let channelID = self.channelId
        try self.userResolver.userPushCenter
            .observable(for: PushAudioMessageRecognitionResult.self)
            .observeOn(MainScheduler.instance)
            .filter({ (result) -> Bool in
                // 只有在识别结果为空的时候弹出提示
                return result.isEnd && result.result.isEmpty && result.channelID == channelID
            })
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                self.dataSourceAPI?.update(
                    messageIds: [result.messageID],
                    doUpdate: { (_) -> PushData? in
                        DispatchQueue.main.async {
                            // 无UI上下文，只能暂时取MainScene
                            if let window = self.userResolver.navigator.mainSceneWindow {
                                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Chat_AudioConvertToTextError,
                                                       on: window)
                            }
                        }
                        return nil
                    })
            }).disposed(by: disposeBag)
    }
}
