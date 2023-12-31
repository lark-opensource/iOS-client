//
//  FloatingParticipantView.swift
//  ByteView
//
//  Created by liujianlong on 2023/5/24.
//

import UIKit
import ByteViewUI
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignStyle
import UniverseDesignFont
import RxSwift

final class FloatingParticipantView: UIView {
    private let renderingBag = DisposeBag()
    let streamRenderView = StreamRenderView()
    let avatar = AvatarView()
    private let cameraHaveNoAccessImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.videoOffOutlined, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 144.0, height: 144.0))
        let imageView = UIImageView(image: image)
        imageView.isHidden = true
        return imageView
    }()

    var isMe = false {
        didSet {
            guard isMe != oldValue else {
                return
            }
            updateAvatarVisibility()
        }
    }

    private(set) var isRendering = false {
        didSet {
            guard self.isRendering != oldValue else {
                return
            }
            updateAvatarVisibility()
        }
    }

    var avatarDesc: String = "" {
        didSet {
            guard avatarDesc != oldValue else {
                return
            }
            updateAvatarVisibility()
        }
    }

    var isUserInfoVisible: Bool = true {
        didSet {
            guard isUserInfoVisible != oldValue else {
                return
            }
            updateAvatarVisibility()
        }
    }

    private let avatarLabel: UILabel = {
        let avatarLabel = UILabel()
        avatarLabel.font = Display.phone ? UDFont.caption3 : UDFont.caption1
        avatarLabel.textColor = UDColor.textCaption
        avatarLabel.numberOfLines = 2
        avatarLabel.textAlignment = .center
        avatarLabel.lineBreakMode = .byTruncatingTail
        return avatarLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        self.addSubview(streamRenderView)
        self.addSubview(cameraHaveNoAccessImageView)
        self.addSubview(avatar)
        self.addSubview(avatarLabel)

        streamRenderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cameraHaveNoAccessImageView.snp.remakeConstraints { make in
            make.height.equalTo(cameraHaveNoAccessImageView.snp.width)
            make.width.equalToSuperview().multipliedBy(0.4).priority(.high)
            make.height.equalToSuperview().multipliedBy(0.4).priority(.high)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.4)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.4)
            make.centerX.equalToSuperview()
            // topMargin: a, bottomMargin: a + 4
            if Display.phone {
                make.centerY.equalToSuperview().offset(-2.0)
            } else {
                make.centerY.equalToSuperview().offset(-8.0)
            }
        }

        avatarLabel.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(8.0)
            make.top.equalTo(avatar.snp.bottom).offset(Display.phone ? 2.0 : 4.0)
        }

        self.isRendering = streamRenderView.isRendering
        streamRenderView.addListener(self)

        InMeetOrientationToolComponent.isLandscapeOrientationRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.updateRenderMode()
            })
            .disposed(by: renderingBag)
        updateAvatarVisibility()
    }

    func updateRenderMode() {
        if self.streamRenderView.streamKey == .local {
            if Display.pad {
                self.streamRenderView.renderMode = .renderModeFit
            } else if isLandscape {
                self.streamRenderView.renderMode = .renderModeAuto
            } else {
                self.streamRenderView.renderMode = .renderModeHidden
            }
        } else {
            if isLandscape {
                self.streamRenderView.renderMode = .renderModeAuto
            } else if Display.phone {
                self.streamRenderView.renderMode = .renderModeHidden
            } else {
                self.streamRenderView.renderMode = .renderModePadPortraitFloating
            }
        }
    }

    private func updateAvatarAndLabel() {
        if self.avatarDesc.isEmpty {
            avatarLabel.isHidden = true
        } else {
            avatarLabel.text = self.avatarDesc
            avatarLabel.isHidden = false
        }
        avatar.snp.remakeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.5).priority(.high)
            make.height.equalToSuperview().multipliedBy(0.5).priority(.high)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.5)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.5)
            make.height.equalTo(avatar.snp.width)
            make.centerX.equalToSuperview()
            // topMargin: a, bottomMargin: a + 5
            if !self.avatarDesc.isEmpty {
                if Display.phone {
                    make.centerY.equalToSuperview().offset(-14.5)
                } else {
                    make.centerY.equalToSuperview().offset(-16.0)
                }
            } else if isUserInfoVisible {
                if Display.phone {
                    make.centerY.equalToSuperview().offset(-2.5)
                } else {
                    make.centerY.equalToSuperview().offset(-8)
                }
            } else {
                make.centerY.equalToSuperview()
            }
        }
    }

    private func updateAvatarVisibility() {
        if self.isRendering {
            self.avatar.isHidden = true
            self.avatarLabel.isHidden = true
            self.cameraHaveNoAccessImageView.isHidden = true
        } else if isMe && Privacy.videoDenied {
            self.avatar.isHidden = true
            self.avatarLabel.isHidden = true
            self.cameraHaveNoAccessImageView.isHidden = false
        } else {
            self.avatar.isHidden = false
            self.cameraHaveNoAccessImageView.isHidden = true
            updateAvatarAndLabel()
        }
    }
}

extension FloatingParticipantView: StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.isRendering = isRendering
    }
}
