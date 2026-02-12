//
//  DexWidget.swift
//  DexWidget
//
//  Created by Mario Duarte on 09/02/26.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Pokemon.self])
        let groupIdentifier = "group.com.marioduarte.DexGroup"
        
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
        
        let directoryURL = groupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        let databaseURL = directoryURL.appendingPathComponent("default.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: databaseURL)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
    }()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry.placeholder)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task { @MainActor in
            var entries: [SimpleEntry] = []
            
            // Generate a timeline consisting of five entries an hour apart, starting from the current date.
            let currentDate = Date()
            
            if let results = try? sharedModelContainer.mainContext.fetch(FetchDescriptor<Pokemon>()) {
                for hourOffset in 0 ..< 10 {
                    let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset*5, to: currentDate)!
                    
                    let entryPokemon = results.randomElement()!
                    
                    let entry = SimpleEntry(date: entryDate,
                                            name: entryPokemon.name,
                                            types: entryPokemon.types,
                                            sprite: entryPokemon.spriteImage)
                    entries.append(entry)
                }
                
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            } else {
                let timeline = Timeline(entries: [SimpleEntry.placeholder, SimpleEntry.placeholder2], policy: .atEnd)
                completion(timeline)
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let name: String
    let types: [String]
    let sprite: Image
    
    static var placeholder: SimpleEntry {
        SimpleEntry(date: .now, name: "bulbasaur", types: ["grass", "poison"], sprite: Image(.bulbasaur))
    }
    
    static var placeholder2: SimpleEntry {
        SimpleEntry(date: .now, name: "mew", types: ["psychic"], sprite: Image(.mew))
    }
}

struct DexWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetSize
    var entry: Provider.Entry
    
    var pokemonImage: some View {
        entry.sprite
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .shadow(color: .black, radius: 2)
    }
    
    var typesView: some View {
        ForEach(entry.types, id: \.self) { type in
            Text(type.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(Color(type.capitalized))
                        .stroke(Color.black, lineWidth: 0.1)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
        }
    }
    
    var body: some View {
        switch widgetSize {
        case .systemMedium:
            HStack {
                pokemonImage
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name.capitalized)
                        .font(.title2)
                        .fontWeight(.black)
                    HStack(spacing: 6) {
                        typesView
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal)
        case .systemLarge:
            VStack {
                Text(entry.name.capitalized)
                    .font(.largeTitle)
                    .fontWeight(.black)
                pokemonImage
                HStack(spacing: 8) {
                    typesView
                }
            }
            .padding()
        default:
                pokemonImage
        }
    }
}

struct DexWidget: Widget {
    let kind: String = "DexWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DexWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(entry.types.first?.capitalized ?? "Gray")
                }
        }
        .configurationDisplayName("Pokedex")
        .description("Acompanhe seus Pokémons capturados.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
#Preview(as: .systemSmall) {
    DexWidget()
} timeline: {
    SimpleEntry.placeholder
    SimpleEntry.placeholder2
}

#Preview(as: .systemMedium) {
    DexWidget()
} timeline: {
    SimpleEntry.placeholder
    SimpleEntry.placeholder2
}

#Preview(as: .systemLarge) {
    DexWidget()
} timeline: {
    SimpleEntry.placeholder
    SimpleEntry.placeholder2
}
