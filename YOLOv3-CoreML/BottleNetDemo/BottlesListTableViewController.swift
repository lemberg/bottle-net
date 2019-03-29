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
  @IBOutlet var takenLabels: [UILabel]!
  
  let disabledImages = [ #imageLiteral(resourceName: "ic_cola_inactive"), #imageLiteral(resourceName: "ic_grimbergen_inactive"), #imageLiteral(resourceName: "ic_pepsi_inactive"), #imageLiteral(resourceName: "ic_staropramen_inactive") ]
  let enabledIages = [ #imageLiteral(resourceName: "ic_cola_active"), #imageLiteral(resourceName: "ic_grimbergen_active"), #imageLiteral(resourceName: "ic_pepsi_active"), #imageLiteral(resourceName: "ic_staropramen_active") ]
  let prices = ["Coca-Cola" : 3.5, "Grimbergen" : 3.00, "Pepsi" : 4.8, "Staropramen" : 5.4]
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // MARK: - Private functions
  
  fileprivate func updateCell(with index: Int, disabled: Bool) {
    if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
      cell.backgroundColor = disabled ? #colorLiteral(red: 0.8784313725, green: 0.8784313725, blue: 0.8784313725, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.9607843137, blue: 0.9882352941, alpha: 1)
      self.images[index].image = disabled ? self.disabledImages[index] : self.enabledIages[index]
      self.priceLabels[index].textColor = disabled ? #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6823529412, alpha: 1) : UIColor.darkText
      self.setupPriceView(at: index, disabled: disabled)
      self.takenLabels[index].isHidden = !disabled
    }
  }
  
  fileprivate func setupPriceView(at index: Int, disabled: Bool) {
    let priceView = self.priceViews[index]
    priceView.layer.borderWidth = 2.0
    priceView.layer.borderColor = disabled ? UIColor.clear.cgColor : UIColor.white.cgColor
    priceView.layer.cornerRadius = 8.0
  }
  
}

extension BottlesListTableViewController: BottleCaptureDelegate {
  func available(bottles: [String]) {
    for bottle in bottles {
      self.set(bottle: bottle, disabled: false)
    }
    
    let missingBottles = classifierLabes.difference(from: bottles)
    var total: Double = 0.0
    for missingBottle in  missingBottles {
      self.set(bottle: missingBottle, disabled: true)
      total += self.prices[missingBottle] ?? 0.0
    }
    
    totalLabel.text = "€\(total)"
    
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

