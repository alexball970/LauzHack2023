//
//  PollVM.swift
//  lauzhackPolls
//
//  Created by Julien Coquet on 02/12/2023.
//


import ActivityKit
import FirebaseFirestore
import Foundation
import SwiftUI
import Observation

@Observable
class PollViewModel {
    
    let db = Firestore.firestore()
    let pollId: String
    
    var poll: Poll? = nil
    var comments = [String]()
    var newComment: String = ""
    var error: String? = nil
    
    
    //var activity: Activity<LivePollsWidgetAttributes>? = nil
    
    init(pollId: String, poll: Poll? = nil) {
        self.pollId = pollId
        self.poll = poll
    }
    
    @MainActor
    func listenToPoll() {
        db.document("polls/\(pollId)")
            .addSnapshotListener { snapshot, error in
                guard let snapshot else { return }
                do {
                    let poll = try snapshot.data(as: Poll.self)
                    withAnimation {
                        self.poll = poll
                    }
                    //self.startActivityIfNeeded()
                } catch {
                    print("Failed to fetch poll")
                }
            }
    }
    
    func incrementOption(_ option: Option) {
        guard let index = poll?.options.firstIndex(where: {$0.id == option.id}) else { return }
        db.document("polls/\(pollId)")
            .updateData([
                "totalCount": FieldValue.increment(Int64(1)),
                "option\(index).count": FieldValue.increment(Int64(1)),
                "lastUpdatedOptionId": option.id,
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                print(error?.localizedDescription ?? "")
            }
        
    }
    
    @MainActor
    func createNewComment() async {
        //isLoading = true
        //defer { isLoading = false }
        
        
        //append comment after get
        
        //(id: String = UUID().uuidString, createdAt: Date? = nil, updatedAt: Date? = nil, title: String, content: String)
        do {
            let documentRef = db.document("comments/\(pollId)")
            
            documentRef.getDocument { documentSnapshot, error in
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                if let data = documentSnapshot?.data(), var content = data["content"] as? String {
                    // Append a new comment with a newline character
                    content += "\n" + self.newComment
                    
                    // Update the Firestore document with the modified content
                    documentRef.setData(["content": content], merge: true) { error in
                        if let error = error {
                            self.error = error.localizedDescription
                        } else {
                            // Clear the new comment after it's been added
                            self.newComment = ""
                        }
                    }
                }
            }
        }
    }
}
    

        /*
        do {
            let data = db.get((pollId),db.document("comments/").getDocument())
            data += newComment + "\n"
            let forum = Forum(content: (data))
            try db.document("comments/\(pollId)").setData(from: forum)
            //try db.document("polls/\(poll.id)").setData(from: poll)
            self.newComment = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
     
    
    
}
*/

