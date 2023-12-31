//
//  PhotoScrollPickerCell.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/6/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Photos
import UniverseDesignIcon

enum ImageRequestResult {
    case iniCloud(UIImage?)
    case image(UIImage)
}

public protocol PhotoScrollPickerCellDelegate: AnyObject {
    func cellSelected(selected: Bool, cell: PhotoScrollPickerCell)
    func releaseCellOutside(cell: PhotoScrollPickerCell)
    func cellIsDragging(cell: PhotoScrollPickerCell)
    func cellIsStopDragging(cell: PhotoScrollPickerCell)
}

extension PhotoScrollPickerCellDelegate {
    func releaseCellOutside(cell: PhotoScrollPickerCell) {}

    func cellIsDragging(cell: PhotoScrollPickerCell) {}

    func cellIsStopDragging(cell: PhotoScrollPickerCell) {}
}

open class PhotoScrollPickerCell: UICollectionViewCell, SelectImageViewDelegate {
    fileprivate var imageViewIsOut: Bool = false

    let imageView: PhotoScrollPickerCellImageView
    let disableMaskView: UIView
    weak var delegate: PhotoScrollPickerCellDelegate?
    weak var currentAsset: PHAsset?
    var panGesture: UIPanGestureRecognizer!
    var selectIndex: Int? {
        didSet {
            imageView.selectIndex = selectIndex
        }
    }

    var imageIndentify: String?
    private (set) var iniCloud: Bool = true

    var cellSupportPanGesture = true {
        didSet {
            if !cellSupportPanGesture {
                imageView.removeGestureRecognizer(panGesture)
            }
        }
    }

    var onDeinit: ((Int) -> Void)?

    var imageTag: Int = 0 {
        didSet {
            imageView.tag = imageTag
        }
    }

    var hideSelectStatus: Bool = false {
        didSet {
            imageView.hideSelectStatus = hideSelectStatus
        }
    }

    private var videoTagView: VideoTagView
    var isVideo: Bool {
        return !videoTagView.isHidden
    }

    override init(frame: CGRect) {
        imageView = PhotoScrollPickerCellImageView(frame: .zero)
        disableMaskView = UIView(frame: .zero)
        videoTagView = VideoTagView()
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N50

        imageView.delegate = self
        imageView.isUserInteractionEnabled = true
        self.addSubview(imageView)

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(ges:)))
        panGesture.delegate = self
        imageView.addGestureRecognizer(panGesture)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        disableMaskView.isUserInteractionEnabled = false
        disableMaskView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.6)

        self.addSubview(disableMaskView)
        disableMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        imageView.addSubview(videoTagView)
        videoTagView.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
            maker.left.equalToSuperview().offset(5)
            maker.bottom.equalToSuperview().offset(-5)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        onDeinit?(self.hashValue)
    }

    func imageSelect(selected: Bool) {
        self.delegate?.cellSelected(selected: selected, cell: self)
    }

    func updateImage(indentifier: String, request: ImageRequestResult) {
        if indentifier == self.imageIndentify {
            switch request {
            case let .iniCloud(image):
                self.iniCloud = true
                self.imageView.image = image
            case let .image(image):
                self.iniCloud = false
                self.imageView.image = image
            }
        }
    }

    /// 给视频Asset对应的Cell添加时间标签，
    ///
    /// - Parameter time: 视频时长
    func setVideoTag(isVideo: Bool, time: TimeInterval) {
        guard isVideo else {
            videoTagView.hidden()
            return
        }

        var time: Int = Int(round(time))
        let seconds = time % 60
        time /= 60
        let minutes = time % 60
        time /= 60

        let timeString: String
        if time == 0 {
            timeString = String(format: "%02d:%02d", minutes, seconds)
        } else {
            timeString = String(format: "%02d:%02d:%02d", time, minutes, seconds)
        }
        videoTagView.show(with: timeString)
    }

    // checkbox不跟随手势滑动的相对于当前view的最大x坐标值
    func getMax(view: UIView) -> CGFloat {
        return view.frame.width - SelectImageView.checkBoxSize.width - SelectImageView.checkBoxPadding
    }

    /// change checkbox frame
    /// - Parameters:
    ///   - picker: superview of collectionView
    ///   - isSetLayout: is set layout or not, otherwise set frame
    func moveCheckBoxFrame(picker: UIView) {
        guard var cellFrameInPicker = self.superview?.convert(self.frame.origin, to: picker) else { return }

        // 如果当前cell的frame相对picker中的x值小于规定的最大x值, 当滑动而改变checkbox的位置为贴cell最右边
        // 否则保持checkbox的位置为贴cell最左边
        // 具体动画效果参考: https://bytedance.feishu.cn/docs/doccn4B1hBccYnpRyRbJTSihFlg#drXKnJ
        if cellFrameInPicker.x < getMax(view: picker) {
            var newX = self.imageView.convert(CGPoint(x: picker.frame.width - SelectImageView.checkBoxSize.width - SelectImageView.checkBoxPadding,
                                                      y: self.imageView.numberBox.frame.minY),
                                              from: picker).x
            newX = min(self.frame.width - SelectImageView.checkBoxSize.width - SelectImageView.checkBoxPadding, newX)
            // 设置checkbox的位置为贴cell最右边
            self.imageView.numberBox.frame = CGRect(x: newX,
                                                    y: SelectImageView.checkBoxPadding,
                                                    width: SelectImageView.checkBoxSize.width,
                                                    height: SelectImageView.checkBoxSize.height)
        } else {
            // 设置checkbox的位置为贴cell最左边
            self.imageView.numberBox.frame = CGRect(x: 0,
                                                    y: SelectImageView.checkBoxPadding,
                                                    width: SelectImageView.checkBoxSize.width,
                                                    height: SelectImageView.checkBoxSize.height)
        }
    }

    // 重设checkbox为初始位置(贴cell右边)
    func resetCheckBoxFrame() {
        self.imageView.numberBox.frame = CGRect(
            x: self.frame.width - SelectImageView.checkBoxSize.width - SelectImageView.checkBoxPadding,
            y: SelectImageView.checkBoxPadding,
            width: SelectImageView.checkBoxSize.width,
            height: SelectImageView.checkBoxSize.height
        )
    }

    func setMaskView(isHidden: Bool) {
        disableMaskView.isHidden = (selectIndex != nil) || isHidden
    }
}

extension PhotoScrollPickerCell: UIGestureRecognizerDelegate {
    @objc
    func handleGesture(ges: UIPanGestureRecognizer) {
        let point = ges.translation(in: self)
        guard let gesView = ges.view as? PhotoScrollPickerCellImageView else {
            return
        }

        let newY = gesView.frame.origin.y + point.y
        gesView.frame.origin.y = newY
        ges.setTranslation(CGPoint(x: 0, y: 0), in: self)

        switch ges.state {
        case .began:
            self.delegate?.cellIsDragging(cell: self)
        case .changed:
            if gesView.frame.origin.y < 0, abs(gesView.frame.origin.y) > gesView.frame.size.height * 0.4 {
                gesView.statusTitle.alpha = 1
                imageViewIsOut = true
            } else {
                gesView.statusTitle.alpha = 0
                imageViewIsOut = false
            }
        case .ended, .cancelled, .failed:
            gesView.statusTitle.alpha = 0

            UIView.animate(withDuration: 0.3, animations: {
                gesView.frame.origin.y = 0
            }, completion: { _ in
                self.delegate?.cellIsStopDragging(cell: self)
            })

            if imageViewIsOut {
                self.delegate?.releaseCellOutside(cell: self)
            }
            imageViewIsOut = false
        default:
            break
        }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer.state == .changed || gestureRecognizer.state == .ended {
            return false
        } else {
            return true
        }
    }
}

final class PhotoScrollPickerCellImageView: SelectImageView {
    let statusTitle: UILabel
    var hideSelectStatus: Bool = false {
        didSet {
            self.numberBox.isHidden = hideSelectStatus
        }
    }

    override init(frame: CGRect) {
        statusTitle = UILabel()
        super.init(frame: frame)
        self.clipsToBounds = true
        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFill
        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        self.addSubview(statusTitle)

        statusTitle.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        statusTitle.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_ReleaseToSend
        statusTitle.font = UIFont.systemFont(ofSize: 10)
        statusTitle.sizeToFit()
        statusTitle.textColor = UIColor.ud.primaryOnPrimaryFill
        statusTitle.backgroundColor = UIColor.gray
        statusTitle.alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class VideoTagView: UIView {

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.videoFilled
            .ud.resized(to: CGSize(width: 12, height: 12))
            .ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        return imageView
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.caption1(.fixed)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        iconView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(6)
        }

        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(iconView.snp.right).offset(4)
            maker.right.equalToSuperview().offset(-6)
        }

        isHidden = true
        layer.cornerRadius = 10
        layer.masksToBounds = true
        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.7)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Display readable time string on tag.
    /// - Parameter duration: total time of video in milliseconds.
    func setDuration(_ duration: Int32) {
        var time: Int = Int(round(TimeInterval(duration) / 1_000))
        let seconds = time % 60
        time /= 60
        let minutes = time % 60
        time /= 60
        let timeString: String
        if time == 0 {
            timeString = String(format: "%02d:%02d", minutes, seconds)
        } else {
            timeString = String(format: "%02d:%02d:%02d", time, minutes, seconds)
        }
        timeLabel.text = timeString
    }

    func show(with timeString: String) {
        timeLabel.text = timeString
        self.isHidden = false
    }

    func hidden() {
        self.isHidden = true
    }
}
