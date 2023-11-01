//
//  PokemonResult.swift
//  CombineSwiftConnectExample
//
//  Created by Chanchana Koedtho on 1/11/2566 BE.
//

import Foundation

// MARK: - PokemonResult
struct PokemonResult: Codable {
    let count: Int
    let next, previous: String
    let results: [Result]
    
    // MARK: - Result
    struct Result: Codable {
        let name: String
        let url: String
    }

}

