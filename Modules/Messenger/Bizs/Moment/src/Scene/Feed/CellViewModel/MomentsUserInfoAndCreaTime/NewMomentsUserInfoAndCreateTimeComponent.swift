//
//  NewMomentsUserInfoAndCreateTimeComponent.swift
//  Moment
//
//  Created by ByteDance on 2023/3/30.
//

import Foundation
import AsyncComponent
import UniverseDesignColor

public final class NewMomentsUserInfoAndCreateTimeComponentProps: ASComponentProps {
    /// 名字属性
    public var name: String = ""
    /// 是否是官方号
    public var isOfficialUser: Bool = false
    /// 部门属性
    public var department: String = ""
    /// 动态时间属性
    public var createTime: String?
    /// 名字后面是否需要换行展示
    public var newLineAfterName: Bool = false
    /// 额外要展示的profile页字段
    public var extraFields: [String] = []
    /// 名字字体
    public var nameFont: UIFont = .systemFont(ofSize: 17, weight: .medium)
    /// 名字颜色
    public var nameColor: UIColor = UIColor.ud.textTitle
    /// extraFields、time的字体
    public var subInfoFont: UIFont = .systemFont(ofSize: 14, weight: .regular)
    /// extraFields、time的颜色
    public var subInfoColor: UIColor = UIColor.ud.textCaption
}

final class NewMomentsUserInfoAndCreateTimeComponent<C: Context>: ASComponent<NewMomentsUserInfoAndCreateTimeComponentProps, EmptyState, NewMomentsUserInfoAndCreateTimeView, C> {
    private var nameFont: UIFont = .systemFont(ofSize: 17, weight: .medium)
    private var departmentFont: UIFont = .systemFont(ofSize: 14)
    public var createTimeFont: UIFont = .systemFont(ofSize: 14)
    private let separatorText = " · "
    private let lock = NSLock()
    private var layoutInfo: ComplexLabelLayoutInfo?

    public override func update(view: NewMomentsUserInfoAndCreateTimeView) {
        super.update(view: view)
        self.lock.lock()
        if let layoutInfo = layoutInfo {
            view.updateView(layoutInfo: layoutInfo)
            lock.unlock()
        } else {
            lock.unlock()
            view.updateView(momentsUserAndCreateTimeInfo: generateMomentsUserAndCreateTimeInfo())
        }
    }
    /// 起名规范
    public override func create(_ rect: CGRect) -> NewMomentsUserInfoAndCreateTimeView {
        let view = NewMomentsUserInfoAndCreateTimeView(frame: rect)
        return view
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        defer {
            lock.unlock()
        }
        let types = NewMomentsUserInfoAndCreateTimeView.generateComplexLabelTypes(momentsUserAndCreateTimeInfo: generateMomentsUserAndCreateTimeInfo())
        let layoutInfo = ComplexLabel.generateLayoutInfo(types: types, maxWidth: size.width)
        lock.lock()
        self.layoutInfo = layoutInfo
        return layoutInfo.size
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    private func generateMomentsUserAndCreateTimeInfo() -> NewMomentsUserInfoAndCreateTimeView.MomentsUserAndCreateTimeInfo {
        return .init(
            nameText: props.name,
            isOfficialUser: props.isOfficialUser,
            extraFields: props.extraFields,
            createTime: props.createTime,
            newLineAfterName: props.newLineAfterName,
            nameFont: props.nameFont,
            nameColor: props.nameColor,
            subInfoFont: props.subInfoFont,
            subInfoColor: props.subInfoColor
        )
    }
}
