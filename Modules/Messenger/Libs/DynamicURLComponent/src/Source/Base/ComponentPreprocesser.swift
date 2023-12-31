//
//  ComponentPreprocesser.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/11/26.
//

import Foundation
import RustPB
import LarkCore
import LarkModel
import TangramService

/// 数据预处理：负责新老数据兼容
final class ComponentPreprocesser {
    /// 将老的Components和LocalPreview转换成State
    /// hideHeader - 本地爬虫隐藏Header
    /// hideTitle - 本地爬虫隐藏title
    static func transformToState(
        entity: URLPreviewEntity,
        hideHeader: Bool = false,
        hideTitle: Bool = false
    ) -> URLPreviewEntity {
        var newEntity = entity
        let isVideo = (!(entity.localPreviewBody?.iframeUrl?.isEmpty ?? true) ||
                       !(entity.localPreviewBody?.videoID?.isEmpty ?? true) ||
                       entity.localPreviewBody?.siteType != .unknown)
        if entity.isLocalPreview, isVideo {
            newEntity = transformLocalPreviewToVideoState(entity: entity, hideHeader: hideHeader, hideTitle: hideTitle)
        } else if entity.isLocalPreview {
            newEntity = transformLocalPreviewToState(entity: entity, hideHeader: hideHeader, hideTitle: hideTitle)
        } else if let previewBody = entity.previewBody,
                  previewBody.states.isEmpty,
                  previewBody.hasComponents,
                  !previewBody.components.elements.isEmpty { // 如果state为空，表示老的数据结构，需要提前转换为state
            newEntity = transformComponentsToState(entity: entity)
        }
        return newEntity
    }

    // 将老的Components结构转换成State结构
    static func transformComponentsToState(entity: URLPreviewEntity) -> URLPreviewEntity {
        guard let previewBody = entity.previewBody, previewBody.hasComponents else { return entity }
        var entity = entity
        let stateID = URLPreviewAdaptor.uniqueID()
        let templateID = URLPreviewAdaptor.uniqueID()

        var template = Basic_V1_URLPreviewTemplate()
        template.templateID = templateID
        template.rootComponentID = previewBody.components.rootIds.first ?? ""
        template.elements = previewBody.components.elements
        template.imageIds = previewBody.components.imageIds
        template.atIds = previewBody.components.atIds
        template.buttonIds = previewBody.components.buttonIds
        template.richtextIds = previewBody.components.richtextIds

        var state = Basic_V1_URLPreviewState()
        state.type = .card
        state.templateID = templateID
        if previewBody.hasCardURL {
            state.cardURL = previewBody.cardURL
        }
        state.actions = transformActions(actions: previewBody.actions)

        entity.localTemplates = [templateID: template]
        entity.previewBody?.currentStateID = stateID
        entity.previewBody?.states = [stateID: state]

        return entity
    }

    // 将老的Action结构转换成新的Action结构
    static func transformActions(actions: [String: Basic_V1_UrlPreviewAction]) -> [String: Basic_V1_UrlPreviewAction] {
        guard !actions.isEmpty else { return actions }
        var newActions = [String: Basic_V1_UrlPreviewAction]()
        actions.forEach { id, action in
            newActions[id] = transformAction(action: action)
        }
        return newActions
    }

    static func transformAction(action: Basic_V1_UrlPreviewAction) -> Basic_V1_UrlPreviewAction {
        var newAction = action
        switch action.method {
        case .get:
            if action.hasParameters {
                newAction.get.parameters = action.parameters
            }
        case .post:
            if action.hasParameters {
                newAction.post.parameters = action.parameters
            }
        case .larkCommand:
            newAction.command.cmd = action.cmd
            if action.hasPacket {
                newAction.command.packet = action.packet
            }
            newAction.command.parameters = action.parameters
        case .openURL:
            newAction.openURLV2.openURL = action.openURL
        // 新增的这几种action都是新结构，不需要转换
        case .switchState, .showToast, .showDialog: break
        @unknown default: assertionFailure("unknown case")
        }
        return newAction
    }

    /// 本地抓取的普通长文类，由本地拼接成State结构
    static func transformLocalPreviewToState(
        entity: URLPreviewEntity,
        hideHeader: Bool,
        hideTitle: Bool
    ) -> URLPreviewEntity {
        guard let localPreviewBody = entity.localPreviewBody else { return entity }
        let rootKey = "root"
        let rootLayoutKey = "rootLayout"
        let cardLayoutKey = "cardLayout"
        let imageKey = "image"
        let headerKey = "header"
        let contentLayoutKey = "contentLayout"
        let titleKey = "title"
        let contentKey = "content"

        let stateID = URLPreviewAdaptor.uniqueID()
        let templateID = URLPreviewAdaptor.uniqueID()

        var state = Basic_V1_URLPreviewState()
        state.type = .card
        var template = Basic_V1_URLPreviewTemplate()
        template.templateID = templateID
        var elements = [String: Basic_V1_URLPreviewComponent]()

        if !isLegalLocalPreview(body: localPreviewBody, hideHeader: hideHeader, hideTitle: hideTitle) {
            var newEntity = entity
            var previewBody = Basic_V1_URLPreviewBody()
            previewBody.currentStateID = stateID
            previewBody.states = [stateID: state]
            newEntity.previewBody = previewBody
            return newEntity
        }

        var root = Basic_V1_URLPreviewComponent()
        var rootThemeColor = Basic_V1_ThemeColor()
        rootThemeColor.token = "imtoken-message-card-bg-body-embed"
        root.style.backgroundColor.linear.colorsV2 = [rootThemeColor]
        root.style.maxWidth.value = 400
        root.style.maxWidth.type = .point
        // 当header或title隐藏时，通过100%撑开卡片
        root.style.width.value = 100
        root.style.width.type = .percentage
        root.type = .empty
        root.childIds = [rootLayoutKey]
        elements[rootKey] = root

        var rootLayout = Basic_V1_URLPreviewComponent()
        rootLayout.type = .linearLayout
        rootLayout.linearLayout.orientation = .column
        rootLayout.linearLayout.crossAxisAlign = .stretch
        rootLayout.linearLayout.padding = 12
        rootLayout.linearLayout.spacing = 8
        let rootLayoutChildIds = hideHeader ? [cardLayoutKey] : [headerKey, cardLayoutKey]
        rootLayout.childIds = rootLayoutChildIds
        elements[rootLayoutKey] = rootLayout

        var cardLayout = Basic_V1_URLPreviewComponent()
        cardLayout.type = .linearLayout
        cardLayout.linearLayout.orientation = .row
        cardLayout.linearLayout.spacing = 8
        cardLayout.linearLayout.wrapWidth = 324
        cardLayout.style.growWeight = 1
        cardLayout.style.shrinkWeight = 1
        cardLayout.childIds = [contentLayoutKey]
        elements[cardLayoutKey] = cardLayout

        if !hideHeader {
            var header = Basic_V1_URLPreviewComponent()
            header.type = .header
            header.header.title = localPreviewBody.domain
            header.header.theme = .light
            header.header.type = .normal
            header.header.numberOfLines = 3
            if let faviconURL = localPreviewBody.faviconUrl {
                header.header.faviconURL = faviconURL
            }
            elements[headerKey] = header
        }

        if let iconURL = localPreviewBody.iconUrl {
            cardLayout.childIds = [imageKey, contentLayoutKey]
            // Basic_V1_URLPreviewComponent是个struct，更改childIds之后需要重新赋值
            elements[cardLayoutKey] = cardLayout

            var image = Basic_V1_URLPreviewComponent()
            image.type = .image
            image.image.image.thumbnail.key = iconURL
            image.style.height.value = 88
            image.style.height.type = .point
            image.style.width.value = 88
            image.style.width.type = .point
            image.style.border.cornerRadius = 4
            elements[imageKey] = image
        }

        var contentLayout = Basic_V1_URLPreviewComponent()
        contentLayout.type = .linearLayout
        contentLayout.linearLayout.orientation = .column
        contentLayout.linearLayout.spacing = 4
        contentLayout.style.shrinkWeight = 1
        let contentLayoutChildIds = hideTitle ? [contentKey] : [titleKey, contentKey]
        contentLayout.childIds = contentLayoutChildIds
        elements[contentLayoutKey] = contentLayout

        if !hideTitle {
            var title = Basic_V1_URLPreviewComponent()
            title.type = .text
            title.text.text = localPreviewBody.title
            title.text.numberOfLines = 2
            title.style.fontLevel.level = 1
            title.style.fontLevel.type = .body
            title.style.textColorV2.token = "text-title"
            elements[titleKey] = title
        }

        var content = Basic_V1_URLPreviewComponent()
        content.type = .text
        content.text.text = localPreviewBody.description
        content.text.numberOfLines = 2
        content.style.fontLevel.level = 2
        content.style.fontLevel.type = .body
        content.style.textColorV2.token = "text-caption"
        content.style.shrinkWeight = 1
        elements[contentKey] = content

        template.rootComponentID = rootKey
        template.elements = elements
        state.templateID = templateID
        if let cardURL = localPreviewBody.cardURL {
            state.cardURL = cardURL
        }

        var newEntity = entity
        var previewBody = Basic_V1_URLPreviewBody()
        previewBody.currentStateID = stateID
        previewBody.states = [stateID: state]
        newEntity.previewBody = previewBody
        newEntity.localTemplates = [templateID: template]
        return newEntity
    }

    /// 本地抓取的视频类，由本地拼接成State结构
    static func transformLocalPreviewToVideoState(
        entity: URLPreviewEntity,
        hideHeader: Bool,
        hideTitle: Bool
    ) -> URLPreviewEntity {
        guard let localPreviewBody = entity.localPreviewBody else { return entity }
        let rootKey = "root"
        let rootLayoutKey = "rootLayout"
        let contentLayoutKey = "contentLayout"
        let headerKey = "header"
        let titleKey = "title"
        let videoKey = "video"

        let stateID = URLPreviewAdaptor.uniqueID()
        let templateID = URLPreviewAdaptor.uniqueID()

        var state = Basic_V1_URLPreviewState()
        state.type = .card
        var template = Basic_V1_URLPreviewTemplate()
        template.templateID = templateID
        var elements = [String: Basic_V1_URLPreviewComponent]()

        if !isLegalVideoPreview(body: localPreviewBody, hideHeader: hideHeader, hideTitle: hideTitle) {
            var newEntity = entity
            var previewBody = Basic_V1_URLPreviewBody()
            previewBody.currentStateID = stateID
            previewBody.states = [stateID: state]
            newEntity.previewBody = previewBody
            return newEntity
        }

        var root = Basic_V1_URLPreviewComponent()
        var rootThemeColor = Basic_V1_ThemeColor()
        rootThemeColor.token = "imtoken-message-card-bg-body-embed"
        root.style.backgroundColor.linear.colorsV2 = [rootThemeColor]
        root.style.maxWidth.value = 400
        root.style.maxWidth.type = .point
        // 当header或title隐藏时，通过100%撑开卡片
        root.style.width.value = 100
        root.style.width.type = .percentage
        root.type = .empty
        root.childIds = [rootLayoutKey]
        elements[rootKey] = root

        var rootLayout = Basic_V1_URLPreviewComponent()
        rootLayout.type = .linearLayout
        rootLayout.style.width.value = 100
        rootLayout.style.width.type = .percentage
        rootLayout.linearLayout.orientation = .column
        rootLayout.linearLayout.crossAxisAlign = .stretch
        rootLayout.linearLayout.mainAxisJustify = .start
        let rootLayoutChildIds = (hideHeader && hideTitle) ? [videoKey] : [videoKey, contentLayoutKey]
        rootLayout.childIds = rootLayoutChildIds
        elements[rootLayoutKey] = rootLayout

        if let iconURL = localPreviewBody.iconUrl {
            var video = Basic_V1_URLPreviewComponent()
            video.type = .video
            video.video.coverImageURL = iconURL
            video.video.site = localPreviewBody.siteType
            video.style.height.value = 224
            video.style.height.type = .point
            if let iframeURL = localPreviewBody.iframeUrl, !iframeURL.isEmpty {
                video.video.iframeURL = iframeURL
            }
            if let tcURL = localPreviewBody.cardURL?.tcURL, !tcURL.isEmpty {
                video.video.srcURL = tcURL
            }
            if let vid = localPreviewBody.videoID, !vid.isEmpty {
                video.video.vid = vid
            }
            elements[videoKey] = video
        }

        var contentLayoutChildIds = [String]()
        if !hideHeader {
            contentLayoutChildIds.append(headerKey)
        }
        if !hideTitle {
            contentLayoutChildIds.append(titleKey)
        }
        if !contentLayoutChildIds.isEmpty {
            var contentLayout = Basic_V1_URLPreviewComponent()
            contentLayout.type = .linearLayout
            contentLayout.linearLayout.orientation = .column
            contentLayout.linearLayout.padding = 12
            contentLayout.linearLayout.spacing = 7
            contentLayout.childIds = contentLayoutChildIds
            elements[contentLayoutKey] = contentLayout
        }

        var header = Basic_V1_URLPreviewComponent()
        header.type = .header
        if let siteName = localPreviewBody.siteName, !siteName.isEmpty {
            header.header.title = siteName
        } else {
            header.header.title = localPreviewBody.domain
        }
        if let faviconURL = localPreviewBody.faviconUrl, !faviconURL.isEmpty {
            header.header.faviconURL = faviconURL
        }
        header.header.theme = .light
        header.header.type = .normal
        elements[headerKey] = header

        var title = Basic_V1_URLPreviewComponent()
        title.type = .text
        title.text.text = localPreviewBody.title
        title.text.numberOfLines = 0
        title.style.fontLevel.type = .body
        title.style.fontLevel.level = 2
        title.style.textColorV2.token = "text-caption"
        elements[titleKey] = title

        template.rootComponentID = rootKey
        template.elements = elements
        state.templateID = templateID
        if let cardURL = localPreviewBody.cardURL {
            state.cardURL = cardURL
        }

        var newEntity = entity
        var previewBody = Basic_V1_URLPreviewBody()
        previewBody.currentStateID = stateID
        previewBody.states = [stateID: state]
        newEntity.previewBody = previewBody
        newEntity.localTemplates = [templateID: template]
        return newEntity
    }

    // 是否能展示长文爬虫卡片
    static func isLegalLocalPreview(
        body: URLLocalPreviewBody,
        hideHeader: Bool,
        hideTitle: Bool
    ) -> Bool {
        if !hideHeader {
            return true
        }
        if !hideTitle, !body.title.isEmpty {
            return true
        }
        if !body.description.isEmpty {
            return true
        }
        if let iconUrl = body.iconUrl, !iconUrl.isEmpty {
            return true
        }
        return false
    }

    // 是否能展示视频爬虫卡片
    static func isLegalVideoPreview(
        body: URLLocalPreviewBody,
        hideHeader: Bool,
        hideTitle: Bool
    ) -> Bool {
        if !hideHeader {
            return true
        }
        if !hideTitle, !body.title.isEmpty {
            return true
        }
        if body.iconUrl != nil {
            return true
        }
        return false
    }
}
