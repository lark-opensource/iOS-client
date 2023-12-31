//
//  UniverseDesignBadgeUpdateCell.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/29.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignBadge

class UniverseDesignBadgeUpdateTool {
    static let shared = UniverseDesignBadgeUpdateTool()

    private let slowTimer = DispatchSource.makeTimerSource()
    private let timer = DispatchSource.makeTimerSource()
    private let quickTimer = DispatchSource.makeTimerSource()
    var slowHandlers: [(() -> Void)] = []
    var handlers: [(() -> Void)] = []
    var quickHandlers: [(() -> Void)] = []

    init() {
        slowTimer.schedule(deadline: .now(), repeating: .seconds(4))
        timer.schedule(deadline: .now(), repeating: .milliseconds(300))
        quickTimer.schedule(deadline: .now(), repeating: .milliseconds(50))
        slowTimer.setEventHandler(handler: self.handleSlowUpdate)
        timer.setEventHandler(handler: self.handleUpdate)
        quickTimer.setEventHandler(handler: self.handleQuickUpdate)
        slowTimer.resume()
        timer.resume()
        quickTimer.resume()
    }

    private func handleSlowUpdate() {
        DispatchQueue.main.async {
            self.slowHandlers.forEach({ $0() })
        }
    }

    private func handleUpdate() {
        DispatchQueue.main.async {
            self.handlers.forEach({ $0() })
        }
    }

    private func handleQuickUpdate() {
        DispatchQueue.main.async {
            self.quickHandlers.forEach({ $0() })
        }
    }
}

class UniverseDesignBadgePositionCase: UniverseDesignBadgeCase {
    private let avatar1 = UniverseDesignBadgeAvatar()
    private let avatar2 = UniverseDesignBadgeAvatar()
    private let icon = UIImageView(image: UDIcon.getIconByKey(.groupOutlined, iconColor: UDBadgeColorStyle.dotBGBlue.color, size: CGSize(width: 24.0, height: 24.0)))

    private let anchors: [[UDBadgeAnchor]] = [
        [.topLeft, .topRight, .bottomRight],
        [.topRight, .bottomRight, .bottomLeft],
        [.bottomRight, .bottomLeft, .topLeft],
        [.bottomLeft, .topLeft, .topRight]
    ]
    private var updateIndex: Int = 0

    override var contentHeight: CGFloat {
        return 56.0
    }

    override init(title: String) {
        super.init(title: title)

        content.addSubview(avatar1)
        content.addSubview(avatar2)
        content.addSubview(icon)

        let badge1 = avatar1.addBadge(.dot, anchor: .topLeft, anchorType: .circle)
        badge1.config.style = .dotBGRed
        badge1.config.contentStyle = .dotCharacterText
        badge1.config.border = .outer
        badge1.config.borderStyle = .dotBorderWhite
        let badge2 = avatar2.addBadge(.number, anchor: .topLeft, anchorType: .circle)
        badge2.config.style = .characterBGRed
        badge2.config.contentStyle = .dotCharacterText
        badge2.config.number = 99
        badge2.config.border = .outer
        badge2.config.borderStyle = .dotBorderWhite
        let badge3 = icon.addBadge(.icon, anchor: .topLeft)
        badge3.config.style = .dotBGGrey
        badge3.config.contentStyle = .dotCharacterText
        badge3.config.icon = UDIcon.getIconByKey(.succeedFilled, iconColor: UDBadgeColorStyle.dotCharacterText.color, size: CGSize(width: 12.0, height: 12.0))

        avatar1.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        avatar2.snp.makeConstraints { (make) in
            make.leading.equalTo(avatar1.snp.trailing).offset(24.0)
            make.centerY.equalToSuperview()
        }

        icon.snp.makeConstraints { (make) in
            make.leading.equalTo(avatar2.snp.trailing).offset(24.0)
            make.centerY.equalToSuperview()
        }

        UniverseDesignBadgeUpdateTool.shared.handlers.append {
            let anchors = self.anchors[self.updateIndex]
            self.avatar1.badge?.config.anchor = anchors[0]
            self.avatar2.badge?.config.anchor = anchors[1]
            self.icon.badge?.config.anchor = anchors[2]
            if self.updateIndex < 3 {
                self.updateIndex += 1
            } else {
                self.updateIndex = 0
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeUpdateCase: UniverseDesignBadgeCase {
    let avatar1 = UniverseDesignBadgeAvatar()
    let avatar2 = UniverseDesignBadgeAvatar()
    let avatar3 = UniverseDesignBadgeAvatar()

    override var contentHeight: CGFloat {
        return 56.0
    }

    override init(title: String) {
        super.init(title: title)

        addSubview(avatar1)
        addSubview(avatar2)
        addSubview(avatar3)

        avatar1.addBadge(.number, anchorType: .circle)
        let badge2 = avatar2.addBadge(.number, anchorType: .circle)
        badge2.config.border = .outer
        badge2.config.borderStyle = .dotCharacterText
        badge2.config.border = .outer
        badge2.config.borderStyle = .dotBorderWhite
        let badge3 = avatar3.addBadge(.number, anchorType: .circle)
        badge3.config.anchorExtendType = .trailing

        avatar1.snp.makeConstraints { (make) in
            make.leading.centerY.equalToSuperview()
        }

        avatar2.snp.makeConstraints { (make) in
            make.leading.equalTo(avatar1.snp.trailing).offset(24.0)
            make.centerY.equalToSuperview()
        }

        avatar3.snp.makeConstraints { (make) in
            make.leading.equalTo(avatar2.snp.trailing).offset(24.0)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeNumberCase: UniverseDesignBadgeUpdateCase {
    private var index: Int = 0

    override init(title: String) {
        super.init(title: title)

        addSubview(avatar1)
        addSubview(avatar2)
        addSubview(avatar3)

        avatar1.badge?.config.type = .number
        avatar1.badge?.config.maxNumber = 99
        avatar1.badge?.config.showZero = true
        avatar2.badge?.config.type = .number
        avatar2.badge?.config.maxNumber = 999
        avatar3.badge?.config.type = .number
        avatar3.badge?.config.maxNumber = 999
        avatar3.badge?.config.maxType = .plus

        UniverseDesignBadgeUpdateTool.shared.quickHandlers.append {
            self.avatar1.badge?.config.number = self.index
            self.avatar2.badge?.config.number = self.index
            self.avatar3.badge?.config.number = self.index
            self.label.text = "数字（\(self.index), max: 99, 999, 999）"
            if self.index < 1111 {
                self.index += 1
            } else {
                self.index = 0
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeUpdateTextCase: UniverseDesignBadgeUpdateCase {
    private let texts: [[String]] = [
        ["N", "Ne", "New"],
        ["New", "Old", "Hello"],
        ["New", "Old", "Hello"]
    ]

    private var index: Int = 0

    override init(title: String) {
        super.init(title: title)

        avatar1.badge?.config.type = .text
        avatar1.badge?.config.showEmpty = true
        avatar2.badge?.config.type = .text
        avatar3.badge?.config.type = .text

        UniverseDesignBadgeUpdateTool.shared.handlers.append {
            self.avatar1.badge?.config.text = self.texts[0][self.index]
            self.avatar2.badge?.config.text = self.texts[1][self.index]
            self.avatar3.badge?.config.text = self.texts[2][self.index]
            self.label.text = "文本"
            if self.index < 2 {
                self.index += 1
            } else {
                self.index = 0
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeReapeatCase: UniverseDesignBadgeUpdateCase {
    override init(title: String) {
        super.init(title: title)

        let icon = UDIcon.getIconByKey(.groupFilled, iconColor: UDBadgeColorStyle.dotCharacterText.color, size: CGSize(width: 10.0, height: 10.0))

        avatar1.badge?.config.type = .dot
        avatar2.badge?.config.type = .number
        avatar3.badge?.config.type = .icon
        avatar3.badge?.config.icon = icon

        UniverseDesignBadgeUpdateTool.shared.quickHandlers.append {
            self.avatar1.badge?.config.type = .dot
            self.avatar1.badge?.config.dotSize = .middle
            self.avatar1.badge?.config.border = .none
            self.avatar1.badge?.config.borderStyle = .custom(.clear)
            self.avatar2.badge?.config.type = .number
            self.avatar2.badge?.config.number = 99
            self.avatar2.badge?.config.maxNumber = 999
            self.avatar3.badge?.config.type = .icon
            self.avatar3.badge?.config.icon = icon
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeIconCase: UniverseDesignBadgeUpdateCase {
    class ImageFetcher: ImageSource {
        var image: UIImage?
        var placeHolderImage: UIImage? = UDIcon.getIconByKey(.groupOutlined, iconColor: UDBadgeColorStyle.dotCharacterText.color, size: CGSize(width: 10.0, height: 10.0))

        func fetchImage(onCompletion: @escaping (Result<UIImage, Error>) -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let icon = UDIcon.getIconByKey(.groupFilled, iconColor: UDBadgeColorStyle.dotCharacterText.color, size: CGSize(width: 10.0, height: 10.0))
                self.image = icon
                onCompletion(.success(icon))
            }
        }

        func reset() {
            image = nil
        }
    }

    override init(title: String) {
        super.init(title: title)

        let fetcher1 = ImageFetcher()
        avatar1.badge?.config.type = .icon
        avatar1.badge?.config.icon = fetcher1
        let fetcher2 = ImageFetcher()
        avatar2.badge?.config.type = .icon
        avatar2.badge?.config.icon = fetcher2
        let fetcher3 = ImageFetcher()
        avatar3.badge?.config.type = .icon
        avatar3.badge?.config.icon = fetcher3

        UniverseDesignBadgeUpdateTool.shared.slowHandlers.append {
            fetcher1.reset()
            self.avatar1.badge?.forceUpdate()
            fetcher2.reset()
            self.avatar2.badge?.forceUpdate()
            fetcher3.reset()
            self.avatar3.badge?.forceUpdate()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignBadgeUpdateCell: UniverseDesignBadgeBaseCell {
    private let caseViews: [UniverseDesignBadgeCase] = [
        UniverseDesignBadgePositionCase(title: "位置"),
        UniverseDesignBadgeNumberCase(title: "数字"),
        UniverseDesignBadgeUpdateTextCase(title: "文本"),
        UniverseDesignBadgeReapeatCase(title: "重复刷新"),
        UniverseDesignBadgeIconCase(title: "图标拉取")
    ]

    override var contentHeight: CGFloat {
        return caseViews.reduce(0, { $0 + $1.height })
    }

    init(title: String) {
        super.init(resultId: "UniverseDesignBadgeUpdateCell", title: title)

        var yOffset: CGFloat = 0.0
        caseViews.enumerated().forEach { (_, caseView) in
            content.addSubview(caseView)

            caseView.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(yOffset)
                make.height.equalTo(caseView.height)
            }

            yOffset += caseView.height
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
