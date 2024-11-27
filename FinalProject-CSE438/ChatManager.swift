//
//  ChatManager.swift
//  FinalProject-CSE438
//
//  Created by Jiayu Huang on 11/6/24.
//

import CoreData
import UIKit

struct MessageType {
    static let transcript = "transcript"
    static let modelThought = "modelThought"
    static let questionAnswer = "questionAnswer"
}

// Singleton class to manage chat operations using Core Data
class ChatManager {
    static let shared = ChatManager()
    
    public let context: NSManagedObjectContext
    
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
    
    func saveMessage(content: String, isFromUser: Bool, messageType: String, chat: Chat) {
        let message = Message(context: context)
        message.content = content
        message.isFromUser = isFromUser
        message.timestamp = Date()
        message.chat = chat
        message.messageType = messageType
        
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
    
    func fetchMessages(for chat: Chat, messageType: String) -> [Message] {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "chat == %@ AND messageType == %@", chat, messageType)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
    
    func updateMessage(_ message: Message, withContent content: String) {
        message.content = content
        do {
            try context.save()
        } catch {
            print("Error updating message: \(error)")
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
    
    func setTitle(_ chat: Chat, title: String) {
        chat.title = title
        do {
            try context.save()
        } catch {
            print("Error changing chat name: \(error)")
        }
    }
}
