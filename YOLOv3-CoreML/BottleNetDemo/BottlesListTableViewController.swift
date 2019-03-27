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

  @IBOutlet weak var totalLabel: UILabel!
  @IBOutlet var priceViews: [UIView]!
  @IBOutlet var images: [UIImageView]!
  @IBOutlet var priceLabels: [UILabel]!
  
  let disabledImages = [ #imageLiteral(resourceName: "ic_cola_inactive"), #imageLiteral(resourceName: "ic_grimbergen_inactive"), #imageLiteral(resourceName: "ic_pepsi_inactive"), #imageLiteral(resourceName: "ic_staropramen_inactive") ]
  let enabledIages = [ #imageLiteral(resourceName: "ic_cola_active"), #imageLiteral(resourceName: "ic_grimbergen_active"), #imageLiteral(resourceName: "ic_pepsi_active"), #imageLiteral(resourceName: "ic_staropramen_active") ]
  
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupPriceViews()
  }
  
  // MARK: - Private functions
  
  fileprivate func setupPriceViews() {
    for view in priceViews {
      view.layer.borderWidth = 2.0
      view.layer.borderColor = UIColor.white.cgColor
      view.layer.cornerRadius = 8.0
    }
  }
  
  fileprivate func updateCell(with index: Int, disabled: Bool) {
    if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
      cell.backgroundColor = disabled ? #colorLiteral(red: 0.8784313725, green: 0.8784313725, blue: 0.8784313725, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.9607843137, blue: 0.9882352941, alpha: 1)
      self.images[index].image = disabled ? self.disabledImages[index] : self.enabledIages[index]
      self.priceLabels[index].textColor = disabled ? #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6823529412, alpha: 1) : UIColor.darkText
    }
  }
  
}

extension BottlesListTableViewController: BottleCaptureDelegate {
  func available(bottles: [String]) {
    for bottle in bottles {
      self.set(bottle: bottle, disabled: false)
    }
    
    let missingBottles = classifierLabes.difference(from: bottles)
    for missingBottle in  missingBottles {
      self.set(bottle: missingBottle, disabled: true)
    }
    
    totalLabel.text = "€\((missingBottles.count - 1) * 3)"
    
  }
  
  func set(bottle: String, disabled: Bool) {
    switch bottle {
    case "Coca-Cola":
      self.updateCell(with: 0, disabled: disabled)
    case "Grimbergen":
      self.updateCell(with: 1, disabled: disabled)
    case "Pepsi":
      self.updateCell(with: 2, disabled: disabled)
    case "Staropramen":
      self.updateCell(with: 3, disabled: disabled)
    default:
      return
    }
  }
}

