//
//  ContentView.swift
//  Dex
//
//  Created by Mario Duarte on 05/02/26.
//

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pokemon.id, animation: .default) private var pokedex: [Pokemon]
    @State private var searchText = ""
    @State private var filterByFavorite = false
    @State private var currentSelection = Pokemon.ALLPokemonType.All
    @State private var imageByShiny = false

        
    private var dynamicPredicate: Predicate<Pokemon> {
        // 1. Preparamos os valores FORA do Predicate
        let search = searchText.lowercased()
        let favoriteOnly = filterByFavorite
        let typeFilter = currentSelection.rawValue.lowercased()
        
        // 2. O Predicate agora contém apenas UMA expressão de retorno
        return #Predicate<Pokemon> { pokemon in
            (search.isEmpty || pokemon.name.localizedStandardContains(search)) &&
            (!favoriteOnly || pokemon.favorite) &&
            (typeFilter == "all" || pokemon.types.contains(typeFilter))
        }
    }
    
    let fetcher = FetchService()
    
    var body: some View {
        if pokedex.isEmpty {
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
                        ForEach((try? pokedex.filter(dynamicPredicate)) ?? pokedex) { pokemon in
                            NavigationLink(value: pokemon) {
                                if pokemon.sprite == nil && imageByShiny == false {
                                    AsyncImage(url: pokemon.spriteURL) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 100, height: 100)
                                } else if imageByShiny == true {
                                    AsyncImage(url: pokemon.shinyURL) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 100, height: 100)
                                }
                                else {
                                    pokemon.spriteImage
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                }
                                
                                VStack (alignment: .leading) {
                                    HStack {
                                        Text(pokemon.name.capitalized)
                                        
                                        if pokemon.favorite {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                        }
                                    }
                                    
                                    HStack {
                                        ForEach(pokemon.types, id: \.self) { type in
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
                                        try modelContext.save()
                                    } catch {
                                        print(error)
                                    }
                                }
                                .tint(pokemon.favorite ? .gray: .yellow)
                            }
                        }
                    } footer: {
                        if pokedex.count < 151 {
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
                .animation(.default, value:searchText)
                
                .navigationDestination(for: Pokemon.self) { pokemon in
                    PokemonDetail(pokemon: pokemon)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                filterByFavorite.toggle()
                            }
                        } label: {
                            Label("Filter by Favorites", systemImage: filterByFavorite ? "star.fill" : "star")
                        }
                        .tint(filterByFavorite ? .yellow : .blue)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                imageByShiny.toggle()
                            }
                        } label: {
                            Label("Filter list by Shiny", systemImage: imageByShiny ? "wand.and.stars" : "wand.and.stars.inverse")
                        }
                        .tint(imageByShiny ? .yellow : .blue)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Filter by Type", selection: $currentSelection.animation()) {
                                ForEach(Pokemon.ALLPokemonType.allCases) { type in
                                    Label(type.rawValue.capitalized, systemImage: type.icon)
                                        .tag(type)
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        .tint(.blue)
                    }
                    
                }

            }
        }

    }
    
    private func getPokemon(from id: Int) {
        Task {
            for i in id..<152 {
                do {
                    
                    let fetchedPokemon = try await fetcher.fetchPokemon(i)
                    
                    modelContext.insert(fetchedPokemon)
                    
                } catch {
                    print(error)
                }
            }
            storeSprites()
        }
    }
    
    private func storeSprites() {
        Task {
            do {
                for pokemon in pokedex {
                    pokemon.sprite = try await URLSession.shared.data(from: pokemon.spriteURL).0
                    pokemon.shiny = try await URLSession.shared.data(from: pokemon.shinyURL).0
                    try modelContext.save()
                    print("sprites stores: \(pokemon.id): \(pokemon.name.capitalized)")
                }
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView().modelContainer(PersistenceController.preview)
}


//                            .onChange(of: currentSelection) {
//                                print("--- TESTE DE FILTRO ---")
//                                print("Tipo selecionado no Botão: \(currentSelection.rawValue)")
//
//                                // Vamos checar o primeiro pokemon da lista como exemplo
//                                if let primeiroPokemon = pokedex.first {
//                                    let bateu = primeiroPokemon.types.contains(currentSelection.rawValue.lowercased())
//                                    print("Testando com: \(primeiroPokemon.name)")
//                                    print("Tipos dele: \(primeiroPokemon.types)")
//                                    print("O filtro funcionou? \(bateu ? "✅ SIM" : "❌ NÃO")")
//                                }
//                            }


//                ToolbarItem {
//                    Button("Add Item", systemImage: "plus") {
//                        getPokemon()
//                    }
//                }

//        .task {
//            getPokemon()
//        }
