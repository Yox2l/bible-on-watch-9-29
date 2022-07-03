const fs = require('fs');
const moment = require('moment')
const timelines = require('./timelines.json');

const ONE_TO_NINE = 'אבגדהוזחט'
const TEN_TO_NINTY = 'יכלמנסעפצ'
function numberToHebrewCount(n) {
    n = Number(n);
    let result;
    if(n === 100) {
        result = 'ק'
    } else if(n > 100) { // The largest chapter in the bible is less than 200 sentces
        result = 'ק' + numberToHebrewCount(n - 100)
    } else if(n < 10) {
        result = ONE_TO_NINE[n - 1]
    } else if(n % 10 === 0) {
        result = TEN_TO_NINTY[n/10 - 1]
    } else {
        result = TEN_TO_NINTY[Math.floor(n/10) - 1] + numberToHebrewCount(n % 10)
    }
    if (result == 'יה') return 'טו'
    if (result == 'יו') return 'טז'
    return result
}

const COLORS = [
    "255,97,97",
    "255,111,97",
    "255,136,97",
    "255,176,97",
    "255,215,97",
    "255,255,97",
    "215,255,97",
    "176,255,97",
    "136,255,97",
    "97,255,97",
    "97,255,136",
    "97,255,176",
    "97,255,215",
    "97,255,255",
    "97,215,255",
    "97,176,255",
    "97,136,255",
    "97,97,255",
    "136,97,255",
    "176,97,255",
    "215,97,255",
    "255,97,255",
    "255,97,215",
    "255,97,176",
    "255,97,136",
    "255,97,97"
]
function calcChapterColor(bookColor, nextColor, index, maxIndex) {
    const color = bookColor.split(',')
    const next = nextColor.split(',')
    const r = parseInt(color[0]) + (parseInt(next[0]) - parseInt(color[1])) * (index / maxIndex)
    const g = parseInt(color[1]) + (parseInt(next[1]) - parseInt(color[1])) * (index / maxIndex)
    const b = parseInt(color[2]) + (parseInt(next[2]) - parseInt(color[1])) * (index / maxIndex)
    return `${Math.round(r)},${Math.round(g)},${Math.round(b)}`
}

const BOOK_GROUP_TO_HEBREW = {
    torah: 'תורה',
    prophets: 'נביאים',
    writings: 'כתובים'
}

async function sleep(x) {
    return new Promise(resolve => setTimeout(resolve, x));
}

function makedirIfNotExists(newDirPath) {
    if(!fs.existsSync(newDirPath)) {
        fs.mkdirSync(newDirPath)
    }
}

async function get_929_chapter_data(books_group, book, chapter) {
    const filename = `data/${books_group}/${book}/${chapter}.json`
    if(fs.existsSync(filename)) {
        return {
            chapterData: JSON.parse(fs.readFileSync(filename)),
            filename: filename
        }
    }
    makedirIfNotExists(`data/${books_group}`)
    makedirIfNotExists(`data/${books_group}/${book}`)
    console.log(`Downloading ${filename}`)
    const url = `https://bible.929.org.il/json/index.php?action=get_chapter_info&books_group=${books_group}&book=${book.replace(/_/g,'-')}&chapter=${chapter}`
    console.log(url)
    const respond  = await fetch(url)
    respond_json = await respond.json()
    fs.writeFileSync(filename, JSON.stringify(respond_json, null, 2), 'utf8')
    await sleep(500)
    return {
        chapterData: respond_json,
        filename: filename
    }
}

async function createChapterContentAndTitles(books_group, book, chapter) {
    const {chapterData, filename} = await get_929_chapter_data(books_group, book, chapter)
    let content = ''
    chapterData.info.verses.forEach(function(item, inx) {
        if(content) {
            content += ' '
        }
        content += `(${numberToHebrewCount(inx + 1)}) ${item.verse}`
    })
    const txt_file_path = 'app_' + filename.replace('.json', '.txt')
    makedirIfNotExists(`app_data/${books_group}`)
    makedirIfNotExists(`app_data/${books_group}/${book}`)
    fs.writeFileSync(txt_file_path, content, 'utf8')
    const sp = chapterData.title.split('-')
    const longTitle = `${sp[0]} פרק ${numberToHebrewCount(sp[2])}`
    const shortTitle = `פרק ${numberToHebrewCount(sp[2])}`
    return {
        longTitle: longTitle,
        shortTitle: shortTitle,
        hebrew_book: sp[0],
        txt_file_path
    }
}

const scrap_929_data = async function() {
    makedirIfNotExists('data')
    makedirIfNotExists('app_data')
    const capter_guide = []
    const map = {}
    let counter = 0
    for(let book in timelines.timeline) {
        console.log(book)
        const walls = timelines.timeline[book].walls
        for(let i in walls) {
            const wall = walls[i]
            if(!wall.chapter) continue;
            console.log(`\t ${wall.chapter}`)
            let books_group = 'torah'
            if(wall.post_title.includes('Prophets')) books_group = 'prophets'
            if(wall.post_title.includes('Writings')) books_group = 'writings'        
            const {longTitle, shortTitle, hebrew_book, txt_file_path} = await createChapterContentAndTitles(books_group, book, wall.chapter)
            const hebrew_book_group = BOOK_GROUP_TO_HEBREW[books_group]
            map[hebrew_book_group] = map[hebrew_book_group] || {}
            map[hebrew_book_group][hebrew_book] = map[hebrew_book_group][hebrew_book] || []
            map[hebrew_book_group][hebrew_book].push({
                title: shortTitle, 
                index: counter
            })
            capter_guide.push({
                title:longTitle, txt_file_path
            })
            counter++
        }
    }
    const finalMap = []
    for(let book_group in map) {
        const books = []
        const book_group_color_index = finalMap.length * 4
        for(let book in map[book_group]) {
            const bookColor = COLORS[book_group_color_index + books.length % COLORS.length]
            const nextColor = COLORS[(book_group_color_index + books.length + 15) % COLORS.length]
            books.push({
                id: book,
                color: COLORS[book_group_color_index + books.length % COLORS.length],
                chapters: map[book_group][book].map((x, i) => ({
                    index: x.index,
                    id: x.title,
                    color: calcChapterColor(bookColor, nextColor, i, map[book_group][book].length),
                }))
            })
        }
        finalMap.push({
            id: book_group,
            books,
            color: COLORS[book_group_color_index]
        })
    }
    fs.writeFileSync(`app_data/map.json`, JSON.stringify(finalMap, null, 2), 'utf8')
    fs.writeFileSync(`app_data/capter_guide.json`, JSON.stringify(capter_guide, null, 2), 'utf8')
}


scrap_929_data()