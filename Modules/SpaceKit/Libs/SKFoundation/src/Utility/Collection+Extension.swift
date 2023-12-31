// 
// Created by duanxiaochen.7 on 2020/1/25.
// Affiliated with SpaceKit.
// 
// Description:

import Foundation

/// 用法：`anArray[at: index]?`，例如 `model[at: 4]?`
extension Collection {
	public subscript (at index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}
