//
//  VideoHelper.swift
//  OmniPresence_AR
//
//  Created by Ravi kishore on 6/28/20.
//  Copyright © 2020 Indegene. All rights reserved.
//

import UIKit

extension UITextField {
  func setBottomBorder() {
    self.borderStyle = .none
    self.layer.backgroundColor = UIColor.white.cgColor

    self.layer.masksToBounds = false
    self.layer.shadowColor = UIColor.gray.cgColor
    self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
    self.layer.shadowOpacity = 1.0
    self.layer.shadowRadius = 0.0
  }
}
