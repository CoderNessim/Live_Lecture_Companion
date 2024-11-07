//
//  ViewController.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 10/25/24.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var navbar: UINavigationItem!
    
    @IBOutlet weak var transcriptTableView: UITableView!
    @IBOutlet weak var modelThoughtsTableView: UITableView!
    
    @IBOutlet weak var textField: UITextField!
    
    var transcriptMessages: [(String, Bool)] = [] // (message, isFromUser)
    
    private var modelThoughtsMessages: [(String, Bool)] = [] // (message, isFromUser)
    
    var currentChat: Chat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true

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
        
        transcriptTableView.backgroundColor = .systemBackground
        modelThoughtsTableView.backgroundColor = .systemBackground
        
        transcriptTableView.rowHeight = UITableView.automaticDimension
        transcriptTableView.estimatedRowHeight = 60
        modelThoughtsTableView.rowHeight = UITableView.automaticDimension
        modelThoughtsTableView.estimatedRowHeight = 60
        
        transcriptTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        modelThoughtsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        textField.delegate = self

        loadMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Scroll both table views to bottom initially
        scrollToBottom(tableView: transcriptTableView)
        scrollToBottom(tableView: modelThoughtsTableView)
    }

    private func scrollToBottom(tableView: UITableView) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty, let chat = currentChat {
            ChatManager.shared.saveMessage(content: text, isFromUser: true, isTranscript: false, chat: chat)
            modelThoughtsMessages.append((text, true))
            textField.text = ""
            
            modelThoughtsTableView.reloadData()
            scrollToBottom(tableView: modelThoughtsTableView)
            
            APICaller.shared.getResponse(input: text) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let output):
                        ChatManager.shared.saveMessage(content: output, isFromUser: false, isTranscript: false, chat: chat)
                        self.modelThoughtsMessages.append((output, false))
                    case .failure(let error):
                        print("Error:", error)
                        let errorMessage = "Sorry, I couldn't process that request."
                        ChatManager.shared.saveMessage(content: errorMessage, isFromUser: false, isTranscript: false, chat: chat)
                        self.modelThoughtsMessages.append((errorMessage, false))
                    }
                    
                    self.modelThoughtsTableView.reloadData()
                    self.scrollToBottom(tableView: self.modelThoughtsTableView)
                }
            }
            return true
        }
        return false
    }
    
    @IBAction func historyButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)

    }
    
    // Load messages from Core Data for the current chat
    private func loadMessages() {
        guard let chat = currentChat else { return }
        
        let transcriptMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: true)
        let modelMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: false)
        
        self.transcriptMessages = transcriptMessages.map { ($0.content!, $0.isFromUser) }
        self.modelThoughtsMessages = modelMessages.map { ($0.content!, $0.isFromUser) }
        
        transcriptTableView.reloadData()
        modelThoughtsTableView.reloadData()
    }
    
}
