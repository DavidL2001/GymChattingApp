//
//  CreateNewMessageView.swift
//  GymChatApp-ITHS
//
//  Created by David Lindström iths on 2/17/23.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUsersWithSameGym()
    }
    
    private func fetchAllUsersWithSameGym() {
        guard let currentUser = FirebaseManager.shared.auth.currentUser else {
            self.errorMessage = "No logged-in user."
            return
        }
        
     
        let currentUserRef = FirebaseManager.shared.firestore.collection("users").document(currentUser.uid)
        
        currentUserRef.getDocument { (documentSnapshot, error) in
            if let error = error {
                self.errorMessage = "Failed to fetch current user: \(error)"
                print("Failed to fetch current user: \(error)")
                return
            }
            
            guard let data = documentSnapshot?.data(),
                  let selectedGym = data["selectedGym"] as? Int else {
                self.errorMessage = "Selected gym not found."
                return
            }
            
         
            FirebaseManager.shared.firestore.collection("users")
                .whereField("selectedGym", isEqualTo: selectedGym)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        self.errorMessage = "Failed to fetch users: \(error)"
                        print("Failed to fetch users: \(error)")
                        return
                    }
                    
                    querySnapshot?.documents.forEach { snapshot in
                        let data = snapshot.data()
                        let user = ChatUser(data: data)
                        
                        
                        if user.uid != currentUser.uid {
                            self.users.append(.init(data: data))
                        }
                    }
                }
        }
    }
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    
  @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView {
                Text(vm.errorMessage)
                
                ForEach(vm.users) { user in
                    Button{
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack(spacing: 16){
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label),
                                        lineWidth: 2)
                                )
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                        }.padding(.horizontal)
                       
                    }
                    Divider()
                        .padding(.vertical, 8)
                    
                }
            }.navigationTitle("New Message")
                .toolbar {
                    ToolbarItemGroup(placement:
                            .navigationBarLeading) {
                                Button {
                                    presentationMode.wrappedValue
                                        .dismiss()
                                } label: {
                                    Text("Cancel")
                                }
                            }
                }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
    //   CreateNewMessageView()
        MainMessagesView()
    }
}
