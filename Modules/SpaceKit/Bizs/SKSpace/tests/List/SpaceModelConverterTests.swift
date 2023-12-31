//
//  SpaceModelConverterTests.swift
//  SKSpace_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/6/15.
// swiftlint:disable file_length type_body_length

import Foundation
@testable import SKSpace
@testable import SKCommon
import SKFoundation
import XCTest
import SKResource
import UniverseDesignEmpty
import SpaceInterface

class EmptyListInteractionHandler: SpaceListItemInteractHandler {
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        { _ in }
    }
    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        { _ in }
    }
    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        SpaceListItem.SlideConfig(actions: [], handler: { _, _ in })
    }
    // 为无权限文件生成侧滑菜单，仅在子文件夹内需要处理
    func generateSlideConfigForNoPermissionEntry(entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        nil
    }
}

class SpaceModelConverterTests: XCTestCase {

    typealias Context = SpaceModelConverter.Context
    typealias Config = SpaceModelConverter.Config
    typealias R = BundleI18n.SKResource

    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    private func convert(entry: SpaceEntry, context: Context? = nil, isReachable: Bool) -> SpaceListItem {
        let netMonitor = MockNetworkStatusMonitor()
        netMonitor.isReachable = isReachable
        return convert(entry: entry,
                       context: context,
                       config: Config(secretLabelEnable: true, netMonitor: netMonitor, preferSquareDefaultIcon: false))
    }

    private func convert(entry: SpaceEntry, context: Context? = nil, config: Config? = nil) -> SpaceListItem {
        let netMonitor = MockNetworkStatusMonitor()
        netMonitor.isReachable = true
        let config = config ?? Config(secretLabelEnable: true, netMonitor: netMonitor, preferSquareDefaultIcon: false)
        let context = context ?? Context(sortType: .allTime, folderEntry: nil, listSource: .recent)
        let items = SpaceModelConverter.convert(entries: [entry],
                                                context: context,
                                                config: config,
                                                handler: EmptyListInteractionHandler())
        return items.first!
    }

    private func convert(entry: SpaceEntry, list: FileSource, sortType: SpaceSortHelper.SortType) -> SpaceListItem {
        convert(entry: entry, context: Context(sortType: sortType, folderEntry: nil, listSource: list))
    }

    // 这里逐个测试 SpaceListItem 的各个属性生成逻辑是否符合预期

    func testConvertEnable() {
        let offlineEnableEntry = SpaceEntry(type: .doc,
                                            nodeToken: "fake_mock-node-token",
                                            objToken: "fake_mock-obj-token")
        let offlineDisableEntry = SpaceEntry(type: .unknownDefaultType,
                                             nodeToken: "mock-unknown-token",
                                             objToken: "mock-unknown-token")
        var item = convert(entry: offlineEnableEntry)
        XCTAssertTrue(item.enable)
        item = convert(entry: offlineDisableEntry)
        XCTAssertTrue(item.enable)

        item = convert(entry: offlineEnableEntry, isReachable: false)
        XCTAssertTrue(item.enable)
        item = convert(entry: offlineDisableEntry, isReachable: false)
        XCTAssertFalse(item.enable)
    }

    func testTitle() {
        let hasPermEntry = SpaceEntry(type: .doc,
                                      nodeToken: "mock-has-perm-token",
                                      objToken: "mock-has-perm-token")
        hasPermEntry.updateName("mock-has-perm-name")
        XCTAssertTrue(hasPermEntry.docsType.isBiz)
        XCTAssertTrue(hasPermEntry.hasPermission)
        var item = convert(entry: hasPermEntry)
        XCTAssertEqual(item.title, hasPermEntry.name)

        let noPermEntry = SpaceEntry(type: .doc,
                                     nodeToken: "mock-no-perm-token",
                                     objToken: "mock-no-perm-token")
        noPermEntry.updateName("mock-no-perm-name")
        noPermEntry.updateExtraValue(["has_perm": false])
        XCTAssertTrue(noPermEntry.docsType.isBiz)
        XCTAssertFalse(noPermEntry.hasPermission)
        item = convert(entry: noPermEntry)
        XCTAssertEqual(item.title, R.Doc_List_Unauthorized_File)

        let nonBizNoPermEntry = SpaceEntry(type: .unknownDefaultType,
                                           nodeToken: "mock-no-perm-no-biz-token",
                                           objToken: "mock-no-perm-no-biz-token")
        nonBizNoPermEntry.updateName("mock-no-perm-no-biz-name")
        nonBizNoPermEntry.updateExtraValue(["has_perm": false])
        XCTAssertFalse(nonBizNoPermEntry.docsType.isBiz)
        XCTAssertFalse(nonBizNoPermEntry.hasPermission)
        item = convert(entry: nonBizNoPermEntry)
        XCTAssertEqual(item.title, nonBizNoPermEntry.name)
    }

    func testMoreEnable() {
        let hasPermEntry = SpaceEntry(type: .doc,
                                      nodeToken: "mock-has-perm-token",
                                      objToken: "mock-has-perm-token")
        XCTAssertTrue(hasPermEntry.docsType.isBiz)
        XCTAssertTrue(hasPermEntry.hasPermission)
        var item = convert(entry: hasPermEntry)
        XCTAssertTrue(item.moreEnable)

        let noPermEntry = SpaceEntry(type: .doc,
                                     nodeToken: "mock-no-perm-token",
                                     objToken: "mock-no-perm-token")
        noPermEntry.updateExtraValue(["has_perm": false])
        XCTAssertTrue(noPermEntry.docsType.isBiz)
        XCTAssertFalse(noPermEntry.hasPermission)
        item = convert(entry: noPermEntry)
        XCTAssertFalse(item.moreEnable)

        // 非 biz 无条件放开 moreEnable，不知道是不是历史 bug
        let nonBizHasPermEntry = SpaceEntry(type: .unknownDefaultType,
                                            nodeToken: "mock-has-perm-token",
                                            objToken: "mock-has-perm-token")
        XCTAssertFalse(nonBizHasPermEntry.docsType.isBiz)
        XCTAssertTrue(nonBizHasPermEntry.hasPermission)
        item = convert(entry: nonBizHasPermEntry)
        XCTAssertTrue(item.moreEnable)

        let nonBizNoPermEntry = SpaceEntry(type: .unknownDefaultType,
                                           nodeToken: "mock-no-perm-no-biz-token",
                                           objToken: "mock-no-perm-no-biz-token")
        nonBizNoPermEntry.updateExtraValue(["has_perm": false])
        XCTAssertFalse(nonBizNoPermEntry.docsType.isBiz)
        XCTAssertFalse(nonBizNoPermEntry.hasPermission)
        item = convert(entry: nonBizNoPermEntry)
        XCTAssertTrue(item.moreEnable)
    }

    func testIsStar() {
        // 非收藏列表里的非收藏节点
        let nonStarEntry = SpaceEntry(type: .doc,
                                      nodeToken: "mock-has-perm-token",
                                      objToken: "mock-has-perm-token")
        XCTAssertFalse(nonStarEntry.stared)
        var item = convert(entry: nonStarEntry)
        XCTAssertFalse(item.isStar)

        // 非收藏列表里的收藏节点
        let starEntry = SpaceEntry(type: .doc,
                                   nodeToken: "mock-has-perm-token",
                                   objToken: "mock-has-perm-token")
        starEntry.updateStaredStatus(true)
        XCTAssertTrue(starEntry.stared)
        item = convert(entry: starEntry)
        XCTAssertTrue(item.isStar)

        // 收藏列表里的收藏节点
        item = convert(entry: starEntry, context: Context(sortType: .allTime, folderEntry: nil, listSource: .favorites))
        XCTAssertFalse(item.isStar)
    }

    func testIsShortcut() {
        let normalEntry = SpaceEntry(type: .doc,
                                     nodeToken: "mock-has-perm-token",
                                     objToken: "mock-has-perm-token")
        XCTAssertFalse(normalEntry.isShortCut)
        var item = convert(entry: normalEntry)
        XCTAssertFalse(item.isShortCut)

        let shortcutEntry = SpaceEntry(type: .doc,
                                       nodeToken: "mock-has-perm-token",
                                       objToken: "mock-has-perm-token")
        shortcutEntry.updateNodeType(1)
        XCTAssertTrue(shortcutEntry.isShortCut)
        item = convert(entry: shortcutEntry)
        XCTAssertTrue(item.isShortCut)
    }

    func testAccessoryItem() {
        /// AccessoryItem 受以下几个因素影响
        /// - 有 folderEntry
        /// - folder.isOldShareFolder = true
        /// - folder.isExternal = true
        /// - file.type.isBiz = true
        /// - file.externalSwitch = true
        /// - file.hasPermission = true
        /// - file.ownerIsCurrentUser (影响按钮颜色)
        let mockUserID = "mock-owner-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID)
        User.current.reloadUserInfo(mockUserInfo)
        defer {
            if let info = originUserInfo {
                User.current.reloadUserInfo(info)
            }
        }
        let folderEntry = FolderEntry(type: .folder, nodeToken: "mock-folder-node-token", objToken: "mock-folder-obj-token")
        folderEntry.updateOwnerType(1)
        folderEntry.updateExtraValue(["is_external": true])

        let entry = SpaceEntry(type: .doc, nodeToken: "mock-node-token", objToken: "mock-obj-token")
        entry.externalSwitch = true
        entry.updateExtraValue(["has_perm": true])
        entry.updateOwnerID(mockUserID)

        func convertItem() -> SpaceListItem {
            convert(entry: entry,
                    context: Context(sortType: .allTime,
                                     folderEntry: folderEntry,
                                     listSource: .subFolder),
                    isReachable: true)
        }

        XCTAssertTrue(folderEntry.isOldShareFolder)
        XCTAssertTrue(folderEntry.isExternal)
        XCTAssertTrue(entry.type.isBiz)
        XCTAssertTrue(entry.hasPermission)
        XCTAssertTrue(entry.ownerIsCurrentUser)
        XCTAssertEqual(entry.authPromptType, AuthPromptType.highlight)
        var item = convertItem()
        XCTAssertEqual(item.accessoryItem?.identifier, "permission-tips")

        folderEntry.updateOwnerType(0)
        folderEntry.updateExtra()
        XCTAssertFalse(folderEntry.isOldShareFolder)
        item = convertItem()
        XCTAssertNil(item.accessoryItem)
        folderEntry.updateOwnerType(1)
        folderEntry.updateExtra()
        XCTAssertTrue(folderEntry.isOldShareFolder)

        folderEntry.updateExtraValue(["is_external": false])
        XCTAssertFalse(folderEntry.isExternal)
        item = convertItem()
        XCTAssertNil(item.accessoryItem)
        folderEntry.updateExtraValue(["is_external": true])
        XCTAssertTrue(folderEntry.isExternal)

        let nonBizEntry = SpaceEntry(type: .unknownDefaultType,
                                     nodeToken: "mock-node-token",
                                     objToken: "mock-obj-token")
        nonBizEntry.externalSwitch = true
        nonBizEntry.updateExtraValue(["has_perm": true])
        nonBizEntry.updateOwnerID(mockUserID)
        XCTAssertFalse(nonBizEntry.type.isBiz)
        XCTAssertTrue(nonBizEntry.hasPermission)
        XCTAssertTrue(nonBizEntry.ownerIsCurrentUser)
        item = convert(entry: nonBizEntry,
                       context: Context(sortType: .allTime,
                                        folderEntry: folderEntry,
                                        listSource: .subFolder),
                       isReachable: true)
        XCTAssertNil(item.accessoryItem)

        entry.updateExtraValue(["has_perm": false])
        XCTAssertFalse(entry.hasPermission)
        XCTAssertEqual(entry.authPromptType, AuthPromptType.none)
        item = convertItem()
        XCTAssertNil(item.accessoryItem)
        entry.updateExtraValue(["has_perm": true])
        XCTAssertTrue(entry.hasPermission)

        entry.updateOwnerID("\(mockUserID)-2")
        XCTAssertFalse(entry.ownerIsCurrentUser)
        XCTAssertEqual(entry.authPromptType, AuthPromptType.normal)
        item = convertItem()
        XCTAssertEqual(item.accessoryItem?.identifier, "permission-tips")
        entry.updateOwnerID(mockUserID)
        XCTAssertTrue(entry.ownerIsCurrentUser)

        entry.externalSwitch = nil
        XCTAssertEqual(entry.authPromptType, AuthPromptType.none)
        item = convertItem()
        XCTAssertNil(item.accessoryItem)
        entry.externalSwitch = false
        XCTAssertEqual(entry.authPromptType, AuthPromptType.none)
        item = convertItem()
        XCTAssertNil(item.accessoryItem)
        entry.externalSwitch = true
        XCTAssertEqual(entry.authPromptType, AuthPromptType.highlight)

        // 兜底验证
        item = convertItem()
        XCTAssertEqual(item.accessoryItem?.identifier, "permission-tips")
    }

    func testTemplateTag() {
        let entry = SpaceEntry(type: .doc,
                               nodeToken: "mock-has-perm-token",
                               objToken: "mock-has-perm-token")
        XCTAssertFalse(entry.hasTemplateTag)
        var item = convert(entry: entry)
        XCTAssertFalse(item.hasTemplateTag)

        entry.updateExtraValue(["template_type": 0])
        XCTAssertFalse(entry.hasTemplateTag)
        item = convert(entry: entry)
        XCTAssertFalse(item.hasTemplateTag)

        entry.updateExtraValue(["template_type": 1])
        XCTAssertTrue(entry.hasTemplateTag)
        item = convert(entry: entry)
        XCTAssertTrue(item.hasTemplateTag)
    }

    func testIsExternal() {
        /// 影响因素
        /// - 非大 B 用户不展示
        /// - folder shortcut 不展示
        /// - 在外部文件夹内不展示
        /// - 在文件夹列表，但没有 parentFolderEntry，不展示
        /// - 最终取决于 file.isExternal
        let mockUserID = "mock-owner-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID)
        mockUserInfo.userType = .standard
        User.current.reloadUserInfo(mockUserInfo)
        defer {
            if let info = originUserInfo {
                User.current.reloadUserInfo(info)
            }
        }

        let entry = SpaceEntry(type: .doc, nodeToken: "mock-node-token", objToken: "mock-obj-token")
        entry.updateExtraValue(["is_external": true])

        XCTAssertTrue(EnvConfig.CanShowExternalTag.value)
        XCTAssertTrue(entry.isExternal)
        var item = convert(entry: entry)
        XCTAssertTrue(item.isExternal)

        // 测试非大B
        mockUserInfo.userType = .simple
        XCTAssertFalse(EnvConfig.CanShowExternalTag.value)
        item = convert(entry: entry)
        XCTAssertFalse(item.isExternal)
        mockUserInfo.userType = .standard
        XCTAssertTrue(EnvConfig.CanShowExternalTag.value)

        // 测试 folder shortcut
        let folderShortcut = FolderEntry(type: .folder, nodeToken: "mock-folder-token", objToken: "mock-folder-token")
        folderShortcut.updateNodeType(1)
        XCTAssertTrue(folderShortcut.isShortCut)
        item = convert(entry: folderShortcut)
        XCTAssertFalse(item.isExternal)

        // 测试在外部文件夹内
        let parentFolder = FolderEntry(type: .folder, nodeToken: "mock-folder-token", objToken: "mock-folder-token")
        parentFolder.updateExtraValue(["is_external": true])
        XCTAssertTrue(parentFolder.isExternal)
        item = convert(entry: entry, context: Context(sortType: .allTime, folderEntry: parentFolder, listSource: .subFolder))
        XCTAssertFalse(item.isExternal)

        // 测试在文件夹内，但是没有传 parent
        item = convert(entry: entry, context: Context(sortType: .allTime, folderEntry: nil, listSource: .subFolder))
        XCTAssertFalse(item.isExternal)

        // 测试在非外部文件夹内
        parentFolder.updateExtraValue(["is_external": false])
        XCTAssertFalse(parentFolder.isExternal)
        item = convert(entry: entry, context: Context(sortType: .allTime, folderEntry: parentFolder, listSource: .subFolder))
        XCTAssertTrue(item.isExternal)

        // 测试 entry 自身的 isExternal
        entry.updateExtraValue(["is_external": false])
        XCTAssertFalse(entry.isExternal)
        item = convert(entry: entry)
        XCTAssertFalse(item.isExternal)
        entry.updateExtraValue(["is_external": true])
        XCTAssertTrue(entry.isExternal)

        item = convert(entry: entry)
        XCTAssertTrue(item.isExternal)
    }

    func testOrganizationTag() {
        /// 影响因素
        /// - 在文件夹内，且文件夹有关联组织 tag 信息，不展示
        /// - 最终取决于 file.organizationTagValue
        let mockTag = "MOCK_TAG"
        let entry = SpaceEntry(type: .doc, nodeToken: "mock-node-token", objToken: "mock-obj-token")
        entry.updateExtraValue(["display_tag": ["tag_value": "MOCK_TAG"]])
        XCTAssertEqual(entry.organizationTagValue, mockTag)
        var item = convert(entry: entry)
        XCTAssertEqual(item.organizationTagValue, mockTag)

        // 测试在关联组织文件夹内
        let parentFolder = FolderEntry(type: .folder, nodeToken: "mock-folder-token", objToken: "mock-folder-token")
        // 暂时不关注 tag 内容是否相同
        parentFolder.updateExtraValue(["display_tag": ["tag_value": "OTHER_TAG"]])
        XCTAssertNotNil(parentFolder.organizationTagValue)
        item = convert(entry: entry, context: Context(sortType: .allTime, folderEntry: parentFolder, listSource: .subFolder))
        XCTAssertNil(item.organizationTagValue)

        // 测试在文件夹内，但是没有传 parent
        item = convert(entry: entry, context: Context(sortType: .allTime, folderEntry: nil, listSource: .subFolder))
        XCTAssertEqual(item.organizationTagValue, mockTag)
    }

    func testListIconType() {
        /// 列表缩略图有以下几种类型
        /// - 文档自定义 icon，功能已下线，暂不验证
        /// - drive 缩略图，需要关注 FG 关、密钥失效场景
        /// - 无权限文档
        /// - 普通 icon
        let mockThumbURL = URL(string: "http://unit.test/icon.png")!
        let mockKey = "key"
        let mockNonce = "nonce"
        let file = DriveEntry(type: .file, nodeToken: "mock-drive", objToken: "mock-drive")
        let mockExtraInfo = SpaceThumbnailInfo.ExtraInfo(url: mockThumbURL,
                                                         encryptType: .GCM(secret: mockKey, nonce: mockNonce))
        let thumbInfo = SpaceThumbnailInfo.encryptedOnly(encryptInfo: mockExtraInfo)
        let mockInfo = SpaceList.ThumbnailInfo(token: file.objToken,
                                               thumbInfo: thumbInfo,
                                               source: .spaceList,
                                               fileType: .file,
                                               failedImage: file.defaultIcon,
                                               placeholder: file.defaultIcon)
        let mockIconType = SpaceList.IconType.thumbIcon(thumbInfo: mockInfo)
        file.updateExtraValue([
            "subtype": "png",
            "icon": mockThumbURL.absoluteString,
            "icon_encrypted_type": true,
            "icon_key": mockKey,
            "icon_nonce": mockNonce
        ])
        var item = convert(entry: file)
        XCTAssertEqual(item.listIconType, mockIconType)

        file.update(secretKeyDelete: true)
        item = convert(entry: file)
        XCTAssertEqual(item.listIconType, SpaceList.IconType.icon(image: file.defaultIcon))

        file.updateExtraValue(["has_perm": false])
        item = convert(entry: file)
        XCTAssertEqual(item.listIconType, SpaceList.IconType.icon(image: file.noPermIcon))

        let nonBizEntry = SpaceEntry(type: .unknownDefaultType, nodeToken: "mock", objToken: "mock")
        item = convert(entry: nonBizEntry)
        XCTAssertEqual(item.listIconType, SpaceList.IconType.icon(image: nonBizEntry.defaultIcon))

        nonBizEntry.updateExtraValue(["has_perm": false])
        item = convert(entry: nonBizEntry)
        XCTAssertEqual(item.listIconType, SpaceList.IconType.icon(image: nonBizEntry.defaultIcon))
    }

    func testGridIconType() {
        let file = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        var item = convert(entry: file)
        XCTAssertEqual(item.gridIconType, SpaceList.IconType.icon(image: file.quickAccessImage))

        file.updateExtraValue(["has_perm": false])
        item = convert(entry: file)
        XCTAssertEqual(item.gridIconType, SpaceList.IconType.icon(image: file.noPermIcon))

        let nonBizEntry = SpaceEntry(type: .unknownDefaultType, nodeToken: "mock", objToken: "mock")
        item = convert(entry: nonBizEntry)
        XCTAssertEqual(item.listIconType, SpaceList.IconType.icon(image: nonBizEntry.quickAccessImage))

        nonBizEntry.updateExtraValue(["has_perm": false])
        item = convert(entry: nonBizEntry)
        XCTAssertEqual(item.listIconType, SpaceList.IconType.icon(image: nonBizEntry.quickAccessImage))
    }

    func testUploadSyncStatus() {
        let entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.syncStatus = SyncStatus(upSyncStatus: .waiting, downloadStatus: .none)
        var item = convert(entry: entry)
        var config = SpaceEntry.SyncUIConfig(show: true,
                                             image: SpaceEntry.upWaitingImage,
                                             title: R.Doc_List_WaitingForSync,
                                             isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .uploading, downloadStatus: .none)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.syncingImage,
                                         title: R.Doc_List_Syncing,
                                         isSyncing: true)
        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .finish, downloadStatus: .none)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.finishImage,
                                         title: R.Doc_Normal_FinishSynchronizing,
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        // finishOver1s 并到 download 里判断
//        entry.syncStatus = SyncStatus(upSyncStatus: .finishOver1s, downloadStatus: .none)
//        item = convert(entry: entry)
//        config = SpaceEntry.SyncUIConfig(show: true,
//                                         image: SpaceEntry.finishImage,
//                                         title: R.Doc_Normal_FinishSynchronizing,
//                                         isSyncing: false)
//        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .failed, downloadStatus: .none)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.failedImage,
                                         title: R.Doc_List_SyncFailed,
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)
    }

    func testDownloadSyncStatus() {
        // 不支持手动离线
        var entry: SpaceEntry = WikiEntry(type: .wiki, nodeToken: "mock", objToken: "mock")
        var item = convert(entry: entry)
        var config = SpaceEntry.SyncUIConfig(show: false,
                                             image: nil,
                                             title: entry.subtitle(listSource: .recent, sortType: .allTime),
                                             isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        // 支持但没有设置手动离线
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .none)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: false,
                                         image: nil,
                                         title: entry.subtitle(listSource: .recent, sortType: .allTime),
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        // finishOver1s 并到 download 里判断
        entry.isSetManuOffline = true
        entry.syncStatus = SyncStatus(upSyncStatus: .finishOver1s, downloadStatus: .none)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: false,
                                         image: nil,
                                         title: "",
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        // show 过会忽略 downloadStatus
        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .waiting)
        entry.hadShownManuStatus = true
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.successImage,
                                         title: entry.subtitle(listSource: .recent, sortType: .allTime),
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        entry.hadShownManuStatus = false
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.downWaitingImage,
                                         title: R.Doc_List_OfflineWaitDownload,
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .downloading)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.syncingImage,
                                         title: R.Doc_List_OfflineDownloading,
                                         isSyncing: true)
        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .success)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.successImage,
                                         title: R.Doc_List_OfflineDownloadSucceed,
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .successOver2s)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.successImage,
                                         title: entry.subtitle(listSource: .recent, sortType: .allTime),
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)

        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .fail)
        item = convert(entry: entry)
        config = SpaceEntry.SyncUIConfig(show: true,
                                         image: SpaceEntry.failedImage,
                                         title: R.Doc_List_OfflineDownloadFailed,
                                         isSyncing: false)
        XCTAssertEqual(item.syncStatus, config)
    }

    func testSecretLabelName() {
        /// 密级标签是否展示受以下因素控制
        /// - FG
        /// - entry.ownerTenantID == user.tenantID
        /// - !entry.secretLabelName.isEmpty
        /// - entry.secLabelCode == .success
        /// - entry.typeSupportSecurityLevel

        func convertItem(entry: SpaceEntry, secretFG: Bool = true) -> SpaceListItem {
            let netMonitor = MockNetworkStatusMonitor()
            netMonitor.isReachable = true
            let config = Config(secretLabelEnable: secretFG, netMonitor: netMonitor, preferSquareDefaultIcon: false)
            return convert(entry: entry,
                           config: config)
        }

        let mockUserID = "mock-owner-id"
        let mockTenantID = "mock-tenant-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID, mockTenantID)
        mockUserInfo.userType = .standard
        User.current.reloadUserInfo(mockUserInfo)
        defer {
            if let info = originUserInfo {
                User.current.reloadUserInfo(info)
            }
        }
        let mockLabelName = "mock-label-name"

        func mockEntry(type: DocsType) -> SpaceEntry {
            let entry = SpaceEntryFactory.createEntry(type: type, nodeToken: "mock", objToken: "mock")
            entry.ownerTenantID = mockTenantID
            entry.update(secureLabelName: mockLabelName)
            entry.update(secLabelCode: .success)
            // typeSupportSecurityLevel
            entry.updateNodeType(nil)
            entry.updateOwnerType(singleContainerOwnerTypeValue)
            return entry
        }

        let entry = mockEntry(type: .doc)

        var item = convertItem(entry: entry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        item = convertItem(entry: entry, secretFG: false)
        XCTAssertNil(item.secureLabelName)

        entry.ownerTenantID = "\(mockTenantID)-2"
        item = convertItem(entry: entry)
        XCTAssertNil(item.secureLabelName)
        entry.ownerTenantID = mockTenantID

        entry.update(secureLabelName: nil)
        item = convertItem(entry: entry)
        XCTAssertNil(item.secureLabelName)
        entry.update(secureLabelName: "")
        item = convertItem(entry: entry)
        XCTAssertNil(item.secureLabelName)
        entry.update(secureLabelName: mockLabelName)

        entry.update(secLabelCode: .empty)
        item = convertItem(entry: entry)
        XCTAssertNil(item.secureLabelName)
        entry.update(secLabelCode: .success)

        // shortcut
        entry.updateNodeType(1)
        item = convertItem(entry: entry)
        XCTAssertNil(item.secureLabelName)
        entry.updateNodeType(nil)

        entry.updateOwnerType(oldFolderOwnerType)
        item = convertItem(entry: entry)
        XCTAssertNil(item.secureLabelName)
        entry.updateOwnerType(singleContainerOwnerTypeValue)

        var otherTypeEntry = mockEntry(type: .mindnote)
        item = convertItem(entry: otherTypeEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        otherTypeEntry = mockEntry(type: .file)
        item = convertItem(entry: otherTypeEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        otherTypeEntry = mockEntry(type: .bitable)
        item = convertItem(entry: otherTypeEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        otherTypeEntry = mockEntry(type: .docX)
        item = convertItem(entry: otherTypeEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        otherTypeEntry = mockEntry(type: .sheet)
        item = convertItem(entry: otherTypeEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        guard let wikiEntry = mockEntry(type: .wiki) as? WikiEntry else {
            XCTFail("create wiki entry failed")
            return
        }
        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "", objToken: "", docsType: .doc, spaceId: ""))
        item = convertItem(entry: wikiEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "", objToken: "", docsType: .mindnote, spaceId: ""))
        item = convertItem(entry: wikiEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "", objToken: "", docsType: .file, spaceId: ""))
        item = convertItem(entry: wikiEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "", objToken: "", docsType: .bitable, spaceId: ""))
        item = convertItem(entry: wikiEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "", objToken: "", docsType: .docX, spaceId: ""))
        item = convertItem(entry: wikiEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        wikiEntry.update(wikiInfo: WikiInfo(wikiToken: "", objToken: "", docsType: .sheet, spaceId: ""))
        item = convertItem(entry: wikiEntry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)

        // 兜底
        item = convertItem(entry: entry)
        XCTAssertEqual(item.secureLabelName, mockLabelName)
    }

    func testThumbnailType() {
        typealias ThumbnailType = SpaceListItem.ThumbnailType
        // folder
        var entry: SpaceEntry = FolderEntry(type: .folder, nodeToken: "mock", objToken: "mock")
        var item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, ThumbnailType.bigType(image: entry.defaultIcon))

        // drive key delete
        entry = DriveEntry(type: .file, nodeToken: "mock", objToken: "mock")
        entry.update(secretKeyDelete: true)
        item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, ThumbnailType.bigType(image: UDEmptyType.ccmDocumentKeyUnavailable.defaultImage()))

        // no perm
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateExtraValue(["has_perm": false])
        item = convert(entry: entry)
        if let icon = entry.noPermIcon {
            XCTAssertEqual(item.thumbnailType, ThumbnailType.bigType(image: icon))
        } else {
            XCTAssertNil(item.thumbnailType)
        }

        entry = SpaceEntry(type: .unknownDefaultType, nodeToken: "mock", objToken: "mock")
        entry.updateExtraValue(["has_perm": false])
        item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, ThumbnailType.bigType(image: entry.defaultIcon))

        // thumbnail
        // 没有任何缩略图信息
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, ThumbnailType.bigType(image: entry.defaultIcon))

        // 只有未加密信息
        let mockUnencryptedURL = URL(string: "http://unit.test/unencrypted.png")!
        let unencryptedOnlyInfo = SpaceThumbnailInfo.unencryptOnly(unencryptURL: mockUnencryptedURL)
        var info = SpaceList.ThumbnailInfo(token: entry.objToken,
                                           thumbInfo: unencryptedOnlyInfo,
                                           source: .spaceList,
                                           fileType: entry.docsType,
                                           failedImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail,
                                           placeholder: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        entry.updateExtraValue(["thumbnail": mockUnencryptedURL.absoluteString])
        item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, .thumbnail(info: info))

        // 只有加密信息
        let mockEncryptedURL = URL(string: "http://unit.test/encrypted.png")!
        let mockSecret = "secret"
        let mockNonce = "nonce"
        let mockEncryptType = SpaceThumbnailInfo.ExtraInfo.EncryptType.GCM(secret: mockSecret, nonce: mockNonce)
        let mockExtraInfo = SpaceThumbnailInfo.ExtraInfo(url: mockEncryptedURL, encryptType: mockEncryptType)
        entry.updateExtraValue(nil)
        entry.thumbExtraInfo = mockExtraInfo
        info = SpaceList.ThumbnailInfo(token: entry.objToken,
                                       thumbInfo: .encryptedOnly(encryptInfo: mockExtraInfo),
                                       source: .spaceList,
                                       fileType: entry.docsType,
                                       failedImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail,
                                       placeholder: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, .thumbnail(info: info))

        // 俩个都有
        entry.updateExtraValue(["thumbnail": mockUnencryptedURL.absoluteString])
        entry.thumbExtraInfo = mockExtraInfo
        info = SpaceList.ThumbnailInfo(token: entry.objToken,
                                       thumbInfo: .encryptedAndUnencrypt(encryptInfo: mockExtraInfo, unencryptURL: mockUnencryptedURL),
                                       source: .spaceList,
                                       fileType: entry.docsType,
                                       failedImage: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail,
                                       placeholder: BundleResources.SKResource.Space.FileList.Grid.grid_cell_fail)
        item = convert(entry: entry)
        XCTAssertEqual(item.thumbnailType, .thumbnail(info: info))
    }

    func testSpecialSubTitle() {
        // nil 场景
        // isBiz
        var entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        // syncStatus.show = false
        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .none)
        // hasPermission = false
        entry.updateExtraValue(["has_perm": false])
        var item = convert(entry: entry)
        XCTAssertNil(item.subtitle)

        entry = SpaceEntry(type: .unknownDefaultType, nodeToken: "mock", objToken: "mock")
        entry.updateExtraValue(["has_perm": false])
        item = convert(entry: entry)
        XCTAssertNotNil(item.subtitle)

        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .none)

        entry.updateExtraValue(["has_perm": true])
        item = convert(entry: entry)
        XCTAssertNotNil(item.subtitle)
        entry.updateExtraValue(["has_perm": false])

        entry.syncStatus = SyncStatus(upSyncStatus: .waiting, downloadStatus: .none)
        item = convert(entry: entry)
        XCTAssertNotNil(item.subtitle)
        entry.syncStatus = SyncStatus(upSyncStatus: .none, downloadStatus: .none)

        item = convert(entry: entry)
        XCTAssertNil(item.subtitle)

        // shortcut 场景
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateNodeType(1)
        item = convert(entry: entry)
        XCTAssertEqual(item.subtitle, R.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder)

        let timeStamp = Date().timeIntervalSince1970
        // drive 最近列表
        entry = DriveEntry(type: .file, nodeToken: "mock", objToken: "mock")
        entry.updateOpenTime(timeStamp)
        entry.updateCreateTime(timeStamp)
        item = convert(entry: entry, list: .recent, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_UploadTime(timeStamp.fileSubTitleDateFormatter))

        entry.updateCreateTime(timeStamp - 10)
        item = convert(entry: entry, list: .recent, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle,
                       R.LarkCCM_NewCM_LastVisitedTime_Description(timeStamp.fileSubTitleDateFormatter))

    }

    func testRecentSubTitle() {
        let timeStamp = Date().timeIntervalSince1970
        var entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateMyEditTime(timeStamp)
        var item = convert(entry: entry, list: .recent, sortType: .lastModifiedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))

        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateCreateTime(timeStamp)
        item = convert(entry: entry, list: .recent, sortType: .latestCreated)
        XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(timeStamp.fileSubTitleDateFormatter))

        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateOpenTime(timeStamp)
        item = convert(entry: entry, list: .recent, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(timeStamp.fileSubTitleDateFormatter))

        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateActivityTime(timeStamp)
        item = convert(entry: entry, list: .recent, sortType: .allTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(timeStamp.fileSubTitleDateFormatter))

        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateOpenTime(timeStamp)
        item = convert(entry: entry, list: .recent, sortType: .updateTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(timeStamp.fileSubTitleDateFormatter))

        // 测一下取时间的兜底逻辑
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        item = convert(entry: entry, list: .recent, sortType: .lastModifiedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))

        entry.updateCreateTime(timeStamp)
        item = convert(entry: entry, list: .recent, sortType: .lastModifiedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))
    }

    func testShareSubTitle() {
        let timeStamp = Date().timeIntervalSince1970
        let mockOwner = "mock-owner"
        // sharedTime
        var entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        var item = convert(entry: entry, list: .share, sortType: .sharedTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_ShareBy("", 0.fileSubTitleDateFormatter))

        entry.updateOwner(mockOwner)
        item = convert(entry: entry, list: .share, sortType: .sharedTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_ShareBy(mockOwner, 0.fileSubTitleDateFormatter))

        entry.updateShareTime(timeStamp)
        item = convert(entry: entry, list: .share, sortType: .sharedTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_ShareBy(mockOwner, timeStamp.fileSubTitleDateFormatter))

        // createTime
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        item = convert(entry: entry, list: .share, sortType: .createTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(0.fileSubTitleDateFormatter))

        entry.updateCreateTime(timeStamp)
        item = convert(entry: entry, list: .share, sortType: .createTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(timeStamp.fileSubTitleDateFormatter))

        // default
        entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        item = convert(entry: entry, list: .share, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))

        entry.updateEditTime(timeStamp)
        item = convert(entry: entry, list: .share, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))
    }

    func testManualOfflineSubTitle() {
        let timeStamp = Date().timeIntervalSince1970
        let entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        // addedManualOfflineTime
        var item = convert(entry: entry, list: .manualOffline, sortType: .addedManualOfflineTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))
        entry.updateEditTime(timeStamp)
        item = convert(entry: entry, list: .manualOffline, sortType: .addedManualOfflineTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))
        entry.updateEditTime(nil)

        // lastModifiedTime
        item = convert(entry: entry, list: .manualOffline, sortType: .lastModifiedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))
        entry.updateEditTime(timeStamp)
        item = convert(entry: entry, list: .manualOffline, sortType: .lastModifiedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))
        entry.updateEditTime(nil)

        // lastOpenTime
        item = convert(entry: entry, list: .manualOffline, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(0.fileSubTitleDateFormatter))
        entry.updateOpenTime(timeStamp)
        item = convert(entry: entry, list: .manualOffline, sortType: .lastOpenTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(timeStamp.fileSubTitleDateFormatter))
        entry.updateOpenTime(nil)

        // latestCreated
        item = convert(entry: entry, list: .manualOffline, sortType: .latestCreated)
        XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(0.fileSubTitleDateFormatter))
        entry.updateCreateTime(timeStamp)
        item = convert(entry: entry, list: .manualOffline, sortType: .latestCreated)
        XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(timeStamp.fileSubTitleDateFormatter))
        entry.updateCreateTime(nil)

        // default
        item = convert(entry: entry, list: .manualOffline, sortType: .sharedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(0.fileSubTitleDateFormatter))
        entry.updateOpenTime(timeStamp)
        item = convert(entry: entry, list: .manualOffline, sortType: .sharedTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastVisitedTime_Description(timeStamp.fileSubTitleDateFormatter))
        entry.updateOpenTime(nil)

        // drive 的特殊逻辑
        let file = DriveEntry(type: .file, nodeToken: "mock", objToken: "mock")
        file.updateOpenTime(timeStamp)
        file.updateCreateTime(timeStamp)
        item = convert(entry: file, list: .manualOffline, sortType: .addedManualOfflineTime)
        XCTAssertEqual(item.subtitle, R.Doc_List_UploadTime(timeStamp.fileSubTitleDateFormatter))
        file.updateCreateTime(timeStamp - 10)
        item = convert(entry: file, list: .manualOffline, sortType: .addedManualOfflineTime)
        XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))

        let size: UInt64 = 1000
        file.fileSize = size
        let sizeText = FileSizeHelper.memoryFormat(size)
        item = convert(entry: file, list: .manualOffline, sortType: .addedManualOfflineTime)
        XCTAssertEqual(item.subtitle, sizeText + R.Doc_Facade_Space + R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))
    }

    func testFavoritesSubTitle() {
        let timeStamp = Date().timeIntervalSince1970
        let mockOwner = "mock-owner"
        // sharedTime
        var entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        entry.updateEditTime(timeStamp)
        var item = convert(entry: entry, list: .favorites, sortType: .addFavoriteTime)
        XCTAssertEqual(item.subtitle,
                       BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))

        item = convert(entry: entry, list: .favorites, sortType: .allTime)
        XCTAssertEqual(item.subtitle,
                       BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))

        entry.updateFavoriteTime(0)
        item = convert(entry: entry, list: .favorites, sortType: .addFavoriteTime)
        XCTAssertEqual(item.subtitle,
                       BundleI18n.SKResource.LarkCCM_NewCM_StarredTime_Description(0.fileSubTitleDateFormatter))

        item = convert(entry: entry, list: .favorites, sortType: .lastModifiedTime)
        XCTAssertEqual(item.subtitle,
                       BundleI18n.SKResource.LarkCCM_NewCM_StarredTime_Description(0.fileSubTitleDateFormatter))
    }

    func testDefaultSubTitle() {
        func test(list: FileSource) {
            let timeStamp = Date().timeIntervalSince1970
            // searchRecentView
            let entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
            var item = convert(entry: entry, list: list, sortType: .createTime)
            XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(0.fileSubTitleDateFormatter))

            entry.updateCreateTime(timeStamp)
            item = convert(entry: entry, list: list, sortType: .createTime)
            XCTAssertEqual(item.subtitle, R.Doc_List_Create_At(timeStamp.fileSubTitleDateFormatter))

            item = convert(entry: entry, list: list, sortType: .allTime)
            XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(0.fileSubTitleDateFormatter))

            entry.updateEditTime(timeStamp)
            item = convert(entry: entry, list: list, sortType: .allTime)
            XCTAssertEqual(item.subtitle, R.LarkCCM_NewCM_LastModifiedTime_Description(timeStamp.fileSubTitleDateFormatter))
        }

        // 有特殊逻辑的list
        let blockList: [FileSource] = [.recent, .share, .manualOffline, .favorites]
        FileSource.allCases.forEach { list in
            guard !blockList.contains(list) else { return }
            test(list: list)
        }
    }

    func testSlideConfig() {
        var entry = SpaceEntry(type: .doc, nodeToken: "mock", objToken: "mock")
        var item = convert(entry: entry)
        XCTAssertNotNil(item.slideConfig)
        XCTAssertEqual(item.entry, entry)

        entry.updateExtraValue(["has_perm": false])
        item = convert(entry: entry)
        XCTAssertNil(item.slideConfig)
        XCTAssertEqual(item.entry, entry)

        entry = SpaceEntry(type: .unknownDefaultType, nodeToken: "mock", objToken: "mock")
        item = convert(entry: entry)
        XCTAssertNotNil(item.slideConfig)
        XCTAssertEqual(item.entry, entry)

        entry.updateExtraValue(["has_perm": false])
        item = convert(entry: entry)
        XCTAssertNotNil(item.slideConfig)
        XCTAssertEqual(item.entry, entry)
    }

    func testInWiki() {
        var entry = WikiEntry(type: .wiki, nodeToken: "mock", objToken: "mock")
        XCTAssertTrue(entry.contentExistInWiki)

        entry.updateExtraValue(["not_wiki_obj": true])
        XCTAssertFalse(entry.contentExistInWiki)

        entry.updateExtraValue(["not_wiki_obj": false])
        XCTAssertTrue(entry.contentExistInWiki)
    }
}
