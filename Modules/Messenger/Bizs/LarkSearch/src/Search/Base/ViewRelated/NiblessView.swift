//
//  NiblessView.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/12.
//

import Foundation
import UIKit

class NiblessView: UIView {
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable, message: "Loading this view from a nib is unsupported")
  public required init?(coder aDecoder: NSCoder) {
    fatalError("Loading this view from a nib is unsupported")
  }
}
