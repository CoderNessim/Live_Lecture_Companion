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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        // Setup navigation bar title
        let titleLabel = UILabel()
        titleLabel.text = "Live Lecture Companion"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        let leftTitleItem = UIBarButtonItem(customView: titleLabel)
        navbar.leftBarButtonItem = leftTitleItem

        // Register table views
        transcriptTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        questionAndAnswerTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
        modelThoughtsTableView.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")

        // Set table view delegates and data sources
        transcriptTableView.dataSource = self
        transcriptTableView.delegate = self
        questionAndAnswerTableView.dataSource = self
        questionAndAnswerTableView.delegate = self
        modelThoughtsTableView.dataSource = self
        modelThoughtsTableView.delegate = self

        // Table view configurations
        configureTableViews()

        textField.delegate = self

        // Load messages
        loadMessages()

        // Initialize AudioRecorder
        let initialTranscript = transcriptMessages.first?.0 ?? ""
        audioRecorder = AudioRecorder(condensedTranscript: initialTranscript)
//        audioRecorder.clearAudioFileIfExists()

        // Register keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
//
//        if let filePath = Bundle.main.path(forResource: "recording 1", ofType: "wav") {
//            print("File path: \(filePath)")
//            
//            // Call the function with the filePath as a string
//            processWavFile(filePath: filePath, condensedTranscript: "", completion: { response in
//                print("Processing response: \(response)")
//            })
//        } else {
//            print("File not found in the bundle!")
//        }

    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismissKeyboard()
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

    private func configureTableViews() {
        // Disable selection and separators
        [transcriptTableView, questionAndAnswerTableView, modelThoughtsTableView].forEach { tableView in
            tableView?.separatorStyle = .none
            tableView?.allowsSelection = false
            tableView?.backgroundColor = .systemBackground
            tableView?.rowHeight = UITableView.automaticDimension
            tableView?.estimatedRowHeight = 60
            tableView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        }
    }

    private func scrollToBottom(tableView: UITableView) {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    // MARK: - Keyboard Handling
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        let offset: CGFloat = 0 // Add 10 points of space between the keyboard and the text input bar

        view.frame.origin.y = -keyboardHeight + offset
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
    }

    // MARK: - UITableViewDataSource and UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == transcriptTableView { return transcriptMessages.count }
        if tableView == questionAndAnswerTableView { return questionAndAnswerMessages.count }
        if tableView == modelThoughtsTableView { return modelThoughtsMessages.count }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChatBubbleCell", for: indexPath) as? ChatBubbleCell else { return UITableViewCell() }
        
        let message = {
            if tableView == transcriptTableView { return transcriptMessages[indexPath.row] }
            if tableView == questionAndAnswerTableView { return questionAndAnswerMessages[indexPath.row] }
            return modelThoughtsMessages[indexPath.row]
        }()
        
        cell.configure(with: message.0, isFromUser: message.1)
        return cell
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if let text = textField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let chat = currentChat {
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
                        let errorMessage = "Sorry, I couldn't process that request."
                        ChatManager.shared.saveMessage(content: errorMessage, isFromUser: false, isTranscript: false, chat: chat)
                        self.questionAndAnswerMessages.append((errorMessage, false))
                        print("Error: \(error)")
                    }
                    self.questionAndAnswerTableView.reloadData()
                    self.scrollToBottom(tableView: self.questionAndAnswerTableView)
                }
            }
        }
        return true
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
//            audioRecorder.clearAudioFileIfExists() // Clear file before starting recording
            audioRecorder.startRecordingAudio()
            microphone.tintColor = darkGreen
        } else {
            audioRecorder.stopRecording()
            microphone.tintColor = .systemBlue
        }
    }
    
    ///SAVING IMAGES
    
    @IBAction func transcriptImageSaved(_ sender: Any) {
            guard let image = transcriptTableView.asImage() else {
                showSaveError("Could not generate image.")
                return
            }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaveCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        @IBAction func modelThoughtsImageSaved(_ sender: Any) {
            guard let image = modelThoughtsTableView.asImage() else {
                   showSaveError("Could not generate image.")
                   return
               }
               UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaveCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        @IBAction func questionAndAnswerImageSaved(_ sender: Any) {
            guard let image = questionAndAnswerTableView.asImage() else {
                   showSaveError("Could not generate image.")
                   return
               }
               UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaveCompletion(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        func showSaveError(_ message: String) {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        @objc func imageSaveCompletion(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            if let error = error {
                let alert = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
        

    private func loadMessages() {
        guard let chat = currentChat else { return }
        transcriptMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: true).map { ($0.content!, $0.isFromUser) }
        questionAndAnswerMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: false).map { ($0.content!, $0.isFromUser) }
        modelThoughtsMessages = ChatManager.shared.fetchMessages(for: chat, isTranscript: true).map { ($0.content!, $0.isFromUser) }

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
