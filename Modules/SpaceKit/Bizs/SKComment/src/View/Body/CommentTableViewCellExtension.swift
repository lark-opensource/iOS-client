//
//  CommentTableViewCellExtension.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/7/27.
//  


import Foundation
import SKFoundation


extension CommentTableViewCell {
    
    /// 是否需要把翻译按钮append到内容最后一行，判断最后一行是否有空间容纳icon
    func needAppendIconAtLastLine() -> (needAppend: Bool, moreThanOne: Bool) {
        guard !translationLoadingView.isHidden else {
            return (false, false)
        }
        let label = translationView.isHidden ? contentLabel : translationView.content
        var contentViewWidth: CGFloat = 0
        if let selfWidth = cellWidth {
            contentViewWidth = selfWidth
        } else {
            contentViewWidth = self.contentView.bounds.size.width
        }

        guard contentViewWidth > 0 else {
            DocsLogger.info("contentViewWidth=0", component: LogComponents.comment)
            return (false, false)
        }
        let labelMaxWith = contentViewWidth - emptySpaceForContent
        
        let result = label.calculateLinesAndlastLineInfo(labelWidth: labelMaxWith, lineSpace: fontLineSpace ?? 0, lineBreakMode: nil)
        let lines = result.numeOfLines
        let lastLineWidth = result.lastLineWidth
        
        let spaceForIcon = labelMaxWith - lastLineWidth
//        DocsLogger.debug("needAppendIconAtLastLine,hidden=\(translationView.isHidden), lastLineWidth=\(lastLineWidth),viewWidth=\(labelMaxWith), cha=\(spaceForIcon)")
        if spaceForIcon > 24 {
            return (true, lines > 1)
        } else {
            return (false, lines > 1)
        }
    }
    
    // loadingView的位置，高度，是否覆盖在尾部
    
    ///  计算新的loadingview 的位置
    ///  - Returns: point：loadingview的坐标，height：最后一行文本的高度，
    ///             isAddTail：是否追加在文本后面，false代表叠加在尾部，用来控制是否显示白色渐变蒙层
    func calculateNewLoadingViewPosition() -> (point: CGPoint, height: CGFloat, isAddTail: Bool) {
        
        var contentViewWidth: CGFloat = 0
        if let selfWidth = cellWidth {
            contentViewWidth = selfWidth
        } else {
            contentViewWidth = self.contentView.bounds.size.width
        }

        guard contentViewWidth > 0 else {
            DocsLogger.info("contentViewWidth=0", component: LogComponents.comment)
            return (CGPoint(), 0, false)
        }
        // 文本label的宽度
        let labelMaxWith = contentViewWidth - emptySpaceForContent
        // 计算：lastLineWidth 最后一行文本的宽度
        //      allLineHeight 文本的整体高度：每一行高度+所有行间距
        //      lastLineHeight 最后一行文本的高度
        let (_, lastLineWidth, allLineHeight, lastLineHeight) = contentLabel.calculateLinesAndlastLineInfo(labelWidth: labelMaxWith, lineSpace: fontLineSpace ?? 0, lineBreakMode: .byWordWrapping)
        //算出文本后面剩余的空白空间
        let spaceForLoading = labelMaxWith - lastLineWidth
        //算出loadingview在label上显示的Y坐标
        let loadingY = allLineHeight - lastLineHeight
        //文本后面剩余的空白空间 是否够放下转圈laoding
        if spaceForLoading > sendingNewLoadingWH {
            // 够放在转圈laoding：
            // 算出loadingview在label上显示的x坐标：最后一行文本的宽度 - loadingview的宽度 + 转圈loading的宽度
            // 为什么最后要加 转圈loading的宽度呢？
            // loadingview布局：长方形的view，内部转圈loading是局右显示的
            // 所以 文本最后一行文本的宽度 - loadingview的宽度 等于  loadingview的尾部跟文本最后一行的尾部重叠
            //     再 + 转圈loading的宽度  等于 转圈loading刚好在文本尾部的后面
            // 就达到了转圈loading显示在文本的后面的效果
            let loadingX = lastLineWidth - sendingNewLoadingViewWidth + sendingNewLoadingWH
            return (CGPoint(x: loadingX, y: loadingY), lastLineHeight, false)
        } else {
            // 不够放在转圈laoding：
            // 算出loadingview在label上显示的x坐标：最后一行文本的宽度 - loadingview的宽
            // 刚好loadingview跟最后一行文本的尾部重叠，再控制显示白色渐变颜色蒙层
            // 就达到了转圈loading叠加再文本的尾部，而且又显示了白色渐变颜色蒙层
            let loadingX = lastLineWidth - sendingNewLoadingViewWidth
            return (CGPoint(x: loadingX, y: loadingY), lastLineHeight, true)
        }
    }
    
    
}
