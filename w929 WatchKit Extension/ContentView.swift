//
//  ContentView.swift
//  w929 WatchKit Extension
//
//  Created by Yotam Lichter on 13/06/2022.
//

import SwiftUI

struct ContentView: View {

    @State private var viewText = ""
    @State private var pos = 0
    var body: some View {
        ScrollView {
            ScrollViewReader { value in
                Button("Back") {
                    loadChapter(x: pos - 1)
                }.id(0)
                if pos != 0 {
                    Text(viewText).multilineTextAlignment(.trailing).lineLimit(nil)
                }
                Button("Next") {
                    loadChapter(x: pos + 1)
                    value.scrollTo(0)
                }
            }
        }
    }
    func loadChapter(x: Int) {
        let filename = "\(x).txt"
        print("loading: \(filename)")
        if x == 0 {
            pos = 0
            viewText = ""
            return
        }
        if let filepath = Bundle.main.path(forResource: "\(x)", ofType: "txt") {
            do {
                viewText = try String(contentsOfFile: filepath)
//                print(viewText)
                pos = x
            } catch {
                // contents could not be loaded
            }
        } else {
            // example.txt not found!
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
