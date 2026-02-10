//
//  Persistence.swift
//  Dex
//
//  Created by Mario Duarte on 05/02/26.
//

import SwiftData
import Foundation

struct PersistenceController {
    
    @MainActor
    static var previewPokemon: Pokemon {
        let decoder = JSONDecoder()
        
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let pokemonData = try! Data(contentsOf: Bundle.main.url(forResource: "samplepokemon", withExtension: "json")!)
        
        let pokemon = try! decoder.decode(Pokemon.self, from: pokemonData)
        
        return pokemon
    }
    
    // our sample preview database
    static let preview: ModelContainer = {
        let container = try! ModelContainer(for: Pokemon.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        container.mainContext.insert(previewPokemon)
        
        return container
    }()
    
}
