// 
// Created by duanxiaochen.7 on 2020/1/16.
// Affiliated with SpaceKit.
// 
// Description:

import Foundation

extension CGRect {
	/// Expand a rectangle by the given `length`. Return the new rectangle. For example,
	/// `CGRect(x: 0, y: 0, width: 0, height: 0).expandEvenly(by: 4)` returns
	/// `CGRect(x: -4, y: -4, width: 8, height: 8)`
	public func expandEvenly(by length: CGFloat) -> CGRect {
		return shift(top: -length, left: -length, bottom: length, right: length)
	}

	/// Shift a rectangle's four edges according to the given direction and value. Return the new rectangle. For example,
	/// `CGRect(x: 0, y: 0, width: 0, height: 0).shift(top: -3, left: -4, bottom: 5, right: -2)` returns
	/// `CGRect(x: -4, y: -3, width: 2, height: 8)`.
	/// - Parameters:
	///   - top: Directly added to `origin.y`.
	///   - left: Directly added to `origin.x`.
	///   - bottom: Directly added to `maxY`.
	///   - right: Directly added to `minY`.
	public func shift(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> CGRect {
		let newOrigin = CGPoint(x: self.origin.x + left, y: self.origin.y + top)
		let newWidth = self.size.width - left + right
		let newHeight = self.size.height - top + bottom
		let newSize = CGSize(width: newWidth, height: newHeight)
		return CGRect(origin: newOrigin, size: newSize)
	}
}
