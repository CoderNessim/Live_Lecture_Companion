//
//  ChatBubbleCell.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 10/30/24.
//

// Custom UITableViewCell for Chat Bubbles
import UIKit

class ChatBubbleCell: UITableViewCell {
    // Add this property
    private var isFromUser: Bool = false
    
    let bubbleBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleBackgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            bubbleBackgroundView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with message: String, isFromUser: Bool) {
        self.isFromUser = isFromUser
        messageLabel.text = message
        
        bubbleBackgroundView.backgroundColor = isFromUser ? .systemBlue : .systemGray5
        messageLabel.textColor = isFromUser ? .white : .label
        
        contentView.constraints.forEach { constraint in
            if constraint.firstItem === bubbleBackgroundView &&
               (constraint.firstAttribute == .leading || constraint.firstAttribute == .trailing) {
                constraint.isActive = false
            }
        }
        
        bubbleBackgroundView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width && constraint.relation == .lessThanOrEqual {
                constraint.constant = isFromUser ? 250 : 300
            }
        }
        
        if isFromUser {
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
            bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 80).isActive = true
        } else {
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
            bubbleBackgroundView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40).isActive = true
        }
    }
}
