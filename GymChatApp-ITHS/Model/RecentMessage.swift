//
//  RecentMessage.swift
//  GymChatApp-ITHS
//
//  Created by David Lindström iths on 2/22/23.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift



struct RecentMessage: Codable, Identifiable {
    
    @DocumentID var id: String?
    let text, email: String
    let fromId, toId: String
    let profileImageUrl: String
    let timestamp: Date
    
    
    
  /*  var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }*/
}
