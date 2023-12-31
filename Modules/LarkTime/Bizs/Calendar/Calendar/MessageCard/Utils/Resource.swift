//
//  Resource.swift
//  Calendar
//
//  Created by pluto on 2023/5/25.
//

import Foundation

final class ReactionResource {
    private static func getVerticalLineImage() -> UIImage {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16)
        let view = UIView()
        view.frame = CGRect(x: 0, y: 2, width: 1, height: 12)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(view)
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        containerView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
