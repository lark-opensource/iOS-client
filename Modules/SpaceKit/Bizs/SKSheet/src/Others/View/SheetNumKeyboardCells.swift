//
//  SheetNumKeyboardCell.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/9.
//

import Foundation
import UniverseDesignColor
import SKFoundation

protocol SheetBaseKeyboardCellDelegate: AnyObject {
    func didReceiveLongPressGesture(_ cell: SheetBaseKeyboardCell)
    func didStopLongPressGesture(_ cell: SheetBaseKeyboardCell)
}

class SheetBaseKeyboardCell: UICollectionViewCell {
    var type: SheetNumKeyboardButtonType = .zero
    weak var delegate: SheetBaseKeyboardCellDelegate?
    var inLongPress: Bool = false
    var longPressGesture: UILongPressGestureRecognizer?
    fileprivate var iconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        return view
    }()

    var iconColor: UIColor {
        return UDColor.iconN1
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        contentView.backgroundColor = normalBgColor
        contentView.layer.cornerRadius = 5.0
        contentView.layer.ud.setShadowColor(UDColor.staticBlack30 & UDColor.staticBlack80)
        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 0
        contentView.addSubview(iconView)
        layoutIconView()
        iconView.image = type.buttonImage()?.ud.withTintColor(iconColor)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = normalBgColor
    }

    func reload() {
        inLongPress = false
        iconView.image = type.buttonImage()?.ud.withTintColor(iconColor)
        if longPressGesture == nil, type == .delete {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(didReceiveLongPressGesture(gesture:)))
            longPressGesture.minimumPressDuration = 0.8
            contentView.addGestureRecognizer(longPressGesture)
        }
    }

    @objc
    func didReceiveLongPressGesture(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            inLongPress = true
            delegate?.didReceiveLongPressGesture(self)
        case .ended, .cancelled, .failed:
            inLongPress = false
            delegate?.didStopLongPressGesture(self)
            resetCommonBackground()
        default:
            ()
        }
    }

    var iconSize: CGSize {
        return CGSize(width: 32, height: 26)
    }

    var touchColor: UIColor {
        return UIColor.ud.N100
    }

    var normalBgColor: UIColor {
        return UIColor.clear
    }

    func layoutIconView() {
        let size = iconSize
        iconView.snp.makeConstraints { (make) in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        contentView.backgroundColor = touchColor
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        contentView.backgroundColor = touchColor
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if !inLongPress {
            resetCommonBackground()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        resetCommonBackground()
    }

    private func resetCommonBackground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
            guard let self = self else { return }
            self.contentView.backgroundColor = self.normalBgColor
        }
    }
}

class SheetCalcKeyboardCell: SheetBaseKeyboardCell {

    override var iconSize: CGSize {
        return CGSize(width: 24, height: 24)
    }

    override var touchColor: UIColor {
        return UIColor.ud.fillPressed
    }

    override var normalBgColor: UIColor {
        return UIColor.ud.N200
    }
}

class SheetDigitalKeyboardCell: SheetBaseKeyboardCell {

    override var iconSize: CGSize {
        return CGSize(width: 44, height: 32)
    }

    override var touchColor: UIColor {
        return UIColor.ud.fillPressed
    }

    override var normalBgColor: UIColor {
        return UIColor.ud.bgBody
    }
}

class SheetHelpKeyboardCell: SheetBaseKeyboardCell {

    override var iconSize: CGSize {
        return CGSize(width: 24, height: 24)
    }

    override var touchColor: UIColor {
        return UIColor.ud.fillPressed
    }

    override var normalBgColor: UIColor {
        return UIColor.ud.N200
    }

    func makeDisable(disable: Bool) {
        self.isUserInteractionEnabled = !disable
        let disableImage = type.buttonImage()?.ud.withTintColor(UIColor.ud.iconDisabled)
        iconView.image = disable ? disableImage : type.buttonImage()?.ud.withTintColor(iconColor)
    }
}
