//
//  SceneListViewModel.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/7.
//

import Foundation
import LarkModel // Chat
import LarkContainer // UserResolver
import LarkEMM // SCPasteboard
import LarkSensitivityControl // Token
import LarkSDKInterface // SDKRustService
import ServerPB // ServerPB
import RxSwift // DisposeBag
import LKCommonsLogging // Logger
import LarkAIInfra // MyAISceneService
import LarkAccountInterface // PassportUserService

final class SceneListViewModel {
    private let logger = Logger.log(SceneListViewModel.self, category: "Module.LarkAI")
    let disposeBag = DisposeBag()
    let chat: Chat
    private let userResolver: UserResolver
    private var sceneAPI: SceneAPI?
    private(set) var sceneService: MyAISceneService?
    private(set) var userService: PassportUserService?
    /// 选中了某个场景，目前场景只支持单选模式
    private(set) var selected: ((_ sceneId: Int64) -> Void)

    /// 当前已经拉取下来的所有数据
    var dataSource: [ServerPB_Office_ai_MyAIScene] = []
    /// 是否有下一页数据
    private(set) var hasMore: Bool = false
    /// 拉取当前页后，服务端返回的下一页开始位置
    private(set) var pageOffset: Int64 = 0

    init(userResolver: UserResolver, chat: Chat, selected: @escaping ((_ sceneId: Int64) -> Void)) {
        self.chat = chat
        self.userResolver = userResolver
        self.selected = selected
        self.sceneAPI = try? userResolver.resolve(assert: SceneAPI.self)
        self.sceneService = try? userResolver.resolve(assert: MyAISceneService.self)
        self.userService = try? userResolver.resolve(assert: PassportUserService.self)
        // 默认先展示上次离开时获取到的首屏场景
        self.dataSource = self.sceneService?.cacheScenes ?? []
    }

    /// 内存缓存中存储一份首屏场景数据
    func saveSceneListToCache() {
        self.sceneService?.cacheScenes = Array(self.dataSource.prefix(20))
        self.logger.info("my ai cache scene list, count:\(self.sceneService?.cacheScenes.count ?? 0)")
    }

    /// 下拉刷新、上拉加载，firstPage传true表示下拉刷新，否则表示上拉加载
    func fetchSceneList(firstPage: Bool, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) {
        self.logger.info("my ai fetch scene begin, firstPage:\(firstPage)")
        self.sceneAPI?.fetchSceneList(pageOffset: firstPage ? 0 : self.pageOffset).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] response in
            guard let `self` = self else { return }
            self.logger.info("my ai fetch scene success, firstPage:\(firstPage), count:\(response.scene.count) more:\(response.hasMore_p) offset:\(response.pageOffset)")
            // 第一页拉取完后，直接移除现有数据
            if firstPage { self.dataSource.removeAll() }
            self.dataSource.append(contentsOf: response.scene)
            self.hasMore = response.hasMore_p
            self.pageOffset = response.pageOffset
            onSuccess()
        }, onError: { error in
            self.logger.error("my ai fetch scene error, firstPage:\(firstPage)", error: error)
            onError(error)
        }).disposed(by: self.disposeBag)
    }

    func switchScene(sceneId: Int64, active: Bool, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) {
        self.logger.info("my ai switch scene begin, active:\(active)")
        self.sceneAPI?.switchScene(sceneId: sceneId, active: active).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.logger.info("my ai switch scene success, active:\(active)")
            // 从数据源中找到这条数据，然后更新场景状态
            if var scene = self.dataSource.first(where: { $0.sceneID == sceneId }) {
                scene.status = active ? .valid : .stop
                self.sceneService?.editSceneSubject.onNext(scene)
            }
            onSuccess()
        }, onError: { [weak self] error in
            self?.logger.error("my ai switch scene error, active:\(active)", error: error)
            onError(error)
        }).disposed(by: self.disposeBag)
    }

    func removeScene(sceneId: Int64, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) {
        self.logger.info("my ai remove scene begin")
        self.sceneAPI?.removeScene(sceneId: sceneId).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.logger.info("my ai remove scene success")
            // 从数据源中找到这条数据，然后更新场景状态
            if var scene = self.dataSource.first(where: { $0.sceneID == sceneId }) {
                scene.status = .delete
                self.sceneService?.editSceneSubject.onNext(scene)
            }
            onSuccess()
        }, onError: { [weak self] error in
            self?.logger.error("my ai remove scene error", error: error)
            onError(error)
        }).disposed(by: self.disposeBag)
    }

    func shareScene(sceneId: Int64, onSuccess: @escaping (() -> Void), onError: @escaping ((Error) -> Void)) {
        self.logger.info("my ai share scene begin")
        self.sceneAPI?.shareScene(sceneId: sceneId).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] link in
            guard let `self` = self else { return }
            let config = PasteboardConfig(token: Token("LARK-PSDA-myai_share_scene_copy"))
            SCPasteboard.general(config).string = link
            self.logger.info("my ai share scene success, link count:\(link.count)")
            onSuccess()
        }, onError: { [weak self] error in
            self?.logger.error("my ai share scene error", error: error)
            onError(error)
        }).disposed(by: self.disposeBag)
    }
}
