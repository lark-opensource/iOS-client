//
//  ForwardFileAlertProvider.swift
//  LarkForward
//
//  Created by kangkang on 2022/8/12.
//

import UIKit
import RxSwift
import LarkCore
import Foundation
import LKCommonsLogging
import UniverseDesignToast
import LarkMessengerInterface
import LarkStorage
import LarkModel

struct ForwardFileAlertContent: ForwardAlertContent {
    let fileURL: String
    let fileName: String
    let fileSize: Int64
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendFileForwardParam(filePath: self.fileURL, fileName: self.fileName)
        let forwardContent = ForwardContentParam.sendFileMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }
    // 展示“创建群组并转发”入口，线上默认展示
    var canCreateGroup: Bool = true
    // 展示话题，线上默认展示
    var includeThread: Bool = true
    // 展示机器人（若该值传false，将置灰机器人，因为老Picker在转发场景里只能置灰机器人，无法过滤机器人），线上默认展示
    var includeBot: Bool = true
    // 展示外部群和外部人，线上默认展示
    var includeOuter: Bool = true
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ForwardFileAlertProvider: ForwardAlertProvider {
    let disposeBag = DisposeBag()
    static let logger = Logger.log(ForwardFileAlertProvider.self, category: "ForwardFile.provider")
    override var pickerTrackScene: String? {
        return "file_forward"
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ForwardFileAlertContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    // 最近转发过滤配置
    override func getFilter() -> ForwardDataFilter? {
        guard let fileContent = content as? ForwardFileAlertContent else { return nil }
        return {
            // 业务不想展示外部人群,isCrossTenant为true的实体将被过滤
            if !fileContent.includeOuter { return !$0.isCrossTenant }
            return true
        }
    }

    // 最近访问过滤配置
    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        guard let fileContent = content as? ForwardFileAlertContent else { return nil }
        // 判断是否过滤外部人、外部群、话题，机器人
        var includeConfigs: IncludeConfigs = [ForwardUserEntityConfig(tenant: fileContent.includeOuter ? .all : .inner),
                                              ForwardGroupChatEntityConfig(tenant: fileContent.includeOuter ? .all : .inner),
                                              ForwardMyAiEntityConfig()]
        if fileContent.includeThread { includeConfigs.append(ForwardThreadEntityConfig()) }
        if fileContent.includeBot { includeConfigs.append(ForwardBotEntityConfig()) }
        return includeConfigs
    }

    // 最近访问和搜索置灰配置
    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let fileContent = content as? ForwardFileAlertContent else { return nil }
        // 搜索目前暂无法过滤机器人，需要置灰机器人来兜底
        var includeConfigs: IncludeConfigs = [ForwardUserEnabledEntityConfig(),
                                              ForwardGroupChatEnabledEntityConfig(),
                                              ForwardThreadEnabledEntityConfig(),
                                              ForwardMyAiEnabledEntityConfig()]
        if fileContent.includeBot { includeConfigs.append(ForwardBotEnabledEntityConfig()) }
        return includeConfigs
    }

    override var shouldCreateGroup: Bool {
        if let fileContent = content as? ForwardFileAlertContent {
            return fileContent.canCreateGroup
        }
        return false
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let fileContent = content as? ForwardFileAlertContent else { return nil }
        let wrapperView = ForwardFileConfirmFooter(content: fileContent)
        wrapperView.didClickAction = { [weak self] in
            guard let self,
                  let targetVc = self.targetVc,
                  let fileDependency = try? self.resolver.resolve(assert: DriveSDKFileDependency.self)
            else { return }
            fileDependency.driveSDKPreviewLocalFile(fileName: fileContent.fileName,
                                                    fileUrl: URL(fileURLWithPath: fileContent.fileURL),
                                                    appID: "10001",
                                                    from: targetVc)
            return
        }
        return wrapperView
    }

    override func shareSureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<ForwardResult> {
        ForwardFileAlertProvider.logger.info("forward file click sure button")
        guard let content = self.content as? ForwardFileAlertContent,
            let window = from.view.window else {
            ForwardFileAlertProvider.logger.error("forward file can not find content or window")
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = PublishSubject<ForwardResult>()
        let forwardService = try? self.userResolver.resolve(assert: ForwardService.self)
        ForwardFileAlertProvider.logger.info("forward file url: \(content.fileURL.asAbsPath().exists) \(content.fileURL) \(content.fileName) \(ids.chatIds)")
        forwardService?.share(fileUrl: content.fileURL,
                              fileName: content.fileName,
                              to: ids.chatIds,
                              userIds: ids.userIds,
                              extraText: input ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { chatIds in
                ForwardFileAlertProvider.logger.info("forward file forward success")
                hud.remove()
                var forwardItems: [ForwardItemParam] = []
                chatIds.forEach {
                    var forwardItemParam = ForwardItemParam(isSuccess: $0.1, type: "", name: "", chatID: $0.0, isCrossTenant: false)
                    forwardItems.append(forwardItemParam)
                }
                var forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
                secondConfirmSubject.onNext(forwardResult)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] error in
                ForwardFileAlertProvider.logger.error("forward file forward failed")
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }

    override func shareSureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<ForwardResult> {
        guard let content = self.content as? ForwardFileAlertContent,
            let window = from.view.window else {
            return .just(ForwardResult.success(ForwardParam(forwardItems: [])))
        }
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let secondConfirmSubject = PublishSubject<ForwardResult>()
        let forwardService = try? self.userResolver.resolve(assert: ForwardService.self)
        forwardService?.share(fileUrl: content.fileURL,
                              fileName: content.fileName,
                              to: ids.chatIds, userIds: ids.userIds,
                              attributeExtraText: attributeInput ?? NSAttributedString(string: ""))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { chatIds in
                hud.remove()
                var forwardItems: [ForwardItemParam] = []
                chatIds.forEach {
                    let forwardItemParam = ForwardItemParam(isSuccess: $0.1, type: "", name: "", chatID: $0.0, isCrossTenant: false)
                    forwardItems.append(forwardItemParam)
                }
                let forwardResult = ForwardResult.success(ForwardParam(forwardItems: forwardItems))
                secondConfirmSubject.onNext(forwardResult)
                secondConfirmSubject.onCompleted()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            }).disposed(by: disposeBag)
        return secondConfirmSubject
    }
}
