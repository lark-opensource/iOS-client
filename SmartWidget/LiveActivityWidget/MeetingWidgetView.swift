//
//  MeetingIconView.swift
//  SmartWidgetExtension
//
//  Created by shin on 2023/2/17.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import ByteViewWidget
import SwiftUI
/*
extension MeetingNetworkStatus {
    var iconName: String? {
        var networkIcon: String?
        switch self {
        case .weak:
            networkIcon = "network_weak"
        case .bad:
            networkIcon = "network_bad"
        case .disconnected:
            networkIcon = "network_disconnected"
        case .normal:
            networkIcon = nil
        @unknown default:
            networkIcon = nil
        }
        return networkIcon
    }
}

struct MeetingNetworkView: View {
    enum IconSize {
        case compact
        case expanded

        var iconOffsetX: CGFloat {
            switch self {
            case .expanded:
                return 0.0
            case .compact:
                return 9
            }
        }
    }
    var networkStatus: MeetingNetworkStatus
    var size: IconSize
    var body: some View {
        if let icon = networkStatus.iconName {
            Image(icon)
                .resizable()
                .frame(width: 22.0, height: 22.0)
                .scaledToFit()
                .offset(x: -size.iconOffsetX, y: 0)
        }
    }
}
*/
struct MeetingContentView: View {
    var tips: String
    var title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            Text("\(tips)")
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(.system(size: 14.0, weight: .medium))
                .frame(height: 22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white.opacity(0.6))
            Text("\(title)")
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .font(.system(size: 18.0, weight: .medium))
                .foregroundColor(.white)
                .frame(height: 26)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MeetingIconView: View {
    enum IconSize {
        case minimal
        case compact
        case expanded

        var avatarSize: CGFloat {
            switch self {
            case .minimal, .compact:
                return 24.0
            case .expanded:
                return 48.0
            }
        }

        var logoSize: CGFloat {
            switch self {
            case .minimal, .compact:
                return 12.0
            case .expanded:
                return 20.0
            }
        }

        var iconOffsetX: CGFloat {
            switch self {
            case .minimal, .compact, .expanded:
                return 5.0
            }
        }

        var iconOffsetY: CGFloat {
            switch self {
            case .minimal, .compact:
                return 0.5
            case .expanded:
                return 0.0
            }
        }

        var videoSize: CGFloat {
            switch self {
            case .minimal, .compact:
                return 13.0
            case .expanded:
                return 26.0
            }
        }
    }

    let videoIcon = "vc_video_filled"
    var avatarImage: UIImage?
    var size: IconSize
    var isLockScreen: Bool = false

    var logoInsertBorder: CGFloat {
        if isLockScreen {
            return 0.0
        }
        switch size {
        case .expanded:
            return 1.5
        case .minimal, .compact:
            return 1.0
        }
    }

    var body: some View {
        let avatarSize = size.avatarSize
        let logoSize = size.logoSize
        let avatarRadius = avatarSize / 2.0
        let containerWidth = avatarSize + size.iconOffsetX
        let containerHeight = avatarSize + size.iconOffsetY
        let logoXOffset = (containerWidth - logoSize) / 2.0
        let logoYOffset = (containerHeight - logoSize) / 2.0 + size.iconOffsetY / 2.0
        let avatarXOffset = size.iconOffsetX / 2.0
        let avatarYOffset = size.iconOffsetY / 2.0
        let insertSize = logoSize + logoInsertBorder * 2.0
        let insertXOffset = (containerWidth - insertSize) / 2.0 + logoInsertBorder
        let insertYOffset = (containerHeight - insertSize) / 2.0 + logoInsertBorder + size.iconOffsetY / 2.0
        var imageSize: CGFloat
        var imageBgColor: Color

        var image: Image
        var needClip = false
        if let avatarImage = avatarImage {
            image = Image(uiImage: avatarImage)
            imageSize = avatarSize
            imageBgColor = Color.clear
            needClip = true
        } else {
            image = Image(videoIcon)
            imageSize = size.videoSize
            imageBgColor = Color(red: 0.204, green: 0.78, blue: 0.141)
        }
        let larkIcon = Image("lark_logo")
            .resizable()
            .scaledToFit()
            .frame(width: logoSize, height: logoSize)
        return ZStack {
            ZStack {
                Circle()
                    .frame(width: avatarSize, height: avatarSize)
                    .foregroundColor(imageBgColor)
                if needClip {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                        .cornerRadius(avatarRadius, antialiased: true)
                } else {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize, height: imageSize)
                }
            }
            .frame(width: avatarSize, height: avatarSize)
            .offset(x: -avatarXOffset, y: -avatarYOffset)
            if !isLockScreen {
                Circle()
                    .frame(width: insertSize, height: insertSize)
                    .foregroundColor(.black)
                    .offset(x: insertXOffset, y: insertYOffset)
            }
            larkIcon.offset(x: logoXOffset, y: logoYOffset)
        }
        .frame(width: containerWidth, height: containerHeight)
    }
}

struct MeetingIconView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingIconView(avatarImage: nil, size: .expanded, isLockScreen: false)
    }
}
