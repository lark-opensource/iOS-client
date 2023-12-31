//
//  BlockMenuViewModel.swift
//  SKBrowser
//
//  Created by zoujie on 2022/3/24.
//  


import Foundation

public final class BlockMenuViewModel {

    private let itemHeigth: CGFloat = 70
    //Block菜单item的宽度,根据当前菜单的宽度和菜单项的个数来设置
    private var minItemWidth: CGFloat = 56
    //iPad分屏下Block菜单父view的最小宽度
    private let minSplitScreenWidth: CGFloat = 320
    //iPad下菜单宽度大于320时，Block菜单item的宽度
    private let iPadNormalItemWidth: CGFloat = 78
    private let menuPadding: CGFloat = 12

    private var isIPad: Bool
    public var data: [BlockMenuItem]
    public var menuWidth: CGFloat = 0

    public init(isIPad: Bool,
                data: [BlockMenuItem]) {
        self.isIPad = isIPad
        self.data = data
    }

    /// 每行排列的item个数
    /// - Returns: 每行排列的item个数
    /// https://bytedance.feishu.cn/mindnotes/bmncn6Wzu8tSXhRodwh3HvlBLUf#mindmap
    public func getPerLineItemNum() -> Int {
        var perMaxLineItemNum = data.count
        let minMenuWidth = CGFloat(data.count) * minItemWidth + 2 * menuPadding + CGFloat(data.count - 1) * BlockMenuConst.minimumInteritemSpacing

        //当菜单宽度不满足一行放下所有item时，一行最多放5个
        if menuWidth < minMenuWidth {
            perMaxLineItemNum = min(5, Int(floor((menuWidth - 2 * menuPadding + BlockMenuConst.minimumInteritemSpacing) / CGFloat(minItemWidth + BlockMenuConst.minimumInteritemSpacing))))
            perMaxLineItemNum = data.count == 6 ? 4 : perMaxLineItemNum
        }

        //iPad分屏情况下，Block菜单宽度小于320，菜单项大于4项时，排布为一行3个
        if isIPad, menuWidth < minSplitScreenWidth, data.count > 4 {
            perMaxLineItemNum = 3
        }

        return min(perMaxLineItemNum, data.count)
    }

    public func countItemHeight(itemWidth: CGFloat) -> [Int: CGFloat] {
        guard data.count > 0 else { return [:] }
        var cellHeight: [Int: CGFloat] = [:]
        let paragraphStyle = NSMutableParagraphStyle()
        /// 仅用于高度计算
        //swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byWordWrapping
        // swiftlint:enable ban_linebreak_byChar
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] =
            [.font: UIFont.systemFont(ofSize: 12),
             .paragraphStyle: paragraphStyle]

        var lineNum = 0
        var lineMaxCellHeight: CGFloat = 0
        let perLineNum = getPerLineItemNum()

        for (i, item) in data.enumerated() {
            guard let text = item.text else { return [:] }
            let stringSize = text.boundingRect(with: CGSize(width: itemWidth - 4,
                                                            height: .greatestFiniteMagnitude),
                                               options: .usesLineFragmentOrigin,
                                               attributes: attributes,
                                               context: nil).size

            //var height: CGFloat = stringSize.height > 15 ? 28 : 14
            var textLineNum = (stringSize.height / 14).rounded()
            textLineNum = textLineNum < 7 ? textLineNum : 6
            var height = 14 * textLineNum
            
            height += 50

            if height > lineMaxCellHeight {
                lineMaxCellHeight = height
            }

            if i >= (perLineNum * (lineNum + 1) - 1) || i == data.count - 1 {
                cellHeight.updateValue(lineMaxCellHeight, forKey: lineNum)
                lineNum += 1
                lineMaxCellHeight = 0
            }
        }

        return cellHeight
    }
}
