//
//  FirebaseManager.swift
//  GymChatApp-ITHS
//
//  Created by David Lindström iths on 2/14/23.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

    class FirebaseManager : NSObject{
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
   
    
    static let shared = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
       
        
        super.init()
    }
    
}

