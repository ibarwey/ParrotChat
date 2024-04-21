//
//  ContentView.swift
//  ChatBotMain
//
//  Created by Jared Davidson on 12/19/23.
//

import SwiftUI
import OpenAI
import UIKit

class ChatController: ObservableObject {
    @Published var messages: [Message] = []
    
    let openAI = OpenAI(apiToken: OPENAI_KEY)
    
    func sendNewMessage(content: String) {
//        let userMessage = Message(content: content, isUser: true, isGrammarCheck: false)
        getGrammarCheckReply(content: content) { result in
            switch result {
            case .success(let res):
                self.messages.append(Message(content: AttributedString(res), contentString: String(res.string), isUser: true, isGrammarCheck: false))
                print(String(res.string))
            case .failure(let error):
                print("Error fetching grammar checks:", error.localizedDescription)
            }
            self.getBotReply()
        }
//        self.messages.append(userMessage)
        
    }
    
    func getGrammarCheckReply(content: String, completion: @escaping (Result<NSMutableAttributedString, Error>) -> Void) {
        getGrammarCheck(content: content) { result in
            switch result {
            case .success(let grammarChecks):
                print("Received grammar edits:", grammarChecks)
                let attributedContent = NSMutableAttributedString(string: content)
                
                grammarChecks.edits.forEach{ edit in
                    // create attributed string
                    let substring = NSMakeRange(edit.start, edit.end - edit.start)
                    attributedContent.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: substring)
                }
                completion(.success(attributedContent))
            case .failure(let error):
                print("Error fetching grammar checks:", error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func getBotReply() {
        let query = ChatQuery(
            messages: self.messages.map({
                .init(role: .user, content: $0.contentString)!
            }),
            model: .gpt3_5Turbo
        )
        print("query")
        print(query)
        
        openAI.chats(query: query) { result in
            switch result {
            case .success(let success):
                guard let choice = success.choices.first else {
                    return
                }
                guard let message = choice.message.content?.string else { return }
                DispatchQueue.main.async {
                    self.messages.append(Message(content: AttributedString(message), contentString: message, isUser: false, isGrammarCheck: false))
                }
            case .failure(let failure):
                print(failure)
            }
        }
    }
}

struct Message: Identifiable {
    var id: UUID = .init()
    var content: AttributedString
    var contentString: String
    var isUser: Bool
    var isGrammarCheck: Bool
}

struct ContentView: View {
    @StateObject var chatController: ChatController = .init()
    @State var string: String = ""
    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatController.messages) {
                    message in
                    MessageView(message: message)
                        .padding(5)
                }
            }
            Divider()
            HStack {
                TextField("Message...", text: self.$string, axis: .vertical)
                    .padding(5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                Button {
                    self.chatController.sendNewMessage(content: string)
                    string = ""
                } label: {
                    Image(systemName: "paperplane")
                }
            }
            .padding()
        }
    }
}

struct MessageView: View {
    var message: Message
    var body: some View {
        Group {
            if message.isUser {
                HStack {
                    Spacer()
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .clipShape(Capsule())
                }
            } else if message.isGrammarCheck {
                HStack {
                    Spacer()
                    Text(message.content)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .clipShape(Capsule())
                }
            } else {
                HStack {
                    Text(message.content)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(Color.white)
                        .clipShape(Capsule())
                    Spacer()
                }
            }
        }
    }
}
