//
//  TimerViewComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import Foundation
import RustPB
import LarkCore
import ByteWebImage
import LarkContainer
import TangramComponent
import LarkSDKInterface
import TangramUIComponent

public final class TimerViewComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: TimerViewComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    @ScopedInjectedLazy var ntpService: ServerNTPTimeService?

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let time = property?.time ?? .init()
        let props = buildComponentProps(property: time, style: style)
        _component = TimerViewComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.TimeProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> TimerViewComponentProps {
        let props = TimerViewComponentProps()
        props.countDown = property.isCountdown
        if let font = style.tcFont {
            props.font = font
        }
        if let textColor = style.textColorV2.color {
            props.textColor = textColor
        }
        // 防止手动修改系统时间，造成duration计算错误
        let localTime = Int64(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970)
        let deltaTime = localTime - (ntpService?.serverTime ?? localTime)
        props.startTime = property.startTimeStamp + deltaTime
        // PC对于i64的值会自动转成""(默认值0)处理，即无法判断是null还是0，因此三端对齐，对于endTime，如果是0的话视为null处理
        props.endTime = (property.hasEndTimeStamp && property.endTimeStamp > 0) ? (property.endTimeStamp + deltaTime) : nil
        props.isEnd = property.isEnd
        return props
    }
}
