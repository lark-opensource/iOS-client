//
//  FaceToFaceKeyboardView.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/8.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa

enum FaceToFaceKeyboardItemType {
    case placeholder // 无效按键
    case delete // 删除
    case number(Int) // 输入数字
}

final class FaceToFaceKeyboardView: UIView {
    var keyboardObservable: Observable<FaceToFaceKeyboardItemType> {
        return Observable.merge(buttonObservables)
    }
    private var buttonObservables: [Observable<FaceToFaceKeyboardItemType>] = []
    private let disposeBag = DisposeBag()
    private let rowCount = 4
    private let columnCount = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear

        var buttons: [FaceToFaceKeyboardItem] = []
        for index in 0..<rowCount * columnCount {
            let itemType: FaceToFaceKeyboardItemType
            if index >= 0 && index < 9 {
                itemType = .number(index + 1)
            } else if index == 10 {
                itemType = .number(0)
            } else if index == 11 {
                itemType = .delete
            } else {
                itemType = .placeholder
            }

            let button = FaceToFaceKeyboardItem(type: itemType)
            buttons.append(button)
            buttonObservables.append(button.rx.controlEvent(.touchUpInside).map { itemType })
        }

        buttons.enumerated().forEach { (index, button) in
            self.addSubview(button)
            let currentRow = index / columnCount
            button.snp.makeConstraints { (make) in
                make.width.equalToSuperview().dividedBy(columnCount)
                make.height.equalToSuperview().dividedBy(rowCount)

                if index % columnCount == 0 {
                    make.left.equalToSuperview()
                } else {
                    let preButton = buttons[index - 1]
                    make.left.equalTo(preButton.snp.right)
                }

                if currentRow == 0 {
                    make.top.equalToSuperview()
                } else {
                    let preButton = buttons[index - columnCount]
                    make.top.equalTo(preButton.snp.bottom)
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FaceToFaceKeyboardItem: UIControl {
    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.N900
        highlightView.alpha = 0.1
        highlightView.layer.cornerRadius = 4
        highlightView.isHidden = true
        return highlightView
    }()

    private lazy var numberLabel: UILabel = {
        let numberLabel = UILabel()
        numberLabel.textColor = UIColor.ud.textCaption
        numberLabel.font = UIFont.systemFont(ofSize: 24)
        numberLabel.textAlignment = .center
        return numberLabel
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.highlightView.isHidden = false
            } else {
                self.highlightView.isHidden = true
            }
        }
    }

    init(type: FaceToFaceKeyboardItemType) {
        super.init(frame: .zero)

        self.backgroundColor = .clear
        self.addSubview(self.highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.7)
            make.height.equalToSuperview().multipliedBy(0.82)
        }

        switch type {
        case .placeholder:
            self.isEnabled = false
        case .delete:
            let deletImageView = UIImageView(image: Resources.faceToFaceKeyboardDeleteItem)
            self.addSubview(deletImageView)
            deletImageView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        case .number(let number):
            self.addSubview(self.numberLabel)
            numberLabel.text = "\(number)"
            numberLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 可点击区域修改
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let relativeFrame = self.bounds
        let horizontalInset = relativeFrame.size.width * 0.1
        let verticalInset = relativeFrame.size.height * 0.1
        let hitFrame = relativeFrame.inset(by: UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset))
        return hitFrame.contains(point)
    }
}
