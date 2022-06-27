//
//  ContentView.swift
//  w929 WatchKit Extension
//
//  Created by Yotam Lichter on 13/06/2022.
//

import SwiftUI

var HOME = "תוכן"

struct Chapter: Decodable, Identifiable {
    let id: String
    let index: Int
}

struct Book: Decodable, Identifiable {
    let id: String
    let chapters: [Chapter]
}

struct BookGroup: Decodable, Identifiable {
    let id: String
    let books: [Book]
}

struct CahpterGuide: Decodable {
    let title: String
    let txt_file_path: String
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

struct ContentView: View {

    @State private var viewText = ""
    @State private var curBookGroup = ""
    @State private var curBook = ""
    
    @State private var title = HOME
    @State private var prevTitle = ""
    @State private var nextTitle = ""
    @State private var pos = 0
    var bookGroup:[BookGroup] =  load("app_data/map.json")
    var chapterGuide:[CahpterGuide] =  load("app_data/capter_guide.json")
    var mmap = ""
    var body: some View {
        NavigationView {
            ScrollView {
                ScrollViewReader { value in
                    if curBookGroup != "" {
                        Button(HOME) {
                            curBookGroup = ""
                            curBook = ""
                            viewText = ""
                            title = HOME
                        }.id(0)
                    }
                    if viewText == "" {
                        ForEach(bookGroup) { g in
                            if curBookGroup == "" {
                                Button(g.id) {
                                    curBookGroup = g.id
                                    title = g.id
                                }
                            }
                            if curBookGroup == g.id {
                                ForEach(g.books) { b in
                                    if curBook == "" {
                                        Button(b.id) {
                                            curBook = b.id
                                            title = b.id
                                        }
                                    }
                                    if curBook == b.id {
                                        ForEach(b.chapters) { c in
                                            Button(c.id) {
                                                loadChapter(x: c.index)
                                                value.scrollTo(0)
                                            }
                                        }
                                    }

                                }
                            }
                        }
                    } else {
                        if prevTitle != "" {
                            Button(prevTitle) {
                                loadChapter(x: pos - 1)
                            }
                        }
                        Text(viewText).multilineTextAlignment(.trailing).lineLimit(nil)
                        if nextTitle != "" {
                            Button(nextTitle) {
                                loadChapter(x: pos + 1)
                                value.scrollTo(0)
                            }
                        }
                    }
                }
            }
        }.navigationTitle(title)
    }
    
    
    func loadChapter(x: Int) {
        let filename = "\(x).txt"
        print("loading: \(filename)")
        print(chapterGuide[x])
        let chapterData = chapterGuide[x]
        if let filepath = Bundle.main.path(forResource: chapterData.txt_file_path, ofType: nil) {
            do {
                viewText = try String(contentsOfFile: filepath)
                title = chapterData.title
                prevTitle = ""
                nextTitle = ""
                if x > 0 {
                    prevTitle = chapterGuide[x - 1].title
                }
                if x + 1 < chapterGuide.count {
                    nextTitle = chapterGuide[x + 1].title
                }
                pos = x
            } catch {
                // contents could not be loaded
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
