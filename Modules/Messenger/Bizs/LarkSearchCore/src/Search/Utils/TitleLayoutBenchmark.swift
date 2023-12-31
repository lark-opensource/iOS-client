//
//  TitleLayoutBenchmark.swift
//  LarkSearch
//
//  Created by Patrick on 2021/7/9.
//

import UIKit
import Foundation
import RustPB
import CoreGraphics

public final class TitleLayoutBenchmark {

    public enum TypeEnum {
        case mainSearch
        case chat
        case docInchat
        case emailOpenSearch
    }

    private static let benchmarkString = "一" // 用汉字“一”作为宽度的基准
    /*
     96 =  16  //avatar left spacing
         + 48  //avatar width
         + 16  //subtitle left spacing
         + 16  //subtitle right spacing
     */
    // TODO: 当前各个 cell title 的宽度并不一样，这次需要的是 messagecell 的宽度
    // 在大搜场景有好几种 cell，title 长度不同，暂时都上传 message 的长度，之后如果有改动再讨论接口 @涂晓龙 @崔文 @秦鹏
    private static let defaultPadding: CGFloat = 96

    public init() { }

    // nolint: magic_number 尺寸大小计算工具类
    // 行宽度，指行内能展示的英文字符的个数
    public func titleCountForChat(searchViewWidth totalWidth: CGFloat) -> Int {
        return  getLayoutCharCount(ofSize: 12, totalWidth: totalWidth - Self.defaultPadding)
    }

    public func subtitleCountForChat(searchViewWidth totalWidth: CGFloat) -> Int {
        return getLayoutCharCount(ofSize: 16, totalWidth: totalWidth - Self.defaultPadding)
    }

    public func titleCountForDocInChat(searchViewWidth totalWidth: CGFloat) -> Int {
        return  getLayoutCharCount(ofSize: 16, totalWidth: totalWidth - Self.defaultPadding)
    }

    public func subtitleCountForDocInChat(searchViewWidth totalWidth: CGFloat) -> Int {
        return getLayoutCharCount(ofSize: 12, totalWidth: totalWidth - Self.defaultPadding)
    }

    public func titleCountForMessage(searchViewWidth totalWidth: CGFloat) -> Int {
        return  getLayoutCharCount(ofSize: 16, totalWidth: totalWidth - Self.defaultPadding)
    }

    public func subtitleCountForMessage(searchViewWidth totalWidth: CGFloat) -> Int {
        return getLayoutCharCount(ofSize: 14, totalWidth: totalWidth - Self.defaultPadding)
    }

    public func titleCountForEmailOpenSearch(searchViewWidth totalWidth: CGFloat) -> Int {
        return  getLayoutCharCount(ofSize: 17, totalWidth: totalWidth - 32 * 2)
    }

    public func subtitleCountForEmailOpenSearch(searchViewWidth totalWidth: CGFloat) -> Int {
        return getLayoutCharCount(ofSize: 14, totalWidth: totalWidth - 32 * 2 )
    }

    private func getLayoutCharCount(ofSize size: CGFloat, totalWidth: CGFloat) -> Int {
        let singleWidth = (Self.benchmarkString as NSString).boundingRect(with: CGSize(width: 1000, height: 1000),
                                                                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                          attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: size)],
                                                                          context: nil).width
        let count = Int(floor(Double(totalWidth / singleWidth * 0.9 * 2)))
        return count
    }
    // enable-lint: magic_number
}
