//
//  ContentView.swift
//  w929 WatchKit Extension
//
//  Created by Yotam Lichter on 13/06/2022.
//

import SwiftUI

var HOME = "תוכן"
var DAILY = "הפרק היומי"

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

var bookGroup:[BookGroup] =  load("app_data/map.json")
var chapterGuide:[CahpterGuide] =  load("app_data/capter_guide.json")

struct ContentView: View {
    @State private var pos = 0
    @State private var viewText = ""
    @State private var curBookGroup = ""
    @State private var curBook = ""
    @State private var title = HOME
    @State private var prevTitle = ""
    @State private var nextTitle = ""
    
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
                    } else {
                        Button(DAILY) {
                            curBookGroup = "Daily"
                            loadDailyChapter()
                        }
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
                                            value.scrollTo(0)
                                        }
                                    }
                                    if curBook == b.id {
                                        ForEach(b.chapters) { c in
                                            Button(c.id) {
                                                loadChapter(newPos: c.index)
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
                                loadChapter(newPos: pos - 1)
                                value.scrollTo(0)
                            }
                        }
                        Text(viewText).multilineTextAlignment(.trailing).lineLimit(nil)
                        if nextTitle != "" {
                            Button(nextTitle) {
                                loadChapter(newPos: pos + 1)
                                value.scrollTo(0)
                            }
                        }
                    }
                }
            }
        }.navigationTitle(title)
    }
    
    func loadDailyChapter() {
        let startDate = Date.init(timeIntervalSince1970: 1644098400) // 06/02/2022 00:00 GMT+2
        let daySince = Int(startDate.distance(to: Date.now)/86400)
        let weekPassInt = daySince / 7
        let dayReminder = daySince % 7
        let index = weekPassInt * 5 + min(dayReminder, 4)
        loadChapter(newPos: index)
    }
    
    
    func loadChapter(newPos: Int) {
        let chapterData = chapterGuide[newPos]
        if let filepath = Bundle.main.path(forResource: chapterData.txt_file_path, ofType: nil) {
            do {
                viewText = try String(contentsOfFile: filepath)
                title = chapterData.title
                prevTitle = ""
                nextTitle = ""
                if newPos > 0 {
                    prevTitle = chapterGuide[newPos - 1].title
                }
                if newPos + 1 < chapterGuide.count {
                    nextTitle = chapterGuide[newPos + 1].title
                }
                pos = newPos
            } catch {
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
