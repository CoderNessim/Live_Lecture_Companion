//
//  ViewController.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 10/25/24.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var navbar: UINavigationItem!
    
    @IBOutlet weak var transcriptTableView: UITableView!
    @IBOutlet weak var modelThoughtsTableView: UITableView!
    
    var transcriptMessages: [(String, Bool)] = [
        ("Welcome to the live lecture!", false),
        ("Thank you! Excited to be here.", false),
        ("Please let me know if you have any questions during the lecture.", false),
        ("Sure thing, I will.", false)
    ] // (message, isFromUser)
    
    var modelThoughtsMessages: [(String, Bool)] = [
        ("The concept being discussed now is crucial for understanding the next topic.", false),
        ("Got it, I will pay extra attention.", true),
        ("Notice how the example relates back to the previous lecture.", false)
    ] // (message, isFromUser)
    
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
        
        // Register the ChatBubbleCell for both table views
        transcriptTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        modelThoughtsTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        
        transcriptTableView.dataSource = self
        transcriptTableView.delegate = self
        modelThoughtsTableView.dataSource = self
        modelThoughtsTableView.delegate = self
        
        transcriptTableView.separatorStyle = .none
        modelThoughtsTableView.separatorStyle = .none
        transcriptTableView.allowsSelection = false
        modelThoughtsTableView.allowsSelection = false
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == transcriptTableView {
            return transcriptMessages.count
        } else if tableView == modelThoughtsTableView {
            return modelThoughtsMessages.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatBubbleCell", for: indexPath) as? ChatBubbleCell else {
            return UITableViewCell()
        }
        
        if tableView == transcriptTableView {
            let message = transcriptMessages[indexPath.row]
            cell.configure(with: message.0, isFromUser: message.1)
        } else if tableView == modelThoughtsTableView {
            let message = modelThoughtsMessages[indexPath.row]
            cell.configure(with: message.0, isFromUser: message.1)
        }
        
        return cell
    }
}
