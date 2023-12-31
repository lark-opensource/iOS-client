//
//  SheetNumKeyboardView.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/6.
//

import Foundation
import SKCommon
import SKUIKit
import UniverseDesignColor

protocol SheetNumKeyboardViewDelegate: AnyObject {
    func didSelectItem(at indexPath: IndexPath?, type: SheetNumKeyboardButtonType, view: SheetNumKeyboardView)
    func didStartLongPress(type: SheetNumKeyboardButtonType, view: SheetNumKeyboardView)
    func didStopLongPress(type: SheetNumKeyboardButtonType, view: SheetNumKeyboardView)
}

class SheetNumKeyboardView: UIView {

    let calcCellReuseIdentifier = "sheet.keyboard.calc"
    let digitalCellReuseIdentifier = "sheet.keyboard.digital"
    let helpCellReuseIdentifier = "sheet.keyboard.help"
    static let maxValidKeyboardWidth: CGFloat = 516
    weak var delegate: SheetNumKeyboardViewDelegate?
    private var viewLayout: SheetNumKeyboardViewLayout = SheetNumKeyboardViewLayout(preferWidth: 375, preferHeight: 258)
    private var items: [[SheetNumKeyboardButtonType]] = [[SheetNumKeyboardButtonType]]()
    private var downItemCell: SheetHelpKeyboardCell?
    private var keyboardWidth: CGFloat = 0
    private var keyboardOptimalHeight: CGFloat { keyboardWidth * 258.0 / 375.0 }
    private var tapGesture: UITapGestureRecognizer?
    
    private var cellSwitchEnable = true
    
    /// 计算自定义键盘真正应该采用的宽度
    static func preferredKeyboardWidth(for preferWidth: CGFloat) -> CGFloat {
        return min(SheetNumKeyboardView.maxValidKeyboardWidth, preferWidth)
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
//        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.contentInsetAdjustmentBehavior = .never
        view.register(SheetCalcKeyboardCell.self, forCellWithReuseIdentifier: calcCellReuseIdentifier)
        view.register(SheetDigitalKeyboardCell.self, forCellWithReuseIdentifier: digitalCellReuseIdentifier)
        view.register(SheetHelpKeyboardCell.self, forCellWithReuseIdentifier: helpCellReuseIdentifier)
        view.backgroundColor = UIColor.ud.N300 & UIColor.ud.bgBodyOverlay.alwaysDark
        view.dataSource = self
        view.delegate = self
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N300 & UIColor.ud.bgBodyOverlay.alwaysDark
        prepareItems()
        addSubview(collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTrait = previousTraitCollection else {
            return
        }
        if #available(iOS 13.0, *) {
            if previousTrait.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
                self.collectionView.reloadData()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        update(containerWidth: bounds.width)
    }
    
    func update(containerWidth: CGFloat) {
        debugPrint("sheet num keyboard view width \(containerWidth)")
        keyboardWidth = SheetNumKeyboardView.preferredKeyboardWidth(for: containerWidth)
        viewLayout = SheetNumKeyboardViewLayout(preferWidth: keyboardWidth, preferHeight: keyboardOptimalHeight)
        collectionView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(keyboardWidth)
            make.height.equalTo(keyboardOptimalHeight)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    private func prepareItems() {
        let calcItem: [SheetNumKeyboardButtonType] = [.currency, .pecent, .slash, .sign]
        let digitalItem: [SheetNumKeyboardButtonType] = [.seven, .four, .one, .zerozero, .eight, .five, .two, .zero, .nine, .six, .three, .point]
        let helpItem: [SheetNumKeyboardButtonType] = [.delete, .right, .down]
        items = [calcItem, digitalItem, helpItem]
    }

    func disableCellSwitch(disable: Bool) {
        guard cellSwitchEnable == disable else {
            return
        }
        cellSwitchEnable = !disable
        collectionView.reloadData()
        
    }

}

extension SheetNumKeyboardView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section <= 2 else { return 0 }
        return items[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var reuseIdentifier = calcCellReuseIdentifier
        switch indexPath.section {
        case 0:
            reuseIdentifier = calcCellReuseIdentifier
        case 1:
            reuseIdentifier = digitalCellReuseIdentifier
        case 2:
            reuseIdentifier = helpCellReuseIdentifier
        default:
            ()
        }
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let cell = cell1 as? SheetBaseKeyboardCell {
            cell.delegate = self
            cell.type = items[indexPath.section][indexPath.row]
            cell.reload()
            if let helpCell = cell as? SheetHelpKeyboardCell {
                helpCell.makeDisable(disable: false)
                if helpCell.type == .down || helpCell.type == .right {
                    helpCell.makeDisable(disable: !cellSwitchEnable)
                }
                return helpCell
            }
            return cell
        } else {
            return cell1
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }
}

extension SheetNumKeyboardView: SheetBaseKeyboardCellDelegate {
    func didReceiveLongPressGesture(_ cell: SheetBaseKeyboardCell) {
        delegate?.didStartLongPress(type: cell.type, view: self)
    }

    func didStopLongPressGesture(_ cell: SheetBaseKeyboardCell) {
        delegate?.didStopLongPress(type: cell.type, view: self)
    }
}

extension SheetNumKeyboardView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let linePadding = viewLayout.itemLinePadding()
        switch section {
        case 0:
           return UIEdgeInsets(top: viewLayout.topPadding(), left: linePadding, bottom: viewLayout.bottomPadding(), right: linePadding)
        case 1:
           return UIEdgeInsets(top: viewLayout.topPadding(), left: 0, bottom: viewLayout.bottomPadding(), right: 0)
        case 2:
           return UIEdgeInsets(top: viewLayout.topPadding(), left: linePadding, bottom: viewLayout.bottomPadding(), right: linePadding)
        default:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return viewLayout.calcButtonSize()
        case 1:
            return viewLayout.numberButtonSize()
        case 2:
            if indexPath.item == 2 {
                return viewLayout.downButtonSize()
            } else {
                return viewLayout.helpButtonSize()
            }
        default:
            return viewLayout.helpButtonSize()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        //同一个Section中不同行直接的间距，在此是左右间距
        return viewLayout.itemLinePadding()
    }

//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//        return 0
//    }
}

extension SheetNumKeyboardView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SheetBaseKeyboardCell else { return }
        delegate?.didSelectItem(at: indexPath, type: cell.type, view: self)
    }
}
