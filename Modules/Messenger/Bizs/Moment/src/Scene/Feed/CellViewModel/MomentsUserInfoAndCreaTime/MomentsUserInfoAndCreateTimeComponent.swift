//
//  MomentsUserAndCreateTime.swift
//  Moment
//
//  Created by ByteDance on 2022/7/8.
//

import Foundation
import AsyncComponent
import UIKit
import SwiftUI
import RichLabel

public final class MomentsUserInfoAndCreateTimeComponentProps: ASComponentProps {
    /// 名字属性
    public var name: String = ""
    /// 是否是官方号
    public var isOfficialUser: Bool = false
    /// 部门属性
    public var department: String = ""
    /// 动态时间属性
    public var createTime: String = ""
    /// 当场的场景页面
    public var scene: UserInfoComponentScene = .feed
}

public enum UserInfoComponentScene {
    /// feed页面，包含名称与部门，均不超过两行
    case feed
    /// detail页面，包含名称，部门与动态创建时间，无限折行
    case detail
    /// profile页面，包含名称与动态创建时间
    case profile
}

final class MomentsUserInfoAndCreateTimeComponent<C: Context>: ASComponent<MomentsUserInfoAndCreateTimeComponentProps, EmptyState, MomentsUserInfoAndCreateTimeView, C> {
    /// 水平分割点与label之间距离
    private lazy var horizontalDistance: CGFloat = 6
    /// 跨行时，label之间的间距
    private var verticalDistance: CGFloat = 2
    private var nameFont: UIFont = .systemFont(ofSize: 17, weight: .medium)
    private var departmentFont: UIFont = .systemFont(ofSize: 14)
    public var createTimeFont: UIFont = .systemFont(ofSize: 14)
    private let separatorText = " · "
    private let lock = NSLock()
    private let layoutEngine = LKTextLayoutEngineImpl()
    private let textParser = LKTextParserImpl()

    /// feed页面时，名称与部门是否跨行
    public var feedMultiLine: Bool = false
    /// 详情页面时，当前创建时间是否与部门在同一行，创建时间label是否隐藏
    public var createTimeIsHide: Bool = true

    public override func update(view: MomentsUserInfoAndCreateTimeView) {
        super.update(view: view)
        self.lock.lock()
        let feedMultiLineValue = self.feedMultiLine
        let createTimeIsHideValue = self.createTimeIsHide
        self.lock.unlock()
        view.updateView(momentsUserAndCreateTimeInfo: MomentsUserInfoAndCreateTimeView.MomentsUserAndCreateTimeInfo(
            nameText: props.name,
            isOfficialUser: props.isOfficialUser,
            departmentText: props.department,
            createTime: props.createTime,
            feedMultiLine: feedMultiLineValue,
            createTimeIsHide: createTimeIsHideValue,
            scene: props.scene))
    }
    /// 起名规范
    public override func create(_ rect: CGRect) -> MomentsUserInfoAndCreateTimeView {
        return MomentsUserInfoAndCreateTimeView(frame: rect,
                                                momentsUserAndCreateTimeInfo: MomentsUserInfoAndCreateTimeView.MomentsUserAndCreateTimeInfo(nameText: props.name ?? "",
                                                                                                                                            isOfficialUser: props.isOfficialUser,
                                                                                                                            departmentText: props.department ?? "",
                                                                                                                            createTime: props.createTime,
                                                                                                                            feedMultiLine: false,
                                                                                                                            createTimeIsHide: true,
                                                                                                                            scene: props.scene))
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        /// 根据场景，计算不同组件的size
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        let name = getAttributeStringOfName()
        switch props.scene {
        case .feed:
            /// 计算当前内容时，name和department的宽度
            var nameWidth = widthForName(name)
            var departmentWidth = widthForDepartment()
            /// 最终返回的高度
            var height: CGFloat = 0.0
            /// 计算department最大高度，最多两行
            let departmentMaxHeight = CGFloat(2) * MomentsDataConverter.heightForString(" ", onWidth: departmentWidth, font: departmentFont) + 1
            /// 如果name，department，分割点的宽度小于最大宽度，则说明在同一行，4用来标识分隔点的大小
            if !props.department.isEmpty {
                if nameWidth + departmentWidth + 2 * horizontalDistance + 4 <= size.width {
                    feedMultiLine = false
                    /// 一行的高度，再加上单行字体包含的一些偏移量
                    return CGSize(width: size.width, height: nameFont.lineHeight + 1)
                } else {
                    nameWidth = min(nameWidth, size.width)
                    departmentWidth = min(departmentWidth, size.width)
                    /// 计算当前文本高度
                    let nameHeight = heightForName(name, onWidth: nameWidth)
                    let departmentHeight = min(heightForDepartment(onWidth: departmentWidth), departmentMaxHeight)
                    height += nameHeight
                    height += departmentHeight
                    height += verticalDistance
                    feedMultiLine = true
                    return CGSize(width: size.width, height: height)
                }
            } else {
                if nameWidth <= size.width {
                    feedMultiLine = true
                    /// 一行的高度，再加上单行字体包含的一些偏移量
                    return CGSize(width: size.width, height: nameFont.lineHeight + 1)
                } else {
                    feedMultiLine = true
                    let nameHeight = heightForName(name, onWidth: size.width)
                    return CGSize(width: size.width, height: nameHeight)
                }
            }
        case .detail:
            var departmentWidth = widthForDepartment()
            let createTimeWidth = min(MomentsDataConverter.widthForString(props.createTime, font: createTimeFont), size.width)
            /// 一行的高度，再加上单行字体包含的一些偏移量
            let createTimeHeight = createTimeFont.lineHeight + 1
            /// 最终将返回的整体高度
            var height: CGFloat = 0.0
            departmentWidth = min(departmentWidth, size.width)
            if !props.department.isEmpty {
                var departmentHeight = heightForDepartment(onWidth: departmentWidth)
                let departmentAndTime = props.department + separatorText + props.createTime
                /// 计算部门与创建时间在同一个label时的宽度，并且两个内容的font相同
                var departmentAndTimeWidth = MomentsDataConverter.widthForString(departmentAndTime, font: departmentFont)
                /// 首先判断department和createTime结合的高度为一行，如果宽度小于最大宽度，则为一行
                if departmentAndTimeWidth < size.width {
                    createTimeIsHide = true
                    /// 一行的高度，再加上单行字体包含的一些偏移量
                    height = departmentFont.lineHeight + 1
                    /// 当detail页面部门与时间未出现跨行时，此component与下方的内容间距加4
                    height += 4
                } else {
                    /// 如果宽度大于一行，则需要判断department单独时的高度，与department和createTime结合时的高度是否一致，若不一致，则代表两者会跨行，需要进行分别展示
                    /// department当前文本的高度
                    let departmentHeight = MomentsDataConverter.heightForString(props.department, onWidth: size.width, font: departmentFont)
                    /// departmentAndTime文本的高度
                    let departmentAndTimeHeight = MomentsDataConverter.heightForString(departmentAndTime, onWidth: size.width, font: departmentFont)
                    if departmentHeight == departmentAndTimeHeight {
                        createTimeIsHide = true
                        height += departmentAndTimeHeight
                    } else {
                        createTimeIsHide = false
                        height += departmentHeight + createTimeHeight + verticalDistance
                    }
                }
            } else {
                height += createTimeHeight
                createTimeIsHide = false
                /// 当detail页面部门与时间未出现跨行时，此component与下方的内容间距加4
                height += 4
            }
            /// 当为详情页时，name可以无限折行，需判断createTime与department是否会在同一行
            let nameHeight = heightForName(name, onWidth: size.width)
            height += nameHeight + verticalDistance
            return CGSize(width: size.width, height: height)
        case .profile:
            /// 当为profile详情页时，只需要名称和动态创建时间
            let nameHeight = heightForName(name, onWidth: size.width)
            return CGSize(width: size.width, height: nameHeight + verticalDistance)
        }
    }

    public func heightForName(_ name: NSAttributedString, onWidth: CGFloat) -> CGFloat {
        self.layoutEngine.preferMaxWidth = onWidth
        // nameSize
        self.textParser.originAttrString = name
        self.textParser.parse()
        self.layoutEngine.attributedText = self.textParser.renderAttrString
        self.layoutEngine.numberOfLines = 0
        let size = self.layoutEngine.layout(size: CGSize(width: onWidth, height: CGFloat(MAXFLOAT)))
        return size.height
    }

    public func widthForName(_ name: NSAttributedString) -> CGFloat {
        self.layoutEngine.preferMaxWidth = CGFloat(MAXFLOAT)
        // nameSize
        self.textParser.originAttrString = name
        self.textParser.parse()
        self.layoutEngine.attributedText = self.textParser.renderAttrString
        self.layoutEngine.numberOfLines = 1
        /// 这里只有一行
        let size = self.layoutEngine.layout(size: CGSize(width: CGFloat(MAXFLOAT), height: nameFont.lineHeight + 5))
        return size.width
    }

    public func heightForDepartment(onWidth: CGFloat) -> CGFloat {
        return MomentsDataConverter.heightForString(props.department, onWidth: onWidth, font: departmentFont)
    }

    private func getAttributeStringOfName() -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: nameFont]
        let attrText = NSMutableAttributedString(string: props.name, attributes: attributes)
        if props.isOfficialUser {
            let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
                //这里其实不会真正创建view，只是利用LKAsyncAttachment算一下文字宽度
                return UIView()
            }, size: OfficialUserLabel.suggestSize)
            attachment.margin = .init(top: 0, left: 6, bottom: 0, right: 0)
            attachment.fontAscent = nameFont.ascender
            attachment.fontDescent = nameFont.descender
            var attachmentAttr = attributes
            attachmentAttr[LKAttachmentAttributeName] = attachment
            attrText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr, attributes: attachmentAttr))
        }
        return attrText
    }

    public func widthForDepartment() -> CGFloat {
        return MomentsDataConverter.widthForString(props.department, font: departmentFont)
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }
}
