//
//  Array+Difference.swift
//  YOLOv3-CoreML
//
//  Created by Oleh Kurnenkov on 3/25/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
  func difference(from other: [Element]) -> [Element] {
    let thisSet = Set(self)
    let otherSet = Set(other)
    return Array(thisSet.symmetricDifference(otherSet))
  }
}
