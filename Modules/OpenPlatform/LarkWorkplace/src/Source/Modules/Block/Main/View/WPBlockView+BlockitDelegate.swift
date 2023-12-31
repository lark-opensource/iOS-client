//
//  WPBlockView+BlockitDelegate.swift
//  LarkWorkplace
//
//  Created by doujian on 2022/7/1.
//

import OPBlockInterface
import ECOInfra
import LarkSetting
import Blockit
import OPSDK
import LarkStorage
import LarkWorkplaceModel

extension WPBlockView: BlockitDelegate {
    func didReceiveLogMessage(
        _ sender: OPBlockEntityProtocol,
        level: OPBlockDebugLogLevel,
        message: String,
        context: OPBlockContext
    ) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to didReceiveLogMessage event, not current context")
            return
        }
        let action = {
            let wpMsg = WPBlockLogMessage(level: level.wpLevel, content: message)

            if self.blockSettings?.workplace?.consoleEnable == true, self.enableBlockConsole {
                if self.logMessages.count >= 500 {
                    self.logMessages.removeFirst()
                }
                self.logMessages.append(wpMsg)
            }

            self.delegate?.blockDidReceiveLogMessage(self, message: wpMsg)
        }

        if !Thread.isMainThread {
            DispatchQueue.main.async {
                action()
            }
            return
        }
        action()
    }

    func contentSizeDidChange(_ sender: OPBlockEntityProtocol, newSize: CGSize, context: OPBlockContext) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to contentSizeDidChange event, not current context")
            return
        }
		updateBlockContentSize(newSize)
    }

    func hideBlockHostLoading(_ sender: OPBlockEntityProtocol) {
        self.hideBlockLoading(nil)
    }

	/// block runtimeReady 等同于 业务onload，使用当前vc状态尝试触发一次onshow
	func onBlockLoadReady(_ sender: OPBlockEntityProtocol, context: OPBlockContext) {
		guard shouldHandleBlockEvent(context: context) else {
			Self.logger.info("no handler to onBlockLoadReady event, not current context")
			return
		}
		(context.lifeCycleTrigger as? OPBlockHostCustomLifeCycleTriggerProtocol)?.hostViewControllerDidAppear(blockVCShow)
	}

    /// mountBlock 成功
    /// - Parameter container: 内部 block 的抽象容器
    func onBlockMountSuccess(container: OPBlockContainerProtocol, context: OPBlockContext) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to onBlockMountSuccess event, not current context")
            return
        }
        self.blockContext = context
        self.innerBlockContainer = container
    }

    /// block 启动成功
    func onBlockLaunchSuccess(context: OPBlockContext) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to onBlockLaunchSuccess event, not current context")
            return
        }
        blockitTimeout = false
        DispatchQueue.main.async {
            if self.blockSettings?.useStartLoading != true {
                if self.stateView.state != .running {
                    self.monitor_blockShowContent(useStartLoading: false)
                }
                self.updateBlockState(.running)
                self.loadingTimer?.invalidate()
                self.loadingTimer = nil
            }
        }
    }

    /// block 配置解析完成
    /// - Parameter config: block 业务中的根目录 index.json 解析完成
    func onBlockConfigLoad(config: OPBlockProjectConfig, context: OPBlockContext) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to onBlockConfigLoad event, not current context")
            return
        }
        guard let configData = config.blocks?.first?.configData else {
            self.blockBizTimeout = false
            return
        }

        DispatchQueue.main.async {
            do {
                self.monitor_trace()
                let data = try JSONSerialization.data(withJSONObject: configData, options: [])
                let settings = try JSONDecoder().decode(BlockSettings.self, from: data)
                self.blockSettings = settings
                self.blockBizTimeout = settings.useStartLoading ?? false

                // 设置操作菜单选项
                self.setupActionItems()

                self.headerSetting = self.parseHeaderSetting()
                self.updateStyleWithBlockSettings()
                self.updateRecommandTagView()
            } catch {
                self.monitor_trace(error: error)
            }
        }
    }

    /// mountBlock 失败
    /// - Parameter error: 目前错误基本就几个，比如 id 网络请求失败，初始化参数错误
    func onBlockMountFail(error: OPError, context: OPBlockContext) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to onBlockMountFail event, not current context")
            return
        }
        blockitTimeout = false
        handleBlockFail(error: error, monitorErrorCode: 101 /* mount_block_fail */)
    }

    /// block 启动失败
    /// - Parameter error: 错误的信息，参照 OPBlockitMonitorCodeLaunch
    func onBlockLaunchFail(error: OPError, context: OPBlockContext) {
        guard shouldHandleBlockEvent(context: context) else {
            Self.logger.info("no handler to onBlockLaunchFail event, not current context")
            return
        }
        blockitTimeout = false
        blockBizTimeout = false
        handleBlockFail(error: error, monitorErrorCode: 102 /* block_launch_fail */)
    }

    private func handleBlockFail(error: OPError, monitorErrorCode: Int) {
        // swiftlint:disable closure_body_length
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if error.monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfoServer.need_upgrade_status {
                self.updateBlockState(.updateTip)
            } else {
                if !self.stateView.state.isLoadFail {
                    self.monitor_blockShowFail([
                        "error_code": monitorErrorCode,
                        "block_error_code": error.monitorCode.code,
                        "block_error_domain": error.monitorCode.domain
                    ])
                    self.updateBlockState(.loadFail(.create(
                        // 组件名如果没有获取到，则用应用名称兜底
                        name: self.parseHeaderSetting().content?.title ?? self.blockModel.title,
                        monitorCode: error.monitorCode
                    )))
                }
                
            }
            self.loadingTimer?.invalidate()
            self.loadingTimer = nil

            self.delegate?.blockDidFail(self, error: error)

            /// 根据条件触发 retry，注意需要晚于 stateView 更新
            /// 1. entity 网络请求失败
            /// 2. guideInfo 网络请求失败
            /// 3. loadMeta 失败
            /// 4. loadPackage 失败
            if let retryReason = error.convertToBlockRetryReason() {
                self.retryAction.tryTriggerRetry(with: retryReason)
            }
        }
        // swiftlint:enable closure_body_length
    }

    /// block 异步请求的 meta & pkg 下载完成
    func onBlockUpdateReady(info: OPBlockUpdateInfo, context: OPBlockContext) {
        DispatchQueue.main.async {
            self.monitor_trace()

            let needUpdate: Bool
            let updateDescription: String
            // update
            switch info {
            case .bug(let description):
                needUpdate = true
                updateDescription = description ?? "bugfix"
            default:
                needUpdate = (self.blockModel.editorProps?.forceUpdate == true)
                updateDescription = "template config"
            }
            self.blockUpdateInfo = info

            Self.logger.info("onBlockUpdateReady", additionalData: [
                "appId": "\(self.blockModel.appId)",
                "needForceUpdate": "\(needUpdate)",
                "updateType": "\(info)"
            ])
            if needUpdate {
                self.monitor_blockLaunchCancel()
                self.loadCurrentBlock(forceUpdateMeta: true)
                Self.logger.info("force update reanson: \(updateDescription)")
            }
        }
    }

    /// 设置操作菜单选项
    private func setupActionItems() {
        actionItems.removeAll()
        
        // Block 分享
        if isShareEnable {
            actionItems.append(.blockShareItem { [weak self] receivers, leaveMessage in
                guard let `self` = self else { return nil }
                return self.share(receivers: receivers, leaveMessage: leaveMessage)
            })
        }

        // Block 从常用中移除
        if blockModel.isInFavoriteComponent {
            actionItems.append(ActionMenuItem.cancelItem(disable: !blockModel.isDeletable))
        }

        // Block设置页面入口
        if let settingUrl = blockModel.settingUrl {
            actionItems.append(ActionMenuItem.settingItem(url: settingUrl))
        }

        // BlockConfig菜单选项
        if let blockConfigItems = blockSettings?.workplace?.getActionItems(itemAction: { [weak self] obj in
            self?.onDeveloperItemClick(item: obj)
        }) {
            actionItems.append(contentsOf: blockConfigItems)
        }

        // 编辑器菜单选项
        if let editorItems = blockModel.editorProps?.getActionItems() {
            actionItems.append(contentsOf: editorItems)
        }

        // Block Console
        if blockSettings?.workplace?.consoleEnable == true, enableBlockConsole {
            actionItems.append(ActionMenuItem.consoleItem())
        }
    }

    func parseHeaderSetting() -> WPTemplateHeader.Setting {
        let style: WPTemplateHeader.Style
        let content: WPTemplateHeader.Content?
        let isRecommand = canShowRecommand && blockModel.isTemplateCommonAndRecommand && blockModel.isTemplateRecommand
        let tagType: WPCellTagType = isRecommand ? .recommandBlock : .none
        if let editorConfig = self.blockModel.editorProps {
            // Priority-1 编辑器配置优先
            if editorConfig.showHeader == true {
                // 读取编辑器配置的内置、外置信息，默认内置
                if editorConfig.isTitleInside == false {
                    style = .outside
                } else if self.blockSettings?.showFrame == false {
                    // 卡片配置了无背景，强制使用 Outside 样式
                    style = .outside
                } else {
                    style = .inside
                }
                // 使用编辑器 Schema 里的配置，编辑器只要配了 showHeader，不论是否为空都取出展示
                // 编辑器下发的 header title 使用多语言文案，策略详见 i18nTitle
                content = WPTemplateHeader.Content(
                    title: editorConfig.i18nTitle ?? "",
                    titleIconUrl: editorConfig.titleIconUrl ?? "",
                    redirectUrl: editorConfig.schema,
                    tagType: tagType
                )
                Self.logger.info("block [\(editorConfig.i18nTitle)] setup editorConfig, show header")
            } else {
                // 编辑器配置了不展示标题，无需更新 header 内容，只隐藏header视图
                style = .none
                // 只解析 itemInfo 里面的 name，用于状态展示
                content = WPTemplateHeader.Content(
                    title: blockModel.title,
                    titleIconUrl: "",
                    redirectUrl: nil,
                    tagType: .none
                )
                Self.logger.info("block [\(blockModel.title)] setup editorConfig, hide header")
            }
        } else if blockModel.isInFavoriteComponent, !blockModel.isStandardBlock {
            // Priority-2，常用组件内的非标 Block, 业务方通过服务端接口上传了标题栏信息
            style = .inside
            var title = blockModel.title
            if let titleCollection = blockModel.item.block?.title, let i18nTitle = WPi18nUtil.getI18nText(titleCollection, defaultLocale: blockModel.item.block?.defaultLocale) {
                title = i18nTitle
            }
            content = WPTemplateHeader.Content(
                title: title,
                titleIconUrl: blockModel.item.block?.titleIconURL ?? "",
                redirectUrl: blockModel.item.block?.schema,
                tagType: tagType
            )
        } else if let blockConfig = self.blockSettings?.workplace, blockConfig.needHeader == true {
            // Priority-3，使用开发者配置的标题内容，
            if self.blockSettings?.showFrame == false {
                // 卡片配置了无背景，强制使用 Outside 样式
                style = .outside
            } else {
                // 已知无编辑器配置，默认内置标题
                style = .inside
            }

            // 使用开发者 BlockConfig 里的配置
            let title = blockConfig.i18nTitle ?? ""
            let titleIconUrl: String = blockConfig.titleIconUrl ?? ""
            if title.isEmpty && titleIconUrl.isEmpty {
                // 开发者没有配置有效内容，尝试从原始信息中获取标题和 icon（一般为后端返回的 WorkPlaceAppItem）
                let itemTitle = self.blockModel.title
                let itemIconUrl = self.blockModel.iconKey

                if itemTitle.isEmpty && itemIconUrl.isEmpty {
                    // 如果还是取不到，就从 Meta 里面解（例如 preview）
                    if let service = OPApplicationService.current.containerService(for: .block),
                       let provider = service.appTypeAbility.generateMetaProvider() {
                        do {
                            let meta = try provider.getLocalMeta(with: blockModel.uniqueId)
                            content = WPTemplateHeader.Content(
                                title: meta.appName,
                                titleIconUrl: meta.appIconUrl,
                                redirectUrl: nil,
                                tagType: tagType
                            )
                            Self.logger.info("block [\(meta.appName)] setup blockConfig, show header default data")
                        } catch {
                            monitor_trace(error: error)
                            content = nil
                        }
                    } else {
                        monitor_trace()
                        content = nil
                    }
                } else {
                    // 如果取到了，就展示后端返回的 name 和 icon
                    content = WPTemplateHeader.Content(
                        title: itemTitle,
                        titleIconUrl: itemIconUrl,
                        redirectUrl: blockConfig.mobileHeaderLink,
                        tagType: tagType
                    )
                    Self.logger.info("block [\(itemTitle)] setup blockConfig, show header block data")
                }
            } else {
                // 开发者配置了有效内容
                content = WPTemplateHeader.Content(
                    title: title,
                    titleIconUrl: titleIconUrl,
                    redirectUrl: blockConfig.mobileHeaderLink,
                    tagType: tagType
                )
                Self.logger.info("block [\(title)] setup blockConfig, show header")
            }
        } else {
            // 不展示标题，无需更新 header 内容
            style = .none
            // 只解析 itemInfo 里面的 name，用于状态展示
            content = WPTemplateHeader.Content(
                title: blockModel.title,
                titleIconUrl: "",
                redirectUrl: nil,
                tagType: .none
            )
            Self.logger.info("block [\(blockModel.title)] not show header")
        }

        return WPTemplateHeader.Setting(style: style, content: content)
    }

    func onBlockBizTimeout(context: OPBlockContext, error: OPError) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            let blockTitle = self.headerSetting.content?.title ?? self.blockModel.title
            self.updateBlockState(.loadFail(.create(name: blockTitle, monitorCode: error.monitorCode)))
            self.monitor_blockShowFail(["error_code": 100])
            self.retryAction.tryTriggerRetry(with: .loadingTimeout)
        }
    }

    func onBlockBizSuccess(context: OPBlockContext) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.updateBlockState(.running)
            self.monitor_blockShowContent(useStartLoading: true)
        }
    }

    func tryHideBlock(context: OPBlockContext) {
        Self.logger.info("[WPBlockView] new-api jsb tryHideBlock success")
        if Thread.isMainThread {
            delegate?.tryHideBlock(self)
        } else {
            DispatchQueue.main.sync {
                delegate?.tryHideBlock(self)
            }
        }
    }

	/* OPBlockWebLifeCycleDelegate */

	// 页面开始加载, 会发送多次
	// 每次路由跳转新页面加载成功触发
	func onPageStart(url: String?, context: OPBlockContext) {}

	// 页面加载成功, 会发送多次
	// 每次路由跳转新页面加载成功触发
	func onPageSuccess(url: String?, context: OPBlockContext) {}

	// 页面加载失败，会发送多次
	// 每次路由跳转新页面加载失败触发
	func onPageError(url: String?, error: OPError, context: OPBlockContext) {}

	// 页面运行时崩溃，会发送多次
	// 目前web场景会发送此事件，每次收到web的ProcessDidTerminate触发
	func onPageCrash(url: String?, context: OPBlockContext) {}

	// block 内容大小发生变化，会发送多次
	func onBlockContentSizeChanged(height: CGFloat, context: OPBlockContext) {
		guard shouldHandleBlockEvent(context: context) else {
			Self.logger.info("no handler to onBlockContentSizeChanged event, not current context")
			return
		}
		let newSize = CGSize(width: blockRenderView.frame.width, height: height)
		updateBlockContentSize(newSize)
	}

	private func updateBlockContentSize(_ newSize: CGSize) {
		var totalSize = newSize
		switch headerSetting.style {
		case .inside:
			totalSize.height += commonInnerTitleHeight
		case .outside:
			totalSize.height += (commonOutterTitleHeight + commonOutterTitleGap)
		case .none:
			break
		}
        let maxAutoHeight = CGFloat(maxAutoHeightConfig.maxHeight)
		Self.logger.info(
			"[BLKH] size change",
			additionalData: [
				"newSize": "\(newSize)",
				"total": "\(totalSize)",
				"isAuto": "\(blockModel.isAutoSizeBlock)",
				"uid": "\(blockModel.uniqueId)",
                "maxAutoHeight": "\(maxAutoHeight)"
			]
		)
        let userId = userService?.user.userID ?? ""
		if blockModel.isAutoSizeBlock {
			let val = min(maxAutoHeight, max(Const.autoBlockMinHeight, totalSize.height))
            let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
            store.set(val, forKey: WPCacheKey.blockHeightLynx(blockId: blockModel.blockId))
            Self.logger.info("[\(WPCacheKey.blockHeightLynx(blockId: blockModel.blockId))] cache data.")
		}
		delegate?.blockContentSizeDidChange(self, newSize: totalSize)
	}

    func onBlockShareStatusUpdate(context: OPBlockContext, enable: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            guard self.shouldHandleBlockEvent(context: context) else {
                Self.logger.info("no handler to onBlockShareStatusUpdate event, not current context")
                return
            }
            self.isShareEnable = enable && self.blockModel.isInFavoriteComponent && !self.blockModel.isStandardBlock
            Self.logger.info("block share enable: \(self.isShareEnable)", additionalData: self.identityInfo)
            self.setupActionItems()
            self.blockHeader.showActionArea = !self.actionItems.isEmpty
        }
    }

    func onBlockShareInfoReady(context: OPBlockContext, info: OPBlockShareInfo) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            guard self.shouldHandleBlockEvent(context: context) else {
                Self.logger.info("no handler to onBlockShareInfoReady event, not current context")
                return
            }
            Self.logger.info("block share info ready", additionalData: self.identityInfo)
            let stateProceedSuccess = self.shareStateMachine.proceed(with: .success)
            if !stateProceedSuccess { return }
            // send share block server request
            let shareParams = WPShareBlockByMessageCardRequestParams(
                receivers: self.shareForwardInfo.receivers,
                itemId: self.blockModel.item.itemId,
                shareInfo: .init(
                    title: .init(info.title),
                    imageKey: .init(info.imageKey),
                    detailBtnName: .init(info.detailBtnName),
                    detailBtnLink: info.detailBtnLink,
                    blockShareName: .init(info.customMainLabel),
                    leaveMessage: self.shareForwardInfo.leaveMessage
                )
            )
            self.dataManager?.shareBlockByMessageCard(
                params: shareParams,
                success: { [weak self] in
                    guard let `self` = self else { return }
                    self.shareStateObservable?.onNext([])
                    self.shareStateObservable?.onCompleted()
                },
                failure: { [weak self] error in
                    self?.shareStateObservable?.onError(error)
                }
            )
        }
    }
}
