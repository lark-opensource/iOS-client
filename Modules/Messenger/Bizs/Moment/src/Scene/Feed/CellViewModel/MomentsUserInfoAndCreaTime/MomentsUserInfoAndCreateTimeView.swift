//
//  MomentsUserInfoAndCreateTimeView.swift
//  Moment
//
//  Created by ByteDance on 2022/7/8.
//

import Foundation
import AsyncComponent
import UIKit

final class MomentsUserInfoAndCreateTimeView: UIView {
    struct MomentsUserAndCreateTimeInfo {
        /// 名字属性
        var nameText: String
        /// 是否是官方号
        var isOfficialUser: Bool
        /// 部门属性
        var departmentText: String
        /// 时间属性
        var createTimeText: String
        /// feed页面时，名称与部门是否跨行
        var feedMultiLine: Bool
        /// 存在时间时，时间是否在部门label中，创建时间label是否隐藏
        var createTimeIsHide: Bool
        /// 当场的场景页面
        var scene: UserInfoComponentScene

        init(nameText: String,
             isOfficialUser: Bool,
             departmentText: String,
             createTime: String = "",
             feedMultiLine: Bool = true,
             createTimeIsHide: Bool = true,
             scene: UserInfoComponentScene) {
            self.nameText = nameText
            self.isOfficialUser = isOfficialUser
            self.departmentText = departmentText
            self.createTimeText = createTime
            self.feedMultiLine = feedMultiLine
            self.createTimeIsHide = createTimeIsHide
            self.scene = scene
        }
    }
    /// 水平分割点与label之间距离
    private var horizontalDistance: CGFloat = 6
    /// 跨行时，label之间的间距
    private var verticalDistance: CGFloat = 2
    /// name的Label
    private lazy var name: MomentsUserNameLabel = {
        let name = MomentsUserNameLabel()
        name.numberOfLines = 0
        //该场景永远不会出现OutOfRange情况。设置了OutOfRange后，richLabel计算是否OutOfRange的逻辑实际上有bug。因此先业务上这么判断一下 规避掉这个bug。5.32版本 @jiaxiao
        //name改成不限行数了，所以needOutOfRangeText永远是false。另外这个view未来计划不用了。6.4版本 @jiaxiao
        name.needOutOfRangeText = false
        name.font = .systemFont(ofSize: 17, weight: .medium)
        name.textColor = UIColor.ud.textTitle
        return name
    }()
    /// department的UILabel
    private lazy var department: UILabel = {
        let department = UILabel()
        department.font = .systemFont(ofSize: 14, weight: .regular)
        department.textColor = UIColor.ud.textCaption
        department.lineBreakMode = NSLineBreakMode.byTruncatingTail
        department.numberOfLines = 2
        return department
    }()
    /// createTime的UILabel
    private lazy var createTime: UILabel = {
        let createTime = UILabel()
        createTime.font = .systemFont(ofSize: 14, weight: .regular)
        createTime.textColor = UIColor.ud.textCaption
        createTime.lineBreakMode = NSLineBreakMode.byTruncatingTail
        createTime.numberOfLines = 1
        return createTime
    }()
    /// name与department之间的点（一行的时候会有一个分割点，跨行后不显示）
    private lazy var dividingPoint: UILabel = {
        let dividingPoint = UILabel()
        dividingPoint.font = .systemFont(ofSize: 14, weight: .regular)
        dividingPoint.textColor = UIColor.ud.textCaption
        dividingPoint.text = "·"
        return dividingPoint
    }()

    init(frame: CGRect, momentsUserAndCreateTimeInfo: MomentsUserAndCreateTimeInfo) {
        super.init(frame: frame)
        addSubview(name)
        addSubview(department)
        addSubview(dividingPoint)
        addSubview(createTime)
        updateView(momentsUserAndCreateTimeInfo: momentsUserAndCreateTimeInfo)
    }

    func updateView(momentsUserAndCreateTimeInfo: MomentsUserAndCreateTimeInfo) {
        name.name = momentsUserAndCreateTimeInfo.nameText
        name.isOfficialUser = momentsUserAndCreateTimeInfo.isOfficialUser
        name.textVerticalAlignment = .middle
        department.text = momentsUserAndCreateTimeInfo.departmentText
        createTime.text = momentsUserAndCreateTimeInfo.createTimeText
        dividingPoint.isHidden = true
        createTime.isHidden = true
        name.snp.removeConstraints()
        department.snp.removeConstraints()
        dividingPoint.snp.removeConstraints()
        createTime.snp.removeConstraints()

        switch momentsUserAndCreateTimeInfo.scene {
        case .feed:
            department.numberOfLines = 2
            if !momentsUserAndCreateTimeInfo.feedMultiLine {
                dividingPoint.isHidden = false
                /// 当前name与department不存在跨行时
                name.snp.remakeConstraints { (make) in
                    make.left.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                    if let width = name.suggestWidth {
                        make.width.equalTo(width) //richLabel自动布局不大可靠，手动算一下宽度。5.32版本 @jiaxiao
                    }
                }
                dividingPoint.snp.remakeConstraints { (make) in
                    make.left.equalTo(name.snp.right).offset(horizontalDistance)
                    make.centerY.equalTo(name)
                }
                department.snp.remakeConstraints { (make) in
                    make.left.equalTo(dividingPoint.snp.right).offset(horizontalDistance)
                    make.centerY.equalTo(name)
                }
            } else {
                name.textVerticalAlignment = .top
                /// 当前name与department存在跨行时，不显示分割点
                dividingPoint.isHidden = true
                name.snp.remakeConstraints { (make) in
                    make.left.right.top.equalToSuperview()
                }
                department.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.lessThanOrEqualTo(name.snp.bottom)
                    make.bottom.equalToSuperview()
                }
            }
        case .detail:
            /// 当前页面为详情页
            department.numberOfLines = 0
            name.textVerticalAlignment = .top
            name.snp.remakeConstraints { (make) in
                make.left.right.top.equalToSuperview()
            }
            /// 当department与createTime不出现跨行时，createTime的label隐藏
            if momentsUserAndCreateTimeInfo.createTimeIsHide {
                if !momentsUserAndCreateTimeInfo.departmentText.isEmpty {
                    department.text = momentsUserAndCreateTimeInfo.departmentText + " · " + momentsUserAndCreateTimeInfo.createTimeText
                }
                department.snp.remakeConstraints { (make) in
                    make.top.lessThanOrEqualTo(name.snp.bottom)
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
            } else {
                /// 当department与createTime出现跨行时，显示createTime的label
                createTime.isHidden = false
                department.snp.remakeConstraints { (make) in
                    make.top.equalTo(name.snp.bottom).offset(momentsUserAndCreateTimeInfo.departmentText.isEmpty ? 0 : verticalDistance)
                    make.left.right.equalToSuperview()
                }
                createTime.snp.remakeConstraints { (make) in
                    make.top.equalTo(department.snp.bottom).offset(verticalDistance)
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
            }
        case .profile:
            /// 当前页面为profile页面，只需要名称和部门
            createTime.isHidden = true
            department.text = ""
            name.snp.remakeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
