//
//  EmotionEmotionViewConfig.swift
//  LarkEmotionKeyboard
//
//  Created by 王元洵 on 2021/2/22.
//

/// EmotionKeyboardViewConfig
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

public struct EmotionKeyboardViewConfig {
    let backgroundColor: UIColor
    let cellDidSelectedColor: UIColor
    let emotionLayout: UICollectionViewFlowLayout
    let sourceLayout: UICollectionViewFlowLayout
    let actionBtnHidden: Bool

    public static let getDefaultEmotionLayout: () -> UICollectionViewFlowLayout = {
        let emotionLayout = UICollectionViewFlowLayout()
        emotionLayout.minimumLineSpacing = 0
        emotionLayout.minimumInteritemSpacing = 0
        emotionLayout.scrollDirection = .horizontal
        return emotionLayout
    }

    public static let getDefaultSourceLayout: () -> UICollectionViewFlowLayout = {
        let sourceLayout = UICollectionViewFlowLayout()
        sourceLayout.scrollDirection = .horizontal
        sourceLayout.itemSize = CGSize(width: 32, height: 32)
        sourceLayout.minimumLineSpacing = Const.minimumLineSpacing
        sourceLayout.minimumInteritemSpacing = 0
        return sourceLayout
    }

    /// init
    public init(backgroundColor: UIColor = UIColor.ud.bgBody,
                cellDidSelectedColor: UIColor = UIColor.ud.fillHover,
                emotionLayout: UICollectionViewFlowLayout? = nil,
                sourceLayout: UICollectionViewFlowLayout? = nil,
                actionBtnHidden: Bool = false) {
        self.backgroundColor = backgroundColor
        self.cellDidSelectedColor = cellDidSelectedColor
        self.actionBtnHidden = actionBtnHidden
        self.emotionLayout = emotionLayout ?? Self.getDefaultEmotionLayout()
        self.sourceLayout = sourceLayout ?? Self.getDefaultSourceLayout()
    }
}

extension EmotionKeyboardViewConfig {
    enum Const {
        public static let minimumLineSpacing: CGFloat = 16
    }
}
