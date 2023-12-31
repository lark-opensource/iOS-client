//
//  UIViewBlurable.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/9/11.
//

import UIKit

public protocol UIViewBlurable {
    var blurRadius: CGFloat { get set }
    var fillColor: UIColor? { get set }
    var fillOpacity: CGFloat { get set }
}
