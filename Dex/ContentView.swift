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
    
    // Estados para o loading
    @State private var isDownloading = false
    @State private var currentProgress: Int = 0
    let totalPokemons = 151
    
    private var dynamicPredicate: Predicate<Pokemon> {
        let search = searchText.lowercased()
        let favoriteOnly = filterByFavorite
        let typeFilter = currentSelection.rawValue.lowercased()
        
        return #Predicate<Pokemon> { pokemon in
            (search.isEmpty || pokemon.name.localizedStandardContains(search)) &&
            (!favoriteOnly || pokemon.favorite) &&
            (typeFilter == "all" || pokemon.types.contains(typeFilter))
        }
    }
    
    let fetcher = FetchService()
    
    var body: some View {
        ZStack { // Adicionado ZStack para sobrepor o loading
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
                                    // ... Seu código de imagem existente ...
                                    if pokemon.sprite == nil && imageByShiny == false {
                                        AsyncImage(url: pokemon.spriteURL) { image in
                                            image.resizable().scaledToFit()
                                        } placeholder: { ProgressView() }
                                            .frame(width: 100, height: 100)
                                    } else if imageByShiny == true {
                                        AsyncImage(url: pokemon.shinyURL) { image in
                                            image.resizable().scaledToFit()
                                        } placeholder: { ProgressView() }
                                            .frame(width: 100, height: 100)
                                    } else {
                                        pokemon.spriteImage.resizable().scaledToFit().frame(width: 100, height: 100)
                                    }
                                    
                                    VStack (alignment: .leading) {
                                        HStack {
                                            Text(pokemon.name.capitalized)
                                            if pokemon.favorite {
                                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                            }
                                        }
                                        HStack {
                                            ForEach(pokemon.types, id: \.self) { type in
                                                Text(type.capitalized)
                                                    .font(.subheadline).fontWeight(.semibold)
                                                    .foregroundStyle(.black).padding(.horizontal, 12).padding(.vertical, 5)
                                                    .background(Color(type.capitalized)).clipShape(.capsule)
                                            }
                                        }
                                    }
                                }
                                .swipeActions {
                                    Button(pokemon.favorite ? "Remove From Favorites" : "Add to Favorites", systemImage: "star") {
                                        pokemon.favorite.toggle()
                                        try? modelContext.save()
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
                    .navigationTitle("Pokedex")
                    .searchable(text: $searchText, prompt: "Search a Pokemon")
                    .navigationDestination(for: Pokemon.self) { pokemon in
                        PokemonDetail(pokemon: pokemon)
                    }
                    .toolbar {
                        // ... Seus ToolbarItems existentes ...
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { withAnimation { filterByFavorite.toggle() } } label: {
                                Label("Filter by Favorites", systemImage: filterByFavorite ? "star.fill" : "star")
                            }.tint(filterByFavorite ? .yellow : .blue)
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button { withAnimation { imageByShiny.toggle() } } label: {
                                Label("Filter list by Shiny", systemImage: imageByShiny ? "wand.and.stars" : "wand.and.stars.inverse")
                            }.tint(imageByShiny ? .yellow : .blue)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Picker("Filter by Type", selection: $currentSelection.animation()) {
                                    ForEach(Pokemon.ALLPokemonType.allCases) { type in
                                        Label(type.rawValue.capitalized, systemImage: type.icon).tag(type)
                                    }
                                }
                            } label: { Image(systemName: "line.3.horizontal.decrease.circle") }.tint(.blue)
                        }
                    }
                }
            }
            
            // UI do Loading que aparece sobre a lista
            if isDownloading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Sincronizando Pokédex")
                            .font(.headline)
                        
                        Text("Baixando dados e imagens: \(currentProgress) de \(totalPokemons)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        ProgressView(value: Double(currentProgress), total: Double(totalPokemons))
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                    }
                    .padding(25)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 10))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3).ignoresSafeArea())
                .transition(.opacity)
            }
        }
        .animation(.default, value: isDownloading)
    }
    
    private func getPokemon(from id: Int) {
        isDownloading = true // Implementado: inicia o loading
        Task {
            for i in id..<152 {
                do {
                    let fetchedPokemon = try await fetcher.fetchPokemon(i)
                    modelContext.insert(fetchedPokemon)
                    
                    // Implementado: Atualiza o progresso visual
                    await MainActor.run { currentProgress = i }
                    
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
                    
                    // Implementado: Atualiza o progresso durante o download dos sprites
                    await MainActor.run { currentProgress = pokemon.id }
                    
                    print("sprites stores: \(pokemon.id): \(pokemon.name.capitalized)")
                }
                
                // Implementado: Finaliza o loading ao terminar o loop
                await MainActor.run { isDownloading = false }
                
            } catch {
                print(error)
                // Implementado: Garante que o loading suma em caso de erro crítico
                await MainActor.run { isDownloading = false }
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
