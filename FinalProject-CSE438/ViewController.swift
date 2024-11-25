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
    @IBOutlet weak var questionAndAnswerTableView: UITableView!
    @IBOutlet weak var modelThoughtsTableView: UITableView!
    
    @IBOutlet weak var microphone: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    var transcriptMessages: [(String, Bool)] = [] // (message, isFromUser)
    private var questionAndAnswerMessages: [(String, Bool)] = [] // (message, isFromUser)
    private var modelThoughtsMessages: [(String, Bool)] = [] // (message, isFromUser)
    
    var currentChat: Chat?
    var isRecording: Bool = false
    
    var audioRecorder: AudioRecorder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true

        let titleLabel = UILabel()
        titleLabel.text = "Live Lecture Companion"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        
        let leftTitleItem = UIBarButtonItem(customView: titleLabel)
        navbar.leftBarButtonItem = leftTitleItem
        
        transcriptTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        questionAndAnswerTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        modelThoughtsTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")

        transcriptTableView.dataSource = self
        transcriptTableView.delegate = self
        questionAndAnswerTableView.dataSource = self
        questionAndAnswerTableView.delegate = self
        modelThoughtsTableView.dataSource = self
        modelThoughtsTableView.delegate = self

        transcriptTableView.separatorStyle = .none
        questionAndAnswerTableView.separatorStyle = .none
        modelThoughtsTableView.separatorStyle = .none
        transcriptTableView.allowsSelection = false
        questionAndAnswerTableView.allowsSelection = false
        modelThoughtsTableView.allowsSelection = false

        transcriptTableView.backgroundColor = .systemBackground
        questionAndAnswerTableView.backgroundColor = .systemBackground
        modelThoughtsTableView.backgroundColor = .systemBackground

        transcriptTableView.rowHeight = UITableView.automaticDimension
        transcriptTableView.estimatedRowHeight = 60
        questionAndAnswerTableView.rowHeight = UITableView.automaticDimension
        questionAndAnswerTableView.estimatedRowHeight = 60
        modelThoughtsTableView.rowHeight = UITableView.automaticDimension
        modelThoughtsTableView.estimatedRowHeight = 60

        transcriptTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        questionAndAnswerTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        modelThoughtsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)

        textField.delegate = self

        loadMessages()

        let initialTranscript = transcriptMessages.first?.0 ?? ""
        audioRecorder = AudioRecorder(condensedTranscript: initialTranscript)

        // Clear any previous audio file at startup
        audioRecorder.clearAudioFileIfExists()
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
        
        scrollToBottom(tableView: transcriptTableView)
        scrollToBottom(tableView: questionAndAnswerTableView)
        scrollToBottom(tableView: modelThoughtsTableView)
    }

    private func scrollToBottom(tableView: UITableView) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == transcriptTableView {
            return transcriptMessages.count
        } else if tableView == questionAndAnswerTableView {
            return questionAndAnswerMessages.count
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
        } else if tableView == questionAndAnswerTableView {
            let message = questionAndAnswerMessages[indexPath.row]
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
            questionAndAnswerMessages.append((text, true))
            textField.text = ""
            
            questionAndAnswerTableView.reloadData()
            scrollToBottom(tableView: questionAndAnswerTableView)
            
            APICaller.shared.getResponse(input: text) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let output):
                        ChatManager.shared.saveMessage(content: output, isFromUser: false, isTranscript: false, chat: chat)
                        self.questionAndAnswerMessages.append((output, false))
                    case .failure(let error):
                        print("Error:", error)
                        let errorMessage = "Sorry, I couldn't process that request."
                        ChatManager.shared.saveMessage(content: errorMessage, isFromUser: false, isTranscript: false, chat: chat)
                        self.questionAndAnswerMessages.append((errorMessage, false))
                    }
                    
                    self.questionAndAnswerTableView.reloadData()
                    self.scrollToBottom(tableView: self.questionAndAnswerTableView)
                }
            }
            return true
        }
        return false
    }
    
    @IBAction func historyButtonTapped(_ sender: Any) {
        if isRecording {
            audioRecorder.stopRecording()
        }
        navigationController?.popViewController(animated: true)
    }

    @IBAction func microphoneTapped(_ sender: Any) {
        isRecording = !isRecording
        let darkGreen = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)

        if isRecording {
            audioRecorder.clearAudioFileIfExists() // Clear file before starting recording
            audioRecorder.startRecordingAudio()
            microphone.tintColor = darkGreen
        } else {
            audioRecorder.stopRecording()
            microphone.tintColor = .systemBlue
        }
    }

    private func loadMessages() {
        guard let chat = currentChat else { return }
        
        let transcriptMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: true)
        let questionAndAnswerMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: false)
        let modelThoughtsMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: true) // Update logic here if needed

        self.transcriptMessages = transcriptMessages.map { ($0.content!, $0.isFromUser) }
        self.questionAndAnswerMessages = questionAndAnswerMessages.map { ($0.content!, $0.isFromUser) }
        self.modelThoughtsMessages = modelThoughtsMessages.map { ($0.content!, $0.isFromUser) }
        
        transcriptTableView.reloadData()
        questionAndAnswerTableView.reloadData()
        modelThoughtsTableView.reloadData()
    }
}


//solution for saving image of a table view found on stack overflow: https://stackoverflow.com/questions/32114807/how-to-render-a-whole-uitableview-as-an-uiimage-in-ios
extension UITableView {
    func asImage() -> UIImage? {

            guard self.numberOfSections > 0, self.numberOfRows(inSection: 0) > 0 else {
                return nil
            }

            self.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)

            var height: CGFloat = 0.0
            for section in 0..<self.numberOfSections {
                var cellHeight: CGFloat = 0.0
                for row in 0..<self.numberOfRows(inSection: section) {
                    let indexPath = IndexPath(row: row, section: section)
                    guard let cell = self.cellForRow(at: indexPath) else { continue }
                    cellHeight = cell.frame.size.height
                }
                height += cellHeight * CGFloat(self.numberOfRows(inSection: section))
            }

            UIGraphicsBeginImageContextWithOptions(CGSize(width: self.contentSize.width, height: height), false, UIScreen.main.scale)

            for section in 0..<self.numberOfSections {
                for row in 0..<self.numberOfRows(inSection: section) {
                    let indexPath = IndexPath(row: row, section: section)
                    guard let cell = self.cellForRow(at: indexPath) else { continue }
                    cell.contentView.drawHierarchy(in: cell.frame, afterScreenUpdates: true)

                    if row < self.numberOfRows(inSection: section) - 1 {
                        self.scrollToRow(at: IndexPath(row: row+1, section: section), at: .bottom, animated: false)
                    }
                }
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return image
        }
}
