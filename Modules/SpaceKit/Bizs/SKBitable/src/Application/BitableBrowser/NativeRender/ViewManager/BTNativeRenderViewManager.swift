//
//  BTNativeRenderViewManager.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/31.
//

import Foundation
import SKInfra

enum NativeRenderViewType: String {
    case cardView
}

final class BTNativeRenderViewManager {
    func creatViewBy(type: NativeRenderViewType, model: SKFastDecodable?, service: BTContainerService?, context: BTNativeRenderContext) -> NativeRenderBaseController? {
        switch type {
        case .cardView:
            guard let cardModel = model as? CardPageModel else {
                return nil
            }
            return BTCardListViewController(model: cardModel, service: service, context: context)
        }
    }
    
    // nolint: cyclomatic_complexity
    static func createTitleValueView(model: BTCardFieldCellModel, 
                                     containerWidth: CGFloat, isMainTitle: Bool) -> BTCellValueViewProtocol {
        switch model.fieldUIType {
        case .text:
            // 多行文本
            let view = BTCardRichTextValueView()
            if isMainTitle {
                view.set(model, with: CardViewConstant.LayoutConfig.textTtileFont, numberOfLines: 2)
            } else {
                view.setData(model, containerWidth: containerWidth)
            }
            return view
        case .lastModifyTime, .createTime, .dateTime:
            // 日期相关
            let view = BTCardDateValueView()
            if isMainTitle {
                view.set(model, with: CardViewConstant.LayoutConfig.textTtileFont, numberOfLines: 2)
            } else {
                view.setData(model, containerWidth: containerWidth)
            }
            return view
        case .autoNumber, .barcode, .number,
                .url, .phone, .email,
                .location,
                .formula,
                .currency:
            // 链接/数字/自动编号/扫码/位置/货币/电话号码/邮箱
            let view = BTCardSimpleTextValueView()
            if isMainTitle {
                view.set(model, with: CardViewConstant.LayoutConfig.textTtileFont, numberOfLines: 2)
            } else {
                view.setData(model, containerWidth: containerWidth)
            }
            return view
        case .attachment:
            // 附件
            let view = BTCardAttachmentValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .button:
            // 按钮
            let view = BTCardButtonValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .checkbox:
            // 复选框
            let view = BTCardCheckBoxValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .duplexLink, .singleLink:
            // 单双向关联
            let view = BTCardLinkValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .stage:
            // 流程
            let view = BTCardStageValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .rating:
            // 评分
            let view = BTCardRatingValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .progress:
            // 进度
            let view = BTCardProgressValueView()
            view.setData(model, containerWidth: containerWidth)
            return view
        case .singleSelect, .multiSelect:
            // 单多选
            let view = BTSingleLineCapsuleView(with: .singleLineCapsule)
            view.setData(model, containerWidth: containerWidth)
            return view
        case .user, .createUser, .group, .lastModifyUser:
            // 人员、群组
            let view = BTSingleLineCapsuleView(with: .singleLineIconCapsule)
            view.setData(model, containerWidth: containerWidth)
            return view
        case .lookup:
            return BTCardEmptyValueView()
        case .notSupport:
            return BTCardEmptyValueView()
        }
    }
}
