//
//  MicCorner.swift
//  ByteView
//
//  Created by wulv on 2023/10/27.
//

import Foundation
import UniverseDesignIcon

class ImageWithCornerView: UIView {
    typealias UpdateImg = ((MicCornerType) -> UIImage)
    private lazy var corner = MicCorner()
    private lazy var imageView = UIImageView()

    var type: MicCornerType {
        get { corner.cornerType }
        set {
            imageView.image = updateImg(newValue)
            corner.cornerType = newValue
        }
    }
    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    private let updateImg: UpdateImg
    init(image: UIImage? = nil, tintColor: UIColor? = nil, updateImg: @escaping UpdateImg) {
        self.updateImg = updateImg
        super.init(frame: .zero)
        if let image = image {
            imageView.image = image
        } else {
            imageView.image = updateImg(.empty)
        }
        imageView.tintColor = tintColor
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        corner.attachToSuperView(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

typealias MicCornerType = MicCorner.CornerType
final class MicCorner: UIImageView {
    static let roomImg: UIImage = UDIcon.getIconByKey(.roomFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 13, height: 13))
    static let roomImgDisabled: UIImage = UDIcon.getIconByKey(.roomFilled, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 13, height: 13))
    private let customSize: CGSize?
    private var lastSuperHeight: CGFloat = 0
    private var attachedView: UIView?

    init(customSize: CGSize? = nil, type: CornerType = .empty) {
        self.customSize = customSize
        self.cornerType = type
        super.init(image: nil)
        updateCorner()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum CornerType: Equatable {
        case empty
        case room(State)

        enum State {
            case normal
            case disabled
        }
    }

    var cornerType: CornerType {
        didSet {
            if oldValue != cornerType {
                updateCorner()
            }
        }
    }

    private func updateCorner() {
        switch cornerType {
        case .empty:
            isHidden = true
        case .room(let state):
            isHidden = false
            switch state {
            case .normal:
                image = Self.roomImg
            case .disabled:
                image = Self.roomImgDisabled
            }
        }
    }

    func attachToSuperView(_ superView: UIView) {
        superView.addSubview(self)
        snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(1.5)
            make.bottom.equalToSuperview()
            make.size.equalTo(customSize ?? CGSize(width: 10, height: 10))
        }
        attachedView = superView
        updateSize()
    }

    private func updateSize() {
        if customSize == nil, let attachedView = attachedView, attachedView.bounds.size.height != lastSuperHeight {
            var size: CGSize
            let h = attachedView.bounds.size.height
            if h >= 24 {
                size = CGSize(width: 13, height: 13)
            } else if h >= 22 {
                size = CGSize(width: 12, height: 12)
            } else if h >= 20 {
                size = CGSize(width: 11, height: 11)
            } else {
                size = CGSize(width: 10, height: 10)
            }
            snp.updateConstraints { make in
                make.size.equalTo(size)
            }
            lastSuperHeight = attachedView.bounds.size.height
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSize()
    }
}
