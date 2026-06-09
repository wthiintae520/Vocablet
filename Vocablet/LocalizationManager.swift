import SwiftUI

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case zhTW = "zh-TW"
    case zhCN = "zh-CN"
    case en   = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zhTW: return "繁體中文"
        case .zhCN: return "简体中文"
        case .en:   return "English"
        }
    }

    var flag: String {
        switch self {
        case .zhTW: return "🇹🇼"
        case .zhCN: return "🇨🇳"
        case .en:   return "🇺🇸"
        }
    }

    /// 從系統 Locale 推導預設語言
    static var systemDefault: AppLanguage {
        let lang   = Locale.current.language.languageCode?.identifier ?? "en"
        let region = Locale.current.region?.identifier ?? ""
        if lang == "zh" {
            return (region == "TW" || region == "HK") ? .zhTW : .zhCN
        }
        return .en
    }
}

// MARK: - Localization Manager

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appUILanguage") }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "appUILanguage"),
           let lang  = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            language = AppLanguage.systemDefault
        }
    }

    // ────────────────────────────────────────────────────────────
    // MARK: - General
    // ────────────────────────────────────────────────────────────
    var cancel:    String { s("取消",   "取消",   "Cancel") }
    var save:      String { s("儲存",   "保存",   "Save") }
    var done:      String { s("完成",   "完成",   "Done") }
    var add:       String { s("加入",   "加入",   "Add") }
    var edit:      String { s("編輯",   "编辑",   "Edit") }
    var unnamed:   String { s("未命名", "未命名", "Unnamed") }
    var play:      String { s("播放",   "播放",   "Play") }

    // ────────────────────────────────────────────────────────────
    // MARK: - App
    // ────────────────────────────────────────────────────────────
    var appName:    String { "Vocablet" }
    var appTagline: String { s("你的英文單字小幫手", "你的英文单词小助手", "Your vocabulary companion") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Tabs
    // ────────────────────────────────────────────────────────────
    var tabWords:     String { s("單字", "单词", "Words") }
    var tabSearch:    String { s("搜尋", "搜索", "Search") }
    var tabFlashcard: String { s("字卡", "字卡", "Cards") }
    var tabSettings:  String { s("設定", "设置", "Settings") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Home
    // ────────────────────────────────────────────────────────────
    var allWords:    String { s("所有單字", "所有单词", "All Words") }
    var allCards:    String { s("所有字卡", "所有字卡", "All Cards") }
    var favorites:   String { s("我的最愛", "我的收藏", "Favorites") }
    var folders:     String { s("書冊",    "书册",    "Booklets") }
    var booklets:    String { s("書冊",    "书册",    "Booklets") }
    var wordsCount:  String { s("個單字",   "个单词",   " words") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Folder / Word List
    // ────────────────────────────────────────────────────────────
    var wordList:  String { s("單字列表", "单词列表", "Word List") }
    var startQuiz: String { s("開始測驗", "开始测验", "Start Quiz") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Word Detail
    // ────────────────────────────────────────────────────────────
    var definition:  String { s("定義",    "定义",    "Definition") }
    var examples:    String { s("例句",    "例句",    "Examples") }
    var notes:       String { s("筆記",    "笔记",    "Notes") }
    var tags:        String { s("標籤",    "标签",    "Tags") }
    var reviewCount: String { s("複習次數", "复习次数", "Reviews") }
    var mastery:     String { s("熟悉度",  "熟悉度",  "Mastery") }
    var addedDate:    String { s("加入日期", "加入日期", "Added") }
    var modifiedDate: String { s("修改日期", "修改日期", "Modified") }
    var flipHint:    String { s("點擊翻轉查看定義", "点击翻转查看定义", "Tap to see definition") }

    func masteryText(_ level: Int16) -> String {
        let texts = [
            s("新",  "新",  "New"),
            s("入門", "入门", "Beginner"),
            s("學習", "学习", "Learning"),
            s("熟悉", "熟悉", "Familiar"),
            s("精通", "精通", "Master"),
        ]
        let idx = Int(min(max(level, 0), 4))
        return texts[idx]
    }

    // ────────────────────────────────────────────────────────────
    // MARK: - Add Word
    // ────────────────────────────────────────────────────────────
    var addWordTitle:  String { s("新增單字",   "新增单词",   "New Word") }
    var editWordTitle: String { s("編輯單字",   "编辑单词",   "Edit Word") }
    var wordTermLabel: String { s("單字",      "单词",      "Word") }
    var phoneticHint:  String { s("音標（選填）例：/ˌserənˈdɪpɪti/",
                                   "音标（选填）例：/ˌserənˈdɪpɪti/",
                                   "Phonetic (optional) e.g. /ˌserənˈdɪpɪti/") }
    var defLabel:      String { s("定義 *",    "定义 *",    "Definition *") }
    var folderLabel:   String { s("書冊",     "书册",     "Booklet") }
    var noCategory:    String { s("不分類",   "不分类",   "No Category") }
    var selectFolder:  String { s("選擇書冊", "选择书册", "Select Booklet") }
    var addToFav:      String { s("加入最愛",  "加入收藏",  "Add to Favorites") }
    var tagInputHint:  String { s("輸入標籤後按 Enter", "输入标签后按回车", "Enter tag, press Return") }

    // ────────────────────────────────────────────────────────────
    // MARK: - New Word Fields
    // ────────────────────────────────────────────────────────────
    var chineseTranslation:   String { s("中文翻譯義項",        "中文翻译义项",        "Chinese Translation") }
    var partOfSpeech:         String { s("詞性",               "词性",               "Part of Speech") }
    var exampleTranslation:   String { s("例句中文翻譯",        "例句中文翻译",        "Example Translation") }
    var exampleSection:       String { s("英文例句",            "英文例句",            "Example Sentence") }
    var englishDefinition:    String { s("英文詳細釋義",        "英文详细释义",        "English Definition") }
    var myNotes:              String { s("我的學習心得與聯想備忘（自訂筆記）",
                                         "我的学习心得与联想备忘（自订笔记）",
                                         "My Study Notes") }
    var saveWord:             String { s("儲存單字筆記",        "保存单词笔记",        "Save Word") }
    var starFavorite:         String { s("星標收藏",            "星标收藏",            "Favorite") }
    var markAsMastered:       String { s("改為精通熟記",        "改为精通熟记",        "Mark as Mastered") }
    var masteryLevelLabel:    String { s("熟練度",              "熟练度",              "Proficiency") }
    var optionalHint:         String { s("（選填）",            "（选填）",            "(optional)") }
    var aiAutoFill:           String { s("AI 自動填寫",         "AI 自动填写",         "AI Auto-fill") }
    var aiFilling:            String { s("填寫中…",            "填写中…",            "Filling…") }
    var newWordTitle:         String { s("新增單字卡",          "新增单词卡",          "New Card") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Settings / AI
    // ────────────────────────────────────────────────────────────
    var displaySection:      String { s("顯示",                   "显示",                   "Display") }
    var showMasteryDots:     String { s("顯示熟練度色點",         "显示熟练度色点",          "Show Mastery Dots") }
    var showMasteryDotsHint: String { s("在單字清單中顯示熟練度色點", "在单词列表中显示熟练度色点", "Show colored dots in word lists") }

    var aiSection:     String { s("AI 設定",         "AI 设置",         "AI Settings") }
    var aiPoweredBy:   String { s("由 Claude (Anthropic) 提供",
                                   "由 Claude (Anthropic) 提供",
                                   "Powered by Claude (Anthropic)") }
    var aiProxyFooter: String { s("AI 自動填寫功能由後端服務代理，使用者無需填入任何 API Key。",
                                   "AI 自动填写功能由后端服务代理，用户无需填入任何 API Key。",
                                   "AI Auto-fill is handled server-side. No API key required from users.") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Add Folder
    // ────────────────────────────────────────────────────────────
    var addFolderTitle:    String { s("新增書冊",       "新增书册",       "New Booklet") }
    var folderNameLabel:   String { s("書冊名稱",       "书册名称",       "Booklet Name") }
    var folderNameHint:    String { s("例：日常英文、商務用語", "例：日常英语、商务用语", "e.g. Daily English") }
    var iconLabel:         String { s("圖示",           "图标",           "Icon") }
    var colorLabel:        String { s("顏色",           "颜色",           "Color") }
    var renameBooklet:     String { s("重新命名",       "重命名",         "Rename") }
    var deleteBooklet:     String { s("刪除",           "删除",           "Delete") }
    var sortByNameAZ:      String { s("依名字排列 A→Z", "按名称排列 A→Z", "Sort A→Z") }
    var sortByDate:        String { s("依新增時間排列", "按添加时间排列", "Sort by Date Added") }
    var nameLabel:         String { s("名稱",           "名称",           "Name") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Search
    // ────────────────────────────────────────────────────────────
    var searchTitle:    String { s("搜尋",    "搜索",    "Search") }
    var filterAll:      String { s("全部",    "全部",    "All") }
    var filterTerm:     String { s("單字",    "单词",    "Word") }
    var filterDef:      String { s("定義",    "定义",    "Definition") }
    var filterTag:      String { s("標籤",    "标签",    "Tag") }
    var allTagsTitle:   String { s("所有標籤", "所有标签", "All Tags") }
    var searchPrompt:   String { s("搜尋單字、定義或標籤", "搜索单词、定义或标签", "Search words, definitions or tags") }
    var emptyWords:     String { s("還沒有單字", "还没有单词", "No Words Yet") }
    var emptyWordsHint: String { s("點擊右上角 + 新增你的第一個單字", "点击右上角+新增你的第一个单词", "Tap + to add your first word") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Flashcard
    // ────────────────────────────────────────────────────────────
    var flashcardTitle: String { s("字卡複習",    "字卡复习",    "Flashcard Review") }
    var know:           String { s("認識",       "认识",       "Know") }
    var dontKnow:       String { s("不熟",       "不熟",       "Don't Know") }
    var sessionDone:    String { s("複習完成！",  "复习完成！",  "Session Complete!") }
    var tryAgain:       String { s("再來一次",    "再来一次",    "Try Again") }
    var noCardsTitle:   String { s("沒有單字可複習", "没有单词可复习", "No Words to Review") }
    var noCardsHint:    String { s("請先新增單字",  "请先新增单词",  "Please add some words first") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Quiz
    // ────────────────────────────────────────────────────────────
    var quizResultTitle:  String { s("測驗結果",          "测验结果",          "Quiz Results") }
    var questionPrompt:   String { s("這個單字的定義是？",  "这个单词的定义是？",  "What is the definition?") }
    var nextQuestion:     String { s("下一題",            "下一题",            "Next") }
    var quizAgain:        String { s("再測一次",           "再测一次",          "Retry") }
    var quizFinish:       String { s("完成",               "完成",              "Finish") }
    var reviewWordsLabel: String { s("需要複習的單字",      "需要复习的单词",     "Words to Review") }

    func quizResultMessage(percent: Int) -> String {
        if percent >= 80 { return s("太棒了！", "太棒了！", "Excellent!") }
        if percent >= 60 { return s("繼續加油！", "继续加油！", "Keep Going!") }
        return s("再接再厲！", "再接再厉！", "Try Harder!")
    }

    // ────────────────────────────────────────────────────────────
    // MARK: - Settings
    // ────────────────────────────────────────────────────────────
    var settingsTitle:     String { s("設定",         "设置",         "Settings") }
    var languageSection:   String { s("語言設定",     "语言设置",     "Language") }
    var uiLanguageLabel:   String { s("介面語言",     "界面语言",     "Interface Language") }
    var pronunciationLabel:String { s("發音腔調",     "发音口音",     "Pronunciation Accent") }
    var americanEng:       String { s("🇺🇸 美式英語", "🇺🇸 美式英语", "🇺🇸 American") }
    var britishEng:        String { s("🇬🇧 英式英語", "🇬🇧 英式英语", "🇬🇧 British") }
    var testPronun:        String { s("試聽發音",     "试听发音",     "Test Pronunciation") }
    var phoneticSystemLabel: String { s("音標系統",       "音标系统",       "Phonetic System") }
    var kkSystem:            String { s("KK 音標（台灣）",  "KK 音标（台湾）",  "KK (Taiwan)") }
    var ipaSystem:           String { s("IPA 國際音標",    "IPA 国际音标",    "IPA (International)") }
    var kkPhoneticLabel:     String { s("KK 音標",        "KK 音标",        "KK Phonetic") }
    var ipaPhoneticLabel:    String { s("IPA 音標",       "IPA 音标",       "IPA Phonetic") }
    var langFooter:        String { s("介面語言預設跟隨系統語言", "界面语言默认跟随系统语言", "Defaults to device language") }
    var notifSection:      String { s("通知設定",     "通知设置",     "Notifications") }
    var dailyReminder:     String { s("每日複習提醒", "每日复习提醒", "Daily Review Reminder") }
    var reminderTime:      String { s("提醒時間",     "提醒时间",     "Reminder Time") }
    var syncSection:       String { s("同步",         "同步",         "Sync") }
    var iCloudSync:        String { s("iCloud 同步",  "iCloud 同步",  "iCloud Sync") }
    var autoSync:          String { s("自動",         "自动",         "Auto") }
    var aboutSection:      String { s("關於",         "关于",         "About") }
    var versionLabel:      String { s("版本",         "版本",         "Version") }
    var developerLabel:    String { s("開發者",       "开发者",       "Developer") }

    // ────────────────────────────────────────────────────────────
    // MARK: - Private helper
    // ────────────────────────────────────────────────────────────
    private func s(_ tw: String, _ cn: String, _ en: String) -> String {
        switch language {
        case .zhTW: return tw
        case .zhCN: return cn
        case .en:   return en
        }
    }
}
