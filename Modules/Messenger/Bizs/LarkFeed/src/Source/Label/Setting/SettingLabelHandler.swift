//
//  SettingLabelHandler.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/20.
//

import Foundation
import LarkOpenFeed
import LarkSDKInterface
import EENavigator
import Swinject
import RxSwift
import RxCocoa
import LarkAccountInterface
import LarkNavigator

/// setting label
final class SettingLabelHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: SettingLabelBody, req: EENavigator.Request, res: Response) throws {
        var vm: SettingLabelViewModel?
        let resolver = self.userResolver
        switch body.mode {
        case .create:
            vm = try CreateLabelViewModel(resolver: resolver, entityId: body.entityId, successCallback: body.successCallback)
        case .edit:
            if let labelId = body.labelId, let labelName = body.labelName {
                vm = try EditLabelViewModel(resolver: resolver, labelId: labelId, labelName: labelName)
            }
        }
        if let viewModel = vm {
            let vc = SettingLabelViewController(vm: viewModel)
            res.end(resource: vc)
        } else {
            res.end(error: RouterError.invalidParameters("setting label mode error"))
        }
    }
}

/// setting label
final class SettingLabelListHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: SettingLabelListBody, req: EENavigator.Request, res: Response) throws {
            let resolver = self.userResolver
            let feedApi = try resolver.resolve(assert: FeedAPI.self)
            let pushLabels = try resolver.userPushCenter.observable(for: PushLabel.self)
            let vm = SettingLabelListViewModel(resolver: resolver,
                                               labelListAPI: feedApi,
                                               entityId: body.entityId,
                                               labelIds: body.labelIds,
                                               pushLabels: pushLabels)
            let vc = SettingLabelListController(vm: vm)
            res.end(resource: vc)
    }
}

final class AddItemInToLabelBodyHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: AddItemInToLabelBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let feedAPI = try resolver.resolve(assert: FeedAPI.self)
        // 确认下是否当前用户创建过label
        feedAPI.getLabelsForFeed(feedId: String(body.feedId))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { response in
                let labelIds = response.groups.map({ $0.id })
                if labelIds.isEmpty {
                    body.infoCallback?(.create, false)
                    let body = SettingLabelBody(mode: .create, entityId: body.feedId, labelId: nil, labelName: nil, successCallback: nil)
                    res.redirect(body: body)
                } else {
                    let existedGroupIds = response.existedGroupIds
                    body.infoCallback?(.edit, !existedGroupIds.isEmpty)
                    let body = SettingLabelListBody(entityId: body.feedId, labelIds: existedGroupIds)
                    res.redirect(body: body)
                }
            })
        res.wait()
    }
}
