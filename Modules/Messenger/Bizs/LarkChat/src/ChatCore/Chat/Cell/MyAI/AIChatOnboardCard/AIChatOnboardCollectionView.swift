//
//  AIChatOnboardCollectionView.swift
//  LarkChat
//
//  Created by Zigeng on 2023/11/14.
//

import Foundation
import UIKit
import ByteWebImage
import UniverseDesignColor
import ServerPB
import UniverseDesignFont

/// onboard卡片的场景列表
final class AIChatOnboardCollectionView: UICollectionView {

    var currentOffset: CGFloat?
    var scenes: [OnboardScene] = [] {
        didSet {
            self.reloadData()
        }
    }

    var newTopicAction: (Int64, UIView) -> Void = { _, _ in }
    var seceneWillDisplay: ((String) -> Void)?

    static var layout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 50)
        return layout
    }

    init(_ frame: CGRect) {
        super.init(frame: frame, collectionViewLayout: Self.layout)
        self.dataSource = self
        self.delegate = self
        self.register(AIChatOnboardCollectionViewCell.self, forCellWithReuseIdentifier: "AIChatOnboardCollectionViewCell")
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.clipsToBounds = true
        self.contentInset = .init(top: 0, left: UX.inset, bottom: 0, right: UX.inset)
        self.decelerationRate = UIScrollView.DecelerationRate.fast
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func caculateCellWidth(total: CGFloat, lineCount: Int, padding: CGFloat) -> CGFloat {
        return (total - padding) / CGFloat(lineCount)
    }
}

// UI常数
extension AIChatOnboardCollectionView {
    struct UX {
        /*↓ Public ↓*/
        /// CollectionView左右的contentInset
        static var inset: CGFloat { 12 }
        /// cell的上屏宽度
        static func cellWidth(_ collectionWidth: CGFloat) -> CGFloat {
            cellWidth(collectionWidth, maxCellWidth: maxCellWidth, padding: leadingRightPadding + inset)
        }
        /// 滑动时调整offset实现分页效果,用户最多能切换一页
        static func adjustOffset(_ view: UICollectionView, currentOffset: CGFloat, withVelocity velocity: CGPoint, offsetPointer: UnsafeMutablePointer<CGPoint>) {
            var curOffsetX = currentOffset
            let tarOffsetX = offsetPointer.pointee.x
            let cellWidth = cellWidth(view.frame.width)
            let lineCapicity: Int = Int(floor(view.bounds.size.width / cellWidth))
            var line = 0
            var preLineOffset: CGFloat = -view.contentInset.left
            var nextLineOffset: CGFloat = -view.contentInset.left
            var lineCount = (view.numberOfItems(inSection: 0) / 3) + ((view.numberOfItems(inSection: 0) % 3 != 0) ? 1 : 0)
            /// 分页offset的数组
            var offsetArray: [CGFloat] = [preLineOffset]
            while line < lineCount - 1 {
                line += lineCapicity
                if line < lineCount - lineCapicity {
                    nextLineOffset = (cellWidth * CGFloat(line)) + (cellSapce * (CGFloat(line) - 1)) - middleHorizontalPadding
                    offsetArray.append(nextLineOffset)
                } else if line == lineCount - lineCapicity {
                    nextLineOffset = (cellWidth * CGFloat(line)) + (cellSapce * (CGFloat(line) - 1)) - middleHorizontalPadding + trailingLeftPadding
                    offsetArray.append(nextLineOffset)
                    break
                } else if line > lineCount - lineCapicity {
                    nextLineOffset = (cellWidth * CGFloat(line)) + (cellSapce * (CGFloat(line) - 1)) - middleHorizontalPadding + trailingLeftPadding
                    offsetArray.append(nextLineOffset)
                    let blankLineCount = lineCapicity + line - lineCount
                    let additionalInset = (cellWidth * CGFloat(blankLineCount)) + (cellSapce * (CGFloat(blankLineCount) - 1))
                    if additionalInset != view.contentInset.right {
                        view.contentInset = UIEdgeInsets(top: view.contentInset.top, left: view.contentInset.left, bottom: view.contentInset.bottom, right: additionalInset)
                    }
                    break
                }
            }
            /// 找到当前页的上一页和下一页
            offsetArray.forEach { offset in
                if offset < curOffsetX - 10, offset > preLineOffset {
                    preLineOffset = offset
                } else if offset > curOffsetX + cellWidth, offset < nextLineOffset {
                    nextLineOffset = offset
                }
            }
            /// 找到目的页的上一页和下一页
            offsetArray.forEach { offset in
                if offset < curOffsetX - 10, offset > preLineOffset {
                    preLineOffset = offset
                } else if offset > curOffsetX + cellWidth, offset < nextLineOffset {
                    nextLineOffset = offset
                }
            }
            let adjustTarOffsetX = closedLineOffset(tarOffsetX, offsetList: offsetArray)
            if velocity.x < -0.3 && abs(adjustTarOffsetX - curOffsetX) < (CGFloat(lineCapicity) * 60) {
               offsetPointer.pointee.x = preLineOffset
           } else if velocity.x > 0.3 && abs(adjustTarOffsetX - curOffsetX) < (CGFloat(lineCapicity) * 60) {
               offsetPointer.pointee.x = nextLineOffset
           // 超距右滑
           } else if adjustTarOffsetX >= nextLineOffset && abs(nextLineOffset - curOffsetX) > cellWidth {
                offsetPointer.pointee.x = nextLineOffset
           //超距左滑
            } else if adjustTarOffsetX <= preLineOffset && abs(preLineOffset - curOffsetX) > cellWidth {
                offsetPointer.pointee.x = preLineOffset
            } else {
                offsetPointer.pointee.x = adjustTarOffsetX
            }
        }
        /*↑ Public ↑*/

        /// cell的间距
        private static var cellSapce: CGFloat { 8 }
        /// 首屏状态右侧额外间距
        private static var leadingRightPadding: CGFloat { 26 }
        /// 末屏状态左侧额外间距
        private static var trailingLeftPadding: CGFloat { leadingRightPadding }
        /// 滑动到中间时的左右间距
        private static var middleHorizontalPadding: CGFloat { (inset + leadingRightPadding) / 2 - cellSapce }
        /// cell的自适应最大宽度
        private static var maxCellWidth: CGFloat { 480 }

        /// 计算cell的宽度，规则为cell最宽为480，首屏右侧始终留白定值padding
        /// 由于精度问题和可能存在的浮点数舍入误差，直接使用浮点数计算可能导致结果稍微偏离预期，使用循环来精确计算
        private static func cellWidth(_ collectionViewWidth: CGFloat, maxCellWidth: CGFloat, padding: CGFloat) -> CGFloat {
            for lineCount in 1...5 {
                let cellWidth = caculateCellWidth(total: collectionViewWidth, lineCount: lineCount, padding: padding)
                if cellWidth < maxCellWidth {
                    return cellWidth
                }
            }
            return 480
        }
        /// 根据列数计算cell的宽度
        private static func cellWidth(total: CGFloat, lineCount: Int, padding: CGFloat) -> CGFloat {
            return (total - padding) / CGFloat(lineCount)
        }
        /// 返回左面最近和最右最近的列偏移量
        private static func closedLineOffset(_ currentOffset: CGFloat, offsetList: [CGFloat]) -> CGFloat {
            var minDifference = CGFloat.greatestFiniteMagnitude
            var closestLineOffset = currentOffset
            offsetList.forEach { offset in
                let difference = abs(offset - currentOffset)
                if difference < minDifference {
                    minDifference = difference
                    closestLineOffset = offset
                }
            }
            return closestLineOffset
        }
    }
}

extension AIChatOnboardCollectionView: UICollectionViewDelegateFlowLayout {
    // scene cell大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UX.cellWidth(self.frame.width)
        return CGSize(width: width, height: 96)
    }

    // 水平间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    // 垂直间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AIChatOnboardCollectionViewCell else { return }
        seceneWillDisplay?(String(cell.sceneID))
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        currentOffset = nil
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentOffset = nil
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if currentOffset == nil {
            currentOffset = scrollView.contentOffset.x
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let collectionView = scrollView as? UICollectionView, let currentOffset = currentOffset else {
            return
        }
        UX.adjustOffset(collectionView,
                        currentOffset: currentOffset,
                        withVelocity: velocity,
                        offsetPointer: targetContentOffset)
    }
}

extension AIChatOnboardCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return scenes.count
    }

    /// 点击cell使用场景创建新话题
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < scenes.count, let window = self.window else { return }
        newTopicAction(scenes[indexPath.row].sceneId, window)
    }

    /// 场景展示时进行埋点上报
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AIChatOnboardCollectionViewCell", for: indexPath) as? AIChatOnboardCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.update(scenes[indexPath.row])
        return cell
    }
}

class AIChatOnboardCollectionViewCell: UICollectionViewCell {
    lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.layer.cornerRadius = 10
        icon.layer.masksToBounds = true
        icon.clipsToBounds = true
        icon.contentMode = .scaleAspectFill
        return icon
    }()

    lazy var label = UILabel()
    lazy var subLabel = UILabel()
    lazy var sceneID: Int64 = 0

    override var isHighlighted: Bool {
        didSet {
            // 根据 isHighlighted 的值更新单元格的外观
            if isHighlighted {
                // 自定义高亮颜色
                self.backgroundColor = UIColor.ud.bgFiller
            } else {
                // 恢复正常状态的颜色
                self.backgroundColor = UIColor.ud.bgBodyOverlay
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        icon.bt.setImage(nil)
        label.text = nil
        subLabel.text = nil
    }

    func update(_ scene: OnboardScene) {
        icon.bt.setLarkImage(
            with: .default(key: scene.imagePassThrough.key ?? ""),
            placeholder: nil,
            passThrough: scene.imagePassThrough
        )
        label.text = scene.title
        sceneID = scene.sceneId
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.22
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14), // 设置字体
            .paragraphStyle: paragraphStyle // 设置段落样式
        ]
        let attributedString = NSAttributedString(string: scene.desc, attributes: attributes)
        subLabel.attributedText = attributedString
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.font = UDFont.headline
        label.textColor = .ud.iconN1
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        subLabel.font = UDFont.body2
        subLabel.textColor = .ud.textCaption
        subLabel.numberOfLines = 3
        self.addSubview(icon)
        self.addSubview(label)
        self.addSubview(subLabel)
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.height.width.equalTo(20)
        }
        label.snp.makeConstraints { make in
            make.centerY.equalTo(icon.snp.centerY)
            make.left.equalTo(icon.snp.right).offset(5)
            make.right.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(22)
        }
        subLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.top.equalTo(label.snp.bottom).offset(4)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        self.layer.cornerRadius = 8
        self.backgroundColor = UIColor.ud.bgBodyOverlay
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
