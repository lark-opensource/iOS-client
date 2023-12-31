//
//  ChatBackgroundImageView.swift
//  LarkChat
//
//  Created by JackZhao on 2023/1/13.
//

import UIKit
import Foundation
import RxSwift
import Swinject
import ServerPB
import LarkModel
import LarkUIKit
import ByteWebImage
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignColor
import UniverseDesignTheme
import LarkMessengerInterface

public final class ChatBackgroundImageView: ByteImageView {
    static let logger = Logger.log(ChatBackgroundImageView.self, category: "Module.IM.Chat")

    private let bag = DisposeBag()
    // 背景图的蒙层
    private let shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.8)
        return view
    }()
    private var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        } else {
            return false
        }
    }
    // 是否是系统默认图
    private var isOriginMode: Bool

    public init(chatId: String? = nil,
                isOriginMode: Bool,
                pushChatTheme: Observable<ChatTheme> = .empty()) {
        self.isOriginMode = isOriginMode
        super.init(image: nil)

        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        reloadShadowView()

        pushChatTheme
            .filter({ theme in
                // 只处理从当前chat的主题改变
                theme.chatId == chatId
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] theme in
                guard let self = self else { return }
                switch theme.style {
                case .image(let img):
                    self.backgroundColor = .clear
                    self.isOriginMode = false
                    self.reloadShadowView()
                    self.bt.setLarkImage(with: .default(key: ""),
                                         placeholder: img)
                case .color(let color):
                    self.backgroundColor = color
                    self.isOriginMode = false
                    self.reloadShadowView()
                    self.bt.setLarkImage(with: .default(key: ""))
                case .key(let key, let fsUnit):
                    self.backgroundColor = .clear
                    self.isOriginMode = false
                    self.reloadShadowView()
                    var pass = ImagePassThrough()
                    pass.key = key
                    pass.fsUnit = fsUnit
                    self.bt.setLarkImage(with: .default(key: key),
                                         passThrough: pass)
                case .defalut:
                    self.backgroundColor = .clear
                    self.isOriginMode = true
                    self.reloadShadowView()
                    self.bt.setLarkImage(with: .default(key: ""))
                case .unknown:
                    break
                }
            }).disposed(by: self.bag)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        reloadShadowView()
    }

    private func reloadShadowView() {
        shadowView.isHidden = !(self.isDarkMode && !isOriginMode)
    }

    public func setImage(theme: ServerPB_Entities_ChatTheme?,
                         changeHandler: (ServerPB_Entities_ChatBackgroundEntity.BackgroundMode) -> Void = { _ in }) {
        switch theme?.backgroundEntity.mode {
        case .originMode:
            changeHandler(.originMode)
            self.backgroundColor = .clear
            self.bt.setLarkImage(with: .default(key: ""))
        case .colorMode:
            if let colorInfo = theme?.backgroundEntity.color {
                changeHandler(.colorMode)
                var color: UIColor?
                // 优先使用udToken，不可用则根据rgb转换颜色
                if colorInfo.hasUdToken, let udColor = UDColor.getValueByBizToken(token: colorInfo.udToken) {
                    color = udColor
                } else if colorInfo.hasLightColor, colorInfo.hasDarkColor {
                    let rgbColor = UIColor.ud.rgb(colorInfo.lightColor) & UIColor.ud.rgb(colorInfo.darkColor)
                    color = rgbColor
                }
                if let color = color {
                    self.backgroundColor = color
                    self.bt.setLarkImage(with: .default(key: ""))
                }
            }
        case .imageMode:
            if let key = theme?.backgroundEntity.imageKey {
                var pass = ImagePassThrough()
                pass.key = key
                pass.fsUnit = theme?.backgroundEntity.fsunit
                // 有缓存再去设置图片
                if LarkImageService.shared.isCached(resource: .default(key: key)) {
                    Self.logger.info("ChatTheme \(key) has cache")
                    changeHandler(.imageMode)
                    self.backgroundColor = .clear
                    self.bt.setLarkImage(with: .default(key: key),
                                         passThrough: pass)
                } else {
                    Self.logger.info("ChatTheme \(key) no cache")
                    changeHandler(.originMode)
                    self.bt.setLarkImage(with: .default(key: key),
                                         passThrough: pass,
                                         options: [.disableAutoSetImage]) { result in
                        do {
                            _ = try result.get().image
                            Self.logger.info("ChatTheme \(key) download image success")
                        } catch {
                            Self.logger.info("ChatTheme \(key) download image resut is nil")
                        }
                    }
                }
            }
        @unknown default:
            break
        }
    }
}

extension Chat {
    var isCustomTheme: Bool {
        self.theme?.backgroundEntity.hasMode == true && self.theme?.backgroundEntity.mode != .originMode
    }
}
