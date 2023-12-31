//
//  FileDisplayInfoUtil.swift
//  LarkFile
//
//  Created by liluobin on 2021/10/20.
//

import Foundation
import UIKit

final class FileDisplayInfoUtil {
    static let gridCellWidth: CGFloat = 100
    static let gridCellHeight: CGFloat = 172
    static let gridCellMinSpace: CGFloat = 16
    static let listCellHeight: CGFloat = 68
    /// 把size转成 "296.5MB" 这种格式
   static func sizeStringFromSize(_ size: Int64) -> String {
        let tokens = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]

        var size: Float = Float(size)
        var mulitiplyFactor = 0
        while size > 1024 {
            size /= 1024
            mulitiplyFactor += 1
        }
        if mulitiplyFactor < tokens.count {
            return deleteLastZero(str: String(format: "%.2f", size)) + " " + tokens[mulitiplyFactor]
        }
        return deleteLastZero(str: String(format: "%.2f", size))
    }

    /// 删除末尾的0
    private static func deleteLastZero(str: String) -> String {
        let splitStrs = str.split(separator: ".")
        // 如果没有小数位/入参str不合理，不进行处理
        if splitStrs.count != 2 { return str }

        var folatStr = splitStrs[1]
        // 去掉folatStr末尾的0，folatStr全为0则folatStr会变为""
        while !folatStr.isEmpty, folatStr.last == "0" {
            folatStr.removeLast()
        }

        // 如果folatStr变为空，则说明小数位全为0，则只需要展示整数部分
        if folatStr.isEmpty { return String(splitStrs[0]) }

        return splitStrs[0] + "." + folatStr
    }

    /// n * 100 + ( n + 1) * 16 < width 中n的最大值 cell个数
    /// 纵向：固定列宽为「100pt」，列间距=左右margin≥16pt（等分但保证间距大于16pt）。垂直底部对齐
    static func gridCellCountForWidth(_ width: CGFloat) -> Int {
        let count = floor((width - gridCellMinSpace) / (gridCellWidth + gridCellMinSpace))
        return Int(count)
    }
    static func gridCellSpaceWidth(_ width: CGFloat) -> CGFloat {
        let count = gridCellCountForWidth(width)
        let space = (width - CGFloat(count) * gridCellWidth) / CGFloat(count + 1)
        return space
    }
    /// 图片与视频
    ///显示尺寸：优先原比例显示图片，使图片长边为高度84pt/宽度100pt，短边按原比例缩放、但保证短边最小宽度28pt/最小高度32pt（为长边的1/3），居中显示超出部分则裁切显示
    /// 分则裁切显示 视频同图片一样处理封面，若无封面则抓取视频第一帧，若均抓不到则显示「视频icon」
    static func displayImageSizeWithOriginSize(_ size: CGSize) -> CGSize {
        let maxImageWidth: CGFloat = 100
        let maxImageHeight: CGFloat = 84
        var expectSize: CGSize = .zero
        if size.width / size.height > maxImageWidth / maxImageHeight {
            expectSize.width = maxImageWidth
            expectSize.height = size.height / (size.width / maxImageWidth)
            if expectSize.height < 28 {
                expectSize.height = 28
            }
        } else {
            expectSize.height = maxImageHeight
            expectSize.width = size.width / (size.height / maxImageHeight)
            if expectSize.width < 32 {
                expectSize.width = 32
            }
        }
        return expectSize
    }

    /// 这里需要粗略的估算一下 每页有少个cell
    /// 不同的样式 & 不同的屏幕(横竖屏)
    static func maxCellPageCount() -> Int {
        let size = UIScreen.main.bounds.size
        let maxLength = max(size.width, size.height)
        let minLength = min(size.width, size.height)
        var maxCount = 20
        /// 参考原有的列表规则
        let listMaxCount = Int(maxLength / Self.listCellHeight * 1.5 + 1)
        maxCount = max(maxCount, listMaxCount)
        /// 最长边为宽
        let maxWidthCount = gridCellCountForWidth(maxLength)
        let maxWidthRow = ceil(minLength / Self.gridCellHeight)
        maxCount = max(maxCount, Int(maxWidthRow) * maxWidthCount + 1)

        /// 最长边为高
        let minWidthCount = gridCellCountForWidth(minLength)
        let minWidthRow = ceil(maxLength / Self.gridCellHeight)
        maxCount = max(maxCount, Int(minWidthRow) * minWidthCount + 1)
        /// 服务端有最大的限制，一屏不能超过70个
        return min(maxCount, 70)
    }
}
