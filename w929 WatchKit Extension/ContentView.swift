//
//  ContentView.swift
//  w929 WatchKit Extension
//
//  Created by Yotam Lichter on 13/06/2022.
//

import SwiftUI

var HOME = "תפריט ראשי"
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

func getColor(r: Double, g: Double, b: Double) -> Color {
    return Color(red: r / 255, green: g / 255, blue: b / 255)
}

var bookGroups:[BookGroup] =  load("app_data/map.json")
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
                        HStack {
                            Button {
                                curBookGroup = ""
                                curBook = ""
                                viewText = ""
                                title = HOME
                            } label: {
                                Label(HOME, systemImage: "menucard")
                            }.background(getColor(r: 255, g: 66, b:161)).cornerRadius(8)
                            if viewText != "" && prevTitle != "" {
                                Button {
                                    loadChapter(newPos: pos - 1)
                                    value.scrollTo(0)
                                } label: {
                                    Label(prevTitle, systemImage: "arrow.forward")
                                }.background(getColor(r: 254, g: 174, b:0)).cornerRadius(8)
                            }
                        }.id(0)
                    } else {
                        Button {
                            curBookGroup = "Daily"
                            loadDailyChapter()
                        } label: {
                            Label(DAILY, systemImage: "pencil")
                        }
                        .background(getColor(r: 0, g: 161, b:255)).cornerRadius(8)
                    }
                    Spacer(minLength: 20)
                    if viewText == "" {
                        ForEach(bookGroups) { bookGroup in
                            if curBookGroup == "" {
                                Button(bookGroup.id) {
                                    curBookGroup = bookGroup.id
                                    title = bookGroup.id
                                }
                            }
                            if curBookGroup == bookGroup.id {
                                ForEach(bookGroup.books) { book in
                                    if curBook == "" {
                                        Button(book.id) {
                                            curBook = book.id
                                            title = book.id
                                            value.scrollTo(0)
                                        }
                                    }
                                    if curBook == book.id {
                                        ForEach(book.chapters) { chapter in
                                            Button(chapter.id) {
                                                loadChapter(newPos: chapter.index)
                                                value.scrollTo(0)
                                            }
                                        }
                                    }

                                }
                            }
                        }
                    } else {
                        Text(viewText).multilineTextAlignment(.trailing).lineLimit(nil)
                        if nextTitle != "" {
                            Button {
                                loadChapter(newPos: pos + 1)
                                value.scrollTo(0)
                            } label: {
                                Label(nextTitle, systemImage: "arrow.backward")
                            }.background(getColor(r: 254, g: 174, b:0)).cornerRadius(8)
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
        loadChapter(newPos: index % 929)
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
