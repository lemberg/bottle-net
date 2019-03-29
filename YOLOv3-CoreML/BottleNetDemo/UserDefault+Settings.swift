//
//  UserDefault+Settings.swift
//  YOLOv3-CoreML
//
//  Created by Oleh Kurnenkov on 3/29/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//

import Foundation

extension UserDefaults {
  var shouldShowRectangles: Bool {
    return UserDefaults.standard.bool(forKey: "enabled_rectangles")
  }
}
