//
//  HomePageCollectionViewLayout.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/11/28.
//

import Foundation
import UIKit
import UniverseDesignColor
import SKFoundation

class HomePageCollectionViewLayout: UICollectionViewFlowLayout {
    
    // 用于存储不同section的自定义装饰View属性,目前只有section == 1有诉求
    private var decorationViewAttrs: [Int:UICollectionViewLayoutAttributes] = [:]

    override init() {
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 初始化时进行一些注册操作
    func setup() {
        // 注册DecorationView
        register(ChartDecorationReusableView.self, forDecorationViewOfKind: ChartDecorationReusableView.decorationViewReuseIdentifier())
    }

    override func prepare() {
        super.prepare()
        
        // 如果collectionView当前没有分区，则直接退出
        guard let collectionView = self.collectionView,
              let numberOfSections = self.collectionView?.numberOfSections
            else {
                return
        }

        let flowLayoutDelegate: UICollectionViewDelegateFlowLayout? = collectionView.delegate as? UICollectionViewDelegateFlowLayout

        // 删除旧的装饰视图的布局数据
        self.decorationViewAttrs.removeAll()

        //分别计算每个section的装饰视图的布局属性
        for section in 0..<numberOfSections {
            // 获取该section下第一个，以及最后一个item的布局属性
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            guard numberOfItems > 0,
                let firstItem = self.layoutAttributesForItem(at:
                    IndexPath(item: 0, section: section)),
                let lastItem = self.layoutAttributesForItem(at:
                    IndexPath(item: numberOfItems - 1, section: section))
                else {
                    continue
            }

            // 获取该section的内边距
            var sectionInset = self.sectionInset
            if let collectionView = self.collectionView, let inset = flowLayoutDelegate?.collectionView?(collectionView, layout: self, insetForSectionAt: section) {
                sectionInset = inset
            }

            // 计算得到该section实际的位置
            var sectionFrame = firstItem.frame.union(lastItem.frame)
            // 计算得到该section实际的尺寸
            if self.scrollDirection == .horizontal {
                sectionFrame.origin.x -= sectionInset.left
                sectionFrame.origin.y = sectionInset.top
                sectionFrame.size.width += sectionInset.left + sectionInset.right
                if let realCollectionView = self.collectionView {
                    sectionFrame.size.height = realCollectionView.frame.height
                } else {
                    DocsLogger.btError("[HomePageCollectionViewLayout] self.scrollDirection == .horizontal get collectionView fail")
                }
            } else {
                sectionFrame.origin.x = sectionInset.left
                sectionFrame.origin.y -= sectionInset.top
                if let realCollectionView = self.collectionView {
                    sectionFrame.size.width = realCollectionView.frame.width
                } else {
                    DocsLogger.btError("[HomePageCollectionViewLayout] self.scrollDirection != .horizontal get collectionView fail")
                }
                sectionFrame.size.height += sectionInset.top + sectionInset.bottom
            }

            // 计算得到DecorationView该实际的尺寸
            let DecorationInset :UIEdgeInsets = .zero // 修改内边距修改这里
            var DecorationFrame = sectionFrame
            if self.scrollDirection == .horizontal {
                DecorationFrame.origin.x = sectionFrame.origin.x + DecorationInset.left
                DecorationFrame.origin.y = DecorationInset.top
            } else {
                DecorationFrame.origin.x = DecorationInset.left
                DecorationFrame.origin.y = sectionFrame.origin.y + DecorationInset.top
            }
            //
            DecorationFrame.size.width = sectionFrame.size.width - (DecorationInset.left + DecorationInset.right)
            DecorationFrame.size.height = sectionFrame.size.height - (DecorationInset.top + DecorationInset.bottom)

            // 根据上面的结果计算装饰图的布局属性
            let sectionAttr = HomePageChartDecorationCollectionViewLayoutAttributes(
                forDecorationViewOfKind: ChartDecorationReusableView.decorationViewReuseIdentifier(),
                with: IndexPath(item: 0, section: section))
            sectionAttr.frame = DecorationFrame
            // 置于底层
            sectionAttr.zIndex = -1
            // 通过代理方法获取该section卡片装饰图使用的颜色
            if section == 1 {
                sectionAttr.backgroundColor = UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
            } else {
                sectionAttr.backgroundColor = .clear
            }

            // 将该section的卡片装饰图的布局属性保存起来
            self.decorationViewAttrs[section] = sectionAttr
        }
    }

    // 返回rect范围下父类的所有元素的布局属性以及子类自定义装饰视图的布局属性
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
            var attrs = super.layoutAttributesForElements(in: rect)
            attrs?.append(contentsOf: self.decorationViewAttrs.values.filter {
                return rect.intersects($0.frame)
            })
            return attrs
    }

    // 返回对应于indexPath的位置的装饰视图的布局属性
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let section = indexPath.section
        if elementKind == ChartDecorationReusableView.decorationViewReuseIdentifier() {
            return self.decorationViewAttrs[section]
        }
        return super.layoutAttributesForDecorationView(ofKind: elementKind,
                                                       at: indexPath)
    }
}
