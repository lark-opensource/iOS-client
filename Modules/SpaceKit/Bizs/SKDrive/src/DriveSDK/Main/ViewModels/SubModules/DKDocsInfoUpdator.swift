//
//  DKDocsInfoUpdator.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/23.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKInfra

class DKDocsInfoUpdator: DKBaseSubModule {
    private var wikiMetaUpdator = WikiMetaUpdator()
    deinit {
        DocsLogger.driveInfo("DKDocsInfoUpdator -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        hostModule?.reachabilityChanged.distinctUntilChanged().subscribe(onNext: { [weak self] reachable in
            if reachable {
                self?.fetchDocsInfoIfNeeded()
            }
        }).disposed(by: bag)
        hostModule?.fileInfoRelay.subscribe(onNext: { [weak self] fileInfo in
            guard let self = self else { return }
            self.docsInfo.fileType = fileInfo.type
            self.hostModule?.docsInfoRelay.accept(self.docsInfo)
        }).disposed(by: bag)

        // 密级权限改动推送
        hostModule?.subModuleActionsCenter.subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            if case .updateDocsInfo = action {
                self.fetchDocsInfoIfNeeded()
            }
        }).disposed(by: bag)
        return self
    }
    
    /// fetchDocsInfo
    func fetchDocsInfoIfNeeded() {
        guard let host = hostModule else { return }
        DocsLogger.driveInfo("fetchDocsInfo")
        let curDocsInfo = self.docsInfo
        var cacheWikiToken: String?
        let group = DispatchGroup()
        group.enter()
        host.netManager.fetchDocsInfo(docsInfo: curDocsInfo) { [weak self, weak host] _ in
            guard let self = self, let host = host else { return }
            group.leave()
        }
        // 如果从wiki打开需要更新docsInfo.wikiInfo
        if host.commonContext.previewFrom == .wiki {
            guard let wikiToken = host.commonContext.wikiToken,
                  var wikiInfo = DocsContainer.shared.resolve(SKDriveDependency.self)!.getWikiInfo(by: wikiToken) else {
                spaceAssertionFailure("preview from wiki need wikitoken")
                return
            }
            curDocsInfo.wikiInfo = wikiInfo
            group.enter()
            wikiMetaUpdator.fetchWikiMetaV2(with: wikiToken, spaceId: wikiInfo.spaceId).subscribe(onSuccess: {[weak self] state in
                DocsLogger.driveInfo("did fetch wikiNodeState")
                curDocsInfo.wikiInfo?.wikiNodeState = state
                cacheWikiToken = wikiToken
                self?.hostModule?.subModuleActionsCenter.accept(.wikiNodeDeletedStatus(isDelete: false))
                group.leave()
            }, onError: { [weak self] error in
                // wiki的删除兜底页放在getNode后处理
                if let code = (error as? NSError)?.code,
                   let wikiError = WikiErrorCode(rawValue: code),
                   (wikiError == .sourceNotExist || wikiError == .nodeHasBeenDeleted) {
                    self?.handleWikiNodeIsDelete()
                }
                group.leave()
            }).disposed(by: bag)
        }
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            curDocsInfo.fileType = self.fileInfo.type
            //这里是为了防止fetchDocsInfo和fetchWikiMetaV2时序出错导致在wiki状况下的shareUrl被修改为非wiki链接
            if let wikiURL = curDocsInfo.wikiInfo?.wikiNodeState.url {
                curDocsInfo.shareUrl = wikiURL
            } else if let cacheWikiToken = cacheWikiToken {
                if let url = curDocsInfo.shareUrl,
                   let spaceURL = URL(string: url) {
                    let wikiURL = WorkspaceCrossRouter.redirect(spaceURL: spaceURL, wikiToken: cacheWikiToken)
                    curDocsInfo.shareUrl = wikiURL.absoluteString
                } else {
                    curDocsInfo.shareUrl = DocsUrlUtil.url(type: .wiki, token: cacheWikiToken).absoluteString
                }
            }
            self.hostModule?.docsInfoRelay.accept(curDocsInfo)
        }
    }

    private func handleWikiNodeIsDelete() {
        guard UserScopeNoChangeFG.ZYP.spaceMoveToEnable else {
            self.hostModule?.subModuleActionsCenter.accept(.wikiNodeDeletedStatus(isDelete: true))
            return
        }
        // 在收藏列表把Space移动到Wiki，再移动回Space后，收藏列表的信息后端不会洗数据，点击打开时会以Wiki形式打开，此时请求Wiki信息肯定是不存在的，导致错误地发出Wiki被删的信号。所以这里前置判断文件所在容器是否已经在Space中，如果在则不会发出wiki节点被删的信号
        WorkspaceCrossNetworkAPI.getContainerInfo(objToken: docsInfo.token, objType: docsInfo.inherentType)
            .subscribe { [weak self] containerInfo, logID in
                guard let self = self else { return }
                guard let containerInfo = containerInfo else {
                    DocsLogger.driveError("fetch containerInfo fail", extraInfo: ["log-id": logID as Any])
                    return
                }
                if containerInfo.containerType == .space {
                    return
                }
                // 发出 Wiki 已被删除信号
                self.hostModule?.subModuleActionsCenter.accept(.wikiNodeDeletedStatus(isDelete: true))
            } onError: { error in
                DocsLogger.driveError("fetch containerInfo failed with error", error: error)
            }
            .disposed(by: bag)
    }
}
