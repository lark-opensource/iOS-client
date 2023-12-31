//
//  SecretGridViewController+Layout.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/4/20.
//  


import Foundation
import UIKit
import SKFoundation
import SKUIKit

//多列表格组件布局类
class UICollectionGridViewLayout: UICollectionViewLayout {
    //记录每个单元格的布局属性
    /*  所有item的布局  */
    private var itemAttributes: [[UICollectionViewLayoutAttributes]] = []
    /* 一行里面所有item的宽，每一行都是一样的  */
    private var itemsSize: [[NSValue]] = []
    /** collectionView的contentSize大小  */
    private var contentSize: CGSize = CGSize.zero
    
    private var maxHeight:CGFloat = 0
    
    // 表头数据
    var cols: [String] = []
    
    // 除表头之外的 列表数据
    var rowsValue: [[DataEntity]] = []
    
    
    //准备所有view的layoutAttribute信息
    override func prepare() {
        guard let collectionView = collectionView else { return }
        if collectionView.numberOfSections == 0 {
            return
        }
        DocsLogger.info("secretLayout: rowsValue: \(rowsValue.count) cols: \(cols.count)")
        var column = 0
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        var contentWidth: CGFloat = 0
        var contentHeight: CGFloat = 0
        
        if itemAttributes.count > 0 {
            return
        }
        
        itemAttributes = []
        itemsSize = []
        
        if itemsSize.count != collectionView.numberOfSections * collectionView.numberOfItems(inSection: 0) {
            calculateItemsSize()
        }

        let rowLength = rowsValue.count
        for section in 0 ... rowLength {
            var sectionAttributes: [UICollectionViewLayoutAttributes] = []
            for index in 0 ..< cols.count {
                let itemSize = itemsSize[section][index].cgSizeValue
                
                let indexPath = IndexPath(item: index, section: section)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                //除第一列，其它列位置都左移一个像素，防止左右单元格间显示两条边框线
                if index == 0{
                    attributes.frame = CGRect(x:xOffset, y:yOffset, width:itemSize.width,
                                              height:itemSize.height).integral
                }else {
                    attributes.frame = CGRect(x:xOffset-1, y:yOffset,
                                              width:itemSize.width+1,
                                              height:itemSize.height).integral
                }
                
                //将表头、首列单元格置为最顶层
                if section == 0 && index == 0 {
                    attributes.zIndex = 1024
                } else if section == 0 || index == 0 {
                    attributes.zIndex = 1023
                }
                
                //表头单元格位置固定
                if section == 0 {
                    var frame = attributes.frame
                    frame.origin.y = collectionView.contentOffset.y
                    attributes.frame = frame
                }
                //首列单元格位置固定
                if index == 0 {
                    var frame = attributes.frame
                    frame.origin.x = collectionView.contentOffset.x
                    + collectionView.contentInset.left
                    attributes.frame = frame
                }
                
                sectionAttributes.append(attributes)
                
                xOffset = xOffset+itemSize.width
                column += 1
                
                if column == cols.count {
                    if xOffset > contentWidth {
                        contentWidth = xOffset
                    }
                    
                    column = 0
                    xOffset = 0
                    yOffset += itemSize.height
                }
            }
            itemAttributes.append(sectionAttributes)
        }
        guard let attributesLast = itemAttributes.last, let attributes = attributesLast.last else { return }
        contentHeight = attributes.frame.origin.y + attributes.frame.size.height
        contentSize = CGSize(width:contentWidth, height:contentHeight)
    }
    
    //需要更新layout时调用
    override func invalidateLayout() {
        itemAttributes = []
        itemsSize = []
        contentSize = CGSize.zero
        super.invalidateLayout()
    }
    
    // 返回内容区域总大小，不是可见区域
    override var collectionViewContentSize: CGSize {
        get {
            return contentSize
        }
    }
    
    // 这个方法返回每个单元格的位置和大小
    override func layoutAttributesForItem(at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        return itemAttributes[indexPath.section][indexPath.row]
    }
    
    // 返回所有单元格位置属性
    override func layoutAttributesForElements(in rect: CGRect)
        -> [UICollectionViewLayoutAttributes]? {
            var attributes: [UICollectionViewLayoutAttributes] = []
            for section in itemAttributes {
                attributes.append(contentsOf: section.filter(
                    {(includeElement: UICollectionViewLayoutAttributes) -> Bool in
                        return rect.intersects(includeElement.frame)
                }))
            }
            return attributes
    }
    
    // 改为边界发生任何改变时（包括滚动条改变），都应该刷新布局。
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    // 计算所有单元格的尺寸（每一列各一个单元格）
    //（每一列的宽度一样，所以只需要确定一行的item的宽度）
    func calculateItemsSize() {
        guard let collectionView = collectionView else { return }
        var remainingWidth = collectionView.frame.width -
            collectionView.contentInset.left - collectionView.contentInset.right
         
        let rowLength = rowsValue.count
        for section in 0 ... rowLength {
            var sectionAttributes: [NSValue] = []
            let sectionMaxString = getMaxLengthString(section: section)
            for index in 0 ..< collectionView.numberOfItems(inSection: 0) {
                let newItemSize = sizeForItemWithColumnIndex(columnIndex: index,
                                                             section: section,
                                                             remainingWidth: remainingWidth,
                                                             sectionMaxString: sectionMaxString)
                let newItemSizeValue = NSValue(cgSize: newItemSize)
                sectionAttributes.append(newItemSizeValue)
            }
            itemsSize.append(sectionAttributes)
        }
    }
    
    //计算某一行的单元格尺寸
    func sizeForItemWithColumnIndex(columnIndex: Int, section: Int, remainingWidth: CGFloat, sectionMaxString: String) -> CGSize {
        // 利用UILabel來取得文字的高度
        func getHeight(withLabelText text: String, width: CGFloat, font: UIFont) -> CGFloat {
            let nsString = NSString(string: text)
            let height = nsString.boundingRect(with: CGSizeMake(width, .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font],context: nil).height
            return height
        }
        
        var width: CGFloat
        if SKDisplay.pad {
            if columnIndex == 0 {
                switch DocsSDK.currentLanguage {
                case .zh_CN, .zh_HK, .zh_TW:
                    width = 115
                default:
                    width = 135
                }
            } else {
                width = 115
            }
        } else {
            if columnIndex == 0 {
                switch DocsSDK.currentLanguage {
                case .zh_CN, .zh_HK, .zh_TW:
                    width = 82
                default:
                    width = 98
                }
            } else {
                width = 84
            }
        }
        // 利用label來取得文字的高度
        let size: CGFloat = getHeight(withLabelText: sectionMaxString, width: 60, font: UIFont.systemFont(ofSize: 14))
        //计算好的宽度还要取整，避免偏移
        if section == 0 {
            return CGSize(width: width, height: min(size + 36, 87))
        } else {
            return CGSize(width: width, height: size + 36)
        }
    }
    
    func getMaxLengthString(section: Int) -> String {
        var maxStr = ""
        if section == 0 {
            for row in 0 ..< cols.count {
                if cols[row].count > maxStr.count {
                    maxStr = cols[row]
                }
            }
        } else {
            for row in 0 ..< cols.count {
                if rowsValue[section - 1][row].text.count > maxStr.count {
                    maxStr = rowsValue[section - 1][row].text
                }
            }
        }
        return maxStr
    }
    
}
