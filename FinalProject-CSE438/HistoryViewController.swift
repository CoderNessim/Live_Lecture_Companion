//
//  HistoryViewController.swift
//  FinalProject-CSE438
//
//  Created by Jiayu Huang on 10/31/24.
//

import UIKit

// MARK: - Data Models
struct ChatGroup {
    let courseName: String
    var chatTitles: [String]
}

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    private var allChatGroups: [ChatGroup] = []
    private var filteredChatGroups: [ChatGroup] = []
    private var isSearching: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupSearchField()
        populateMockData()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "HeaderView")
        
        // Enable default separators
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        
        tableView.selectionFollowsFocus = false
        
        tableView.contentInset = .zero
        tableView.sectionFooterHeight = 0
    }
    
    private func setupSearchField() {
        searchField.delegate = self
        searchField.placeholder = "Search"
        searchField.layer.cornerRadius = 16
        searchField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: searchField.frame.height))
        searchField.leftViewMode = .always
        searchField.addTarget(self, action: #selector(searchFieldDidChange), for: .editingChanged)
    }
    
    private func populateMockData() {
        let cse517Chats = [
            "Machine Learning Algorithms",
            "Neural Networks",
            "Deep Learning Models",
        ]
        
        let cse438Chats = [
            "iOS Development Basics",
            "UIKit Tutorial",
            "App Navigation Flow",
            "Database Integration",
            "UI Design Questions"
        ]

        let cse542Chats = [
            "Rust traits and generics"
        ]
        
        allChatGroups = [
            ChatGroup(courseName: "CSE517", chatTitles: cse517Chats),
            ChatGroup(courseName: "CSE438", chatTitles: cse438Chats),
            ChatGroup(courseName: "CSE542", chatTitles: cse542Chats),
        ]
        
        filteredChatGroups = allChatGroups
    }
    
    @objc private func searchFieldDidChange() {
        guard let searchText = searchField.text?.lowercased(), !searchText.isEmpty else {
            isSearching = false
            filteredChatGroups = allChatGroups
            tableView.reloadData()
            return
        }
        
        isSearching = true
        filteredChatGroups = allChatGroups.compactMap { group in
            let filteredTitles = group.chatTitles.filter { title in
                title.lowercased().contains(searchText)
            }
            return filteredTitles.isEmpty ? nil : ChatGroup(courseName: group.courseName, chatTitles: filteredTitles)
        }
        
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredChatGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredChatGroups[section].chatTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let chatTitle = filteredChatGroups[indexPath.section].chatTitles[indexPath.row]
        
        // Configure cell
        var content = cell.defaultContentConfiguration()
        content.text = chatTitle
        content.textProperties.font = .systemFont(ofSize: 16)
        content.textProperties.color = .label
        
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView")
        var content = UIListContentConfiguration.groupedHeader()
        content.text = filteredChatGroups[section].courseName
        content.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        content.textProperties.color = .label
        
        if section == 0 {
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
        } else {
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 12, trailing: 0)
        }
        
        headerView?.contentConfiguration = content
        headerView?.backgroundConfiguration = .clear()
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // TODO
        if let mainVC = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
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
