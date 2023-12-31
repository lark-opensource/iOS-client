//
//  InstanceLayoutAlgorithm.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/5.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RustPB
import RxSwift

typealias DaysInstancesContentMap = [Int32: [DaysInstanceViewContent]]
typealias LayoutAlgorithm = (DaysInstancesContentMap,
                                    _ isSingleDay: Bool,
                                    _ panelSize: CGSize,
                                    _ daysRange: [Int32]) -> DaysInstancesContentMap
typealias LayoutRequest = (_ daysInstanceSlotMetrics: [Rust.InstanceLayoutSlotMetric], _ isSingleDay: Bool) -> Observable<GetInstancesLayoutResponse>

final class InstanceLayoutConvert {
    func layoutToFrame(layout: InstanceLayout,
                               panelSize: CGSize,
                               index: Int) -> CGRect {
        return CGRect(x: locateConvertor(layout.xOffset, panelSize.width - 4) + panelSize.width * CGFloat(index),
                      y: locateConvertor(layout.yOffset, panelSize.height),
                      width: locateConvertor(layout.width, panelSize.width - 4),
                      height: locateConvertor(layout.height, panelSize.height))
    }

    private func locateConvertor(_ present: Float, _ totalSize: CGFloat) -> CGFloat {
        return CGFloat(present) / 100.0 * totalSize
    }

}

final class InstancesLayoutAlgorithm {
    private let layoutRequest: LayoutRequest
    private let daysInstanceLabelLayout = DaysInstanceLabelLayout()
    private let disposeBag = DisposeBag()
    init(layoutRequest: @escaping LayoutRequest) {
        self.layoutRequest = layoutRequest
    }

    func layoutInstances(daysInstencesMap: DaysInstancesContentMap,
                         isSingleDay: Bool,
                         panelSize: CGSize,
                         daysRange: [Int32]) -> DaysInstancesContentMap {
        var result = [Int32: [DaysInstanceViewContent]]()

        let mappings = daysInstencesMap.mapValues { (instenceContents) -> [String: DaysInstanceViewContent] in
            return Dictionary(uniqueKeysWithValues: instenceContents.enumerated().map { (String($0), $1) })
        }

        let slots = mapInstencesToSlots(instances: daysInstencesMap)

        layoutRequest(slots, isSingleDay)
            .map({ $0.daysInstanceLayout })
            .subscribe(onNext: { (daysInstanceLayout) in
                daysInstanceLayout.forEach({ (dayInstanceLayout) in
                    let layoutDay = dayInstanceLayout.layoutDay
                    guard let index = daysRange.firstIndex(of: layoutDay),
                        let mapping = mappings[layoutDay] else {
                        assertionFailureLog()
                        return
                    }
                    var r = [DaysInstanceViewContent]()
                    let layoutConvert = InstanceLayoutConvert()
                    dayInstanceLayout.instancesLayout.forEach({ (instanceLayout) in
                        if var i = mapping[instanceLayout.id] {
                            let frame = layoutConvert.layoutToFrame(layout: instanceLayout,
                                                           panelSize: panelSize,
                                                           index: index)
                            i.frame = frame
                            i.instancelayout = instanceLayout
                            i.index = index
                            i.zIndex = Int(instanceLayout.zIndex)
                            let (titleStyle, subTitleStyle) = self.daysInstanceLabelLayout
                                .getLabelStyle(frame: frame, content: i)
                            i.titleStyle = titleStyle
                            i.subTitleStyle = subTitleStyle
                            r.append(i)
                        }
                    })
                    result[layoutDay] = r
                })
            }).disposed(by: disposeBag)
        return result
    }

    /// 给会议室忙闲专用的布局方法 会议室忙闲不存在日程重叠的情况 不走sdk布局逻辑
    /// [update] 会议室支持管理员配置需求允许出现特殊的重叠日程 受到影响的日程改为双列布局
    /// - Parameters:
    ///   - daysInstancesMap: key: JulianDay 在此场景下只有一个 value: 日程
    ///   - isSingleDay: 历史遗留 在这个场景下无用
    ///   - panelSize: 整个忙闲页的大小 用来和日程所占比例相乘计算出view大小
    ///   - daysRange: JulianDay 的范围 在这个场景下也只会有一天 可以忽略
    /// - Returns: 计算出的布局结果 [Int32: [DaysInstanceViewContent]]
    func meetingRoomLayoutInstances(daysInstancesMap: DaysInstancesContentMap,
                                    isSingleDay: Bool,
                                    panelSize: CGSize,
                                    daysRange: [Int32]) -> DaysInstancesContentMap {
        // 强制设置为单日 其他与普通忙闲保持一致
        layoutInstances(daysInstencesMap: daysInstancesMap, isSingleDay: true, panelSize: panelSize, daysRange: daysRange)
    }

    private func mapInstencesToSlots(instances: DaysInstancesContentMap)
        -> [Rust.InstanceLayoutSlotMetric] {
            return instances.reduce([]) { (result, arg1) -> [Rust.InstanceLayoutSlotMetric] in
                var result = result
                let (layoutDay, instanceContents) = arg1
                var slotMetrics = Rust.InstanceLayoutSlotMetric()
                slotMetrics.layoutDay = layoutDay
                slotMetrics.slotMetrics = instanceContents.enumerated().map(instanceToSlotMetric)
                result.append(slotMetrics)
                return result
            }
    }

    private func instanceToSlotMetric(index: Int, instance: DaysInstanceViewContent) -> InstanceSlotMetric {
        var matric = InstanceSlotMetric()
        matric.id = String(describing: index)
        matric.startTime = Int64(instance.startDate.timeIntervalSince1970)
        matric.startDay = instance.startDay
        matric.startMinute = instance.startMinute
        matric.endTime = Int64(instance.endDate.timeIntervalSince1970)
        matric.endDay = instance.endDay
        matric.endMinute = instance.endMinute
        return matric
    }

}
