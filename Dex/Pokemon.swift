//
//  Pokemon.swift
//  Dex
//
//  Created by Mario Duarte on 10/02/26.
//
//

import Foundation
import SwiftData
import SwiftUI


@Model class Pokemon: Decodable{
    
    @Attribute(.unique) var id: Int
    var name: String
    var types: [String]
    var hp: Int
    var attack: Int
    var defense: Int
    var specialAttack: Int
    var specialDefense: Int
    var speed: Int
    var spriteURL: URL
    var shinyURL: URL
    var sprite: Data?
    var shiny: Data?
    var favorite: Bool = false
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case types
        case stats
        case sprites
        
        enum TypeDictionaryKeys: CodingKey {
            case type
            
            enum TypeKeys: CodingKey {
                case name
            }
        }
        
        enum StatDictionaryKeys: CodingKey {
            case baseStat
        }
        
        enum SpriteKeys: String, CodingKey {
            case spriteURL = "frontDefault"
            case shinyURL = "frontShiny"
        }
    }
    
    enum ALLPokemonType: String, Decodable, CaseIterable, Identifiable {
        
        case All
        case Bug
        case Dragon
        case Electric
        case Fairy
        case Fighting
        case Fire
        case Flying
        case Ghost
        case Grass
        case Ground
        case Ice
        case Normal
        case Poison
        case Psychic
        case Rock
        case Steel
        case Water
        
        var id: ALLPokemonType{
            self
        }
        
        var icon: String {
            switch self {
            case .All:
                "square.stack.3d.up.fill"
            case .Bug:
                "ant.fill"
            case .Dragon:
                "lizard.fill"
            case .Electric:
                "bolt.fill"
            case .Fairy:
                "sparkles"
            case .Fighting:
                "figure.martial.arts"
            case .Fire:
                "flame.fill"
            case .Flying:
                "wind"
            case .Ghost:
                "moon.stars.fill"
            case .Grass:
                "leaf.fill"
            case .Ground:
                "mountain.2.fill"
            case .Ice:
                "snowflake"
            case .Normal:
                "circle.hexagongrid"
            case .Poison:
                "flask.fill"
            case .Psychic:
                "eye.fill"
            case .Rock:
                "fossil.shell.fill"
            case .Steel:
                "hammer.fill"
            case .Water:
                "drop.fill"
            }
        }
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        var decodedTypes: [String] = []
        var typesContainer = try container.nestedUnkeyedContainer(forKey: .types)
        while !typesContainer.isAtEnd {
            let typesDictionaryContainer = try typesContainer.nestedContainer(keyedBy: CodingKeys.TypeDictionaryKeys.self)
            let typeContainer = try typesDictionaryContainer.nestedContainer(keyedBy: CodingKeys.TypeDictionaryKeys.TypeKeys.self, forKey: .type)
            let type = try typeContainer.decode(String.self, forKey: .name)
            decodedTypes.append(type)
        }
        
        // Bird Pokemon with 2 Type [Normal, Flying]
        if decodedTypes.count == 2  && decodedTypes[0] == "normal" {
            decodedTypes.swapAt(0, 1)
        }
        
        types = decodedTypes
        
        var decodedStats: [Int] = []
        var statsContainer = try container.nestedUnkeyedContainer(forKey: .stats)
        while !statsContainer.isAtEnd {
            let statsDictionaryContainer = try statsContainer.nestedContainer(keyedBy: CodingKeys.StatDictionaryKeys.self)
            let stat = try statsDictionaryContainer.decode(Int.self, forKey: .baseStat)
            decodedStats.append(stat)
        }
        
        hp = decodedStats[0]
        attack = decodedStats[1]
        defense = decodedStats[2]
        specialAttack = decodedStats[3]
        specialDefense = decodedStats[4]
        speed = decodedStats[5]
        
        let spriteContainer = try container.nestedContainer(keyedBy: CodingKeys.SpriteKeys.self, forKey: .sprites)
        
        spriteURL = try spriteContainer.decode(URL.self, forKey: .spriteURL)
        shinyURL = try spriteContainer.decode(URL.self, forKey: .shinyURL)
    }
    
    @MainActor
    var spriteImage: Image {
        if let data = sprite, let image = UIImage(data: data) {
            Image(uiImage: image)
        } else {
            Image(.bulbasaur)
        }
    }
    
    @MainActor
    var shinyImage: Image {
        if let data = shiny, let image = UIImage(data: data) {
            Image(uiImage: image)
        } else {
            Image(.shinybulbasaur)
        }
    }
    
    @MainActor
    var background: ImageResource {
        switch types[0] {
        case "rock", "ground", "steel", "fighting", "ghost", "dark", "psychic":
                .rockgroundsteelfightingghostdarkpsychic
        case "fire", "dragon":
                .firedragon
        case "flying", "bug":
                .flyingbug
        case "ice":
                .ice
        case "water":
                .water
        default :
                .normalgrasselectricpoisonfairy
        }
    }
    var typeColor: Color {
        Color(types[0].capitalized)
    }
    var stats: [Stat] {
        [
            Stat(id: 1, name: "HP", value: hp),
            Stat(id: 2, name: "Attack", value: attack),
            Stat(id: 3, name: "Defense", value: defense),
            Stat(id: 4, name: "Special Attack", value: specialAttack),
            Stat(id: 5, name: "Special Defense", value: specialDefense),
            Stat(id: 6, name: "Speed", value: speed)
        ]
    }
    
    var highestStat: Stat {
        stats.max { stat1,stat2 in
            stat1.value < stat2.value
        }!
    }
    
    struct Stat:Identifiable {
        let id: Int
        let name: String
        let value: Int
    }
}

