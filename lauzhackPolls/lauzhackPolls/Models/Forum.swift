//
//  Forum.swift
//  lauzhackPolls
//
//  Created by Alexandre Ballenghien on 3/12/23.
//

import FirebaseFirestoreSwift
import Foundation

struct Forum: Codable, Identifiable, Hashable {
    
    var id: String
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    
    var title: String
    var content: String
    
    init(id: String = UUID().uuidString, createdAt: Date? = nil, updatedAt: Date? = nil, title: String, content: String) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.content = content
    }
}


