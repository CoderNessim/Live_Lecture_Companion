//
//  HistoryViewController.swift
//  FinalProject-CSE438
//
//  Created by Nessim Yohros on 11/1/24.
//

import UIKit

enum TimePeriod: Int, CaseIterable {
    case today
    case yesterday
    case thisWeek
    case older
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .older: return "Older"
        }
    }
}

struct GroupedChats {
    let period: TimePeriod
    var chats: [Chat]
}

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    private var allChats: [Chat] = []
    private var filteredChats: [Chat] = []
    private var isSearching: Bool = false
    private var groupedChats: [GroupedChats] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchField()
        loadChats()
        self.title = "Chats"
        
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditingMode))
    }
    
    //    @objc private func toggleEditingMode() {
    //        tableView.setEditing(!tableView.isEditing, animated: true)
    //        navigationItem.rightBarButtonItem?.title = tableView.isEditing ? "Done" : "Edit"
    //    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        tableView.selectionFollowsFocus = false
        tableView.contentInset = .zero
        tableView.sectionFooterHeight = 0
    }
    
    private func setupSearchField() {
        searchField.delegate = self
        searchField.placeholder = "Search"
        searchField.layer.cornerRadius = 10
        searchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: searchField.frame.height))
        searchField.leftViewMode = .always
        searchField.addTarget(self, action: #selector(searchFieldDidChange), for: .editingChanged)
    }
    
    private func loadChats() {
        allChats = ChatManager.shared.fetchAllChats()
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)!
        
        var todayChats: [Chat] = []
        var yesterdayChats: [Chat] = []
        var thisWeekChats: [Chat] = []
        var olderChats: [Chat] = []
        
        for chat in allChats {
            guard let createdAt = chat.createdAt else { continue }
            
            if calendar.isDate(createdAt, inSameDayAs: now) {
                todayChats.append(chat)
            } else if calendar.isDate(createdAt, inSameDayAs: startOfYesterday) {
                yesterdayChats.append(chat)
            } else if createdAt >= startOfWeek {
                thisWeekChats.append(chat)
            } else {
                olderChats.append(chat)
            }
        }
        
        groupedChats = []
        if !todayChats.isEmpty {
            groupedChats.append(GroupedChats(period: .today, chats: todayChats))
        }
        if !yesterdayChats.isEmpty {
            groupedChats.append(GroupedChats(period: .yesterday, chats: yesterdayChats))
        }
        if !thisWeekChats.isEmpty {
            groupedChats.append(GroupedChats(period: .thisWeek, chats: thisWeekChats))
        }
        if !olderChats.isEmpty {
            groupedChats.append(GroupedChats(period: .older, chats: olderChats))
        }
        
        filteredChats = allChats
        tableView.reloadData()
    }
    
    @IBAction func createChatButtonPressed(_ sender: Any) {
        if let chat = ChatManager.shared.createChat(title: "Chat \(allChats.count + 1)") {
            allChats.insert(chat, at: 0)
            
            if let firstGroup = groupedChats.first, firstGroup.period == .today {
                groupedChats[0].chats.insert(chat, at: 0)
            } else {
                groupedChats.insert(GroupedChats(period: .today, chats: [chat]), at: 0)
            }
            
            if !isSearching {
                filteredChats = allChats
            }
            
            tableView.reloadData()
            
            if let chatVC = storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
                chatVC.currentChat = chat
                navigationController?.pushViewController(chatVC, animated: true)
            }
        }
    }
    
    @objc private func searchFieldDidChange() {
        guard let searchText = searchField.text?.lowercased(), !searchText.isEmpty else {
            isSearching = false
            filteredChats = allChats
            tableView.reloadData()
            return
        }
        
        isSearching = true
        filteredChats = allChats.filter { $0.title?.lowercased().contains(searchText) ?? false }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let chatToDelete: Chat
            if isSearching {
                chatToDelete = filteredChats[indexPath.row]
                filteredChats.remove(at: indexPath.row)
            } else {
                chatToDelete = groupedChats[indexPath.section].chats[indexPath.row]
                groupedChats[indexPath.section].chats.remove(at: indexPath.row)
                if groupedChats[indexPath.section].chats.isEmpty {
                    groupedChats.remove(at: indexPath.section)
                }
            }
            
            ChatManager.shared.deleteChat(chatToDelete)
            
            if let indexInAllChats = allChats.firstIndex(where: { $0.title == chatToDelete.title }) {
                allChats.remove(at: indexInAllChats)
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : groupedChats.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredChats.count
        }
        return groupedChats[section].chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let chat = isSearching ? filteredChats[indexPath.row] : groupedChats[indexPath.section].chats[indexPath.row]
        let chatTitle = chat.title
        
        var content = cell.defaultContentConfiguration()
        content.text = chatTitle
        content.textProperties.font = .systemFont(ofSize: 16)
        content.textProperties.color = .label
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        let pencilIcon = UIImage(systemName: "pencil")
        let accessoryImageView = UIImageView(image: pencilIcon)
        accessoryImageView.isUserInteractionEnabled = true
        accessoryImageView.tag = indexPath.row
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapPencilIcon(_:)))
        accessoryImageView.addGestureRecognizer(tapGesture)
        cell.accessoryView = accessoryImageView
        
        return cell
    }
    
    @objc private func didTapPencilIcon(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let chat = filteredChats[index]
        
        let alert = UIAlertController(title: "Edit Chat Name", message: "Enter a new name for your chat", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = chat.title
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                ChatManager.shared.setTitle(chat, title: newName)
                self?.loadChats()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView")
        var content = UIListContentConfiguration.groupedHeader()
        
        let headerTitle = isSearching ? "Search Results" : groupedChats[section].period.title
        content.text = headerTitle
        content.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        content.textProperties.color = .label
        content.textProperties.allowsDefaultTighteningForTruncation = false
        content.textProperties.transform = .none
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 12, trailing: 16)
        
        headerView?.contentConfiguration = content
        headerView?.backgroundConfiguration = .clear()
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let mainVC = storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            mainVC.currentChat = filteredChats[indexPath.row]
            navigationController?.pushViewController(mainVC, animated: true)
        }
    }
}

// MARK: - UITextFieldDelegate
extension HistoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
