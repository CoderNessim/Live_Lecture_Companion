//
//  ChatManager.swift
//  FinalProject-CSE438
//
//  Created by Jiayu Huang on 11/6/24.
//

import CoreData
import UIKit

// Singleton class to manage chat operations using Core Data
class ChatManager {
    static let shared = ChatManager()
    
    private let context: NSManagedObjectContext
    
    // Private initializer to ensure only one instance is created
    private init() {
        self.context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    func createChat(title: String) -> Chat? {
        let chat = Chat(context: context)
        chat.title = title
        chat.id = UUID()
        chat.createdAt = Date()
        
        do {
            try context.save()
            return chat
        } catch {
            print("Error creating chat: \(error)")
            return nil
        }
    }
    
    func saveMessage(content: String, isFromUser: Bool, isTranscript: Bool, chat: Chat) {
        let message = Message(context: context)
        message.content = content
        message.isFromUser = isFromUser
        message.isTranscript = isTranscript
        message.timestamp = Date()
        message.chat = chat
        
        do {
            try context.save()
        } catch {
            print("Error saving message: \(error)")
        }
    }
    
    func fetchAllChats() -> [Chat] {
        let request: NSFetchRequest<Chat> = Chat.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching chats: \(error)")
            return []
        }
    }
    
    func fetchMessages(for chat: Chat, isTranscript: Bool) -> [Message] {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "chat == %@ AND isTranscript == %@", chat, NSNumber(value: isTranscript))
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
    
    func deleteChat(_ chat: Chat) {
        context.delete(chat)
        do {
            try context.save()
        } catch {
            print("Error deleting chat: \(error)")
        }
    }
}
