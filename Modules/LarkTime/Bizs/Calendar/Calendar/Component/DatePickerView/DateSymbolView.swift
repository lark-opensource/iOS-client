//
//  DateSymbolView.swift
//  Calendar
//
//  Created by zhuchao on 2019/5/10.
//

import UIKit
import LarkUIKit
import CalendarFoundation
import LarkTimeFormatUtils

final class DateSymbolView: UIView, UIScrollViewDelegate {

    private var amCell: CellView?
    private var pmCell: CellView?
    private let scrollView = UIScrollView()
    private let cellMinScale: CGFloat = 0.85
    var selectedAction: ((_ isAm: Bool) -> Void)?

    init(isAm: Bool, frame: CGRect) {
        super.init(frame: frame)
        layoutScrollView(scrollView)
        layoutCells(on: scrollView, isAm: isAm)
        scrollView.delegate = self
    }

    func changeColor(isInvalid: Bool) {
        amCell?.label.textColor = UIColor.ud.textTitle
        pmCell?.label.textColor = UIColor.ud.textTitle

        let textColor = isInvalid ? UIColor.ud.functionDangerContentDefault : UIColor.ud.textTitle
        let cell = getCenterCell()
        cell?.label.textColor = textColor
    }

    private func getCenterCell() -> CellView? {
        return getIsAm() ? self.amCell : self.pmCell
    }

    func getIsAm() -> Bool {
        return !(scrollView.contentOffset.y > scrollView.frame.height / 6.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard Display.pad else {
            return
        }
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: scrollView.frame.height * (4.0 / 3.0))
    }

    private func layoutScrollView(_ scrollView: UIScrollView) {
        scrollView.frame = self.bounds
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: scrollView.frame.height * (4.0 / 3.0))
        addSubview(scrollView)
        scrollView.snp.makeConstraints({make in
            make.edges.equalToSuperview()
        })
    }

    private func layoutCells(on scrollView: UIScrollView, isAm: Bool) {
        let stackView = UIStackView(frame: CGRect(origin: .zero, size: scrollView.contentSize))
        stackView.axis = .vertical
        stackView.alignment = .fill
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints({make in
            make.top.equalToSuperview()
            make.left.equalTo(self.snp.left)
            make.right.equalTo(self.snp.right)
            make.height.equalToSuperview().multipliedBy(4.0 / 3.0)
        })

        // 获得各个语言下 AM/PM 的表达
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        formatter.dateFormat = ""

        let cellFrame = CGRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.contentSize.height / 4.0)
        for i in 0..<4 {
            let cell: CellView
            if i == 1 {// am
                cell = CellView(text: formatter.amSymbol ?? "AM", frame: cellFrame)
                if !isAm {
                    cell.label.transform = CGAffineTransform(scaleX: cellMinScale, y: cellMinScale)
                }
                amCell = cell
            } else if i == 2 {// pm
                cell = CellView(text: formatter.pmSymbol ?? "PM", frame: cellFrame)
                if isAm {
                    cell.label.transform = CGAffineTransform(scaleX: cellMinScale, y: cellMinScale)
                }
                pmCell = cell
            } else {
                cell = CellView(text: "", frame: cellFrame)
            }
            stackView.addArrangedSubview(cell)
            cell.snp.makeConstraints { (make) in
                make.height.equalTo(scrollView.frame.height / 3.0)
                make.left.right.equalToSuperview()
            }
        }
        if !isAm {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height / 3.0), animated: false)
        }
        // 挡住顶部和底部防止滚动露出底色
        let topCover = UIView(frame: CGRect(origin: CGPoint(x: 0, y: -scrollView.contentSize.height + 1), size: scrollView.contentSize))
        topCover.backgroundColor = UIColor.ud.bgBody
        scrollView.addSubview(topCover)
        topCover.snp.makeConstraints({make in
            make.left.equalTo(self.snp.left)
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(stackView.snp.top)
            make.height.equalTo(scrollView.contentSize.height - 1)
        })

        let bottomCover = UIView(frame: CGRect(origin: CGPoint(x: 0, y: scrollView.contentSize.height - 1), size: scrollView.contentSize))
        bottomCover.backgroundColor = UIColor.ud.bgBody
        scrollView.addSubview(bottomCover)
        bottomCover.snp.makeConstraints({make in
            make.left.equalTo(self.snp.left)
            make.right.equalTo(self.snp.right)
            make.top.equalTo(stackView.snp.bottom)
            make.height.equalTo(scrollView.contentSize.height - 1)
        })
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollDidEnd(scrollView: scrollView)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let amCell = self.amCell, let pmCell = self.pmCell else {
            assertionFailureLog()
            return
        }
        changeScale(for: amCell)
        changeScale(for: pmCell)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollDidEnd(scrollView: scrollView)
    }

    func scrollDidEnd(scrollView: UIScrollView) {
        // 划过半格就滚动到底部
        if scrollView.contentOffset.y > scrollView.frame.height / 6.0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.frame.height / 3.0), animated: true)
            selectedAction?(false)
        } else {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            selectedAction?(true)
        }
    }

    private func changeScale(for cell: CellView) {
        let centerY = cell.convert(CGPoint(x: cell.bounds.width / 2.0, y: cell.bounds.height / 2.0), to: self).y
        var offSet = abs(bounds.height / 2.0 - centerY)
        let maxDistance = bounds.height / 3.0
        if offSet > maxDistance { offSet = maxDistance }
        let scale = 1 - (1 - cellMinScale) * (offSet / maxDistance)
        cell.label.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

private final class CellView: UIView {
    let label = UILabel()
    init(text: String, frame: CGRect) {
        super.init(frame: frame)
        label.text = text
        layoutLabel(label)
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size = self.frame.size
        return size
    }

    private func layoutLabel(_ label: UILabel) {
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        self.addSubview(label)
        label.snp.makeConstraints({make in
            make.centerX.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(-20)
            make.right.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(-15)
            make.bottom.equalToSuperview().offset(15)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
