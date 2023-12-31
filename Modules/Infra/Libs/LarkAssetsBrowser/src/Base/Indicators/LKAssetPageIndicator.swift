//
//  LKAssetPageIndicator.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit

public protocol LKAssetPageIndicator: UIView {

    func setup(with assetBrowser: LKAssetBrowser)

    func reloadData(numberOfItems: Int, pageIndex: Int)

    func didChanged(pageIndex: Int)
}
