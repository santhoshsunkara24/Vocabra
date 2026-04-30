import '../models/word_entry.dart';

class DailyWordService {
  Future<WordEntry> getDailyWord() async {
    final words = [
      {"word": "Articulate", "meaning": "Having or showing the ability to speak fluently and coherently.", "example": "She was an articulate speaker.", "pronunciation": "ar · TIK · yuh · luht"},
      {"word": "Resilient", "meaning": "Able to withstand or recover quickly from difficult conditions.", "example": "She showed her resilient nature.", "pronunciation": "ri · ZIL · yuhnt"},
      {"word": "Pragmatic", "meaning": "Dealing with things sensibly and realistically in a practical way.", "example": "A pragmatic approach to politics.", "pronunciation": "prag · MAT · ik"},
      {"word": "Meticulous", "meaning": "Showing great attention to detail; very careful and precise.", "example": "Meticulous attention to detail.", "pronunciation": "muh · TIK · yuh · luhs"},
      {"word": "Plethora", "meaning": "A large or excessive amount of something.", "example": "A plethora of advice.", "pronunciation": "PLETH · er · uh"},
      {"word": "Eloquent", "meaning": "Fluent or persuasive in speaking or writing.", "example": "An eloquent speaker.", "pronunciation": "EL · uh · kwuhnt"},
      {"word": "Epiphany", "meaning": "A moment of sudden and great revelation or realization.", "example": "I had an epiphany during the meeting.", "pronunciation": "ih · PIF · uh · nee"},
      {"word": "Paradigm", "meaning": "A typical example or pattern of something; a model.", "example": "The discovery was a new paradigm for science.", "pronunciation": "PAR · uh · dime"},
      {"word": "Tenacious", "meaning": "Tending to keep a firm hold of something; clinging or adhering closely.", "example": "A tenacious grip on power.", "pronunciation": "tuh · NAY · shuhs"},
      {"word": "Candid", "meaning": "Truthful and straightforward; frank.", "example": "Her candid response was appreciated.", "pronunciation": "KAN · did"},
      {"word": "Serendipity", "meaning": "The occurrence of events by chance in a happy or beneficial way.", "example": "A fortunate stroke of serendipity.", "pronunciation": "ser · uhn · DIP · ih · tee"},
      {"word": "Ubiquitous", "meaning": "Present, appearing, or found everywhere.", "example": "His ubiquitous influence was felt by all.", "pronunciation": "yoo · BIK · wih · tuhs"},
      {"word": "Magnanimous", "meaning": "Generous or forgiving, especially towards a rival or less powerful person.", "example": "A magnanimous gesture of peace.", "pronunciation": "mag · NAN · uh · muhs"},
      {"word": "Lucid", "meaning": "Expressed clearly; easy to understand.", "example": "A lucid account of the events.", "pronunciation": "LOO · sid"},
      {"word": "Trivial", "meaning": "Of little value or importance.", "example": "Don't bother with trivial details.", "pronunciation": "TRIV · ee · uhl"},
      {"word": "Profound", "meaning": "Very great or intense; having or showing great knowledge.", "example": "A profound sense of loss.", "pronunciation": "pruh · FOUND"},
      {"word": "Lethargic", "meaning": "Affected by lethargy; sluggish and apathetic.", "example": "I felt tired and lethargic.", "pronunciation": "luh · THAR · jik"},
      {"word": "Melancholy", "meaning": "A feeling of pensive sadness, typically with no obvious cause.", "example": "An air of melancholy surrounded him.", "pronunciation": "MEL · uhn · kol · ee"},
      {"word": "Audacious", "meaning": "Showing a willingness to take surprisingly bold risks.", "example": "A series of audacious schemes.", "pronunciation": "aw · DAY · shuhs"},
      {"word": "Conundrum", "meaning": "A confusing and difficult problem or question.", "example": "One of the most difficult conundrums for the team.", "pronunciation": "kuh · NUN · druhm"},
      {"word": "Fastidious", "meaning": "Very attentive to and concerned about accuracy and detail.", "example": "He chooses his words with fastidious care.", "pronunciation": "fa · STID · ee · uhs"},
      {"word": "Garrulous", "meaning": "Excessively talkative, especially on trivial matters.", "example": "A garrulous old man.", "pronunciation": "GAIR · uh · luhs"},
      {"word": "Inquisitive", "meaning": "Curious or inquiring.", "example": "He was a very inquisitive child.", "pronunciation": "in · KWIZ · uh · tiv"},
      {"word": "Juxtapose", "meaning": "Place or deal with close together for contrasting effect.", "example": "Black-and-white photos juxtaposed with color images.", "pronunciation": "JUK · stuh · poze"},
      {"word": "Munificent", "meaning": "Larger or more generous than is usual or necessary.", "example": "A munificent gesture.", "pronunciation": "myoo · NIF · uh · suhnt"},
      {"word": "Nefarious", "meaning": "Wicked or criminal.", "example": "The nefarious activities of the organized-crime syndicates.", "pronunciation": "nuh · FAIR · ee · uhs"},
      {"word": "Obtuse", "meaning": "Annoyingly insensitive or slow to understand.", "example": "He wondered if the doctor was being deliberately obtuse.", "pronunciation": "uhb · TOOS"},
      {"word": "Quixotic", "meaning": "Exceedingly idealistic; unrealistic and impractical.", "example": "A vast and perhaps quixotic project.", "pronunciation": "kwik · SOT · ik"},
      {"word": "Sycophant", "meaning": "A person who acts obsequiously toward someone important to gain advantage.", "example": "A flock of sycophants.", "pronunciation": "SIK · uh · fuhnt"},
      {"word": "Trepidation", "meaning": "A feeling of fear or agitation about something that may happen.", "example": "The men set off in fear and trepidation.", "pronunciation": "trep · ih · DAY · shuhn"},
    ];

    // Get absolute days since epoch so it mathematically never repeats on month rollovers
    final daysSinceEpoch = DateTime.now().difference(DateTime(1970, 1, 1)).inDays;
    final index = daysSinceEpoch % words.length;
    
    final data = words[index];

    return WordEntry(
      id: "daily_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}",
      word: data["word"],
      dictionaryMeaning: data["meaning"],
      usageExample: data["example"],
      pronunciation: data["pronunciation"],
      dateAdded: DateTime.now(),
      source: 'ai',
    );
  }
}
