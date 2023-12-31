import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignStyle
import UniverseDesignFont
import SnapKit

final class FloatingTopStatusView: UIView {
    struct TopIcons: OptionSet {
        var rawValue: UInt8
        static let recording = TopIcons(rawValue: 1)
        static let transcribe = TopIcons(rawValue: 1 << 1)
        static let live = TopIcons(rawValue: 1 << 2)
    }
    private static let recordingIcon = UDIcon.getIconByKey(.recordingColorful,
                                                           iconColor: UDColor.functionDangerFillDefault,
                                                           size: CGSize(width: 10.0, height: 10.0))

    private static let transcribeIcon = UDIcon.getIconByKey(.transcribeFilled,
                                                            iconColor: UDColor.primaryContentDefault,
                                                            size: CGSize(width: 10.0, height: 10.0))

    private static let liveIcon = UDIcon.getIconByKey(.livestreamFilled,
                                                      iconColor: UDColor.functionDangerFillDefault,
                                                      size: CGSize(width: 10.0, height: 10.0))

    var networkImg: UIImage? {
        didSet {
            guard self.networkImg !== oldValue else {
                return
            }
            self.updateIcons()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var icons: TopIcons = [] {
        didSet {
            guard self.icons != oldValue else {
                return
            }
            self.updateIcons()
        }
    }

    private func updateIcons() {
        guard !self.icons.isEmpty || self.networkImg != nil else {
            self.isHidden = true
            return
        }

        self.isHidden = false
        self.subviews.forEach({ $0.removeFromSuperview() })
        var iconImage: [UIImage] = []
        if self.icons.contains(.recording) {
            iconImage.append(Self.recordingIcon)
        }
        if self.icons.contains(.transcribe) {
            iconImage.append(Self.transcribeIcon)
        }
        if self.icons.contains(.live) {
            iconImage.append(Self.liveIcon)
        }
        if let networkImg = self.networkImg {
            iconImage.append(networkImg)
        }

        let iconViews = iconImage.map(UIImageView.init(image:))

        var prevView: UIView?
        for v in iconViews {
            self.addSubview(v)
            v.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 10.0, height: 10.0))
                if let prevView = prevView {
                    make.left.equalTo(prevView.snp.right).offset(4.0)
                    make.centerY.equalTo(prevView)
                } else {
                    make.left.equalToSuperview().offset(4.0)
                    make.top.bottom.equalToSuperview().inset(3.0)
                }

                if v === iconViews.last {
                    make.right.equalToSuperview().offset(-4.0)
                }
            }
            prevView = v
        }
    }

    private func setupSubviews() {
        self.backgroundColor = UDColor.N00.withAlphaComponent(0.9)
        self.layer.cornerRadius = 6.0
        updateIcons()
    }
}
