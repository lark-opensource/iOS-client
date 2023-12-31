//
//  LarkProfileSectionTab.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/12/28.
//

import Foundation
import Swinject
import UniverseDesignLoading
import LarkContainer
import RxSwift
import ServerPB
import LKCommonsTracker
import Homeric

public final class LarkProfileSectionTab: ProfileSectionTab, LarkProfileTab {
    
    @ScopedInjectedLazy var profileAPI: LarkProfileAPI?
    private let tabKey: String
    private var context: ProfileContext
    private var profile: ProfileInfoProtocol
    private var disposeBag = DisposeBag()

    public static func createTab(by tab: LarkUserProfilTab,
                                 resolver: UserResolver,
                                 context: ProfileContext,
                                 profile: ProfileInfoProtocol,
                                 dataProvider: ProfileDataProvider) -> ProfileTabItem? {
        guard tab.tabType == .fSectionCluster else {
            return nil
        }

        let title = tab.name.getString()
        return ProfileTabItem(title: title,
                              identifier: "LarkProfileSectionTab" + title) { [weak dataProvider] in
            guard let provider = dataProvider else {
                return ProfileBaseTab()
            }

            let item1 = ProfileSectionSkeletonItem(styles: [.title, .content, .content])
            let item2 = ProfileSectionSkeletonItem(styles: [.title, .subtitle, .subtitle])
            return LarkProfileSectionTab(resolver: resolver,
                                         tabKey: tab.key,
                                         title: title,
                                         sectionItems: [item1, item2],
                                         profile: profile,
                                         context: context)
        }
    }

    init(resolver: UserResolver,
         tabKey: String,
         title: String,
         sectionItems: [ProfileSectionItem] = [],
         profile: ProfileInfoProtocol,
         context: ProfileContext) {
//        self.userResolver = resolver
        self.context = context
        self.tabKey = tabKey
        self.profile = profile
        super.init(resolver: resolver, title: title, sectionItems: sectionItems)

        self.errorLoad = { [weak self] in
            self?.fetchData()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }

    public func update(_ profile: ProfileInfoProtocol, context: ProfileContext) {
        self.profile = profile
        self.context = context
        self.fetchData()
    }

    public func fetchData() {
        guard let data = context.data as? LarkProfileData, let source = ProfileSource(rawValue: data.source.rawValue) else { return }
        let scene: ProfileScene = self.profile.userInfoProtocol.userID.isEmpty ? .byContactToken : .byUserID
        self.profileAPI?
            .getSectionClusterTab(userID: self.profile.userInfoProtocol.userID,
                                  contactToken: data.contactToken,
                                  scene: scene,
                                  source: source,
                                  sectionKeys: [self.tabKey])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                let items = LarkProfileSectionTab.transformServerPB(by: self.tabKey,
                                                                    response: response)
                self.trackTabInformation(isFailed: false, sectionCount: items.count)
                self.updateSections(items)
            }, onError: { [weak self] (_) in
                guard let self = self else { return }
                self.trackTabInformation(isFailed: true, sectionCount: 0)
                self.updateSections([], isError: true)
            }).disposed(by: self.disposeBag)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        var params: [AnyHashable: Any] = [:]
        params["click"] = self.tabKey
        params["to_user_id"] = profile.userInfoProtocol.userID
        params["target"] = "profile_tab_information_view"
        Tracker.post(TeaEvent(Homeric.PROFILE_MAIN_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }

    private func trackTabInformation(isFailed: Bool, sectionCount: Int) {
        var params: [AnyHashable: Any] = [:]
        params["tab"] = self.tabKey
        params["section_count"] = sectionCount
        params["state"] = isFailed ? "fail" : "success"
        Tracker.post(TeaEvent(Homeric.PROFILE_TAB_INFORMATION_VIEW, params: params))
    }
}

public extension LarkProfileSectionTab {
    class func transformServerPB(by tabKey: String,
                                 response: ServerPB.ServerPB_Users_PullSectionClusterTabResponse) -> [ProfileSectionItem] {
        guard let tabs = response.sectionTabs[tabKey]?.sections else {
            return []
        }
        var items: [ProfileSectionItem] = []
        for tab in tabs {
            var item = ProfileSectionNormalItem()
            let titleContent = tab.refLink.fieldName.getString()
            let title = ProfileSectionTitleCellItem(title: tab.name.getString(),
                                                    content: titleContent,
                                                    showPushIcon: tab.refLink.link.isEmpty ? false : true,
                                                    pushLink: tab.refLink.link)
            item.cellItems.append(title)
            for normalItem in tab.items {
                let content = normalItem.content.fieldName.getString()
                if content.isEmpty {
                    let cellItem = ProfileSectionNormalCellItem(title: normalItem.title.getString(),
                                                                subTitle: normalItem.subTitle.getString(),
                                                                content: content,
                                                                showPushIcon: normalItem.content.link.isEmpty ? false : true,
                                                                pushLink: normalItem.content.link)
                    item.cellItems.append(cellItem)
                } else {
                    let cellItem = ProfileSectionLinkCellItem(title: normalItem.title.getString(),
                                                              subTitle: normalItem.subTitle.getString(),
                                                              content: content,
                                                              pushLink: normalItem.content.link)
                    item.cellItems.append(cellItem)
                }
            }
            items.append(item)
        }
        return items
    }
}
