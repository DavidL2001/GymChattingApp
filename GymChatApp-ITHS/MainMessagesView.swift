//
//  MainMessagesView.swift
//  GymChatApp-ITHS
//
//  Created by David Lindström iths on 2/13/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestore

struct RecentMessages: Codable, Identifiable {
    
    var id: String { documentId }
    
    

    let documentId: String
    let text, email: String
    let fromId, toId: String
    let profileImageUrl: String
    let timestamp: Date
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

        
    }
    
    
}

struct GymSelectionView: View {
    @Binding var isPresented: Bool
    let updateGymSelection: (Int) -> Void

    var body: some View {
        NavigationView {
            List {
                Button("Friskis & Svettis") { updateGymSelection(1) }
                Button("Nordic Wellness") { updateGymSelection(2) }
                Button("SATS") { updateGymSelection(3) }
                Button("Fitness24Seven") { updateGymSelection(4) }
            }
            .navigationTitle("Change Gym")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}



class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth
                .currentUser?.uid == nil
        }
        
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    
    @Published var recentMessages = [RecentMessages]()
        private var isInitialFetchDone = false 
    
    private func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            recentMessages = []
            return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in if let error = error {
                self.errorMessage = "Failed to listen for recent messages: \(error)"
                print (error)
                return
            }
                
                
                querySnapshot?.documentChanges.forEach({ change in
                        let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.documentId == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
                    
                
                   
                })
        }
    }
    
    func fetchCurrentUser() {
        guard let uid =
                FirebaseManager.shared.auth
            .currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return }
        
       
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch current user: \(error)"
                    print("Failed to fetch current user:", error)
                    return
                }
                
       
                guard let data = snapshot?.data() else {
                    self.errorMessage = "No data found"
                    return}
                
                self.chatUser = .init(data: data)
                self.fetchRecentMessagesForCurrentUser(uid: uid)
            }
    }
    private func fetchRecentMessagesForCurrentUser(uid: String) {
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print(error)
                    return
                }

                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    let newMessage = RecentMessages(documentId: docId, data: change.document.data())
                    
                   
                    if let index = self.recentMessages.firstIndex(where: { $0.documentId == docId }) {
            
                        self.recentMessages[index] = newMessage
                    } else {
                    
                        self.recentMessages.insert(newMessage, at: 0)
                    }
                })
            }
    }


    
    @Published var isUserCurrentlyLoggedOut = false
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        recentMessages.removeAll()
        try? FirebaseManager.shared.auth.signOut()
    }
    
}

struct MainMessagesView: View {
    
    @State var shouldShowLogOutOptions = false
    
    @State var shouldNavigateToChatLogView = false
    
    @State private var shouldShowGymSelection = false

    
    @ObservedObject private var vm = MainMessagesViewModel()
    
    
    var body: some View {
        NavigationView {
            
            VStack{
                //Text("USER: \(vm.chatUser?.uid ?? "")")
                
               customNavBar
               messagesView
                
                NavigationLink("", isActive:
                $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(
               newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
            .sheet(isPresented: $shouldShowGymSelection) {
                                        GymSelectionView(isPresented: $shouldShowGymSelection, updateGymSelection: { selectedGym in
                                            vm.updateGymForCurrentUser(selectedGym: selectedGym)
                                            shouldShowGymSelection = false
                                        })
                                    }
        }
    }
    
    private var customNavBar: some View {
        HStack(spacing: 16){
            
            WebImage(url: URL(string:
            vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 50)
                    .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4){
                let email =
                "\(vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? "")"
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                
                HStack{
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
               
            }
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
                
            }
            Button(action: {
                                      shouldShowGymSelection = true
                                  }) {
                                      Image(systemName: "dumbbell.fill")
                                          .font(.system(size: 24, weight: .bold))
                                          .foregroundColor(Color(.label))
                                  }
                              
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message:
                Text("what do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("handle sign out")
                    vm.handleSignOut()
                }),
               // .default(Text("Default button")),
                .cancel()
            ])
        }
        
        .fullScreenCover(isPresented:
            $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    
    private var messagesView: some View{
        ScrollView {
            ForEach(vm.recentMessages) { RecentMessages in
                VStack{
                 //   NavigationLink {
                  //      Text("Destination")
                    
                    Button {
                        let uid = FirebaseManager.shared.auth.currentUser?
                            .uid == RecentMessages.fromId ?
                        RecentMessages.toId : RecentMessages.fromId
                        self.chatUser = .init(data:
                                                [FirebaseConstants.email: RecentMessages.email,
                                                 FirebaseConstants.profileImageUrl: RecentMessages.profileImageUrl, FirebaseConstants.uid: uid])
                        self.shouldNavigateToChatLogView.toggle()
                    } label: {
                        HStack(spacing: 16){
                            WebImage(url: URL(string: RecentMessages.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(
                                                RoundedRectangle(cornerRadius: 64)
                                                    .stroke(Color.black, lineWidth: 1)
                                                    
                                            )
                                .shadow(radius: 5)
                            
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text(RecentMessages.username)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                Text(RecentMessages.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Text(RecentMessages.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
            
        }
    }
    
    @State var shouldShowNewMessageScreen = false
    
    private var newMessageButton: some View {
        Button{
            shouldShowNewMessageScreen.toggle()
        }label: {
            HStack{
                Spacer()
                Text("+ Contact Local Gym/Members")
                    .font(.system(size: 16,weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: {user
                 in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
            })
        }
    }
    @State var chatUser: ChatUser?
}

extension MainMessagesViewModel {
    func updateGymForCurrentUser(selectedGym: Int) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let userData = ["selectedGym": selectedGym]
        FirebaseManager.shared.firestore.collection("users").document(uid).updateData(userData) { err in
            if let err = err {
                print("Failed to update gym: \(err)")
                return
            }
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            .preferredColorScheme(.dark)
        
        MainMessagesView()
    }
        
}
