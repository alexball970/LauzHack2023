//
//  Option.swift
//  lauzhackPolls
//
//  Created by Julien Coquet on 02/12/2023.
//

import Foundation

struct Option: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var count: Int
    var name: String
}
