//
//  ByteViewWidget.swift
//  SmartWidgetExtension
//
//  Created by shin on 2023/2/13.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import ByteViewWidget
import SwiftUI
import WidgetKit

#if swift(>=5.7.1)
@available(iOSApplicationExtension 16.0, *)
private func getUIImageFromURL(_ url: URL?) -> UIImage? {
    var image: UIImage?
    if let url = url {
        image = UIImage(contentsOfFile: url.path())
        if image == nil {
            do {
                let data = try Data(contentsOf: url)
                image = UIImage(data: data)
            } catch {}
        }
    }
    return image
}

@available(iOSApplicationExtension 16.1, *)
struct ByteViewMeetingWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MeetingAttributes.self) { context in
            let image = getUIImageFromURL(context.state.avatarURL)
            //let networkStatus: MeetingNetworkStatus = context.state.networkStatus
            let showNetwork = false //networkStatus != .normal
            let isMeetOngoing = context.state.isMeetOngoing ?? false
            var tips = context.state.topic
            var title = context.state.speaker
            if context.state.meetingType == .meet {
                tips = isMeetOngoing ? context.state.tips : context.state.topic
                title = isMeetOngoing ? context.state.topic : context.state.speaker
            }
            return ZStack {
                Image("lock_screen_bg").resizable().scaledToFill()
                HStack {
                    VStack {
                        MeetingIconView(avatarImage: image, size: .expanded, isLockScreen: true)
                    }.padding(EdgeInsets(top: 26, leading: 22, bottom: 25, trailing: 0))
                    MeetingContentView(tips: tips, title: title)
                        .padding(EdgeInsets(top: 0, leading: 3, bottom: 0, trailing: showNetwork ? 0 : 22))
                    /*
                    if showNetwork {
                        VStack(alignment: .center) {
                            Spacer()
                            MeetingNetworkView(networkStatus: networkStatus, size: .expanded)
                            Spacer()
                        }
                        .frame(width: 22.0, height: MeetingIconView.IconSize.expanded.avatarSize)
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 26))
                    }
                     */
                }
            }
        } dynamicIsland: { context in
            //let networkStatus: MeetingNetworkStatus = context.state.networkStatus
            let image = getUIImageFromURL(context.state.avatarURL)
            let isMeetOngoing = context.state.isMeetOngoing ?? false
            let showNetwork = false//networkStatus != .normal
            var tips = context.state.topic
            var title = context.state.speaker
            if context.state.meetingType == .meet {
                tips = isMeetOngoing ? context.state.tips : context.state.topic
                title = isMeetOngoing ? context.state.topic : context.state.speaker
            }
            return DynamicIsland {
                // Create the expanded presentation.
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        MeetingIconView(avatarImage: image, size: .expanded)
                    }
                    .padding(EdgeInsets(top: 18, leading: 3, bottom: 18, trailing: 0))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    /*
                    if showNetwork {
                        VStack(alignment: .center) {
                            MeetingNetworkView(networkStatus: networkStatus, size: .expanded)
                        }
                        .frame(width: 22.0, height: MeetingIconView.IconSize.expanded.avatarSize)
                        .padding(EdgeInsets(top: 18, leading: 0, bottom: 18, trailing: 4))
                    }
                     */
                }
                DynamicIslandExpandedRegion(.center) {
                    AnyView(MeetingContentView(tips: tips, title: title))
                        .padding(EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: showNetwork ? -24 : -60))
                }
            } compactLeading: {
                MeetingIconView(avatarImage: image, size: .compact)
            } compactTrailing: {
                /*
                MeetingNetworkView(networkStatus: networkStatus, size: .compact)
                    .padding(EdgeInsets(top: 0, leading: 9, bottom: 0, trailing: 0))
                 */
            } minimal: {
                MeetingIconView(avatarImage: image, size: .minimal)
            }
        }
    }
}
#endif
