//
//  VideoCoverView.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/8/17.
//

import UIKit
import Foundation
public final class VideoCoverView: UIImageView {
    public typealias SetImageCompletion = (_ image: UIImage?, _ error: Error?) -> Void
    public typealias SetImageTask = (_ imageView: UIImageView, _ completion: SetImageCompletion?) -> Void
    public typealias OnTap = (_ imageView: UIImageView) -> Void

    public var setImageTask: SetImageTask? {
        didSet {
            // reset
            coverImageView.image = nil
            blurView.isHidden = true
            gradient.isHidden = true
            self.image = nil
            if let task = setImageTask {
                task(coverImageView, { [weak self] image, error in
                    self?.setupCover(image: image, error: error)
                })
            }
        }
    }

    public var duration: Int64 = 0 {
        didSet {
            if duration > 0 {
                durationLabel.isHidden = false
                durationLabel.text = Self.timeString(seconds: duration)
            } else {
                durationLabel.isHidden = true
            }
        }
    }

    public var onTap: OnTap? {
        didSet {
            self.videoTapGesture?.isEnabled = (onTap != nil)
            self.isUserInteractionEnabled = (onTap != nil)
        }
    }

    private lazy var coverImageView: UIImageView = {
        let coverImageView = UIImageView(frame: .zero)
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.backgroundColor = UIColor.clear
        return coverImageView
    }()

    private lazy var playIcon: UIImageView = {
        let playIcon = UIImageView()
        playIcon.image = BundleResources.playVideo
        return playIcon
    }()

    private lazy var durationLabel: PaddingLabel = {
        let durationLabel = PaddingLabel(frame: .zero)
        durationLabel.padding = .init(top: 2, left: 8, bottom: 2, right: 8)
        durationLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        durationLabel.numberOfLines = 1
        durationLabel.font = UIFont.ud.caption1
        durationLabel.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.6)
        durationLabel.layer.cornerRadius = 6
        durationLabel.clipsToBounds = true
        return durationLabel
    }()

    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = .init(x: 0.5, y: 0)
        gradient.endPoint = .init(x: 0.5, y: 1)
        gradient.locations = [0, 0.5, 1]
        gradient.colors = [UIColor.ud.staticBlack.withAlphaComponent(0.2).cgColor,
                           UIColor.clear.cgColor,
                           UIColor.ud.staticBlack.withAlphaComponent(0.2).cgColor]
        return gradient
    }()

    private lazy var blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))

    private var videoTapGesture: UITapGestureRecognizer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        let videoTapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapped))
        self.videoTapGesture = videoTapGesture
        videoTapGesture.isEnabled = false
        self.addGestureRecognizer(videoTapGesture)
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
        self.backgroundColor = UIColor.ud.N900
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.isHidden = true

        addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        coverImageView.layer.insertSublayer(gradient, at: 0)
        gradient.frame = self.bounds
        gradient.isHidden = true

        addSubview(playIcon)
        playIcon.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.center.equalToSuperview()
        }

        addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    private func setupCover(image: UIImage?, error: Error?) {
        // 重置frame
        gradient.frame = self.bounds
        guard let image = image else {
            // 重置根节点的image
            self.image = nil
            blurView.isHidden = true
            gradient.isHidden = false
            return
        }
        // 设置渐变Layer
        gradient.isHidden = false
        // 设置模糊背景
        self.image = image
        blurView.isHidden = false
    }

    @objc
    private func onTapped() {
        self.onTap?(coverImageView)
    }
}

extension VideoCoverView {
    /// seconds to h:m:s
    public static func timeString(seconds: Int64) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        return formatter.string(from: TimeInterval(seconds)) ?? String(seconds)
    }
}
