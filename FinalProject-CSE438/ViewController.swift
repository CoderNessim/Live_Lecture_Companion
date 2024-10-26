//
//  ViewController.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 10/25/24.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var navbar: UINavigationItem!
    
    override func viewDidLoad() {
            super.viewDidLoad()
                        
            // Create a UILabel for the left title
            let titleLabel = UILabel()
            titleLabel.text = "Live Lecture Companion"
            titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = .white // Adjust text color to stand out on the gray background
            titleLabel.sizeToFit()
            
            // Set the label as the left bar button item
            let leftTitleItem = UIBarButtonItem(customView: titleLabel)
            navbar.leftBarButtonItem = leftTitleItem
        }
}


