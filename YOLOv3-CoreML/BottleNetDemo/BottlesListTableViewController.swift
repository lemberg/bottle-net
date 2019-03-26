//
//  BottlesListTableViewController.swift
//  YOLOv3-CoreML
//
//  Created by Oleh Kurnenkov on 3/25/19.
//  Copyright © 2019 Lemberg Solutions. All rights reserved.
//

import Foundation
import UIKit

class BottlesListTableViewController: UITableViewController {
  @IBOutlet weak var colaLabel: UILabel!
  @IBOutlet weak var grimbergenLabel: UILabel!
  @IBOutlet weak var pepsiLabel: UILabel!
  @IBOutlet weak var Staropramenlabel: UILabel!
  
}

extension BottlesListTableViewController: BottleCaptureDelegate {
  func available(bottles: [String]) {
    for bottle in bottles {
      self.set(bottle: bottle, enabled: true)
    }
    
    for missingBottle in classifierLabes.difference(from: bottles) {
      self.set(bottle: missingBottle, enabled: false)
    }
    
  }
  
  func set(bottle: String, enabled: Bool) {
    switch bottle {
    case "Coca-Cola":
      self.colaLabel.isEnabled = enabled
    case "Grimbergen":
      self.grimbergenLabel.isEnabled = enabled
    case "Pepsi":
      self.pepsiLabel.isEnabled = enabled
    case "Staropramen":
      self.Staropramenlabel.isEnabled = enabled
    default:
      return
    }
  }
}

