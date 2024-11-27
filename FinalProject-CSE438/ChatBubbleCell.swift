//
//  ChatBubbleCell.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 10/30/24.
//

// Custom UITableViewCell for Chat Bubbles
import UIKit

class ChatBubbleCell: UITableViewCell {
    private var trailingConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    
    let bubbleBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 4
        view.isUserInteractionEnabled = true // Enable interaction
        return view
    }()
    
    let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.isUserInteractionEnabled = true // Enable interaction
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupContextMenuInteraction()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupContextMenuInteraction()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(bubbleBackgroundView)
        bubbleBackgroundView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            bubbleBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleBackgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
            bubbleBackgroundView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            messageLabel.topAnchor.constraint(equalTo: bubbleBackgroundView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleBackgroundView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleBackgroundView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleBackgroundView.bottomAnchor, constant: -12)
        ])

        // Create constraints for trailing and leading, but don’t activate them here
        trailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        leadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    }
    
    private func setupContextMenuInteraction() {
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            bubbleBackgroundView.addInteraction(interaction)
        }
    }
    
    func configure(with message: String, isFromUser: Bool) {
        messageLabel.text = message

        if isFromUser {
            bubbleBackgroundView.backgroundColor = UIColor(red: 0.27, green: 0.45, blue: 0.83, alpha: 1.0)
            messageLabel.textColor = .white
            
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            bubbleBackgroundView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1.0)
            messageLabel.textColor = .darkGray
            
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension ChatBubbleCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint)
                                -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // Create a copy action
            let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.string = self.messageLabel.text
            }
            return UIMenu(title: "", children: [copyAction])
        }
    }
}
