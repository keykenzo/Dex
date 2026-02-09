//
//  ContentView.swift
//  Dex
//
//  Created by Mario Duarte on 05/02/26.
//

import SwiftUI
import CoreData
import Foundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest<Pokemon>(sortDescriptors: []) private var all
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Pokemon.id, ascending: true)],
        animation: .default)
    private var pokedex: FetchedResults<Pokemon>
    
//    @FetchRequest<Pokemon>(
//        sortDescriptors: [SortDescriptor(\.id)],
//        animation: .default
//    )
//    
//    private var pokedex // <- erro
    
    @State private var searchText = ""
    @State private var filterByFavorite = false
    
    private var dynamicPredicate: NSPredicate {
        var predicates: [NSPredicate] = []
        
        // Search predicate
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name contains[c] %@", searchText))
        }
        
        // Filter by favorite
        
        if filterByFavorite {
            predicates.append(NSPredicate(format: "favorite == %d", true))
        }
        // Combine and return it
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    let fetcher = FetchService()
    
    var body: some View {
        if all.isEmpty {
            ContentUnavailableView {
                Label("No Pokemon", image: .nopokemon)
            } description: {
                Text("There aren't any pokemon yet.\nFetch some Pokemon to get started!")
            } actions: {
                Button("Fetch Pokemon", systemImage: "antenna.radiowaves.left.and.right") {
                    getPokemon(from: 1)
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            NavigationStack {
                List {
                    Section {
                        ForEach(pokedex) { pokemon in
                            NavigationLink(value: pokemon) {
                                AsyncImage(url: pokemon.sprite) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 100, height: 100)
                                
                                VStack (alignment: .leading) {
                                    HStack {
                                        Text(pokemon.name!.capitalized)
                                        
                                        if pokemon.favorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                    
                                    HStack {
                                        ForEach(pokemon.types!, id: \.self) { type in
                                            Text(type.capitalized)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 5)
                                                .background(Color(type.capitalized))
                                                .clipShape(.capsule)
                                        }
                                    }
                                }
                            }
                            .swipeActions{
                                Button(pokemon.favorite ? "Remove From Favorites" : "Add to Favorites", systemImage: "star") {
                                    pokemon.favorite.toggle()
                                    
                                    do {
                                        try viewContext.save()
                                    } catch {
                                        print(error)
                                    }
                                }
                                .tint(pokemon.favorite ? .gray: .yellow)
                            }
                        }
                    } footer: {
                        if all.count < 151 {
                            ContentUnavailableView {
                                Label("Missing Pokemon", image: .nopokemon)
                            } description: {
                                Text("The fetch was interrupted!\nFetch the rest of Pokemon.")
                            } actions: {
                                Button("Fetch Pokemon", systemImage: "antenna.radiowaves.left.and.right") {
                                    getPokemon(from: pokedex.count + 1)
                                } .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                // Destination on pokemon page
                .navigationTitle("Pokedex")
                .searchable(text: $searchText, prompt: "Search a Pokemon")
                .autocorrectionDisabled()
                .onChange(of: searchText){
                    pokedex.nsPredicate = dynamicPredicate
                }
                .onChange(of: filterByFavorite){
                    pokedex.nsPredicate = dynamicPredicate
                }
                
                .navigationDestination(for: Pokemon.self) { pokemon in
                    Text(pokemon.name ?? "no name")
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            filterByFavorite.toggle()
                        } label: {
                            Label("Filter by Favorites", systemImage: filterByFavorite ? "star.fill" : "star")
                        }
                        .tint(filterByFavorite ? .yellow : .blue)
                    }
                    //                ToolbarItem {
                    //                    Button("Add Item", systemImage: "plus") {
                    //                        getPokemon()
                    //                    }
                    //                }
                }
            }
        }
//        .task {
//            getPokemon()
//        }
    }
    
    private func getPokemon(from id: Int) {
        Task {
            for i in id..<152 {
                do {
                    
                    let fetchedPokemon = try await fetcher.fetchPokemon(i)
                    let pokemon = Pokemon(context: viewContext)
                    
                    pokemon.id = fetchedPokemon.id
                    pokemon.name = fetchedPokemon.name
                    pokemon.types = fetchedPokemon.types
                    pokemon.hp = fetchedPokemon.hp
                    pokemon.attack = fetchedPokemon.attack
                    pokemon.specialAttack = fetchedPokemon.specialAttack
                    pokemon.specialDefense = fetchedPokemon.specialDefense
                    pokemon.speed = fetchedPokemon.speed
                    pokemon.sprite = fetchedPokemon.sprite
                    pokemon.shiny = fetchedPokemon.shiny
                    
//                    if pokemon.id % 2 == 0 {
//                        pokemon.favorite = true
//                    } //teste da funcao pokemon.favorite
                    
                    try viewContext.save()
                    
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
