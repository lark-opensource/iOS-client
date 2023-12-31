//
//  ImageWrapperExtensions.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/11/1.
//

import Foundation
import UIKit

// MARK: - Value Type

extension Data: ImageCompatibleValue {}

extension String: ImageCompatibleValue {}

// MARK: - Object Type

extension UIButton: ImageCompatible {}

extension UIImage: ImageCompatible {}

extension UIImageView: ImageCompatible {}
