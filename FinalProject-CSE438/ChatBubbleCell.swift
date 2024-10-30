//
//  ChatBubbleCell.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 10/30/24.
//

// Custom UITableViewCell for Chat Bubbles
import UIKit

class ChatBubbleCell: UITableViewCell {
    // MARK: - UI Elements
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
    
    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Views
    private func setupViews() {
        contentView.addSubview(bubbleBackgroundView)
        contentView.addSubview(messageLabel)
    }
    
    func configure(with message: String, isFromUser: Bool) {
        messageLabel.text = message
        bubbleBackgroundView.backgroundColor = isFromUser ? UIColor.systemBlue : UIColor.lightGray
        messageLabel.textColor = isFromUser ? UIColor.white : UIColor.black
        
        // Update layout based on message sender
        let bubbleConstraints = isFromUser ? setupUserBubbleConstraints() : setupBotBubbleConstraints()
        NSLayoutConstraint.activate(bubbleConstraints)
    }
    
    // MARK: - Layout Constraints
    private func setupUserBubbleConstraints() -> [NSLayoutConstraint] {
        // Pin the bubble to the right for user messages
        return [
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleBackgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8)
        ]
    }
    
    private func setupBotBubbleConstraints() -> [NSLayoutConstraint] {
        // Pin the bubble to the left for bot messages
        return [
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleBackgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -8),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -8)
        ]
    }
}
